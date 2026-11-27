//
//  GameMix.swift
//  FluentIsh
//
//  Word bank restructure, Phase 4: today's games mix the daily theme with
//  words the user already knows.
//
//  - Connections keeps the day's 3 themed groups and swaps the easiest
//    (yellow, difficulty 1) group for a personal group: 4 words from one
//    category of the user's bank, or starter words for a new user. 12 daily
//    tiles + 4 known tiles is the closest whole-group split to ⅔ / ⅓.
//    Once the game is saved, the personal group is saved with it
//    (GameResult.personalGroup), so it can't change mid-game.
//  - Word Guess keeps the shared daily answer (always a word from that
//    day's deck), so friends still play the same word.
//  - Both games report per-word results to the word bank when finished.
//
//  No UI and no Firebase: tested in FluentIshTests/GameMixTests.swift.
//

import Foundation

/// A personal Connections group and the word behind each tile.
struct PersonalGroup {
    let group: ConnectionsGroup
    let wordIds: [String]
}

nonisolated enum GameMix {
    /// The personal group replaces the group with this difficulty.
    static let replacedDifficulty = 1

    /// The Connections label for a group of words from one category.
    static func label(forCategory category: String) -> String {
        switch category {
        case "Café & Dining": "En la mesa"
        case "Shopping": "De compras"
        case "Around Town": "Por la ciudad"
        case "Home": "En casa"
        case "Celebrations": "De fiesta"
        case "Work": "En el trabajo"
        case "Free Time": "Tiempo libre"
        case "Daily Verb": "Verbos de cada día"
        case "Connector": "Conectores"
        case "Culture & Idioms": "Expresiones"
        default: "Palabras básicas"
        }
    }

    /// Picks 4 known words from one category for today's Connections.
    /// - `known`: the user's bank (today's deck words are skipped: they're
    ///   the daily part already); `starters` come after them.
    /// - Skips categories of today's deck, so the personal group doesn't
    ///   compete with the themed groups, and any word that's already a tile
    ///   in the groups that stay.
    /// - The candidates are shuffled with a seed for the day, so the group
    ///   changes from day to day. nil if no category has 4 usable words.
    static func personalGroup(known: [Word], starters: [Word], deck: [Word],
                              puzzle: ConnectionsPuzzle, seed: String) -> PersonalGroup? {
        var rng = SeededGenerator(seed: seed)
        let deckIds = Set(deck.compactMap(\.id))
        let deckCategories = Set(deck.map(\.category))
        let keptTiles = Set(puzzle.groups.filter { $0.difficulty != replacedDifficulty }
                                .flatMap(\.words).map(ExerciseBuilder.normalized))

        let usable: (Word) -> Bool = { word in
            guard let id = word.id, !deckIds.contains(id), !deckCategories.contains(word.category) else { return false }
            return !keptTiles.contains(ExerciseBuilder.normalized(ExerciseBuilder.bareForm(word)))
        }
        let bankIds = Set(known.compactMap(\.id))
        let candidates = known.filter(usable).shuffled(using: &rng)
            + starters.filter { usable($0) && !bankIds.contains($0.id ?? "") }.shuffled(using: &rng)

        var byCategory: [String: [Word]] = [:]
        for word in candidates {
            let tile = ExerciseBuilder.normalized(ExerciseBuilder.bareForm(word))
            var group = byCategory[word.category, default: []]
            guard !group.contains(where: { ExerciseBuilder.normalized(ExerciseBuilder.bareForm($0)) == tile }) else { continue }
            group.append(word)
            byCategory[word.category] = group
            if group.count == 4 {
                return PersonalGroup(
                    group: ConnectionsGroup(category: label(forCategory: word.category),
                                            words: group.map(ExerciseBuilder.bareForm),
                                            difficulty: replacedDifficulty),
                    wordIds: group.compactMap(\.id))
            }
        }
        return nil
    }

    /// The day's puzzle with the personal group in place of the yellow one,
    /// at the same position (saved `solvedGroups` are positions). Unchanged
    /// without a personal group or a yellow group.
    static func mixedPuzzle(_ puzzle: ConnectionsPuzzle, personal: ConnectionsGroup?) -> ConnectionsPuzzle {
        guard let personal,
              let index = puzzle.groups.firstIndex(where: { $0.difficulty == replacedDifficulty }) else { return puzzle }
        var groups = puzzle.groups
        groups[index] = personal
        return ConnectionsPuzzle(groups: groups)
    }

    /// Tile → word ID, for tiles that are one of `words` (deck words and the
    /// personal group). Other tiles have no word doc and aren't tracked.
    static func tileWordIds(puzzle: ConnectionsPuzzle, words: [Word]) -> [String: String] {
        var byForm: [String: String] = [:]
        for word in words {
            guard let id = word.id else { continue }
            byForm[ExerciseBuilder.normalized(ExerciseBuilder.bareForm(word))] = id
        }
        var result: [String: String] = [:]
        for tile in puzzle.groups.flatMap(\.words) {
            if let id = byForm[ExerciseBuilder.normalized(tile)] { result[tile] = id }
        }
        return result
    }

    /// Word bank results for a finished Connections game: a tracked tile is
    /// right if the player found its group without a hint.
    static func connectionsAnswers(puzzle: ConnectionsPuzzle, solved: Set<Int>, hinted: Set<Int>,
                                   tileWordIds: [String: String]) -> [VocabAnswer] {
        puzzle.groups.indices.flatMap { index in
            puzzle.groups[index].words.compactMap { tile in
                tileWordIds[tile].map {
                    VocabAnswer(wordId: $0, correct: solved.contains(index) && !hinted.contains(index))
                }
            }
        }
    }

    /// Word bank result for a finished Word Guess: the deck word that is the
    /// answer, right if the last guess was the answer. Empty if no deck word
    /// matches.
    static func wordGuessAnswers(answer: String, guesses: [String], deck: [Word]) -> [VocabAnswer] {
        let key = GameRules.normalize(answer)
        guard let id = deck.first(where: { GameRules.normalize($0.lemma) == key })?.id else { return [] }
        return [VocabAnswer(wordId: id, correct: guesses.last.map { GameRules.normalize($0) == key } ?? false)]
    }

    /// Word bank results for a finished Word Cookies game: one per found
    /// word that has a `wordId` (always including the base deck word), in
    /// grid order. Right if no letter of it was revealed by a hint. Words
    /// without a word doc aren't tracked. The game is the same for everyone,
    /// so nothing is mixed in.
    static func wordCookiesAnswers(rows: [WordCookiesGame.Row], foundWords: [String],
                                   hintedWords: Set<String>) -> [VocabAnswer] {
        rows.compactMap { row in
            guard let id = row.wordId, foundWords.contains(row.word) else { return nil }
            return VocabAnswer(wordId: id, correct: !hintedWords.contains(row.word))
        }
    }
}
