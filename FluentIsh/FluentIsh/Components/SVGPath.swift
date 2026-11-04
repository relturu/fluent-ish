//
//  SVGPath.swift
//  FluentIsh
//
//  Turns an SVG path string ("M 32 36 C 20 28 8 32 10 20 Z") into a SwiftUI Path.
//
//  Why: the mascot was drawn as inline SVG in the AI Studio prototype
//  (src/components/common/Mascot.tsx). Keeping the exact same `d` strings in
//  Swift means every shape can be checked line-by-line against the original,
//  and a designer can tweak a curve by editing numbers instead of re-drawing.
//
//  Supports the commands the mascot uses: M, L, C, Q, Z (absolute coordinates),
//  including implicit repeats ("L 1 2 3 4" = two line segments).
//

import SwiftUI

enum SVGPath {
    /// Parses once and caches, since the mascot redraws every animation frame.
    private static var cache: [String: Path] = [:]

    static func path(_ d: String) -> Path {
        if let cached = cache[d] { return cached }
        let parsed = parse(d)
        cache[d] = parsed
        return parsed
    }

    private static func parse(_ d: String) -> Path {
        var path = Path()
        var tokens = tokenize(d)[...]
        var command: Character = "M"

        func number() -> CGFloat {
            guard case .number(let value)? = tokens.first else { return 0 }
            tokens.removeFirst()
            return value
        }
        func point() -> CGPoint { CGPoint(x: number(), y: number()) }

        while let token = tokens.first {
            if case .command(let c) = token {
                command = c
                tokens.removeFirst()
                if c == "Z" || c == "z" { path.closeSubpath(); continue }
            }
            switch command {
            case "M":
                path.move(to: point())
                command = "L"   // SVG rule: extra pairs after M are line-tos
            case "L":
                path.addLine(to: point())
            case "C":
                let c1 = point(), c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            case "Q":
                let c = point(), end = point()
                path.addQuadCurve(to: end, control: c)
            default:
                assertionFailure("Unsupported SVG command \(command) in \(d)")
                tokens.removeFirst()
            }
        }
        return path
    }

    private enum Token { case command(Character), number(CGFloat) }

    private static func tokenize(_ d: String) -> [Token] {
        var tokens: [Token] = []
        var current = ""
        func flush() {
            if let value = Double(current) { tokens.append(.number(CGFloat(value))) }
            current = ""
        }
        for ch in d {
            if ch.isLetter {
                flush()
                tokens.append(.command(ch))
            } else if ch == " " || ch == "," {
                flush()
            } else if ch == "-" && !current.isEmpty {
                flush()
                current = "-"
            } else {
                current.append(ch)
            }
        }
        flush()
        return tokens
    }
}
