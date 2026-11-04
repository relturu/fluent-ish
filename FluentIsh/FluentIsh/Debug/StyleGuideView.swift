//
//  StyleGuideView.swift
//  FluentIsh
//
//  DEBUG-only screen that redraws the AI Studio "Fluent·ish Style Guide"
//  (palette, type scale, 3D buttons) with the real SwiftUI tokens. Compare
//  it with the design-doc screenshot to check colours, fonts and buttons
//  before any screen uses them.
//

#if DEBUG
import SwiftUI

struct StyleGuideView: View {
    private let swatches: [(Color, String, String, String)] = [
        (.flame, "#FF6B2C", "Flame Orange", "Primary Action & CTAs"),
        (.indigo, "#1F1B4D", "Deep Indigo", "Primary Text & Ink"),
        (.connPurple, "#7B5CFF", "Connections Purple", "Game Accent: Connections"),
        (.sunny, "#FFC93C", "Sunny Yellow", "Game Accent: Word Guess (Dark text)"),
        (.aqua, "#19C3B1", "Aqua", "Game Accent: Mini Crossword"),
        (.success, "#3DDC84", "Success Green", "Success feedback & Solved state"),
        (.coral, "#FF5C6C", "Error Coral", "Mistakes & warnings"),
        (.offWhite, "#FFF8EC", "Warm Off-White", "App Canvas Light Mode"),
    ]

    private let typeRows: [(TextStyle, String, String, String)] = [
        (.display, "Display", "30 · ExtraBold", "¡Hola, Sofía!"),
        (.h1, "H1", "24 · ExtraBold", "la sobremesa"),
        (.h2, "H2", "19 · Bold", "Today's Games"),
        (.h3, "H3", "15 · Bold", "Connections · Conexiones"),
        (.body, "Body", "13 · Medium", "70% Review · 30% New"),
        (.caption, "Caption", "11 · Bold caps", "Today's games"),
        (.serifHero, "Serif Hero", "Fraunces 32 · 800", "¡Hola, Sofía!"),
        (.serifTitle, "Serif Title", "Fraunces 22 · 700", "Daily Vocab"),
    ]

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                section("Color Palette (Game-Centric Scheme)") {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(swatches, id: \.1) { swatch in
                            swatchCard(swatch)
                        }
                    }
                }

                section("Typography: Plus Jakarta Sans + Fraunces", id: "type") {
                    VStack(spacing: 0) {
                        ForEach(Array(typeRows.enumerated()), id: \.offset) { index, row in
                            typeRow(row)
                            if index < typeRows.count - 1 { Divider().overlay(Color.hairline) }
                        }
                    }
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline))
                }

                section("Chunky 3D Tactile Buttons", id: "buttons") {
                    VStack(spacing: 14) {
                        buttonPanel(title: "LIGHT MODE", scheme: .light)
                        buttonPanel(title: "DARK MODE", scheme: .dark)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.canvas)
        .scrollIndicators(.hidden)
        .onAppear {
            // Launch with `-scrollTo type` or `-scrollTo buttons` to jump to a
            // section (lets screenshots be taken from the command line).
            if let target = UserDefaults.standard.string(forKey: "scrollTo") {
                proxy.scrollTo(target, anchor: .top)
            }
        }
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 10) {
            Text("DESIGN DOC")
                .font(.jakarta(11, 800))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.flame, in: Capsule())
            HStack(spacing: 0) {
                Text("Fluent")
                Circle().fill(Color.flame).frame(width: 6, height: 6).padding(.horizontal, 2)
                Text("ish Style Guide")
            }
            .font(.jakarta(18, 800))
            .foregroundStyle(Color.offWhite)
            Spacer()
        }
        .padding(16)
        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 8)
    }

    private func section<Content: View>(_ title: String, id: String = "", @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).textStyle(.h2).foregroundStyle(Color.ink)
            content()
        }
        .id(id)
    }

    private func swatchCard(_ s: (Color, String, String, String)) -> some View {
        let darkText = s.0 == .sunny || s.0 == .aqua || s.0 == .success || s.0 == .offWhite
        return VStack(alignment: .leading, spacing: 0) {
            Text(s.1)
                .font(.jakarta(14, 800))
                .foregroundStyle(darkText ? Color.indigo : .white)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
                .background(s.0)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.2).textStyle(.h3).foregroundStyle(Color.ink)
                Text(s.3).font(.jakarta(11, 500)).foregroundStyle(Color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .background(Color.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.hairline))
    }

    private func typeRow(_ row: (TextStyle, String, String, String)) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.1).font(.jakarta(14, 700)).foregroundStyle(Color.flame)
                Text(row.2).font(.jakarta(11, 500)).foregroundStyle(Color.inkMuted)
            }
            Spacer(minLength: 12)
            Text(row.3)
                .textStyle(row.0)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func buttonPanel(title: String, scheme: ColorScheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.jakarta(12, 800))
                .tracking(0.6)
                .foregroundStyle(scheme == .dark ? Color.flame : Color.inkMuted)
            Button("Play Game (Flame)") {}.buttonStyle(.tactile(.primary, fullWidth: true))
            HStack(spacing: 10) {
                Button("Purple") {}.buttonStyle(.tactile(.purple, size: .small, fullWidth: true))
                Button("Yellow") {}.buttonStyle(.tactile(.yellow, size: .small, fullWidth: true))
                Button("Aqua") {}.buttonStyle(.tactile(.aqua, size: .small, fullWidth: true))
            }
            HStack(spacing: 10) {
                Button("Play") {}.buttonStyle(.tactile(.secondary, size: .small, fullWidth: true))
                Button("Off") {}.buttonStyle(.tactile(.outline, size: .small, fullWidth: true))
                Button("Disabled") {}.buttonStyle(.tactile(.primary, size: .small, fullWidth: true)).disabled(true)
            }
        }
        .padding(18)
        .background(Color.canvas, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline))
        .environment(\.colorScheme, scheme)
    }
}

#Preview("Light") { StyleGuideView() }
#Preview("Dark") { StyleGuideView().preferredColorScheme(.dark) }
#endif
