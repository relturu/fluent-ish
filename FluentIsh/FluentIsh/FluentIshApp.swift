//
//  FluentIshApp.swift
//  FluentIsh
//
//  Created by Arielle Turullols on 10/24/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct FluentIshApp: App {
    init() {
        // Reads GoogleService-Info.plist and connects to fluent-ish-9d543.
        // Must run before any Auth or Firestore call.
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await signInIfNeeded() }
        }
    }

    // V1 uses anonymous auth: every device gets a uid with no login screen.
    // The session is saved on the device, so this only signs in on first launch.
    private func signInIfNeeded() async {
        if let user = Auth.auth().currentUser {
            #if DEBUG
            print("🔥 Already signed in, uid: \(user.uid)")
            #endif
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            #if DEBUG
            print("🔥 Signed in anonymously, uid: \(result.user.uid)")
            #endif
        } catch {
            print("🔥 Anonymous sign-in failed: \(error)")
        }
    }
}
