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
                .onOpenURL { url in
                    // Handle shared puzzle URLs:
                    // https://kcirtapfromspace.github.io/sudoku/?s=SHORT_CODE
                    // https://kcirtapfromspace.github.io/sudoku/?p=PUZZLE_STRING
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                        return
                    }

                    // Try short code first (?s=)
                    if let shortCode = components.queryItems?.first(where: { $0.name == "s" })?.value,
                       shortCode.count == 8 {
                        gameManager.loadSharedPuzzle(shortCode)
                        return
                    }

                    // Fall back to 81-char puzzle (?p=)
                    if let puzzleParam = components.queryItems?.first(where: { $0.name == "p" })?.value,
                       puzzleParam.count == 81 {
                        gameManager.loadSharedPuzzle(puzzleParam)
                    }
                }
        }
    }
}
