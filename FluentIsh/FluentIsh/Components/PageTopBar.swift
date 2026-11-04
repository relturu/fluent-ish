//
//  PageTopBar.swift
//  FluentIsh
//
//  The header on every tab: "Fluent•ish / Today" on the left, small actions
//  (level, Rules, streak) on the right. It stays pinned while the page
//  scrolls, with a translucent cream background and a hairline underneath,
//  like the prototype's sticky header (HiFiElements.tsx PageTopBar).
//
//  Also: the brand wordmark, the streak flame and the level pill, since
//  they only appear inside top bars.
//

import SwiftUI

struct PageTopBar<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 8) {
            BrandWordmark()
            Text("/")
                .font(.jakarta(17, 700))
                .foregroundStyle(Color.ink.opacity(0.3))
            Text(title)
                .font(.jakarta(15, 700))
                .foregroundStyle(Color.ink.opacity(0.9))
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background {
            Rectangle().fill(.ultraThinMaterial)
                .overlay(Color.canvas.opacity(0.9))
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}

extension PageTopBar where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

/// "Fluent•ish", with the orange dot.
struct BrandWordmark: View {
    var size: CGFloat = 19

    var body: some View {
        HStack(spacing: size * 0.22) {
            Text("Fluent")
            Circle().fill(Color.flame).frame(width: size * 0.33, height: size * 0.33)
            Text("ish")
        }
        .font(.jakarta(size, 800))
        .tracking(-0.3)
        .foregroundStyle(Color.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fluentish")
    }
}

/// Orange flame + day count + status dot. The dot is green once today's
/// streak is counted (any XP earned today) and pale orange until then.
/// When counted, the flame pulses with a soft glow (flamePulseGlow, 2.4s).
struct StreakIndicator: View {
    let count: Int
    let countedToday: Bool
    var action: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .scaleEffect(glowing ? 1.08 : 1)
                    .shadow(color: Color.flame.opacity(countedToday ? (glowing ? 0.8 : 0.4) : 0),
                            radius: glowing ? 7 : 3)
                Text("\(count)")
                    .font(.jakarta(15, 800))
                    .monospacedDigit()
                Circle()
                    .fill(countedToday ? Color.success : Color.flame.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
            .foregroundStyle(Color.flame)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            guard countedToday, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { glowing = true }
        }
        .accessibilityLabel(countedToday
            ? "Streak \(count) days, counted today"
            : "Streak \(count) days, finish a game or lesson to count today")
    }
}

/// "🇪🇸 B1" in purple: the current CEFR level. Tapping shows level progress (step 7).
struct LevelPill: View {
    let flag: String
    let level: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 5) {
                Text(flag).font(.system(size: 14))
                Text(level).font(.jakarta(15, 800))
            }
            .foregroundStyle(Color.connPurple)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Level \(level)")
    }
}

/// Small lavender pill used for "Rules" on Progress.
struct PillButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.jakarta(13, 700))
                .foregroundStyle(Color.connPurple)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.connPurple.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.connPurple.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        PageTopBar(title: "Today") {
            HStack(spacing: 14) {
                LevelPill(flag: "🇪🇸", level: "B1")
                StreakIndicator(count: 14, countedToday: false)
            }
        }
        PageTopBar(title: "Progress") {
            HStack(spacing: 12) {
                PillButton(title: "Rules") {}
                StreakIndicator(count: 15, countedToday: true)
            }
        }
        Spacer()
    }
    .background(Color.canvas)
}
