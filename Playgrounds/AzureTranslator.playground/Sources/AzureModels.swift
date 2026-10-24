import Foundation

public struct DictionaryLookupResult: Codable {
    public let normalizedSource: String
    public let displaySource: String
    public let translations: [DictionaryTranslation]
}

public struct DictionaryTranslation: Codable {
    public let normalizedTarget: String
    public let displayTarget: String
    public let posTag: String?
    public let confidence: Double
    public let prefixWord: String?
    public let backTranslations: [BackTranslation]?
}

public struct BackTranslation: Codable {
    public let normalizedText: String
    public let displayText: String
    public let numExamples: Int
    public let frequencyCount: Int
}

public struct DictionaryExampleResult: Codable {
    public let normalizedSource: String
    public let normalizedTarget: String
    public let examples: [DictionaryExample]
}

public struct DictionaryExample: Codable {
    public let sourcePrefix: String
    public let sourceTerm: String
    public let sourceSuffix: String
    public let targetPrefix: String
    public let targetTerm: String
    public let targetSuffix: String

    public var sourceSentence: String {
        sourcePrefix + sourceTerm + sourceSuffix
    }

    public var targetSentence: String {
        targetPrefix + targetTerm + targetSuffix
    }
}

public struct TranslateResult: Codable {
    public let translations: [TranslationText]
}

public struct TranslationText: Codable {
    public let text: String
    public let to: String
}

public struct DetectResult: Codable {
    public let language: String
    public let score: Double
    public let isTranslationSupported: Bool
    public let isTransliterationSupported: Bool
}
