import SwiftUI

@main
struct SudokuApp: App {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Start prefetching puzzles immediately on app launch
        Task(priority: .background) {
            await PuzzleCache.shared.prefetchAll()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        // Auto-pause when app goes to background
                        gameManager.currentGame?.pause()
                        gameManager.saveCurrentGame()
                    }
                }
        }
    }
}
