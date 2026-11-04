//
//  AudioButton.swift
//  FluentIsh
//
//  Ported from design/ai-studio/src/components/common/HiFiElements.tsx
//  (AudioButton, lines 1011–1036, and speakSpanish, lines 27–40).
//
//  The orange speaker button that reads a Spanish word or sentence aloud.
//  plan.md: pronunciation is on-device (AVSpeechSynthesizer), no audio files.
//
//      AudioButton(text: word.term)            // small, next to a word
//      AudioButton(text: word.term, size: .large)
//

import SwiftUI
import AVFoundation

struct AudioButton: View {
    enum Size { case small, large }

    let text: String
    var size: Size = .small

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let side: CGFloat = size == .large ? 44 : 32          // w-11 / w-8
        Button {
            Speech.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size == .large ? 18 : 14, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? Color.sunny : Color.flame)
                .frame(width: side, height: side)
                .background(colorScheme == .dark ? Color(hex: 0x292461) : Color.flame.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: size == .large ? 16 : 12, style: .continuous))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Listen to \(text)")
    }
}

/// Speaks Spanish with the device's voice. One shared synthesizer: if it
/// were created per tap, it would be freed before it finished speaking.
enum Speech {
    private static let synthesizer = AVSpeechSynthesizer()

    static func speak(_ text: String, language: String = "es-ES") {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9   // a little slower for learners
        synthesizer.speak(utterance)
    }
}

#Preview {
    HStack {
        Text("la sobremesa").textStyle(.h2)
        AudioButton(text: "la sobremesa")
        AudioButton(text: "la sobremesa", size: .large)
    }
    .padding()
    .background(Color.canvas)
}
