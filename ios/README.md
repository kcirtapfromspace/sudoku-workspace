# Sudoku iOS App

A native iOS Sudoku app powered by the Rust `sudoku-core` engine.

## Requirements

- Xcode 15.0+
- iOS 16.0+ deployment target
- Rust toolchain (for building the engine)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for generating Xcode project)

## Quick Start

### 1. Install Dependencies

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install xcodegen
brew install xcodegen

# Add iOS targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

### 2. Build the Project

```bash
# From the workspace root
cd ios
./build.sh
```

This will:
- Build the Rust library for iOS device and simulator
- Generate Swift bindings via UniFFI
- Create an XCFramework
- Generate the Xcode project

### 3. Open in Xcode

```bash
open Sudoku/Sudoku.xcodeproj
```

Or generate the project manually:

```bash
cd Sudoku
xcodegen generate
open Sudoku.xcodeproj
```

## Project Structure

```
ios/
├── build.sh              # Build script for Rust + Xcode project
├── Frameworks/           # Generated XCFramework (after build)
└── Sudoku/
    ├── project.yml       # xcodegen configuration
    ├── Sudoku/
    │   ├── SudokuApp.swift
    │   ├── Models/
    │   │   └── GameModels.swift
    │   ├── ViewModels/
    │   │   └── GameViewModel.swift
    │   ├── Views/
    │   │   ├── ContentView.swift
    │   │   ├── GameView.swift
    │   │   ├── GridView.swift
    │   │   ├── CellView.swift
    │   │   ├── NumberPadView.swift
    │   │   ├── SettingsView.swift
    │   │   └── StatsView.swift
    │   ├── Services/
    │   │   └── GameManager.swift
    │   ├── Resources/
    │   │   └── Assets.xcassets/
    │   └── Generated/    # UniFFI-generated Swift bindings
    └── SudokuTests/
```

## Features

- **Native SwiftUI interface** - Modern iOS design with full Dark Mode support
- **Universal app** - Optimized for both iPhone and iPad
- **Multiple input methods** - Tap, external keyboard support
- **Game features** - Undo/redo, hints, candidates/notes mode
- **Statistics** - Track games played, best times, win streaks
- **Persistence** - Auto-save games, statistics stored locally
- **Accessibility** - VoiceOver support, Dynamic Type

## Integrating the Rust Engine

The app uses UniFFI to bridge between Swift and Rust. The Swift implementation in `GameViewModel.swift` currently contains a pure-Swift puzzle generator for development. To use the Rust engine:

1. Run `./build.sh` to generate the XCFramework and Swift bindings
2. Add the generated `SudokuEngine.xcframework` to the Xcode project
3. Import `SudokuEngine` in Swift files that need it
4. Replace the Swift puzzle generation with calls to the Rust `SudokuGame` class

Example usage with Rust engine:

```swift
import SudokuEngine

// Create a new game
let game = SudokuGame.newClassic(difficulty: .medium)

// Make a move
let result = game.makeMove(row: 0, col: 0, value: 5)

// Get hint
if let hint = game.getHint() {
    print("Hint: \(hint.explanation)")
}
```

## Development Notes

### Running Without Rust

The app includes a pure-Swift implementation of the puzzle generator and solver for development purposes. This allows you to run and test the UI without building the Rust library.

### Building for Release

For App Store submission, ensure you:
1. Build the Rust library in release mode
2. Set your development team in Xcode
3. Configure App Store Connect for Game Center and iCloud

## License

MIT License - see the root LICENSE file.
