#!/bin/bash
set -e

# Build script for iOS Sudoku app
# This script builds the Rust library for iOS and generates the Xcode project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$SCRIPT_DIR"
SUDOKU_DIR="$IOS_DIR/Sudoku"

# Use rustup's toolchain instead of Homebrew's if both are installed
RUSTC="${HOME}/.cargo/bin/rustc"
CARGO="${HOME}/.cargo/bin/cargo"

# Check if rustup cargo exists, fallback to system
if [ ! -f "$CARGO" ]; then
    CARGO="cargo"
    RUSTC="rustc"
fi

echo "=== Sudoku iOS Build Script ==="
echo "Using cargo: $CARGO"
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed."
        echo "Install with: $2"
        exit 1
    fi
}

check_tool "rustup" "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

# Add iOS targets if not present
echo "1. Adding Rust iOS targets..."
rustup target add aarch64-apple-ios 2>/dev/null || true
rustup target add aarch64-apple-ios-sim 2>/dev/null || true
rustup target add x86_64-apple-ios 2>/dev/null || true

# Build Rust library for iOS
echo ""
echo "2. Building Rust library for iOS..."

cd "$WORKSPACE_DIR"

# Build for iOS device (arm64)
echo "   Building for iOS device (aarch64-apple-ios)..."
RUSTC="$RUSTC" $CARGO build -p sudoku-ffi --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 for Apple Silicon)
echo "   Building for iOS simulator (aarch64-apple-ios-sim)..."
RUSTC="$RUSTC" $CARGO build -p sudoku-ffi --release --target aarch64-apple-ios-sim

# Build for iOS simulator (x86_64 for Intel Macs)
echo "   Building for iOS simulator (x86_64-apple-ios)..."
RUSTC="$RUSTC" $CARGO build -p sudoku-ffi --release --target x86_64-apple-ios

# Build for native (needed for uniffi-bindgen)
echo "   Building for native (for bindgen)..."
RUSTC="$RUSTC" $CARGO build -p sudoku-ffi --release

# Create output directory
FRAMEWORK_DIR="$IOS_DIR/Frameworks"
mkdir -p "$FRAMEWORK_DIR"

# Create fat library for simulator (combining x86_64 and arm64-sim)
echo ""
echo "3. Creating fat library for simulator..."
lipo -create \
    "$WORKSPACE_DIR/target/aarch64-apple-ios-sim/release/libsudoku_ffi.a" \
    "$WORKSPACE_DIR/target/x86_64-apple-ios/release/libsudoku_ffi.a" \
    -output "$FRAMEWORK_DIR/libsudoku_ffi_sim.a"

# Copy device library
cp "$WORKSPACE_DIR/target/aarch64-apple-ios/release/libsudoku_ffi.a" "$FRAMEWORK_DIR/libsudoku_ffi_device.a"

# Generate Swift bindings
echo ""
echo "4. Generating Swift bindings..."
mkdir -p "$SUDOKU_DIR/Sudoku/Generated"
"$WORKSPACE_DIR/target/release/uniffi-bindgen" generate \
    --library "$WORKSPACE_DIR/target/release/libsudoku_ffi.dylib" \
    --language swift \
    --out-dir "$SUDOKU_DIR/Sudoku/Generated"

# Copy header and modulemap to Frameworks
# Modulemap must be named module.modulemap for Swift to discover it via SWIFT_INCLUDE_PATHS
cp "$SUDOKU_DIR/Sudoku/Generated/SudokuEngineFFI.h" "$FRAMEWORK_DIR/"
cp "$SUDOKU_DIR/Sudoku/Generated/SudokuEngineFFI.modulemap" "$FRAMEWORK_DIR/module.modulemap"

echo ""
echo "5. Libraries built at:"
echo "   - Device: $FRAMEWORK_DIR/libsudoku_ffi_device.a"
echo "   - Simulator: $FRAMEWORK_DIR/libsudoku_ffi_sim.a"
echo ""
echo "   Swift bindings: $SUDOKU_DIR/Sudoku/Generated/SudokuEngine.swift"
echo "   FFI header: $FRAMEWORK_DIR/SudokuEngineFFI.h"

# Generate Xcode project (if xcodegen is installed)
echo ""
echo "6. Generating Xcode project..."
if command -v xcodegen &> /dev/null; then
    cd "$SUDOKU_DIR"
    xcodegen generate
    echo "   Xcode project generated successfully!"
else
    echo "   xcodegen not found. Install with: brew install xcodegen"
    echo "   Then run: cd ios/Sudoku && xcodegen generate"
fi

echo ""
echo "=== Build Complete ==="
echo ""
echo "Next steps:"
echo "1. Open ios/Sudoku/Sudoku.xcodeproj in Xcode"
echo "2. Add the static library and header to your project:"
echo "   - Link libsudoku_ffi_device.a (device) or libsudoku_ffi_sim.a (simulator)"
echo "   - Add SudokuEngineFFI.h to your bridging header"
echo "3. Select your development team in project settings"
echo "4. Build and run on simulator or device"
echo ""
