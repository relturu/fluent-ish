//
//  InfoSheet.swift
//  FluentIsh
//
//  The sheet behind every (i) and "About ↗" on Today: what the activity is,
//  a tip, the XP it's worth, and a button to start it. The prototype used a
//  centred popup; a native sheet does the same job, with swipe-to-dismiss
//  and VoiceOver support for free.
//

import SwiftUI

struct InfoContent: Identifiable {
    let id: String
    let badge: String
    let title: String
    let subtitle: String
    let description: String
    let tip: String
    let reward: String
    let actionLabel: String
    let route: TodayRoute?
}

struct InfoSheet: View {
    let content: InfoContent
    var onAction: (TodayRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(content.badge.uppercased())
                            .font(.jakarta(10, 800))
                            .tracking(0.8)
                            .foregroundStyle(Color.flame)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.flame.opacity(0.15), in: Capsule())
                        Text(content.title)
                            .font(.fraunces(21, 700))
                            .foregroundStyle(Color.ink)
                        Text(content.subtitle)
                            .textStyle(.body)
                            .foregroundStyle(Color.inkMuted)
                    }
                    Spacer()
                    CloseButton { dismiss() }
                }

                Text(content.description)
                    .font(.jakarta(14, 500))
                    .foregroundStyle(Color.ink.opacity(0.85))
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Tip").font(.jakarta(12, 800)).foregroundStyle(Color.flame)
                    Text(content.tip).font(.jakarta(13, 500)).foregroundStyle(Color.ink.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.canvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.sunny.opacity(0.35)))

                HStack {
                    Text("Reward").font(.jakarta(13, 600)).foregroundStyle(Color.inkMuted)
                    Spacer()
                    Text(content.reward).font(.jakarta(13, 800)).foregroundStyle(Color.flame)
                }

                if let route = content.route {
                    Button {
                        dismiss()
                        onAction(route)
                    } label: {
                        Label(content.actionLabel, systemImage: "play.fill")
                    }
                    .buttonStyle(.tactile(.primary, fullWidth: true))
                }
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.modal)
        .presentationCornerRadius(28)
    }
}

/// Round "×" used on sheets and modals.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(Color.hairline, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

// MARK: - Level progress

/// Tapping the 🇪🇸 B1 pill: how far to the next CEFR level.
struct LevelProgressSheet: View {
    let flag: String
    let level: ProgressRules.LevelInfo

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(flag) Level \(level.name)")
                    .font(.fraunces(20, 700))
                    .foregroundStyle(Color.ink)
                Spacer()
                CloseButton { dismiss() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(level.nextName.map { "\(level.xpToNext.formatted()) XP to \($0)" } ?? "Top level reached. ¡Felicidades!")
                    .font(.jakarta(14, 800))
                    .foregroundStyle(Color.flame)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.segmentTrack)
                        Capsule()
                            .fill(LinearGradient(colors: [.aqua, .connPurple, .flame], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, geo.size.width * min(1, level.fraction)))
                    }
                }
                .frame(height: 9)
                HStack {
                    Text("\(level.xp.formatted()) XP")
                    Spacer()
                    if let next = level.nextFloor { Text("\(next.formatted()) XP") }
                }
                .font(.jakarta(11, 600))
                .foregroundStyle(Color.inkMuted)
            }
            .accessibilityElement(children: .combine)

            Button("Got it") { dismiss() }
                .buttonStyle(.tactile(.secondary, fullWidth: true))
        }
        .padding(24)
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.modal)
        .presentationCornerRadius(28)
    }
}
