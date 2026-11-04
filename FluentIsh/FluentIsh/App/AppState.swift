//
//  AppState.swift
//  FluentIsh
//
//  The app-wide state every screen can read: who's signed in, their profile
//  and their progress in the current language. Created once in FluentIshApp
//  and passed down with `.environment(appState)`; a view reads it with
//  `@Environment(AppState.self) private var appState`.
//
//  @Observable means SwiftUI redraws any view that read a property when that
//  property changes. Profile and progress use Firestore *snapshot listeners*,
//  so when a game writes new XP (step 5+), the top bar's streak and level
//  update by themselves, on every tab.
//

import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AppState {
    private(set) var uid: String?
    private(set) var user: AppUser?
    private(set) var progress: LanguageProgress?
    /// Set when sign-in or a listener fails, so the UI can say so.
    private(set) var errorMessage: String?

    /// Target language code (es · fr · it · pt). Only Spanish is seeded for V1.
    var language = "es"

    @ObservationIgnored private var listeners: [ListenerRegistration] = []
    @ObservationIgnored private let db = Firestore.firestore()

    // MARK: Derived values for the top bar

    var today: String { ProgressRules.dayKey() }

    var streak: Int {
        guard let progress else { return 0 }
        return ProgressRules.displayedStreak(current: progress.currentStreak,
                                             lastActiveDate: progress.lastActiveDate, today: today)
    }

    var streakCountedToday: Bool {
        guard let progress else { return false }
        return ProgressRules.countedToday(lastActiveDate: progress.lastActiveDate, today: today)
    }

    var level: ProgressRules.LevelInfo { ProgressRules.level(forXP: progress?.xp ?? 0) }

    /// First name for greetings ("¡Hola, Sofía!").
    var firstName: String {
        user?.displayName.split(separator: " ").first.map(String.init) ?? ""
    }

    // MARK: Startup

    /// Signs in (anonymously, V1) and starts listening to the user's data.
    func start() async {
        do {
            let uid: String
            if let current = Auth.auth().currentUser {
                uid = current.uid
                #if DEBUG
                print("🔥 Already signed in, uid: \(uid)")
                #endif
            } else {
                uid = try await Auth.auth().signInAnonymously().user.uid
                #if DEBUG
                print("🔥 Signed in anonymously, uid: \(uid)")
                #endif
            }
            self.uid = uid
            listen(uid: uid)
        } catch {
            errorMessage = "Couldn't sign in: \(error.localizedDescription)"
            print("🔥 Anonymous sign-in failed: \(error)")
        }
    }

    private func listen(uid: String) {
        listeners.forEach { $0.remove() }
        listeners = [
            db.document("users/\(uid)").addSnapshotListener { [weak self] snapshot, error in
                self?.handle(snapshot, error, label: "profile") { self?.user = $0 }
            },
            db.document("users/\(uid)/progress/\(language)").addSnapshotListener { [weak self] snapshot, error in
                self?.handle(snapshot, error, label: "progress") { self?.progress = $0 }
            },
        ]
    }

    /// Decodes a listener update. A missing document isn't an error: a brand
    /// new user has no profile until onboarding (step 6) creates it.
    private func handle<T: Decodable>(_ snapshot: DocumentSnapshot?, _ error: Error?, label: String,
                                      assign: (T?) -> Void) {
        if let error {
            errorMessage = "Couldn't load your \(label): \(error.localizedDescription)"
            return
        }
        guard let snapshot, snapshot.exists else { assign(nil); return }
        do {
            assign(try snapshot.data(as: T.self))
        } catch {
            errorMessage = "Your \(label) data doesn't match the app: \(error.localizedDescription)"
            print("🔥 Decode \(label) failed: \(error)")
        }
    }
}
