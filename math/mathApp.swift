//
//  mathApp.swift
//  math
//
//  Created by mac on 20/3/2026.
//

import SwiftUI
import SwiftData

@main
struct mathApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LeaderboardEntry.self, GameSession.self, Enemy.self, UserPreferences.self])
    }
}
