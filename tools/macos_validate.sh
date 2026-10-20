#!/usr/bin/env bash
# Safe macOS handoff checks for the Tangerine application bundle.
#
# The default path only inspects the bundle and its signature.  Launching is
# opt-in and observation never terminates a process or writes a report file.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
APP_PATH="$ROOT/reverse-engineering/Tangerine.app"
LAUNCH_MODE=0
OBSERVE_SECONDS=10
CHECK_FAILURES=0


redact_stream() {
    LC_ALL=C sed -E 's/appl_[A-Za-z0-9]+/[REDACTED_REVENUECAT_KEY]/g'
}


say() {
    printf '%s\n' "$*" | redact_stream
}


usage() {
    cat <<'EOF' | redact_stream
Usage: tools/macos_validate.sh [OPTIONS]

Run non-launching bundle and signing checks by default.  All displayed
RevenueCat client-key-shaped values are replaced before they are printed.

Options:
  --app PATH       application bundle to inspect (default: repository copy)
  --launch         explicitly request a launch, then observe for 10 seconds
  --seconds N      observation wait in seconds (1-60; used with --launch)
  --help           show this help text

The collector never terminates a process and does not write a results file.
EOF
}


usage_error() {
    say "[error] $1"
    usage
    exit 2
}


run_check() {
    local label="$1"
    shift
    local output
    local status

    say "[check] $label"
    if output=$("$@" 2>&1); then
        status=0
    else
        status=$?
    fi

    if [ -n "$output" ]; then
        printf '%s\n' "$output" | redact_stream
    fi

    if [ "$status" -eq 0 ]; then
        say "[ok] $label"
    else
        say "[not confirmed] $label (exit $status)"
        CHECK_FAILURES=$((CHECK_FAILURES + 1))
    fi
    return 0
}


run_optional_check() {
    local label="$1"
    shift
    local command_name="$1"
    shift

    if command -v "$command_name" >/dev/null 2>&1; then
        run_check "$label" "$command_name" "$@"
    else
        say "[skip] $label (command unavailable: $command_name)"
    fi
}


run_entitlements_check() {
    local output
    local status

    say "[check] embedded entitlements"
    if output=$(codesign --display --entitlements - --xml "$APP_PATH" 2>&1); then
        if output=$(printf '%s\n' "$output" | plutil -convert xml1 -o - - 2>&1); then
            status=0
        else
            status=$?
        fi
    else
        status=$?
    fi

    if [ -n "$output" ]; then
        printf '%s\n' "$output" | redact_stream
    fi

    if [ "$status" -eq 0 ]; then
        say "[ok] embedded entitlements"
    else
        say "[not confirmed] embedded entitlements (exit $status)"
        CHECK_FAILURES=$((CHECK_FAILURES + 1))
    fi
    return 0
}


static_checks() {
    local info_plist
    local executable

    say "[mode] static and signing checks only"
    run_check "application bundle exists" test -d "$APP_PATH"
    if [ ! -d "$APP_PATH" ]; then
        say "[note] no bundle was found; provide --app PATH or restore the repository copy"
        return 0
    fi

    info_plist="$APP_PATH/Contents/Info.plist"
    executable="$APP_PATH/Contents/MacOS/Tangerine"
    run_check "Info.plist exists" test -f "$info_plist"
    run_check "main executable exists" test -f "$executable"

    if [ -f "$info_plist" ]; then
        run_optional_check "Info.plist syntax" plutil -lint "$info_plist"
        run_optional_check "bundle identifier" plutil -extract CFBundleIdentifier raw -o - "$info_plist"
    fi
    if [ -f "$executable" ]; then
        run_optional_check "main executable format" file "$executable"
    fi

    if [ "$(uname -s 2>/dev/null || printf 'unknown')" = "Darwin" ]; then
        run_optional_check "codesign verification" codesign --verify --deep --strict --verbose=2 "$APP_PATH"
        run_optional_check "Gatekeeper assessment" spctl --assess --type execute --verbose=4 "$APP_PATH"
        run_optional_check "code-signing identity" codesign --display --verbose=4 "$APP_PATH"
        if command -v codesign >/dev/null 2>&1 && command -v plutil >/dev/null 2>&1; then
            run_entitlements_check
        else
            say "[skip] embedded entitlements (codesign and plutil are required)"
        fi
    else
        say "[skip] macOS signing checks require Darwin"
    fi
}


launch_observation() {
    local pids
    local status

    if [ "$(uname -s 2>/dev/null || printf 'unknown')" != "Darwin" ]; then
        say "[skip] --launch requires macOS"
        return 0
    fi
    if [ ! -d "$APP_PATH" ]; then
        say "[skip] launch observation requires an existing application bundle"
        return 0
    fi
    if ! command -v open >/dev/null 2>&1; then
        say "[skip] launch observation requires the macOS open command"
        return 0
    fi

    say "[launch] requesting the application; process ownership remains with the user"
    run_check "application launch request" open "$APP_PATH"
    say "[observe] waiting ${OBSERVE_SECONDS} seconds; the collector will not terminate the process"
    if sleep "$OBSERVE_SECONDS"; then
        say "[observe] bounded wait completed"
    else
        status=$?
        say "[not confirmed] bounded wait interrupted (exit $status)"
        CHECK_FAILURES=$((CHECK_FAILURES + 1))
    fi

    if command -v pgrep >/dev/null 2>&1; then
        say "[check] Tangerine process observation"
        if pids=$(pgrep -x Tangerine 2>&1); then
            say "[observed] Tangerine process id(s): $pids"
        else
            status=$?
            printf '%s\n' "$pids" | redact_stream
            say "[not observed] no Tangerine process was reported (exit $status)"
            CHECK_FAILURES=$((CHECK_FAILURES + 1))
        fi
    else
        say "[skip] process observation (command unavailable: pgrep)"
    fi
}


while [ "$#" -gt 0 ]; do
    case "$1" in
        --app)
            [ "$#" -ge 2 ] || usage_error "--app requires a bundle path"
            APP_PATH="$2"
            shift 2
            ;;
        --launch)
            LAUNCH_MODE=1
            shift
            ;;
        --seconds)
            [ "$#" -ge 2 ] || usage_error "--seconds requires an integer from 1 to 60"
            case "$2" in
                ''|*[!0-9]*) usage_error "--seconds requires an integer from 1 to 60" ;;
            esac
            [ "$2" -ge 1 ] && [ "$2" -le 60 ] || usage_error "--seconds requires an integer from 1 to 60"
            OBSERVE_SECONDS="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage_error "unknown option: $1"
            ;;
    esac
done


say "Tangerine macOS validation collector"
say "[app] $APP_PATH"
if [ "$LAUNCH_MODE" -eq 1 ]; then
    say "[mode] explicit launch plus bounded observation (${OBSERVE_SECONDS}s)"
else
    say "[mode] default non-launching run"
fi

static_checks
if [ "$LAUNCH_MODE" -eq 1 ]; then
    launch_observation
else
    say "[skip] launch observation (use --launch explicitly)"
fi

if [ "$CHECK_FAILURES" -eq 0 ]; then
    say "PASS: requested validation checks completed"
    exit 0
fi

say "DONE: $CHECK_FAILURES check(s) were not confirmed; remaining checks completed"
exit 1
