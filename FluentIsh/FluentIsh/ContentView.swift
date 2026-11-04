//
//  ContentView.swift
//  FluentIsh
//
//  Temporary root view. During step 2–3 of the V1 build it shows the DEBUG
//  style guide so the design system can be checked against the AI Studio
//  screenshots. Step 4 replaces this with the real app shell (tab bar).
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if DEBUG
        StyleGuideView()
        #else
        Text("Fluent·ish")
        #endif
    }
}

#Preview {
    ContentView()
}
