# Database Compression Decision

**Date:** 2025-12-27
**Status:** Accepted

## Context
The application ships with multiple SQLite databases (one per language) in `assets/database/`. To reduce the distribution size (APK/IPA/AAB), these assets must be compressed.

## Alternatives Evaluated

| Algorithm | Total Size (Approx) | Compression Ratio | Notes |
| :--- | :--- | :--- | :--- |
| **Original** | ~872 MiB | 100% | Raw SQLite files |
| **Snappy** | ~415 MiB | 47.6% | Optimized for speed, poor ratio |
| **GZIP** (`-9`) | ~380 MiB | 43.6% | Standard, widely supported |
| **ZSTD** (`-22` Ultra) | ~224 MiB | 25.7% | Excellent ratio, fast decompression |
| **XZ** (`-9`) | ~217 MiB | 24.9% | Best ratio, slower decompression |

## Decision
**Selected Algorithm: Zstandard (ZSTD)** (Level 22, Ultra)

### Rationale
Although **XZ** provided slightly better compression (saving ~7 MiB total or ~0.8%), **ZSTD** was selected because:
1.  **Decompression Speed**: ZSTD is significantly faster at decompressing data at runtime, which is critical for application startup time or first-access latency when expanding the database.
2.  **Negligible Size Difference**: The 7 MiB difference is a worthy trade-off for the performance gains.
3.  **Modern Standard**: ZSTD is becoming the industry standard for high-performance compression.

## Implementation options
Compressed database artifacts (`*.db.zst`) are published as release assets (for example, on GitHub Releases) and downloaded by the application at runtime. The app must decompress these downloaded files before use. For environments where downloading is not possible or as a fallback, uncompressed SQLite databases are bundled under `assets/database/*.db`, which `openConnection` can load directly if no downloaded database is available.

## Library selection

- **Runtime (App)**:
  - **Non-Linux platforms (Android/iOS, etc.)**: `zstandard` package.
    - Used for decompressing databases on the device.
    - Efficient C bindings, works well on Android/iOS.
  - **Linux**: `es_compression` package (via the `eszstd` binary).
    - Used for decompressing databases on Linux to avoid issues with system shared libraries required by `zstandard`.
- **Tooling (ETL/CLI)**: `es_compression` package.
  - Used in `tool/builder.dart` for compressing databases during generation.
  - **Reason**: The `zstandard` package (and its CLI wrapper) relies on system shared libraries which caused unresolved dependency errors in the Linux dev environment. `es_compression` (and its `eszstd` tool) provides a compatible implementation that works reliably in both the CLI environment for compression tasks and the Linux runtime for decompression.
