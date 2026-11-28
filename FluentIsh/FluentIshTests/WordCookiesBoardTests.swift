//
//  WordCookiesBoardTests.swift
//  FluentIshTests
//
//  Sizes for the Word Cookies screen (Features/Games/WordCookies/
//  WordCookiesBoard): the base word on top, the rest in two columns, and
//  the board always fits without scrolling.
//

import CoreGraphics
import Testing
@testable import FluentIsh

struct WordCookiesBoardTests {

    /// Sunday's rows as WordCookiesGame sorts them: ÁREA ARTE RATA TAREA
    /// TRAGAR REGATEAR. The base word (REGATEAR) is the last row.
    private let regatear = [4, 4, 4, 5, 6, 8]

    // MARK: Arrangement

    @Test func baseWordOnTopAndTheRestInTwoColumns() {
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        #expect(arrangement.top == 5)
        #expect(arrangement.left == [0, 1, 2])         // down the left column first
        #expect(arrangement.right == [3, 4])
        #expect(arrangement.rowCount == 4)              // top + 3
    }

    @Test func evenSplitWhenTheCountAllows() {
        let arrangement = WordCookiesBoard.arrange(rowCount: 5, top: 4)
        #expect(arrangement.left == [0, 1])
        #expect(arrangement.right == [2, 3])
    }

    @Test func baseWordCanBeAnyRow() {
        // A base word that isn't the longest still goes on top.
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 2)
        #expect(arrangement.top == 2)
        #expect(arrangement.left == [0, 1, 3])
        #expect(arrangement.right == [4, 5])
    }

    @Test func noRowsMeansAnEmptyBoard() {
        let arrangement = WordCookiesBoard.arrange(rowCount: 0, top: nil)
        #expect(arrangement == .init(top: nil, left: [], right: []))
        #expect(arrangement.rowCount == 0)
    }

    @Test func aTopRowOutsideTheBoardIsIgnored() {
        let arrangement = WordCookiesBoard.arrange(rowCount: 3, top: 7)
        #expect(arrangement.top == nil)
        #expect(arrangement.left == [0, 1])
        #expect(arrangement.right == [2])
    }

    // MARK: Slot size

    @Test func theLongestColumnWordSetsTheSize() {
        // TRAGAR (6) in half of 333pt: ((333 − 14) / 2 − 5 × 5) / 6 = 22.4 → 22.
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        let side = WordCookiesBoard.slotSide(for: arrangement, lengths: regatear, in: CGSize(width: 333, height: 400))
        #expect(side == 22)
    }

    @Test func shortRowsAreLimitedByHeight() {
        // 4 rows in 120pt: (120 − 3 × 8) / 4 = 24.
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        let side = WordCookiesBoard.slotSide(for: arrangement, lengths: [3, 3, 3, 4, 4, 6], in: CGSize(width: 400, height: 120))
        #expect(side == 24)
    }

    @Test func slotsAreCappedOnBigBoards() {
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        let side = WordCookiesBoard.slotSide(for: arrangement, lengths: [3, 3, 3, 3, 3, 4], in: CGSize(width: 400, height: 600))
        #expect(side == WordCookiesBoard.maxSlot)
    }

    @Test func everythingFitsOnTheBoard() {
        let size = CGSize(width: 315, height: 160)
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        let side = WordCookiesBoard.slotSide(for: arrangement, lengths: regatear, in: size)
        let gap = WordCookiesBoard.slotGap
        #expect(8 * side + 7 * gap <= size.width)                                      // REGATEAR on top
        #expect(2 * (6 * side + 5 * gap) + WordCookiesBoard.columnGap <= size.width)   // two 6-letter words side by side
        #expect(4 * side + 3 * WordCookiesBoard.rowGap <= size.height)                 // 4 rows
    }

    @Test func noSlotsBeforeTheBoardIsMeasured() {
        // The board starts at .zero, and padding makes the inside negative.
        let arrangement = WordCookiesBoard.arrange(rowCount: 6, top: 5)
        #expect(WordCookiesBoard.slotSide(for: arrangement, lengths: regatear, in: CGSize(width: -28, height: -28)) == 0)
    }

    // MARK: Circle

    @Test func theCircleShrinksOnlyOnShortScreens() {
        #expect(WordCookiesBoard.circleSide(forHeight: 0) == 270)       // not measured yet
        #expect(WordCookiesBoard.circleSide(forHeight: 760) == 270)     // most phones
        #expect(WordCookiesBoard.circleSide(forHeight: 590) == 224)     // iPhone SE
        #expect(WordCookiesBoard.circleSide(forHeight: 400) == 180)     // never smaller than 180
    }
}
