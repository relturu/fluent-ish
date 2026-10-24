import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(PlaygroundSupport)
import PlaygroundSupport
#endif

private struct TranslatorConfiguration {
    let key: String
    let region: String
    let endpoint: URL

    static func load(from environment: [String: String]) throws -> TranslatorConfiguration {
        guard let key = environment["AZURE_KEY"], !key.isEmpty else {
            throw TranslatorError.missingEnvironmentVariable("AZURE_KEY")
        }
        guard let region = environment["AZURE_REGION"], !region.isEmpty else {
            throw TranslatorError.missingEnvironmentVariable("AZURE_REGION")
        }
        guard
            let endpointValue = environment["AZURE_ENDPOINT"],
            let endpoint = URL(string: endpointValue),
            let components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false),
            components.scheme?.lowercased() == "https",
            components.host != nil,
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil
        else {
            throw TranslatorError.invalidEndpoint
        }

        return TranslatorConfiguration(key: key, region: region, endpoint: endpoint)
    }
}

private enum TranslatorError: LocalizedError {
    case missingEnvironmentVariable(String)
    case invalidEndpoint
    case invalidResponse
    case networkFailure(String, String)
    case httpStatus(Int, String?)
    case decodingFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let name):
            return "Required environment variable \(name) is missing or empty."
        case .invalidEndpoint:
            return "AZURE_ENDPOINT must be an HTTPS base URL without credentials, query, or fragment."
        case .invalidResponse:
            return "The service returned a non-HTTP response."
        case .networkFailure(let path, let detail):
            return "Network request to \(path) failed: \(detail)"
        case .httpStatus(let status, let requestID):
            if let requestID {
                return "Azure returned HTTP \(status) (request ID: \(requestID))."
            }
            return "Azure returned HTTP \(status)."
        case .decodingFailed(let path, let detail):
            return "Could not decode the \(path) response: \(detail)"
        }
    }
}

private struct TextRequest: Encodable {
    let text: String

    enum CodingKeys: String, CodingKey {
        case text = "Text"
    }
}

private struct DictionaryExampleRequest: Encodable {
    let text: String
    let translation: String

    enum CodingKeys: String, CodingKey {
        case text = "Text"
        case translation = "Translation"
    }
}

private struct TranslatorClient {
    let configuration: TranslatorConfiguration
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func lookup(_ text: String) async throws -> [DictionaryLookupResult] {
        try await post(
            path: "/dictionary/lookup",
            queryItems: [
                URLQueryItem(name: "from", value: "es"),
                URLQueryItem(name: "to", value: "en")
            ],
            body: [TextRequest(text: text)]
        )
    }

    func examples(for text: String, translation: String) async throws -> [DictionaryExampleResult] {
        try await post(
            path: "/dictionary/examples",
            queryItems: [
                URLQueryItem(name: "from", value: "es"),
                URLQueryItem(name: "to", value: "en")
            ],
            body: [DictionaryExampleRequest(text: text, translation: translation)]
        )
    }

    func translate(_ text: String) async throws -> [TranslateResult] {
        try await post(
            path: "/translate",
            queryItems: [
                URLQueryItem(name: "from", value: "es"),
                URLQueryItem(name: "to", value: "en")
            ],
            body: [TextRequest(text: text)]
        )
    }

    func detect(_ text: String) async throws -> [DetectResult] {
        try await post(
            path: "/detect",
            queryItems: [],
            body: [TextRequest(text: text)]
        )
    }

    private func post<Response: Decodable, Body: Encodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: [Body]
    ) async throws -> Response {
        guard var components = URLComponents(
            url: configuration.endpoint,
            resolvingAgainstBaseURL: false
        ) else {
            throw TranslatorError.invalidEndpoint
        }
        let basePath = components.path.hasSuffix("/")
            ? String(components.path.dropLast())
            : components.path
        components.path = basePath + path
        components.queryItems = [URLQueryItem(name: "api-version", value: "3.0")] + queryItems

        guard let url = components.url else {
            throw TranslatorError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue(configuration.region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranslatorError.networkFailure(path, error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslatorError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let requestID = httpResponse.value(forHTTPHeaderField: "X-RequestId")
            throw TranslatorError.httpStatus(httpResponse.statusCode, requestID)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw TranslatorError.decodingFailed(path, error.localizedDescription)
        }
    }
}

private func runDemonstration() async {
    #if canImport(PlaygroundSupport)
    defer { PlaygroundPage.current.finishExecution() }
    #endif

    do {
        let configuration = try TranslatorConfiguration.load(
            from: ProcessInfo.processInfo.environment
        )
        let translator = TranslatorClient(configuration: configuration)

        print("=== A. Dictionary Lookup: charlar (Spanish → English) ===")
        var exampleSource: String?
        var exampleTranslation: String?
        do {
            let results = try await translator.lookup("charlar")
            if let result = results.first,
               let best = result.translations.max(by: { $0.confidence < $1.confidence }) {
                print("Best translation: \(best.displayTarget)")
                print("Part of speech: \(best.posTag ?? "not provided")")
                print("Confidence: \(String(format: "%.2f%%", best.confidence * 100))")
                exampleSource = result.normalizedSource
                exampleTranslation = best.normalizedTarget
            } else {
                print("No dictionary translations were found for “charlar”.")
            }
        } catch {
            print("Dictionary lookup failed: \(error.localizedDescription)")
        }

        print("\n=== B. Dictionary Examples: charlar ===")
        if let exampleSource, let exampleTranslation {
            do {
                let results = try await translator.examples(
                    for: exampleSource,
                    translation: exampleTranslation
                )
                if let example = results.first?.examples.first {
                    print("Spanish: \(example.sourceSentence)")
                    print("English: \(example.targetSentence)")
                } else {
                    print("No example sentences are available for this translation.")
                }
            } catch {
                print("Dictionary examples failed: \(error.localizedDescription)")
            }
        } else {
            print("Skipped: lookup did not return a normalized translation.")
        }

        print("\n=== C. Translate: Spanish → English ===")
        do {
            let results = try await translator.translate(
                "En nuestra sobremesa nunca falta un cortado."
            )
            if let translation = results.first?.translations.first {
                print("English: \(translation.text)")
            } else {
                print("The translation response did not contain a translation.")
            }
        } catch {
            print("Translation failed: \(error.localizedDescription)")
        }

        print("\n=== D. Detect language ===")
        do {
            let results = try await translator.detect("un cortado bien cargado y risas")
            if let detection = results.first {
                print("Language: \(detection.language)")
                print("Confidence: \(String(format: "%.2f%%", detection.score * 100))")
            } else {
                print("The detection response did not contain a result.")
            }
        } catch {
            print("Language detection failed: \(error.localizedDescription)")
        }
    } catch {
        print("Azure Translator setup failed: \(error.localizedDescription)")
    }
}

#if canImport(PlaygroundSupport)
PlaygroundPage.current.needsIndefiniteExecution = true
#endif

Task {
    await runDemonstration()
}
