# iOS Sudoku App - Bug Fixes and Feature Plan

## Summary of Issues

1. **Note Mode Bug** - Entering a single note shows ALL candidates
2. **Missing Note Options** - Need "Check Notes" functionality
3. **Long Press for Notes** - Enable single note entry via long press
4. **Disruptive Celebrations** - Replace overlay with subtle wiggle
5. **Sequential Completion Detection** - Celebrate filling in order 1-9
6. **Cell Selection Bug** - Investigate difficulty clicking empty cells
7. **Background Pause** - Auto-pause timer when app backgrounds
8. **Game History** - Track and replay past games

---

## Issue 1: Note Mode Bug (CRITICAL)

### Root Cause
In `GameViewModel.swift` line 277-285, when `toggleCandidate()` is called:
1. Line 282 sets `showCandidates = true`
2. In `syncFromEngine()` line 121, when `showCandidates` is true, it reads `state.candidates` from the Rust engine for ALL cells
3. The Rust engine's `candidates` field contains ALL valid candidates (auto-calculated), not just user-entered ones
4. Result: User enters ONE note in ONE cell, but ALL calculated candidates appear on THE ENTIRE BOARD

### Fix: Track User Candidates Separately in Swift

**Files to modify:**
- `/ios/Sudoku/Sudoku/ViewModels/GameViewModel.swift`

**Changes:**
1. Add new property to track user-entered candidates:
   ```swift
   private var userCandidates: [[Set<Int>]] = Array(repeating: Array(repeating: [], count: 9), count: 9)
   private var usingAutoFill: Bool = false
   ```

2. Modify `toggleCandidate()` to update local tracking:
   ```swift
   private func toggleCandidate(_ value: Int, at row: Int, col: Int) {
       let cell = cells[row][col]
       if cell.isGiven || cell.value != 0 { return }

       showCandidates = true
       // Toggle in local tracking
       if userCandidates[row][col].contains(value) {
           userCandidates[row][col].remove(value)
       } else {
           userCandidates[row][col].insert(value)
       }

       _ = game.toggleCandidate(row: UInt8(row), col: UInt8(col), value: UInt8(value))
       syncFromEngine()
   }
   ```

3. Modify `syncFromEngine()` to use correct candidate source:
   ```swift
   let candidates: Set<Int>
   if usingAutoFill {
       candidates = showCandidates ? Self.dataToSet(state.candidates) : []
   } else {
       candidates = userCandidates[row][col]
   }
   ```

4. Modify `fillAllCandidates()` to set `usingAutoFill = true`
5. Modify `clearAllCandidates()` to set `usingAutoFill = false` and clear `userCandidates`

---

## Issue 2: Add "Check Notes" Feature

**Files to modify:**
- `/crates/sudoku-ffi/src/lib.rs` - Add Rust function
- `/ios/Sudoku/Sudoku/ViewModels/GameViewModel.swift` - Add Swift wrapper
- `/ios/Sudoku/Sudoku/Views/GameView.swift` - Add UI menu item

**Rust FFI changes:**
```rust
pub fn remove_invalid_candidates(&self) {
    let mut grid = self.grid.lock().unwrap();
    let solution = self.solution.lock().unwrap();

    for row in 0..9 {
        for col in 0..9 {
            let pos = Position::new(row, col);
            if grid.cell(pos).is_empty() {
                let correct = solution.get(pos).unwrap_or(0);
                // Keep only the correct candidate
                grid.cell_mut(pos).set_candidates(BitSet::single(correct));
            }
        }
    }
}
```

**UI:** Add "Check Notes" button to notes menu in GameView.swift

---

## Issue 3: Long Press for Single Note Entry

**Files to modify:**
- `/ios/Sudoku/Sudoku/Models/GameModels.swift` - Add temporary mode
- `/ios/Sudoku/Sudoku/Views/GridView.swift` - Add long press gesture
- `/ios/Sudoku/Sudoku/ViewModels/GameViewModel.swift` - Handle temporary mode

**Changes:**
1. Add to `InputMode` enum: `case temporaryCandidate`

2. Add long press gesture in `GridView.swift`:
   ```swift
   .onLongPressGesture(minimumDuration: 0.5) {
       game.selectCell(row: row, col: col)
       game.enterTemporaryNoteMode()
       hapticFeedback(.medium)
   }
   ```

3. In `GameViewModel.swift`:
   - Store previous mode before switching to temporary
   - After entering one note, revert to previous mode

---

## Issue 4: Non-Disruptive Celebrations

**Files to modify:**
- `/ios/Sudoku/Sudoku/Views/GameView.swift` - Replace overlay, add wiggle effect
- `/ios/Sudoku/Sudoku/Views/GridView.swift` - Apply wiggle to cells
- `/ios/Sudoku/Sudoku/ViewModels/GameViewModel.swift` - Track celebrating cells

**Changes:**
1. Create `WiggleEffect` modifier (similar to existing `ShakeEffect`):
   ```swift
   struct WiggleEffect: GeometryEffect {
       var progress: CGFloat
       var animatableData: CGFloat { get { progress } set { progress = newValue } }

       func effectValue(size: CGSize) -> ProjectionTransform {
           let shake = sin(progress * .pi * 6) * 4 * (1 - progress)
           return ProjectionTransform(CGAffineTransform(translationX: shake, y: 0))
       }
   }
   ```

