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
- Use short, plain-language commit messages that describe the actual change; conventional prefixes are not required.
- Keep `.opencode/` and `reverse-engineering/Tangerine.app/` ignored and never commit them.

## Latest Validation State

- On October 20, 2026, the corrected default `tools/macos_validate.sh` run on an Apple Silicon Mac passed bundle existence, Info.plist, arm64 format, code-signature verification, Gatekeeper assessment, signing identity, and embedded-entitlement parsing.
- A subsequent `tools/macos_validate.sh --launch --seconds 20` run repeated the static checks, received a successful macOS `open` request, waited 20 seconds, and observed two exact-name `Tangerine` processes with `pgrep -x`; the collector did not terminate either process.
- These runs establish signing and bounded process-visibility evidence only; UI readiness, conversion, cleanup, network, purchase, and other user workflows remain unvalidated.
- Commit `3a3e5b8` fixed the entitlement pipeline by keeping `codesign` stderr diagnostics separate from the XML sent to `plutil`.
- The next runtime step is direct macOS observation of UI and representative conversion workflows, followed by targeted network and cleanup checks.
- The report and memory update was verified with `make test`, `python3 -m py_compile tools/verify.py`, and `bash -n tools/macos_validate.sh`.
- On October 20, 2026, the commit-message guidance in `.agents/rules/rules.md` was reconciled with `AGENTS.md`: use natural plain-language messages instead of requiring conventional prefixes.
- A native macOS SwiftUI clean-room reconstruction was added under `reconstruction/TangerineReplica/`; it recreates the menu-bar shell, welcome flow, fan UI, settings state, drag/drop state, progress/error states, and safe path-copy action, while explicitly leaving unverified converter backends disconnected.
- Swift/Xcode are unavailable in the Linux worker, so the reconstruction is source-checked by `make test` but must be built and visually compared on macOS.
- On October 20, 2026, the first Mac build exposed that SwiftUI `openSettings` is macOS 14-only while the package targets macOS 13; the menu-bar settings action now uses `SettingsLink`, and `make test` verifies the macOS 13-compatible path remains in place.
- The follow-up Mac build showed `SettingsLink` is also macOS 14-only in the installed SDK. The settings action now guards `SettingsLink` with `if #available(macOS 14.0, *)` and uses the Settings-scene `showSettingsWindow:` action on macOS 13; offline checks pass, but the Mac build still needs to be rerun.
- On October 20, 2026, the user-side Apple Silicon Mac completed `swift build` and `swift run TangerineReplica` after the availability fix. This verifies native compilation there; UI visibility, visual parity, and conversion workflows are still unobserved.
- The user clarified the core runtime gesture: drag a file, then tap Shift, Command, or Control to open one of three menus. The full report and a fresh REA/strings pass identify the three original wheel names as conversion, tools, and actions, plus `DragGestureMonitor` global/local event monitors. The replica is being changed to a transient drag overlay and global/local monitor instead of a permanent drop prompt.
- The original extracted `reverse-engineering/Tangerine.app` bundle is now absent after the uninstall step; `make test` correctly skips the extracted-package metadata check while continuing the archive, collector, reconstruction, and report checks.
- After the first modifier-menu attempt did not present the expected interaction, the menu-bar popover was changed to show `RootView`/the fan directly instead of an intermediate command list, so file drops land on the visible fan surface.
- The user then reported that no Tangerine icon appeared even though `TangerineReplica` processes were alive. The menu-bar implementation was changed from SwiftUI `MenuBarExtra` to an explicit AppKit `NSStatusItem` with an `NSPopover` hosting the fan; this needs native Mac build and icon verification.
- The attached runtime screenshot showed the earlier fan as a ring of large translated rounded-rectangle tiles. The renderer was corrected to shared-center radial wedge petals with real hit regions, paging for the full recovered catalog, and a documented option inspector based on the report's conversion/tool/file-action options.
- Added an `Open Conversion Fan` command to the status-item popover so the radial fan and its option inspector can be tested without starting an external Finder drag; the drag shortcut path remains available for Shift/Command/Control runtime checks.
- The latest user screenshot confirms the intended selection gesture: a Finder file remains held with the green copy badge while it is moved over a fan petal. The replica now adds an AppKit drag destination over the fan, radial hover hit testing, highlighted-action state, and commit-on-release; this is the remaining macOS interaction to verify.
- On October 20, 2026, the user-provided `IMG_2776.MOV` captured the reconstruction running on macOS. The recording visibly shows the conversion wheel over a dragged `test_no_author.pdf`, the JPEG petal highlighted with the center label `JPEG / Image conversion`, then the MP4 petal highlighted with `MP4 / Video conversion`, followed by the fan returning to its drag-ready state. This verifies the visible hover, modifier-wheel, and release/reset interaction; it does not prove that the disconnected converter backend produced an output file.
