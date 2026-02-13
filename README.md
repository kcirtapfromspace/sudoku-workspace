# Sudoku (Rust Engine + TUI + WASM + iOS)

Shared Sudoku engine written in Rust, with:

- Terminal UI (`crates/sudoku-tui`)
- WebAssembly build (`crates/sudoku-wasm`)
- iOS app (Rust via FFI) (`ios/`)

## Demos

### TUI

![TUI demo](docs/demos/tui.gif)

### WASM

![WASM demo](docs/demos/wasm.gif)

## Quickstart

### TUI

```bash
cargo run -p sudoku-tui --bin sudoku
```

### WASM

```bash
wasm-pack build crates/sudoku-wasm --target web --out-dir crates/sudoku-wasm/www/pkg --release
cd crates/sudoku-wasm/www
python3 serve.py 8080
```

Then open `http://127.0.0.1:8080/`.

### iOS

Open `ios/Sudoku/Sudoku.xcodeproj` in Xcode and run the `Sudoku` scheme.

## Puzzle Generation (Rust)

Puzzle generation lives in the Rust core crate:

- Generator: `crates/sudoku-core/src/generator.rs`
- Solver + uniqueness + difficulty rating: `crates/sudoku-core/src/solver.rs`

At a high level:

1. **Create a fully solved grid** (a complete valid Sudoku solution).
2. **Remove givens while preserving uniqueness**:
   - Remove values (using symmetric pairs) to form a puzzle.
   - After each removal, verify the puzzle still has **exactly one solution** (the solver stops once it finds 2).
3. **Rate the puzzle difficulty** using a human-style technique simulation and retry generation until it matches the requested difficulty.

The iOS app uses this same generator through the Rust FFI layer (`crates/sudoku-ffi`), and stores the solved grid alongside the puzzle so it can power hints and validation.

