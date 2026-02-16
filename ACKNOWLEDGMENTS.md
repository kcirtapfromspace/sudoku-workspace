# Acknowledgments

This project builds on the work of many open source communities and Sudoku researchers. Credit where credit is due.

## Sudoku Theory & Technique References

The solving engine implements techniques documented by these invaluable community resources:

- **[Hodoku](http://hodoku.sourceforge.net/)** by Bernhard Hobiger — technique definitions, classification, and the fish/chain taxonomy that our solver follows.
- **[Sudoku Explainer](https://github.com/SudokuMonster/SudokuExplainer)** — the community-standard SE difficulty rating scale (1.5–11.0) used in `Technique::se_rating()`.
- **[SudokuWiki](https://www.sudokuwiki.org/)** by Andrew Stuart — detailed technique tutorials and interactive demonstrations that informed many implementations.
- **J.F. Crook** — "A Pencil-and-Paper Algorithm for Solving Sudoku Puzzles" (2009), the formal foundation for candidate elimination.

## Community & Taxonomy

The solving engine's technique taxonomy and terminology conventions draw on decades of
community research:

- **StrmCkr** and the **[Enjoy Sudoku Players Forum](http://forum.enjoysudoku.com/)** —
  canonical definitions of strong link (XOR) vs weak inference (NAND), ALS degree-of-freedom
  framework, fish sector constraint taxonomy (Basic/Franken/Mutant), and wing classification
  (W/M/S/L/H naming via strong-link-type patterns VVV, VLV, LVL, etc.).
- **[Sudopedia](http://sudopedia.enjoysudoku.com/)** — community wiki documenting technique
  definitions and their historical evolution.
- **[r/sudoku](https://www.reddit.com/r/sudoku/)** — ongoing community review and validation
  of technique implementations.

## Rust Dependencies

### Core Engine (`sudoku-core`)
| Crate | License | Description |
|-------|---------|-------------|
| [serde](https://crates.io/crates/serde) | MIT OR Apache-2.0 | Serialization framework |
| [getrandom](https://crates.io/crates/getrandom) | MIT OR Apache-2.0 | Cross-platform random number generation |

### Terminal UI (`sudoku-tui`)
| Crate | License | Description |
|-------|---------|-------------|
| [crossterm](https://crates.io/crates/crossterm) | MIT | Cross-platform terminal manipulation |
| [clap](https://crates.io/crates/clap) | MIT OR Apache-2.0 | Command-line argument parsing |
| [serde](https://crates.io/crates/serde) | MIT OR Apache-2.0 | Serialization framework |
| [serde_json](https://crates.io/crates/serde_json) | MIT OR Apache-2.0 | JSON serialization |
| [dirs](https://crates.io/crates/dirs) | MIT OR Apache-2.0 | Platform directory paths |
| [rand](https://crates.io/crates/rand) | MIT OR Apache-2.0 | Random number generation |

### WebAssembly (`sudoku-wasm`)
| Crate | License | Description |
|-------|---------|-------------|
| [wasm-bindgen](https://crates.io/crates/wasm-bindgen) | MIT OR Apache-2.0 | Rust/WASM interop by the Rust and WebAssembly Working Group |
| [js-sys](https://crates.io/crates/js-sys) | MIT OR Apache-2.0 | JavaScript API bindings |
| [web-sys](https://crates.io/crates/web-sys) | MIT OR Apache-2.0 | Web API bindings |
| [serde](https://crates.io/crates/serde) | MIT OR Apache-2.0 | Serialization framework |
| [serde_json](https://crates.io/crates/serde_json) | MIT OR Apache-2.0 | JSON serialization |
| [serde-wasm-bindgen](https://crates.io/crates/serde-wasm-bindgen) | MIT | Serde adapter for wasm-bindgen |
| [console_error_panic_hook](https://crates.io/crates/console_error_panic_hook) | MIT OR Apache-2.0 | Better panic messages in browser console |
| [getrandom](https://crates.io/crates/getrandom) | MIT OR Apache-2.0 | Cross-platform random number generation |

### iOS FFI (`sudoku-ffi`)
| Crate | License | Description |
|-------|---------|-------------|
| [uniffi](https://crates.io/crates/uniffi) | MPL-2.0 | Cross-language FFI bindings by Mozilla |
| [serde_json](https://crates.io/crates/serde_json) | MIT OR Apache-2.0 | JSON serialization |

## Web Resources

- **[JetBrains Mono](https://www.jetbrains.com/lp/mono/)** — monospace font used in the web UI, served via Google Fonts. Licensed under the [SIL Open Font License 1.1](https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt).

## iOS Build Tooling

- **[fastlane](https://fastlane.tools/)** — iOS build automation. MIT License.

## License

This project is licensed under the [MIT License](LICENSE).
