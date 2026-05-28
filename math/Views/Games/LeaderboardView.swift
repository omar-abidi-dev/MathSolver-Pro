import SwiftUI
import SwiftData

/// Displays ranked leaderboard scores from previous games
struct LeaderboardView: View {
    @Query(sort: \LeaderboardEntry.score, order: .reverse) private var allEntries: [LeaderboardEntry]
    @State private var selectedMode: GameMode = .speedTrainer
    
    var filteredEntries: [LeaderboardEntry] {
        allEntries.filter { $0.gameModeEnum == selectedMode }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode filter
                Picker("Game Mode", selection: $selectedMode) {
                    Text("Speed Trainer").tag(GameMode.speedTrainer)
                    Text("Battle").tag(GameMode.battle)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "leaderboard.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Scores Yet")
                            .font(.headline)
                        
                        Text("Play a game to appear on the leaderboard!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRow(
                                rank: index + 1,
                                entry: entry
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.visible)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Single leaderboard entry row
struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.nickname)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(entry.difficultyEnum?.rawValue.capitalized ?? "Unknown")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Score and accuracy
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.score)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(String(format: "%.1f%%", entry.accuracy))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        default:
            return .blue
        }
    }
    
    private var difficultyColor: Color {
        guard let difficulty = entry.difficultyEnum else { return .blue }
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
    
    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.date, relativeTo: Date())
    }
}

#Preview {
    LeaderboardView()
        .modelContainer(for: LeaderboardEntry.self, inMemory: true)
}
