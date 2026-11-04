//
//  RootView.swift
//  FluentIsh
//
//  Decides what fills the screen at launch. Step 4: the tab shell.
//  Step 6 adds the onboarding branch (first launch → onboarding → tabs).
//
//  DEBUG: launch with `-screen styleguide` to open the design-system screen.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        content
            .preferredColorScheme(darkMode ? .dark : .light)
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "screen") == "styleguide" {
            StyleGuideView()
        } else {
            MainTabView()
        }
        #else
        MainTabView()
        #endif
    }
}
