# Sudoku Engine in Rust - Implementation Plan

## Overview
A cross-platform Sudoku engine powering iOS, Android, and a TUI interface. Full-featured with puzzle generation, solving, hints, and support for variant rules.

## Architecture

```
sudoku-workspace/
├── Cargo.toml              # Workspace root
├── crates/
│   ├── sudoku-core/        # Core engine (no dependencies)
│   ├── sudoku-ffi/         # UniFFI bindings for mobile
│   └── sudoku-tui/         # Terminal interface
├── uniffi-bindgen/         # Generated Swift/Kotlin bindings
└── examples/
```

## Crate Structure

### 1. `sudoku-core` (Library)
Pure Rust, zero external dependencies for maximum portability.

**Core Types:**
```rust
// Flexible grid supporting 4x4, 9x9, 16x16
pub struct Grid<const N: usize> {
    cells: [[Cell; N]; N],
    constraints: Vec<Box<dyn Constraint>>,
}

pub struct Cell {
    value: Option<u8>,
    candidates: BitSet,
    given: bool,
}

// Constraint trait for variants
pub trait Constraint: Send + Sync {
    fn validate(&self, grid: &Grid, pos: Position, value: u8) -> bool;
    fn affected_cells(&self, pos: Position) -> Vec<Position>;
}
```

**Built-in Constraints:**
- `RowConstraint` - standard row uniqueness
- `ColumnConstraint` - standard column uniqueness
- `BoxConstraint` - standard box uniqueness
- `DiagonalConstraint` - for X-Sudoku variant
- `KillerCageConstraint` - sum constraints for Killer Sudoku
- `ThermoConstraint` - increasing sequence along a path

**Solver (Backtracking + Human Techniques):**
- Naked/Hidden singles, pairs, triples
- Pointing pairs, box/line reduction
- X-Wing, Swordfish
- Backtracking fallback for unsolvable-by-logic puzzles
- Difficulty rating based on techniques required

**Generator:**
- Start with solved grid (randomized fill)
- Remove cells symmetrically
- Verify unique solution exists
- Rate difficulty, retry if not in target range

**Key APIs:**
```rust
impl Grid {
    pub fn new_classic() -> Self;
    pub fn new_with_constraints(constraints: Vec<Box<dyn Constraint>>) -> Self;
    pub fn set_cell(&mut self, pos: Position, value: u8) -> Result<(), MoveError>;
    pub fn get_candidates(&self, pos: Position) -> BitSet;
    pub fn validate(&self) -> ValidationResult;
    pub fn is_complete(&self) -> bool;
}

impl Solver {
    pub fn solve(&self, grid: &Grid) -> Option<Grid>;
    pub fn count_solutions(&self, grid: &Grid, limit: usize) -> usize;
    pub fn get_hint(&self, grid: &Grid) -> Option<Hint>;
    pub fn rate_difficulty(&self, grid: &Grid) -> Difficulty;
}

impl Generator {
    pub fn generate(&self, difficulty: Difficulty) -> Grid;
    pub fn generate_variant(&self, difficulty: Difficulty, constraints: Vec<...>) -> Grid;
}
```

### 2. `sudoku-ffi` (UniFFI Bindings)
Exposes core functionality to Swift (iOS) and Kotlin (Android).

**uniffi.toml configuration:**
```toml
[bindings.swift]
module_name = "SudokuEngine"

[bindings.kotlin]
package_name = "com.sudoku.engine"
```

**Exposed Interface:**
- `SudokuGame` - main game state object
- `newClassicGame(difficulty)`
- `newKillerGame(difficulty)`
- `makeMove(row, col, value)` -> `MoveResult`
- `getHint()` -> `Hint?`
- `undo()` / `redo()`
- `getCandidates(row, col)` -> `[Int]`
- `serialize()` / `deserialize()` for save/load

### 3. `sudoku-tui` (Terminal Interface)
Built with crossterm only (no ratatui).

**Features:**
- 9x9 grid rendering with box borders
- Keyboard navigation (hjkl/arrows)
- Number input (1-9), candidates mode (shift+1-9)
- Visual highlighting of related cells
- Timer display
- Hint system
- Undo/redo
- Save/load games
- Color themes

**Screen Layout:**
```
┌───────┬───────┬───────┐
│ 5 3 · │ · 7 · │ · · · │  Time: 05:23
│ 6 · · │ 1 9 5 │ · · · │  Difficulty: Hard
│ · 9 8 │ · · · │ · 6 · │
├───────┼───────┼───────┤  Controls:
│ 8 · · │ · 6 · │ · · 3 │  1-9: Enter number
│ 4 · · │ 8 · 3 │ · · 1 │  0/Del: Clear cell
│ 7 · · │ · 2 · │ · · 6 │  n: New game
├───────┼───────┼───────┤  h: Hint
│ · 6 · │ · · · │ 2 8 · │  u: Undo
│ · · · │ 4 1 9 │ · · 5 │  c: Candidates mode
│ · · · │ · 8 · │ · 7 9 │  q: Quit
└───────┴───────┴───────┘
```

## Implementation Order

### Phase 1: Core Engine Foundation
1. Set up workspace with three crates
2. Implement `Cell`, `Position`, `BitSet` types
3. Implement `Grid` struct with basic operations
4. Implement standard constraints (Row, Column, Box)
5. Add move validation and candidate tracking

### Phase 2: Solver
1. Implement backtracking solver (correctness first)
2. Add human-technique solvers (singles, pairs)
3. Implement solution counting
4. Add difficulty rating

### Phase 3: Generator
1. Implement grid filling algorithm
2. Add cell removal with uniqueness check
3. Implement difficulty targeting
4. Add symmetry options

### Phase 4: TUI
1. Set up crossterm rendering loop
2. Implement grid drawing
3. Add keyboard input handling
4. Implement game state management
5. Add timer, undo/redo, save/load

### Phase 5: Variants
1. Add `DiagonalConstraint` for X-Sudoku
2. Add `KillerCageConstraint` with cage definitions
3. Update generator for variant support
4. Update TUI to render variant elements (cages, diagonals)

### Phase 6: UniFFI Bindings
1. Add uniffi dependency and setup
2. Define UDL interface
3. Create wrapper types for FFI safety
4. Generate and test Swift bindings
5. Generate and test Kotlin bindings

## Key Design Decisions

1. **Generic grid size** - Use `const N: usize` generic for 4x4/9x9/16x16 support
2. **Trait-based constraints** - Allows adding new variants without modifying core
3. **BitSet for candidates** - Efficient storage and operations for pencil marks
4. **Immutable solver input** - Solver takes `&Grid`, returns new `Grid`
5. **Serialization** - Use serde with JSON for save/load, works across all platforms

## Dependencies

```toml
# sudoku-core - minimal
[dependencies]
serde = { version = "1", features = ["derive"] }

# sudoku-tui
[dependencies]
sudoku-core = { path = "../sudoku-core" }
crossterm = "0.27"
serde_json = "1"

# sudoku-ffi
[dependencies]
sudoku-core = { path = "../sudoku-core" }
uniffi = "0.25"
```

## Verification Plan

1. **Unit tests** for each constraint type
2. **Property tests** for solver (every generated puzzle has unique solution)
3. **Integration tests** for full game flow
4. **TUI manual testing** across terminals (iTerm, Terminal.app, Windows Terminal)
5. **Mobile binding tests** - create minimal iOS/Android test apps
