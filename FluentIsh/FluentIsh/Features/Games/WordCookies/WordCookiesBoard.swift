//
//  WordCookiesBoard.swift
//  FluentIsh
//
//  Sizes for the Word Cookies screen, worked out from the space available,
//  so the slot board never has to scroll. Pure math, no SwiftUI views, so
//  it can be unit tested (FluentIshTests/WordCookiesBoardTests).
//
//  The board is laid out like the real Word Cookies: the base word alone on
//  top, centered, and every other word below it in two columns (shortest
//  first, down the left column, then down the right one).
//  Every slot is the same square size: the largest that lets the top word
//  fit the board's width, the longest other word fit half of it, and all
//  the rows fit its height. Capped at `maxSlot` so a small puzzle on a big
//  phone doesn't get giant slots.
//

import CoreGraphics

nonisolated enum WordCookiesBoard {

    /// Space between two slots in a row.
    static let slotGap: CGFloat = 5
    /// Space between two rows.
    static let rowGap: CGFloat = 8
    /// The least space between the two columns.
    static let columnGap: CGFloat = 14
    /// The biggest a slot gets.
    static let maxSlot: CGFloat = 44

    /// Which rows go where. Each number is a position in `WordCookiesGame.rows`.
    struct Arrangement: Equatable {
        /// The base word, alone on top. nil only when there are no rows.
        let top: Int?
        /// The other words, top to bottom.
        let left: [Int]
        let right: [Int]

        /// How many rows tall the board is: the top word plus the taller column.
        var rowCount: Int { (top == nil ? 0 : 1) + max(left.count, right.count) }
    }

    /// Puts row `top` (the base word) on top and splits the rest into two
    /// columns, the left one getting the extra word when the count is odd.
    /// `WordCookiesGame.rows` is already shortest first, then A–Z, so the
    /// columns read in that order too.
    static func arrange(rowCount: Int, top: Int?) -> Arrangement {
        let top = top.flatMap { (0..<rowCount).contains($0) ? $0 : nil }
        let others = (0..<rowCount).filter { $0 != top }
        let leftCount = (others.count + 1) / 2
        return Arrangement(top: top,
                           left: Array(others.prefix(leftCount)),
                           right: Array(others.dropFirst(leftCount)))
    }

    /// Side of one square slot, in whole points, so the arrangement fits in
    /// `size` (the board minus its padding). `lengths[i]` is the number of
    /// letters in row i. 0 if there's no room yet (e.g. before the board has
    /// been measured).
    static func slotSide(for arrangement: Arrangement, lengths: [Int], in size: CGSize) -> CGFloat {
        func longest(_ rows: [Int]) -> Int {
            rows.map { lengths.indices.contains($0) ? lengths[$0] : 0 }.max() ?? 0
        }
        var limits: [CGFloat] = [maxSlot]
        if let top = arrangement.top, longest([top]) > 0 {
            limits.append(side(fitting: longest([top]), in: size.width))
        }
        let columnLetters = longest(arrangement.left + arrangement.right)
        if columnLetters > 0 {
            limits.append(side(fitting: columnLetters, in: (size.width - columnGap) / 2))
        }
        let rows = CGFloat(arrangement.rowCount)
        if rows > 0 {
            limits.append((size.height - rowGap * (rows - 1)) / rows)
        }
        return max(0, (limits.min() ?? 0).rounded(.down))
    }

    /// The slot side that fits `letters` slots (and the gaps between them)
    /// in `width`.
    private static func side(fitting letters: Int, in width: CGFloat) -> CGFloat {
        let count = CGFloat(letters)
        return (width - slotGap * (count - 1)) / count
    }

    /// Side of the tile circle (the pan): 38% of the height below the
    /// header, between 180 and 270. Shuffle and Hint sit in its corners, not
    /// in a row of their own, so the pan can take that height. Full size on
    /// most phones; smaller on short ones (iPhone SE) so the board has room.
    /// The full 270 before the screen has been measured.
    static func circleSide(forHeight height: CGFloat) -> CGFloat {
        guard height > 0 else { return 270 }
        return min(270, max(180, (height * 0.38).rounded(.down)))
    }
}
