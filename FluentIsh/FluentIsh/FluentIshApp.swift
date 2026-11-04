//
//  FluentIshApp.swift
//  FluentIsh
//
//  Created by Arielle Turullols on 10/24/26.
//

import SwiftUI
import FirebaseCore

@main
struct FluentIshApp: App {
    /// App-wide state (auth, profile, progress), shared with every screen.
    @State private var appState: AppState

    init() {
        // Reads GoogleService-Info.plist and connects to fluent-ish-9d543.
        // Must run before any Auth or Firestore call (AppState uses Firestore).
        FirebaseApp.configure()
        // Plus Jakarta Sans + Fraunces live in Resources/Fonts; register them
        // before the first view draws.
        FontRegistry.registerAll()
        _appState = State(initialValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .task {
                    // V1 uses anonymous auth: every device gets a uid with no
                    // login screen, saved on the device across launches.
                    await appState.start()
                    #if DEBUG
                    await DataSmokeTest.run()   // prints 🧪 results to the console
                    #endif
                }
        }
    }
}
