//
//  Haptics.swift
//  FluentIsh
//
//  Small wrapper so game code reads `Haptics.success()` instead of creating
//  feedback generators everywhere. The web prototype had no haptics; these
//  stand in for its sound effects on tile taps, right/wrong answers and wins.
//
//  (Tactile buttons already tap on press via .sensoryFeedback, so you don't
//  need to call these from a button action.)
//
//  The simulator ignores haptics; feel them on a real iPhone.
//

import UIKit

enum Haptics {
    /// Light tap: selecting a tile, typing a letter.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Correct group, solved word, lesson finished.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Wrong guess or mistake.
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Something worth noticing but not wrong (e.g. "one away").
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
