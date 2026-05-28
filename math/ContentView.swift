//
//  ContentView.swift
//  math
//
//  Created on 20/3/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("darkMode") var darkMode = false  // T013: Dark mode preference
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Home
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 1: Scan / Camera
            CameraScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Tab 2: Graph
            GraphView()
                .tabItem {
                    Label("Graph", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
            
            // Tab 3: History
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(3)
            
            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .preferredColorScheme(darkMode ? .dark : nil)  // T013: Apply dark mode preference
    }
}

#Preview {
    ContentView()
}
