import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct AzureTranslatorUsageExample {
    static func main() async throws {
        let endpointString =
            ProcessInfo.processInfo.environment["AZURE_ENDPOINT"]
            ?? "https://api.cognitive.microsofttranslator.com"
        guard let endpoint = URL(string: endpointString) else {
            throw ConfigurationError.invalidEndpoint
        }
        let configuration = try AzureTranslator.Configuration(
            key: requiredEnvironmentValue("AZURE_KEY"),
            region: requiredEnvironmentValue("AZURE_REGION"),
            endpoint: endpoint
        )
        let translator = AzureTranslator(configuration: configuration)

        print("=== Dictionary Lookup ===")
        let lookups = try await translator.dictionaryLookup(text: "charlar")
        if let lookup = lookups.first,
           let bestTranslation = lookup.translations.max(by: {
               $0.confidence < $1.confidence
           }) {
            print("\(lookup.displaySource) → \(bestTranslation.displayTarget)")

            print("\n=== Dictionary Examples ===")
            let exampleResults = try await translator.dictionaryExamples(
                text: lookup.normalizedSource,
                translation: bestTranslation.normalizedTarget
            )
            if let example = exampleResults.first?.examples.first {
                print("Spanish: \(example.sourceSentence)")
                print("English: \(example.targetSentence)")
            } else {
                print("No dictionary examples available.")
            }
        } else {
            print("No dictionary translation found.")
            print("\n=== Dictionary Examples ===")
            print("Skipped: lookup returned no normalized translation.")
        }

        print("\n=== Translate ===")
        let translations = try await translator.translate(
            text: "En nuestra sobremesa nunca falta un cortado."
        )
        if let translation = translations.first?.translations.first {
            print("English: \(translation.text)")
        } else {
            print("No translation returned.")
        }

        print("\n=== Detect Language ===")
        let detections = try await translator.detectLanguage(
            text: "un cortado bien cargado y risas"
        )
        if let detection = detections.first {
            print(
                "Language: \(detection.language); confidence: " +
                    "\(String(format: "%.2f%%", detection.score * 100))"
            )
        } else {
            print("No language detection result returned.")
        }
    }

    private static func requiredEnvironmentValue(_ name: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[name], !value.isEmpty else {
            throw ConfigurationError.missingEnvironmentVariable(name)
        }
        return value
    }
}

private enum ConfigurationError: LocalizedError {
    case missingEnvironmentVariable(String)
    case invalidEndpoint

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let name):
            return "Set the \(name) environment variable before running this example."
        case .invalidEndpoint:
            return "AZURE_ENDPOINT must be a valid URL."
        }
    }
}
