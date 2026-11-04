//
//  ProgressTabView.swift
//  FluentIsh
//
//  Progress tab. (Named ProgressTabView so it doesn't clash with SwiftUI's
//  built-in ProgressView spinner.) Step 14 builds Player Stats, the Quest
//  Path and the Word Log. "Rules" opens the rules modal in step 9.
//

import SwiftUI

struct ProgressTabView: View {
    var body: some View {
        TabPage(title: "Progress") {
            HStack(spacing: 12) {
                PillButton(title: "Rules") {}
                AppStreakIndicator()
            }
        } content: {
            ComingSoon(step: 14, text: "Player Stats, Quest Path\nand Word Log")
        }
    }
}
