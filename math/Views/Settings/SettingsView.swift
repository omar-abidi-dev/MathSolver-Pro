import SwiftUI

/// Settings and preferences for the app
struct SettingsView: View {
    @AppStorage("defaultDifficulty") var defaultDifficulty = "intermediate"
    @AppStorage("showSteps") var showSteps = true
    @AppStorage("showKeyboard") var showKeyboard = false
    @AppStorage("darkMode") var darkMode = false
    
    var body: some View {
        NavigationView {
            Form {
                // Solver Settings
                Section(header: Text("Solver Settings")) {
                    Picker("Default Difficulty", selection: $defaultDifficulty) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                    }
                    
                    Toggle("Show Solution Steps", isOn: $showSteps)
                    Toggle("Show Math Keyboard", isOn: $showKeyboard)
                }
                
                // Display Settings
                Section(header: Text("Display")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI")
                            .foregroundColor(.gray)
                    }
                }
                
                // Support
                Section(header: Text("Support")) {
                    Button(action: { /* Send feedback */ }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: { /* Visit website */ }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Visit Website")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Reset
                Section {
                    Button(role: .destructive) {
                        resetSettings()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func resetSettings() {
        defaultDifficulty = "intermediate"
        showSteps = true
        showKeyboard = false
        darkMode = false
    }
}

#Preview {
    SettingsView()
}
