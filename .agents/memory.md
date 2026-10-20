# Workspace Memory

Persistent state, established patterns, verified facts, and project notes for the Tangerine workspace.

## Project Overview

- **Repository**: Tangerine reverse-engineering workspace (`overtough/tangerine`).
- **Target Application**: macOS `Tangerine.app` (Bundle ID: `com.th.Tangerine`, Version: `2.0.2`, Build: `9`, Target OS: macOS 13.0+).
- **Core Objective**: Maintain evidence-based static analysis, offline verification tooling, and macOS handoff validation procedures without running unconfined binaries in development workers.

## Environment & Tooling State

- **Python Version**: 3.11.2 (pinned in `.python-version`).
- **Dependencies**: Python standard library only (no third-party packages in `requirements.txt`).
- **Primary Test Runner**: `make test` executes `python3 tools/verify.py`.
- **Collector Tool**: `tools/macos_validate.sh` (POSIX bash script for macOS verification and safe redaction).
- **REA Tooling**: `npx -y rea-agents@6.7.0` used for non-executing artifact inspection.

## Key Verified Artifact Facts

- **Bundle Format**: Mach-O 64-bit Little-Endian executable.
- **Redaction Rules**: Any RevenueCat API key matching `appl_[A-Za-z0-9]+` must be redacted as `[REDACTED_REVENUECAT_KEY]`.
- **Primary Report**: [reports/tangerine-reverse-engineering.md](file:///Users/anuragkrishnavennela/Projects/Tangerine/reports/tangerine-reverse-engineering.md).

## Operational Conventions

- Always run `make test` before completing tasks or committing changes.
- Use conventional commits format (e.g., `feat:`, `fix:`, `docs:`, `chore:`).
- Keep `.opencode/` and `reverse-engineering/Tangerine.app/` ignored and never commit them.

## Latest Validation State

- On October 20, 2026, the corrected default `tools/macos_validate.sh` run on an Apple Silicon Mac passed bundle existence, Info.plist, arm64 format, code-signature verification, Gatekeeper assessment, signing identity, and embedded-entitlement parsing.
- The successful run was non-launching; no process startup, conversion, cleanup, network, purchase, or UI behavior was observed.
- Commit `3a3e5b8` fixed the entitlement pipeline by keeping `codesign` stderr diagnostics separate from the XML sent to `plutil`.
- The next runtime step is an explicit macOS launch observation using `tools/macos_validate.sh --launch --seconds N`.
- The report and memory update was verified with `make test`, `python3 -m py_compile tools/verify.py`, and `bash -n tools/macos_validate.sh`.