2. Add to `GameViewModel`:
   ```swift
   @Published var celebratingCells: Set<String> = []

   func triggerRowCelebration(_ row: Int) {
       for col in 0..<9 { celebratingCells.insert("\(row)-\(col)") }
       autoClearCelebration(after: 0.5)
   }
   ```

3. In `GridView.swift`, apply wiggle to celebrating cells

4. Remove `CelebrationOverlay` for row/col/box completions (keep only for game win)

---

## Issue 5: Sequential Completion Detection

**Files to modify:**
- `/ios/Sudoku/Sudoku/ViewModels/GameViewModel.swift` - Track fill order
- `/ios/Sudoku/Sudoku/Models/GameModels.swift` - Update CelebrationEvent, GameStatistics

**Changes:**
1. Track fill order for each row/col/box:
   ```swift
   private var rowFillOrder: [Int: [Int]] = [:]
   ```

2. In `setValue()`, record the value entered for non-given cells

3. When detecting completion, check if fill order is sequential (1,2,3... or ...7,8,9)

4. Update `CelebrationEvent`:
   ```swift
   case rowComplete(row: Int, isSequential: Bool = false)
   ```

5. Add to `GameStatistics`:
   ```swift
   var sequentialCompletions: Int = 0
   ```

---

## Issue 6: Cell Selection Investigation

**Files to check:**
- `/ios/Sudoku/Sudoku/Views/GridView.swift`
- `/ios/Sudoku/Sudoku/Views/CellView.swift`

**Potential fixes:**
1. Add `.contentShape(Rectangle())` before `.onTapGesture` to ensure entire cell area is tappable
2. Increase Konami gesture `minimumDistance` from 30 to 50 in `GameView.swift` to reduce tap interference

---

## Issue 7: Auto-Pause on App Background

**Files to modify:**
- `/ios/Sudoku/Sudoku/SudokuApp.swift` - Add scene phase monitoring

**Changes:**
```swift
@main
struct SudokuApp: App {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        gameManager.currentGame?.pause()
                    }
                }
        }
    }
}
```

---

## Issue 8: Game History Tracking (Puzzle Library)

**New files to create:**
- `/ios/Sudoku/Sudoku/Models/GameHistory.swift` - Data models
- `/ios/Sudoku/Sudoku/Services/GameHistoryManager.swift` - Persistence
- `/ios/Sudoku/Sudoku/Views/GameHistoryView.swift` - UI

**Data model - Store unique puzzles by hash:**
```swift
struct PuzzleRecord: Codable, Identifiable {
    var id: String { puzzleHash }
    let puzzleHash: String        // SHA-256 hash of puzzle string (unique ID)
    let puzzleString: String      // 81-char puzzle (givens as digits, empty as ".")
    let difficulty: Difficulty
    let firstPlayedAt: Date
    var lastPlayedAt: Date
    var playCount: Int
    var bestTime: TimeInterval?
    var wins: Int
    var losses: Int
}
```

**Key implementation:**
1. Add `getPuzzleFingerprint()` to `GameViewModel` - extracts given cells as 81-char string
2. Generate SHA-256 hash from puzzle string as unique identifier
3. `GameHistoryManager` stores puzzles in a dictionary keyed by hash (no limit)
4. When starting a game, lookup by hash - increment playCount if exists, create new if not
5. `GameHistoryView` shows list sorted by lastPlayedAt with:
   - Difficulty badge
   - Play count
   - Best time (if won)
   - Replay button
6. User can load any puzzle by hash (shareable puzzle codes possible in future)

**Storage:** UserDefaults with puzzle dictionary. Consider migration to SQLite if library grows very large.

---

## Implementation Priority

1. **High Priority (Critical bugs)**
   - Issue 1: Note mode bug fix
   - Issue 6: Cell selection fix
   - Issue 7: Auto-pause on background

2. **Medium Priority (UX improvements)**
   - Issue 4: Non-disruptive celebrations
   - Issue 3: Long press for notes

3. **Lower Priority (New features)**
   - Issue 2: Check Notes feature
   - Issue 5: Sequential completion detection
   - Issue 8: Game history (largest scope)

---

## Verification Plan

1. **Note Mode**: Toggle note mode, tap a single number, verify ONLY that note appears in that ONE cell (not the whole board)
2. **Note Mode - Fill All**: Tap "Fill All Notes", verify all valid candidates appear across board
3. **Cell Selection**: Tap empty cells directly, verify they select immediately
4. **Background Pause**: Start game, switch to another app, return, verify timer was paused
5. **Celebrations**: Complete a row, verify cells wiggle briefly without blocking overlay
6. **Sequential Celebration**: Fill a row in order 1-2-3..., verify enhanced celebration
7. **Long Press**: Long press empty cell, enter note, verify mode reverts after
8. **Check Notes**: Add some incorrect notes, tap "Check Notes", verify they're removed
9. **Game History**: Complete a game, view history, verify puzzle appears with play count
10. **Replay**: From history, tap replay on a puzzle, verify same puzzle loads
