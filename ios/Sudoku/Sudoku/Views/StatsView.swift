import SwiftUI

struct StatsView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    var stats: GameStatistics { gameManager.statistics }

    var body: some View {
        NavigationStack {
            List {
                // Overview
                Section("Overview") {
                    StatItem(title: "Games Played", value: "\(stats.gamesPlayed)")
                    StatItem(title: "Games Won", value: "\(stats.gamesWon)")
                    StatItem(title: "Win Rate", value: String(format: "%.1f%%", stats.winRate * 100))
                    StatItem(title: "Total Play Time", value: formatTime(stats.totalPlayTime))
                }

                // Streaks
                Section("Streaks") {
                    StatItem(title: "Current Streak", value: "\(stats.currentStreak)")
                    StatItem(title: "Best Streak", value: "\(stats.bestStreak)")
                }

                // Best Times
                Section("Best Times") {
                    ForEach(Difficulty.allCases) { difficulty in
                        if let bestTime = stats.bestTimes[difficulty] {
                            StatItem(title: difficulty.displayName, value: formatTime(bestTime))
                        } else {
                            StatItem(title: difficulty.displayName, value: "—")
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(GameManager())
}
