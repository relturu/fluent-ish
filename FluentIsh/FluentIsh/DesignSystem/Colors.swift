//
//  Colors.swift
//  FluentIsh
//
//  Brand colour tokens from the AI Studio design (src/index.css and the
//  "Fluent·ish Style Guide"). Views use these names, never raw hex, so a
//  colour change happens in one place.
//
//  Colours that differ between light and dark mode are built with
//  `Color(light:dark:)`, which wraps a dynamic UIColor. iOS picks the right
//  one from the current colour scheme, including the app's own Dark Mode
//  toggle (applied with .preferredColorScheme at the root).
//

import SwiftUI
import UIKit

extension Color {
    // MARK: Brand (same in light and dark)

    /// Flame Orange: primary actions, CTAs, streak, active tab.
    static let flame = Color(hex: 0xFF6B2C)
    /// Darker bottom edge of flame 3D buttons.
    static let flameEdge = Color(hex: 0xD94E13)
    /// Deep Indigo: primary text and ink in light mode.
    static let indigo = Color(hex: 0x1F1B4D)
    static let indigoEdge = Color(hex: 0x120F32)
    /// Connections Purple: Connections accent, levels.
    static let connPurple = Color(hex: 0x7B5CFF)
    static let connPurpleEdge = Color(hex: 0x5B3CE0)
    /// Sunny Yellow: Word Guess accent (use dark text on it).
    static let sunny = Color(hex: 0xFFC93C)
    static let sunnyEdge = Color(hex: 0xD49C14)
    /// Aqua: Mini Crossword accent (use dark text on it).
    static let aqua = Color(hex: 0x19C3B1)
    static let aquaEdge = Color(hex: 0x119688)
    /// Success Green: correct answers, solved state, streak-counted dot.
    static let success = Color(hex: 0x3DDC84)
    static let successEdge = Color(hex: 0x25B867)
    /// Error Coral: mistakes and warnings.
    static let coral = Color(hex: 0xFF5C6C)
    /// Warm Off-White: the light-mode canvas.
    static let offWhite = Color(hex: 0xFFF8EC)
    /// Crossword board background (both modes).
    static let crosswordBoard = Color(hex: 0x120F32)

    // MARK: Semantic (adapt to light / dark)

    /// App background behind everything.
    static let canvas = Color(light: 0xFFF8EC, dark: 0x17143A)
    /// Cards and grouped lists.
    static let card = Color(light: 0xFFFFFF, dark: 0x221E52)
    /// Raised surfaces inside cards (search fields, inactive tiles).
    static let raised = Color(light: 0xF0EAE0, dark: 0x292461)
    /// Modal sheets.
    static let modal = Color(light: 0xFFFFFF, dark: 0x1E1A46)
    /// Main text.
    static let ink = Color(light: 0x1F1B4D, dark: 0xFFF8EC)
    /// Secondary text, inactive tab icons.
    static let inkMuted = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.6)
        : UIColor(hex: 0x706E7B) })
    /// Hairline borders on cards and dividers.
    static let hairline = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.1)
        : UIColor(hex: 0x1F1B4D, alpha: 0.1) })
    /// Segmented-control track.
    static let segmentTrack = Color(light: 0xF0EAE0, dark: 0x252156)
    /// Mascot speech bubble.
    static let speechBubble = Color(light: 0x211D4E, dark: 0x2B265E)

    // Word chips on the Daily Vocab card: review words are teal, new words orange.
    static let chipReviewBg = Color(light: 0xE6F9F6, dark: 0x1A3F4A)
    static let chipReviewText = Color(light: 0x0E7A6E, dark: 0x5EE6D6)
    static let chipNewBg = Color(light: 0xFFF3EC, dark: 0x4A2A2A)
    static let chipNewText = Color(light: 0xC84814, dark: 0xFF9A6C)
}

// MARK: - Hex helpers

extension Color {
    /// `Color(hex: 0xFF6B2C)`. Integer literals catch typos at compile time,
    /// unlike string parsing.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// A colour that switches with the colour scheme.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Parses "#E8743B" or "E8743B" (e.g. `AppUser.avatarColor` from Firestore).
    /// Falls back to flame orange if the string isn't valid hex.
    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        self.init(hex: UInt32(cleaned, radix: 16) ?? 0xFF6B2C)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
