# Default: fast local check (compile + clippy on core only)
default: check

# --- Fast local targets (use during development) ---

# Quick compile check — no codegen, no tests
check:
    cargo check -p sudoku-core

# Check all native crates (excludes wasm)
check-all:
    cargo check --workspace --exclude sudoku-wasm

# Run only sudoku-core tests (68 of 72 tests live here)
test-core:
    cargo test -p sudoku-core

# Run a single test by name fragment
test name:
    cargo test -p sudoku-core -- {{name}}

# Run TUI tests only
test-tui:
    cargo test -p sudoku-tui

# Clippy on core only
lint:
    cargo clippy -p sudoku-core -- -D warnings

# Format check
fmt:
    cargo fmt --all -- --check

# Format fix
fmt-fix:
    cargo fmt --all

# --- Crate-specific builds ---

# Build the TUI binary (debug)
build-tui:
    cargo build -p sudoku-tui

# Build the TUI binary (release)
build-tui-release:
    cargo build -p sudoku-tui --release

# Build WASM (requires wasm32-unknown-unknown target)
build-wasm:
    cd crates/sudoku-wasm && wasm-pack build --target web --release

# Build FFI (UniFFI for iOS)
build-ffi:
    cargo build -p sudoku-ffi

# --- Full CI-equivalent targets ---

# Full workspace test (mirrors CI rust job, excludes wasm)
test-all:
    cargo test --workspace --exclude sudoku-wasm --all-features

# Full CI pipeline: fmt + clippy + test + wasm build
ci: fmt lint-all test-all build-wasm
    @echo "CI passed."

# Clippy on full workspace
lint-all:
    cargo clippy --workspace --exclude sudoku-wasm --all-features -- -D warnings

# --- Soundness (slow, for pre-push verification) ---

# Run only the hint soundness tests
test-soundness:
    cargo test -p sudoku-core -- soundness

# --- Convenience ---

# Run the TUI
run *args:
    cargo run -p sudoku-tui -- {{args}}

# Clean build artifacts
clean:
    cargo clean
