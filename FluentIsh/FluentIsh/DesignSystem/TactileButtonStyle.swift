//
//  TactileButtonStyle.swift
//  FluentIsh
//
//  The "chunky 3D" buttons from the design (src/index.css .btn-3d-*).
//  On the web they're a coloured box with a 4px darker bottom border; pressing
//  removes the border and moves the box down 4px, so it looks pushed in.
//
//  SwiftUI version: two rounded rectangles. The darker "edge" sits behind the
//  face, shifted down by `depth`. When pressed, the face slides down onto the
//  edge and hides it. A ButtonStyle gets `configuration.isPressed` for free,
//  so there's no gesture code.
//
//  Usage:
//    Button("Play Game") { … }.buttonStyle(.tactile(.primary, fullWidth: true))
//    Button("Purple") { … }.buttonStyle(.tactile(.purple, size: .small))
//

import SwiftUI

struct TactileButtonStyle: ButtonStyle {
    enum Variant: CaseIterable {
        case primary    // flame orange, white text: the main CTA
        case secondary  // deep indigo, cream text: "Play" on game cards
        case purple
        case yellow     // dark text
        case aqua       // dark text
        case outline    // card-coloured with a grey border: "Off", "Replay"
    }

    enum Size {
        case large   // 46pt tall, 14pt text, 16pt corners
        case small   // 38pt tall, 12pt text, 12pt corners
    }

    var variant: Variant = .primary
    var size: Size = .large
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        TactileButtonBody(configuration: configuration, variant: variant, size: size, fullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == TactileButtonStyle {
    static func tactile(_ variant: TactileButtonStyle.Variant = .primary,
                        size: TactileButtonStyle.Size = .large,
                        fullWidth: Bool = false) -> TactileButtonStyle {
        TactileButtonStyle(variant: variant, size: size, fullWidth: fullWidth)
    }
}

/// A separate View so it can read the environment (enabled state, colour scheme).
/// ButtonStyle.makeBody itself can't use @Environment.
private struct TactileButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: TactileButtonStyle.Variant
    let size: TactileButtonStyle.Size
    let fullWidth: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    private var pressed: Bool { configuration.isPressed && isEnabled }
    private var depth: CGFloat { variant == .outline ? 2 : 4 }
    private var radius: CGFloat { size == .large ? 16 : 12 }
    private var height: CGFloat { size == .large ? 46 : 38 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        configuration.label
            .font(.jakarta(size == .large ? 14 : 12, 700))
            .foregroundStyle(colors.text)
            .lineLimit(1)
            .padding(.horizontal, size == .large ? 20 : 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height - depth)
            .background {
                shape.fill(colors.face)
                    .overlay {
                        if variant == .outline { shape.strokeBorder(colors.edge, lineWidth: 2) }
                    }
            }
            // The edge: same shape, darker, peeking out below the face.
            .background { shape.fill(colors.edge).offset(y: pressed ? 0 : depth) }
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)            // reserve room so layout doesn't jump
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.1), value: pressed)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, isDown in isDown }
    }

    private var colors: (face: Color, edge: Color, text: Color) {
        let dark = colorScheme == .dark
        switch variant {
        case .primary:   return (.flame, .flameEdge, .white)
        case .secondary: return dark ? (Color(hex: 0x292461), Color(hex: 0x1A1646), .offWhite)
                                     : (.indigo, .indigoEdge, .offWhite)
        case .purple:    return (.connPurple, .connPurpleEdge, .white)
        case .yellow:    return (.sunny, .sunnyEdge, .indigo)
        case .aqua:      return (.aqua, .aquaEdge, .indigo)
        case .outline:   return dark ? (.card, Color.white.opacity(0.3), .offWhite)
                                     : (.card, Color(hex: 0xB9B6C8), .indigo)
        }
    }
}
