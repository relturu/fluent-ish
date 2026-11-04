//
//  RootView.swift
//  FluentIsh
//
//  Decides what fills the screen at launch:
//  splash (waiting for the first Firestore snapshots) → onboarding (signed in,
//  but no profile yet) → the tabs.
//
//  DEBUG: `-screen styleguide` opens the design-system screen;
//  `-screen onboarding` previews onboarding (don't finish it: it would
//  overwrite the signed-in user's progress);
//  `-freshStart YES` signs out first, so you get a new user and onboarding.
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
        } else if UserDefaults.standard.string(forKey: "screen") == "onboarding" {
            OnboardingView()   // preview only: finishing would overwrite this user's progress
        } else {
            appContent
        }
        #else
        appContent
        #endif
    }

    @ViewBuilder
    private var appContent: some View {
        Group {
            if !appState.loaded {
                SplashView(message: appState.errorMessage)
            } else if appState.needsOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.loaded)
        .animation(.easeInOut(duration: 0.35), value: appState.needsOnboarding)
    }
}

/// Shown for the moment between launch and the first Firestore snapshot.
struct SplashView: View {
    var message: String?

    var body: some View {
        VStack(spacing: 16) {
            MascotView(mood: .waving, size: .lg)
            BrandWordmark()
            if let message {
                Text(message)
                    .textStyle(.body)
                    .foregroundStyle(Color.coral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
    }
}
