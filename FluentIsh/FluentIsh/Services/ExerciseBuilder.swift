//
//  ExerciseBuilder.swift
//  FluentIsh
//
//  Builds Skill Exercises from the user's own words (word bank restructure,
//  Phase 3), so exercises review what the user knows least. The result is a
//  normal `Exercise`, so ExerciseView plays it like a seeded one.
//
//  - Definition Match: Spanish term ↔ English definition.
//  - Fill in the Blank: the word blanked out of its example sentence; wrong
//    choices are other words of the same part of speech (same gender for
//    nouns, so the article doesn't give the answer away).
//  - Sentence Builder: the English example is the prompt; the player builds
//    the Spanish example from shuffled tiles (hard adds decoy tiles).
//
//  Shuffles use a generator seeded from the day, type and difficulty, so an
//  exercise looks the same every time it's opened that day. No UI and no
//  Firebase: tested in FluentIshTests/ExerciseBuilderTests.swift.
//

import Foundation

/// A built exercise plus the word behind each item (`wordIds[i]` ↔
/// `exercise.items[i]`), so results can update the word bank.
struct BuiltExercise {
    let exercise: Exercise
    let wordIds: [String]
}

nonisolated enum ExerciseBuilder {
    static let types = ["fillBlank", "sentenceBuilder", "definitionMatch"]
    static let difficulties = ["easy", "medium", "hard"]

    /// Document-style ID for the daily log ("done today" tick, XP once a day).
    static func id(type: String, difficulty: String) -> String { "gen_\(type)_\(difficulty)" }

    /// Items per exercise: Definition Match pairs, or screens for the others.
    static func itemCount(type: String, difficulty: String) -> Int {
        let base = type == "definitionMatch" ? 4 : 3
        switch difficulty {
        case "hard": return base + 2
        case "medium": return base + 1
        default: return base
        }
    }

    /// Fill in the Blank options: 3 on easy (plan.md), 4 otherwise.
    static func choiceCount(difficulty: String) -> Int { difficulty == "easy" ? 3 : 4 }

    /// Longest example sentence (in words) for Sentence Builder.
    static func maxSentenceWords(difficulty: String) -> Int {
        switch difficulty {
        case "easy": 6
        case "medium": 8
        default: .max
        }
    }

    /// Builds one exercise. `words` is the word bank, least familiar first
    /// (then starter words); items take the first eligible words in that
    /// order. `pool` supplies wrong choices and decoys. nil if too few words fit.
    static func build(type: String, difficulty: String, words: [Word], pool: [Word], seed: String) -> BuiltExercise? {
        var rng = SeededGenerator(seed: seed)
        let count = itemCount(type: type, difficulty: difficulty)
        var items: [ExerciseItem] = []
        var wordIds: [String] = []
        var usedAnswers: Set<String> = []

        for word in words where items.count < count {
            guard let id = word.id, !wordIds.contains(id) else { continue }
            let item: ExerciseItem?
            switch type {
            case "fillBlank": item = fillBlank(word, difficulty: difficulty, pool: pool, rng: &rng)
            case "sentenceBuilder": item = sentenceBuilder(word, difficulty: difficulty, pool: pool, rng: &rng)
            default: item = definitionMatch(word)
            }
            // Two items with the same answer would be ambiguous (e.g. two
            // matching definitions), so skip the second.
            guard let item, usedAnswers.insert(normalized(item.answer)).inserted else { continue }
            items.append(item)
            wordIds.append(id)
        }
        guard items.count >= (type == "definitionMatch" ? 2 : 1) else { return nil }

        let exercise = Exercise(id: id(type: type, difficulty: difficulty), language: words.first?.language ?? "es",
                                type: type, title: title(type), subtitle: subtitle(type),
                                difficulty: difficulty, items: items)
        return BuiltExercise(exercise: exercise, wordIds: wordIds)
    }

    // MARK: Item builders

    static func definitionMatch(_ word: Word) -> ExerciseItem {
        ExerciseItem(prompt: word.term, answer: word.definitionEn)
    }

    /// nil if the word doesn't appear unchanged in its example (e.g. a verb
    /// that's conjugated there), or there aren't enough wrong choices.
    static func fillBlank(_ word: Word, difficulty: String, pool: [Word],
                          rng: inout SeededGenerator) -> ExerciseItem? {
        guard let example = word.example, let found = blank(word, in: example) else { return nil }
        let capitalized = found.answer.first?.isUppercase ?? false
        let answerKey = normalized(found.answer)

        // Same part of speech first (and same gender for nouns), then any single word.
        let candidates = pool.filter { $0.id != word.id && !bareForm($0).contains(" ") }
        let close = candidates.filter {
            $0.partOfSpeech == word.partOfSpeech && (word.partOfSpeech != "noun" || $0.gender == word.gender)
        }
        var wrong: [String] = []
        for other in close.shuffled(using: &rng) + candidates.shuffled(using: &rng) {
            guard wrong.count < choiceCount(difficulty: difficulty) - 1 else { break }
            var form = bareForm(other)
            if capitalized { form = form.prefix(1).uppercased() + form.dropFirst() }
            guard normalized(form) != answerKey, !wrong.contains(form) else { continue }
            wrong.append(form)
        }
        guard wrong.count == choiceCount(difficulty: difficulty) - 1 else { return nil }
        return ExerciseItem(prompt: found.prompt, answer: found.answer,
                            choices: ([found.answer] + wrong).shuffled(using: &rng), promptEn: word.exampleEn)
    }

    /// nil without an example and translation, or if the example is too long
    /// for the difficulty.
    static func sentenceBuilder(_ word: Word, difficulty: String, pool: [Word],
                                rng: inout SeededGenerator) -> ExerciseItem? {
        guard let example = word.example, let english = word.exampleEn else { return nil }
        let answerTiles = ExerciseRules.words(example)
        guard answerTiles.count >= 3, answerTiles.count <= maxSentenceWords(difficulty: difficulty) else { return nil }

        var tiles = answerTiles
        if difficulty == "hard" {
            let inSentence = Set(answerTiles.map(normalized))
            let decoys = pool.map(bareForm)
                .filter { !$0.contains(" ") && !inSentence.contains(normalized($0)) }
                .shuffled(using: &rng)
            tiles += Set(decoys).sorted().shuffled(using: &rng).prefix(2)
        }
        // Never hand over the tiles already in order.
        var shuffled = tiles.shuffled(using: &rng)
        if Array(shuffled.prefix(answerTiles.count)) == answerTiles { shuffled = Array(shuffled.reversed()) }
        return ExerciseItem(prompt: english, answer: example, choices: shuffled)
    }

    // MARK: Helpers

    /// The example with the word replaced by "___", and the exact text that
    /// was replaced (it keeps the example's capitals: "Hola" in "¡Hola! …").
    static func blank(_ word: Word, in example: String) -> (prompt: String, answer: String)? {
        let forms = Set([word.lemma, bareForm(word)].map(normalized))
        // Expressions ("por favor"): find the phrase itself.
        if let phrase = forms.first(where: { $0.contains(" ") }),
           let range = example.range(of: phrase, options: [.caseInsensitive, .diacriticInsensitive]) {
            return (example.replacingCharacters(in: range, with: ExerciseRules.blank), String(example[range]))
        }
        // Single words: a whole token, ignoring punctuation around it.
        var tokens = example.components(separatedBy: " ")
        for (index, token) in tokens.enumerated() {
            let core = token.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
            guard !core.isEmpty, forms.contains(normalized(core)), let range = token.range(of: core) else { continue }
            tokens[index] = token.replacingCharacters(in: range, with: ExerciseRules.blank)
            return (tokens.joined(separator: " "), core)
        }
        return nil
    }

    /// The term without its article: "la acera" → "acera".
    static func bareForm(_ word: Word) -> String {
        for article in ["el ", "la ", "los ", "las "] where word.term.hasPrefix(article) {
            return String(word.term.dropFirst(article.count))
        }
        return word.lemma
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    static func title(_ type: String) -> String {
        switch type {
        case "fillBlank": "Fill in the Blank"
        case "sentenceBuilder": "Sentence Builder"
        default: "Definition Match"
        }
    }

    static func subtitle(_ type: String) -> String {
        switch type {
        case "fillBlank": "Completa la Frase"
        case "sentenceBuilder": "Construye la Frase"
        default: "Une las Parejas"
        }
    }
}

/// A small repeatable random generator (SplitMix64). Seeded from a string
/// with FNV-1a, because Swift's `hashValue` changes on every launch.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3 }
        state = hash
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }
}
