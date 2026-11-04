//
//  GameHeaderBar.swift
//  FluentIsh
//
//  Ported from design/ai-studio/src/components/common/HiFiElements.tsx
//  (GameHeaderBar, lines 642–733). It's the worked example in
//  docs/porting-guide.md: compare the two side by side.
//
//  The sticky header on every game and exercise screen: "← Back" on the
//  left, title (+ subtitle) in the middle, and optional "?" (how to play)
//  and "!" (hint) buttons on the right.
//
//  Usage, on a screen pushed from Today:
//
//      ScrollView { ... }
//          .background(Color.canvas)
//          .safeAreaInset(edge: .top, spacing: 0) {
//              GameHeaderBar(title: "Conexiones", subtitle: "4 mistakes left",
//                            onHowToPlay: { showRules = true }, onHint: nil)
//          }
//          .toolbar(.hidden, for: .navigationBar)
//

import SwiftUI

struct GameHeaderBar<Badge: View>: View {
    let title: String
    var subtitle: String? = nil
    var onHowToPlay: (() -> Void)? = nil
    var onHint: (() -> Void)? = nil
    /// Back defaults to popping the navigation stack.
    var onBack: (() -> Void)? = nil
    @ViewBuilder var badge: Badge

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 8) {
            // Left slot (min-w-[64px])
            Button {
                if let onBack { onBack() } else { dismiss() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left").font(.system(size: 14, weight: .bold))
                    Text("Back").font(.jakarta(13, 700))
                }
                .foregroundStyle(Color.ink.opacity(0.8))
                .frame(minHeight: 44)                       // min-h-[44px]
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(minWidth: 64, alignment: .leading)

            // Centre title (type-h3 truncate)
            VStack(spacing: 1) {
                Text(title)
                    .textStyle(.h3)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.jakarta(11, 600))
                        .foregroundStyle(Color.ink.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)

            // Right slot: badge, ?, !
            HStack(spacing: 6) {
                badge
                if let onHowToPlay {
                    SquareIconButton(symbol: "?", tint: .ink, fill: Color(light: 0xFFFFFF, dark: 0x252156),
                                     border: Color.ink.opacity(0.15), label: "How this game works",
                                     action: onHowToPlay)
                }
                if let onHint {
                    SquareIconButton(symbol: "!", tint: .flame, fill: Color.flame.opacity(0.12),
                                     border: Color.flame.opacity(0.35), label: "Get a hint",
                                     action: onHint)
                }
            }
            .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.horizontal, 16)                           // px-4
        .padding(.vertical, 6)                              // py-2.5 (minus the 44pt tap height)
        .background {                                       // bg-[#FFF8EC]/95 backdrop-blur-md
            Rectangle().fill(.ultraThinMaterial)
                .overlay(Color.canvas.opacity(0.95))
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {                      // border-b border-[#1F1B4D]/10
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}

extension GameHeaderBar where Badge == EmptyView {
    init(title: String, subtitle: String? = nil, onHowToPlay: (() -> Void)? = nil,
         onHint: (() -> Void)? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onHowToPlay: onHowToPlay,
                  onHint: onHint, onBack: onBack) { EmptyView() }
    }
}

/// The 36pt rounded "?" and "!" buttons (w-9 h-9 rounded-xl).
private struct SquareIconButton: View {
    let symbol: String
    let tint: Color
    let fill: Color
    let border: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(symbol)
                .font(.jakarta(13, 800))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(border))
                .frame(width: 44, height: 44)               // Apple's minimum tap target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack(spacing: 0) {
        GameHeaderBar(title: "Conexiones", subtitle: "4 mistakes left", onHowToPlay: {}, onHint: {})
        Spacer()
    }
    .background(Color.canvas)
}
