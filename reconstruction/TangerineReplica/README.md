# TangerineReplica

This is a native macOS SwiftUI reconstruction of the observed Tangerine shell.
It is intentionally a clean-room implementation: it does not copy the
original executable, private client configuration, signing material, or
bundled helpers.

## Current slice

- macOS 13+ SwiftUI menu-bar app using an AppKit `NSStatusItem` and SwiftUI popover.
- First-run welcome flow reflecting the recovered onboarding steps.
- Modifier-aware drag menus: holding Shift, Command, or Control while dropping
  a file selects one of three menu states.
- Conversion-fan-style drag/drop panel with recovered categories and actions.
- File selection, action selection, progress/error states, and settings state.
- Safe `Copy Path` action and explicit “backend not connected” states for
  conversion actions; it does not pretend to reproduce unverified conversion
  semantics.

## Run on macOS

From this directory on an Apple Silicon Mac with Xcode command-line tools:

```sh
swift run TangerineReplica
```

The Linux worker in this repository cannot compile or launch SwiftUI/AppKit,
so `swift build` must be run on macOS. The parent repository's `make test`
remains the portable offline verification command.

## Evidence boundary

The layout and labels are based on the static reverse-engineering report and
REA artifact evidence. Exact visual dimensions, animation timing, conversion
compatibility, entitlement gating, purchase behavior, and every native action
remain unverified until compared on macOS.
