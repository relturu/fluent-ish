//
//  Fonts.swift
//  FluentIsh
//
//  The design uses two Google Fonts (both SIL Open Font License, licence files
//  are next to the .ttf files in Resources/Fonts):
//    - Plus Jakarta Sans: everything (UI, body, headings)
//    - Fraunces: the friendly serif in "¡Hola, Sofía!", "Daily Vocab", modal titles
//
//  Both are *variable* fonts: one file holds every weight, and we ask for an
//  exact weight (e.g. 800) through the font's "wght" axis. That's why we build
//  fonts through UIFontDescriptor instead of Font.custom(name:size:).
//
//  The fonts are registered at launch (FontRegistry.registerAll) instead of
//  listed under UIAppFonts in Info.plist, because this project generates its
//  Info.plist from build settings and that key can't be set there.
//

import SwiftUI
import UIKit
import CoreText

enum FontRegistry {
    private static let files = ["PlusJakartaSans", "Fraunces"]

    /// Call once, before any view is drawn (FluentIshApp.init).
    static func registerAll() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing font file \(name).ttf in the app bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Error 105 = already registered (e.g. SwiftUI previews); harmless.
                let cfError = error?.takeRetainedValue()
                if let cfError, CFErrorGetCode(cfError) != 105 {
                    print("⚠️ Font \(name) failed to register: \(cfError)")
                }
            }
        }
    }
}

enum FontFamily: String {
    case jakarta = "Plus Jakarta Sans"
    case fraunces = "Fraunces"
}

extension UIFont {
    /// Builds a variable-font instance at an exact CSS-style weight (400…800).
    static func brand(_ family: FontFamily, size: CGFloat, weight: Int) -> UIFont {
        // OpenType axis tags as 4-byte integers: 'wght' and 'opsz'.
        let wghtAxis = 0x7767_6874
        let opszAxis = 0x6F70_737A
        var variations: [Int: CGFloat] = [wghtAxis: CGFloat(weight)]
        if family == .fraunces {
            // Fraunces changes shape with size ("optical size"). Browsers set it
            // to the font size automatically; we do the same so headings match.
            variations[opszAxis] = min(max(size, 9), 144)
        }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family.rawValue,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations,
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension Font {
    /// Plus Jakarta Sans at an exact weight: `.jakarta(15, 700)`.
    static func jakarta(_ size: CGFloat, _ weight: Int = 500) -> Font {
        Font(UIFont.brand(.jakarta, size: size, weight: weight))
    }

    /// Fraunces serif at an exact weight: `.fraunces(32, 800)`.
    static func fraunces(_ size: CGFloat, _ weight: Int = 700) -> Font {
        Font(UIFont.brand(.fraunces, size: size, weight: weight))
    }
}
