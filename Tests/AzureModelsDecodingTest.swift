import Foundation

@main
struct AzureModelsDecodingTest {
    static func main() throws {
        let decoder = JSONDecoder()

        let lookupJSON = """
        [{
          "normalizedSource": "charlar",
          "displaySource": "charlar",
          "translations": [{
            "normalizedTarget": "chat",
            "displayTarget": "chat",
            "posTag": "VERB",
            "confidence": 0.62,
            "prefixWord": "",
            "backTranslations": [{
              "normalizedText": "charlar",
              "displayText": "charlar",
              "numExamples": 15,
              "frequencyCount": 120
            }]
          }]
        }]
        """
        let lookup = try decoder.decode(
            [DictionaryLookupResult].self,
            from: Data(lookupJSON.utf8)
        )
        precondition(lookup.first?.translations.first?.displayTarget == "chat")
        precondition(lookup.first?.translations.first?.backTranslations?.first?.frequencyCount == 120)

        let lookupWithoutOptionalFieldsJSON = """
        [{
          "normalizedSource": "sobremesa",
          "displaySource": "sobremesa",
          "translations": [{
            "normalizedTarget": "after-dinner conversation",
            "displayTarget": "after-dinner conversation",
            "confidence": 0.5
          }]
        }]
        """
        let lookupWithoutOptionalFields = try decoder.decode(
            [DictionaryLookupResult].self,
            from: Data(lookupWithoutOptionalFieldsJSON.utf8)
        )
        precondition(lookupWithoutOptionalFields.first?.translations.first?.posTag == nil)
        precondition(lookupWithoutOptionalFields.first?.translations.first?.backTranslations == nil)

        let examplesJSON = """
        [{
          "normalizedSource": "charlar",
          "normalizedTarget": "chat",
          "examples": [{
            "sourcePrefix": "Nos gusta ",
            "sourceTerm": "charlar",
            "sourceSuffix": " después de cenar.",
            "targetPrefix": "We like to ",
            "targetTerm": "chat",
            "targetSuffix": " after dinner."
          }]
        }]
        """
        let examples = try decoder.decode(
            [DictionaryExampleResult].self,
            from: Data(examplesJSON.utf8)
        )
        precondition(examples.first?.examples.first?.sourceSentence == "Nos gusta charlar después de cenar.")
        precondition(examples.first?.examples.first?.targetSentence == "We like to chat after dinner.")

        let translateJSON = """
        [{"translations":[{"text":"We like to chat.","to":"en"}]}]
        """
        let translations = try decoder.decode(
            [TranslateResult].self,
            from: Data(translateJSON.utf8)
        )
        precondition(translations.first?.translations.first?.text == "We like to chat.")

        let detectJSON = """
        [{
          "language":"es",
          "score":1.0,
          "isTranslationSupported":true,
          "isTransliterationSupported":false
        }]
        """
        let detections = try decoder.decode(
            [DetectResult].self,
            from: Data(detectJSON.utf8)
        )
        precondition(detections.first?.language == "es")
        precondition(detections.first?.isTranslationSupported == true)

        print("Azure response decoding tests passed.")
    }
}
