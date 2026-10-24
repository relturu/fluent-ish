import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct AzureTranslator: Sendable {
    public struct Configuration: Sendable {
        public let key: String
        public let region: String
        public let endpoint: URL

        public init(
            key: String,
            region: String,
            endpoint: URL = URL(string: "https://api.cognitive.microsofttranslator.com")!
        ) throws {
            guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AzureTranslatorError.missingConfiguration("AZURE_KEY")
            }
            guard !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AzureTranslatorError.missingConfiguration("AZURE_REGION")
            }
            guard
                endpoint.scheme?.lowercased() == "https",
                endpoint.host != nil,
                endpoint.user == nil,
                endpoint.password == nil,
                endpoint.query == nil,
                endpoint.fragment == nil
            else {
                throw AzureTranslatorError.invalidEndpoint
            }

            self.key = key
            self.region = region
            self.endpoint = endpoint
        }

        public static func from(bundle: Bundle = .main) throws -> Configuration {
            guard let key = bundle.object(forInfoDictionaryKey: "AZURE_KEY") as? String else {
                throw AzureTranslatorError.missingConfiguration("AZURE_KEY")
            }
            guard let region = bundle.object(forInfoDictionaryKey: "AZURE_REGION") as? String else {
                throw AzureTranslatorError.missingConfiguration("AZURE_REGION")
            }

            let endpointString =
                bundle.object(forInfoDictionaryKey: "AZURE_ENDPOINT") as? String
                ?? "https://api.cognitive.microsofttranslator.com"
            guard let endpoint = URL(string: endpointString) else {
                throw AzureTranslatorError.invalidEndpoint
            }

            return try Configuration(key: key, region: region, endpoint: endpoint)
        }
    }

    private let configuration: Configuration
    private let session: URLSession

    public init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func dictionaryLookup(
        text: String,
        from sourceLanguage: String = "es",
        to targetLanguage: String = "en"
    ) async throws -> [DictionaryLookupResult] {
        try await post(
            path: "/dictionary/lookup",
            parameters: [
                URLQueryItem(name: "from", value: sourceLanguage),
                URLQueryItem(name: "to", value: targetLanguage)
            ],
            body: [TextRequest(text: text)]
        )
    }

    public func dictionaryExamples(
        text: String,
        translation: String,
        from sourceLanguage: String = "es",
        to targetLanguage: String = "en"
    ) async throws -> [DictionaryExampleResult] {
        try await post(
            path: "/dictionary/examples",
            parameters: [
                URLQueryItem(name: "from", value: sourceLanguage),
                URLQueryItem(name: "to", value: targetLanguage)
            ],
            body: [DictionaryExampleRequest(text: text, translation: translation)]
        )
    }

    public func translate(
        text: String,
        from sourceLanguage: String = "es",
        to targetLanguage: String = "en"
    ) async throws -> [TranslateResult] {
        try await post(
            path: "/translate",
            parameters: [
                URLQueryItem(name: "from", value: sourceLanguage),
                URLQueryItem(name: "to", value: targetLanguage)
            ],
            body: [TextRequest(text: text)]
        )
    }

    public func detectLanguage(text: String) async throws -> [DetectResult] {
        try await post(path: "/detect", parameters: [], body: [TextRequest(text: text)])
    }

    private func post<Response: Decodable, Body: Encodable>(
        path: String,
        parameters: [URLQueryItem],
        body: [Body]
    ) async throws -> Response {
        guard var components = URLComponents(
            url: configuration.endpoint,
            resolvingAgainstBaseURL: false
        ) else {
            throw AzureTranslatorError.invalidEndpoint
        }

        let basePath = components.path.hasSuffix("/")
            ? String(components.path.dropLast())
            : components.path
        components.path = basePath + path
        components.queryItems = [
            URLQueryItem(name: "api-version", value: "3.0")
        ] + parameters

        guard let url = components.url else {
            throw AzureTranslatorError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            configuration.key,
            forHTTPHeaderField: "Ocp-Apim-Subscription-Key"
        )
        request.setValue(
            configuration.region,
            forHTTPHeaderField: "Ocp-Apim-Subscription-Region"
        )
        request.setValue(
            "application/json; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AzureTranslatorError.networkFailure(path, error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureTranslatorError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let requestID = httpResponse.value(forHTTPHeaderField: "X-RequestId")
            let message = Self.apiErrorMessage(from: data)
            throw AzureTranslatorError.httpStatus(
                code: httpResponse.statusCode,
                requestID: requestID,
                message: message
            )
        }

        let responseData = data.isEmpty ? Data("[]".utf8) : data
        do {
            return try JSONDecoder().decode(Response.self, from: responseData)
        } catch {
            throw AzureTranslatorError.decodingFailure(path, error)
        }
    }

    private static func apiErrorMessage(from data: Data) -> String? {
        guard
            let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = response["error"] as? [String: Any]
        else {
            return nil
        }
        return error["message"] as? String ?? error["code"] as? String
    }
}

public enum AzureTranslatorError: LocalizedError {
    case missingConfiguration(String)
    case invalidEndpoint
    case networkFailure(String, Error)
    case invalidResponse
    case httpStatus(code: Int, requestID: String?, message: String?)
    case decodingFailure(String, Error)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration(let name):
            return "Missing Azure Translator configuration value: \(name)."
        case .invalidEndpoint:
            return "Azure Translator endpoint must be a valid HTTPS base URL."
        case .networkFailure(let path, let error):
            return "Azure Translator request to \(path) failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Azure Translator returned a non-HTTP response."
        case .httpStatus(let code, let requestID, let message):
            let requestDetails = requestID.map { " (request ID: \($0))" } ?? ""
            let messageDetails = message.map { ": \($0)" } ?? ""
            return "Azure Translator returned HTTP \(code)\(requestDetails)\(messageDetails)"
        case .decodingFailure(let path, let error):
            return "Could not decode Azure Translator response from \(path): \(error.localizedDescription)"
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
