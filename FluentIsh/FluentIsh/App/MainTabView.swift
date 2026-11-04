//
//  MainTabView.swift
//  FluentIsh
//
//  The four tabs (Today · Progress · Friends · Settings) and the custom tab
//  bar from the design: an orange icon + label and a short orange bar on top
//  for the active tab, muted grey for the rest.
//
//  Why custom instead of SwiftUI's TabView bar: the design's bar (indicator
//  line, colours, font) can't be styled that closely with the system one.
//  All four tabs stay alive in a ZStack and only the selected one is shown,
//  so each tab keeps its scroll position and navigation when you switch away
//  and back, the same as a system TabView.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case today, progress, friends, settings
    var id: Self { self }

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .today: "flame"
        case .progress: "chart.bar"
        case .friends: "person.2"
        case .settings: "gearshape"
        }
    }
}

struct MainTabView: View {
    @State private var selection: AppTab = MainTabView.initialTab

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    page(for: tab)
                }
                .opacity(selection == tab ? 1 : 0)
                .allowsHitTesting(selection == tab)
                .accessibilityHidden(selection != tab)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(selection: $selection)
        }
    }

    @ViewBuilder
    private func page(for tab: AppTab) -> some View {
        switch tab {
        case .today: TodayView()
        case .progress: ProgressTabView()
        case .friends: FriendsView()
        case .settings: SettingsView()
        }
    }

    /// DEBUG: launch with `-tab progress` to open on a tab (for screenshots).
    private static var initialTab: AppTab {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "tab"), let tab = AppTab(rawValue: raw) {
            return tab
        }
        #endif
        return .today
    }
}

struct TabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let active = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 5) {
                        Capsule()
                            .fill(active ? Color.flame : .clear)
                            .frame(width: 28, height: 3)
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: active ? .semibold : .regular))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(.jakarta(12, active ? 700 : 600))
                    }
                    .foregroundStyle(active ? Color.flame : Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: selection)
        .background {
            Rectangle().fill(.ultraThinMaterial)
                .overlay(Color.canvas.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}
