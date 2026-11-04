//
//  SpeechBubble.swift
//  FluentIsh
//
//  The bubble Churro talks in. Two looks from the design:
//    .dark  - indigo bubble with white text (Today greeting "¡Un cafecito y a jugar!")
//    .light - card-coloured bubble with an orange outline (onboarding, toasts)
//  The little pointer triangle sits on the edge facing Churro.
//

import SwiftUI

struct SpeechBubble: View {
    enum Style { case dark, light }
    enum Pointer { case bottom, leading, trailing, none }

    let text: String
    var style: Style = .dark
    var pointer: Pointer = .bottom
    var maxWidth: CGFloat = 230
    var fontSize: CGFloat = 13

    var body: some View {
        Text(text)
            .font(.jakarta(fontSize, 700))
            .multilineTextAlignment(.center)
            .foregroundStyle(style == .dark ? Color.white : Color.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: maxWidth)
            .fixedSize(horizontal: false, vertical: true)
            .background(bubbleFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if style == .light {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.flame.opacity(0.3))
                }
            }
            .overlay(alignment: pointerAlignment) {
                if pointer != .none {
                    Rectangle()
                        .fill(bubbleFill)
                        .frame(width: 11, height: 11)
                        .rotationEffect(.degrees(45))
                        .offset(pointerOffset)
                }
            }
    }

    private var bubbleFill: Color { style == .dark ? .speechBubble : .card }

    private var pointerAlignment: Alignment {
        switch pointer {
        case .bottom, .none: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    private var pointerOffset: CGSize {
        switch pointer {
        case .bottom, .none: CGSize(width: 0, height: 5)
        case .leading: CGSize(width: -5, height: 0)
        case .trailing: CGSize(width: 5, height: 0)
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        SpeechBubble(text: "¡Un cafecito y a jugar!")
        MascotView(mood: .waving, size: .sm)
    }
    .padding()
    .background(Color.canvas)
}
