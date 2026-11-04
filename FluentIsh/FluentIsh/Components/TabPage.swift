//
//  TabPage.swift
//  FluentIsh
//
//  Shared layout for the four tab screens: the pinned PageTopBar, a scrolling
//  cream page underneath, and room for the tab bar at the bottom. Each tab
//  only supplies its title, top-bar actions and content:
//
//      TabPage(title: "Friends") { AppStreakIndicator() } content: { … }
//

import SwiftUI

struct TabPage<Trailing: View, Content: View>: View {
    let title: String
    var spacing: CGFloat = 24
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(Self.startAtBottom ? .bottom : .top)
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            PageTopBar(title: title) { trailing }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension TabPage {
    /// DEBUG: `-scrollBottom YES` opens tabs scrolled to the end (screenshots).
    static var startAtBottom: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "scrollBottom")
        #else
        false
        #endif
    }
}

/// The streak flame wired to the signed-in user's progress. Used on every tab.
struct AppStreakIndicator: View {
    @Environment(AppState.self) private var appState
    var action: (() -> Void)? = nil

    var body: some View {
        StreakIndicator(count: appState.streak, countedToday: appState.streakCountedToday, action: action)
    }
}
