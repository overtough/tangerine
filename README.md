# Tangerine reverse-engineering workspace

This workspace contains a static reverse-engineering report for the attached
macOS `Tangerine.app` package. The application itself is intentionally not
committed: it is a user-provided binary artifact and contains a public client
configuration value plus Apple signing material. The original attachment is
kept under the OmniRush attachment inbox when available, and an extracted
copy may be placed under `reverse-engineering/Tangerine.app` for local checks.

## Scope

The report covers package metadata, Mach-O load commands, embedded signing
entitlements, Swift/Objective-C reflection names, readable strings, bundled
helper runtimes, conversion limits, privacy metadata, persistence keys, and
the inferred user workflows. No binary or helper was launched in the Linux
worker. A macOS dynamic run, UI walkthrough, and network capture are called
out separately as remaining validation work.

## Setup

Requirements:

- Python 3.11.2, pinned in `.python-version`.
- GNU Make.
- Docker is optional.

The analysis scripts use only the Python standard library. There are no
third-party packages to install; `requirements.txt` records that fact.

## Run

Run the offline checks from this directory:

```sh
make test
```

The check validates the attached ZIP when present, rejects unsafe archive
paths, checks the extracted app's basic identity and Mach-O magic, and checks
that the report does not contain the raw RevenueCat API key.

To validate the same checks in a clean Linux container:

```sh
docker build -t tangerine-re-analysis .
docker run --rm tangerine-re-analysis
```

## macOS validation handoff

Run the remaining validation on an isolated Apple Silicon Mac running macOS
13 or newer. The original `Tangerine.app` is not committed, so copy or restore
it first, either at `reverse-engineering/Tangerine.app` or at another path.
From the repository root:

```sh
chmod +x tools/macos_validate.sh
./tools/macos_validate.sh --app /path/to/Tangerine.app
```

The default run is non-launching. It checks that the bundle and main
executable exist, validates `Info.plist`, reports the executable format, and
on macOS runs `codesign --verify`, `spctl --assess`, and signing identity and
entitlement inspection. Entitlements use the non-deprecated
`codesign --entitlements - --xml | plutil` form. If `--app` is omitted, the
collector uses
`reverse-engineering/Tangerine.app` relative to the repository. Expected
command failures are reported and the remaining checks still run; a check that
cannot be confirmed gives the collector a nonzero exit status.

To explicitly request a bounded observation, use `--launch`. The collector
requests the app through macOS `open`, waits ten seconds, and reports whether a
`Tangerine` process is visible. The wait can be set to a value from 1 through
60 seconds:

```sh
./tools/macos_validate.sh --app /path/to/Tangerine.app --launch
./tools/macos_validate.sh --app /path/to/Tangerine.app --launch --seconds 20
```

Launch mode is opt-in. The collector does not terminate or force-close the
application, does not write a results file, and replaces every displayed value
matching `appl_[A-Za-z0-9]+` before printing it. Close the app yourself after
the observation if needed.

The collector proves only the local bundle/signing observations that its
commands report and, in launch mode, that a process was visible during the
bounded observation. It does not prove conversion compatibility or cleanup,
complete UI behavior, network or document-byte handling, StoreKit/RevenueCat
offerings, purchase/restore behavior, or Intel compatibility. Those require
separate hands-on macOS tests and should not be inferred from a successful
collector run.

## Optional REA static pass

The report also records a provider-neutral REA pass. To reproduce those
execution-free observations without changing client configuration, use the
version-pinned CLI fallback from the repository root:

```sh
npx -y rea-agents@6.7.0 inspect-artifact \
  reverse-engineering/Tangerine.app --format json > /tmp/tangerine-rea-artifact.json
npx -y rea-agents@6.7.0 trace-dylib-resolution \
  reverse-engineering/Tangerine.app --format json > /tmp/tangerine-rea-dyld.json
npx -y rea-agents@6.7.0 analyze-javascript-application \
  reverse-engineering/Tangerine.app/Contents/Resources \
  --artifact-format directory \
  --source-path OfficePreview.js --source-path PagesWriter.js \
  --format json > /tmp/tangerine-rea-js.json
```

The artifact inventory, dyld resolver, and selected JavaScript pass do not
execute Tangerine. The JavaScript command intentionally selects only the two
bridge files; it is not a complete application-wide JavaScript inventory. The
native `inspect_plist` and `inspect_macho` REA operations require a macOS
provider and therefore remain unavailable in this Linux worker. REA client
setup was not applied: its dry-run plan would write global OpenCode
configuration and a global skill, which requires explicit approval and a
restart/reconnection.

## Native macOS reconstruction

The clean-room SwiftUI reconstruction lives in
`reconstruction/TangerineReplica/`. It targets macOS 13+, uses a native AppKit
`NSStatusItem` with a SwiftUI popover, and recreates the observed welcome flow,
global drag shortcut monitor, transient conversion fan, settings, operation
progress, and safe path-copy action.
The original converter backends, purchase services, signing identity, and
private client configuration are not copied. Unsupported conversions report
that the backend is not connected instead of producing false output.

Run it on the Apple Silicon Mac, not in this Linux worker:

```sh
cd reconstruction/TangerineReplica
swift run TangerineReplica
```

The current worker has no Swift or Xcode toolchain, so a native `swift build`
check cannot run here. The native build and `swift run TangerineReplica` were
completed on the user's Apple Silicon Mac on October 20, 2026. Visual
comparison and representative conversion workflows remain to be checked
there. The portable `make test` command validates the reconstruction scaffold
and the existing reverse-engineering checks.

## Deliverable

Read `reports/tangerine-reverse-engineering.md`. It records evidence hashes,
the recovered architecture, feature map, data and network flows, security
observations, and the exact limits of this static analysis.
