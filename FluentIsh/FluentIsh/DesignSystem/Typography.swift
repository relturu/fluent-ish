//
//  Typography.swift
//  FluentIsh
//
//  The type scale from the style guide (src/index.css .type-*), plus the serif
//  styles the screens use. Apply with `.textStyle(.h1)`.
//
//  CSS → SwiftUI translation:
//    font-size px      → points (1:1 on iPhone)
//    letter-spacing em → tracking = em × size
//    line-height ×     → lineSpacing = (multiplier − ~1.2) × size; SwiftUI already
//                        includes the font's natural line height (~1.2 for these fonts)
//

import SwiftUI

enum TextStyle: CaseIterable {
    case display        // 30 · 800   "¡Hola, Sofía!" (sans version)
    case h1             // 24 · 800   "la sobremesa"
    case h2             // 19 · 700   "Today's Games", section titles
    case h3             // 15 · 700   card titles, "Connections · Conexiones"
    case body           // 13 · 500
    case bodyMedium     // 13 · 600
    case caption        // 11 · 700   UPPERCASE labels ("TODAY'S GAMES")
    case serifHero      // Fraunces 32 · 800   Today greeting
    case serifTitle     // Fraunces 22 · 700   "Daily Vocab", "Skill Exercises"
    case serifCard      // Fraunces 20 · 700   modal titles

    var font: Font {
        switch self {
        case .display:    .jakarta(30, 800)
        case .h1:         .jakarta(24, 800)
        case .h2:         .jakarta(19, 700)
        case .h3:         .jakarta(15, 700)
        case .body:       .jakarta(13, 500)
        case .bodyMedium: .jakarta(13, 600)
        case .caption:    .jakarta(11, 700)
        case .serifHero:  .fraunces(32, 800)
        case .serifTitle: .fraunces(22, 700)
        case .serifCard:  .fraunces(20, 700)
        }
    }

    var size: CGFloat {
        switch self {
        case .display: 30
        case .h1: 24
        case .h2: 19
        case .h3: 15
        case .body, .bodyMedium: 13
        case .caption: 11
        case .serifHero: 32
        case .serifTitle: 22
        case .serifCard: 20
        }
    }

    /// Letter spacing in points.
    var tracking: CGFloat {
        switch self {
        case .display: -0.025 * size
        case .h1: -0.02 * size
        case .h2: -0.015 * size
        case .caption: 0.04 * size
        case .serifHero: -0.02 * size
        default: 0
        }
    }

    /// Extra space between wrapped lines.
    var lineSpacing: CGFloat {
        switch self {
        case .body, .bodyMedium: 0.25 * size
        case .h3: 0.15 * size
        case .h2: 0.1 * size
        default: 0
        }
    }

    var isUppercase: Bool { self == .caption }
}

extension View {
    /// Applies a style from the type scale.
    func textStyle(_ style: TextStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}
