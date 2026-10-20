#!/usr/bin/env python3
"""Offline integrity checks for the Tangerine reverse-engineering workspace.

This tool never launches the submitted application or any bundled helper.  It
only parses the archive/package metadata and validates the report scaffold.
"""

from __future__ import annotations

import hashlib
import plistlib
import re
import stat
import subprocess
import sys
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "reports" / "tangerine-reverse-engineering.md"
APP = ROOT / "reverse-engineering" / "Tangerine.app"
COLLECTOR = ROOT / "tools" / "macos_validate.sh"
REPLICA = ROOT / "reconstruction" / "TangerineReplica"


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_archive(path: Path) -> None:
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            fail(f"archive contains a corrupt member: {archive.testzip()}")
        names = [PurePosixPath(info.filename) for info in archive.infolist()]
        if not names:
            fail("archive is empty")
        for name in names:
            if name.is_absolute() or ".." in name.parts:
                fail(f"archive path escapes its extraction root: {name}")
        top_level = {name.parts[0] for name in names if name.parts}
        if "Tangerine.app" not in top_level:
            fail("archive does not contain Tangerine.app")
    print(f"archive ok: {path.name} sha256={sha256(path)}")


def check_package() -> None:
    if not APP.exists():
        print("package check skipped: extracted Tangerine.app is not present")
        return

    info_path = APP / "Contents" / "Info.plist"
    executable = APP / "Contents" / "MacOS" / "Tangerine"
    if not info_path.is_file() or not executable.is_file():
        fail("extracted app is missing Info.plist or its main executable")

    info = plistlib.loads(info_path.read_bytes())
    expected = {
        "CFBundleIdentifier": "com.th.Tangerine",
        "CFBundleShortVersionString": "2.0.2",
        "CFBundleVersion": "9",
        "LSMinimumSystemVersion": "13.0",
    }
    for key, value in expected.items():
        if info.get(key) != value:
            fail(f"Info.plist {key} is {info.get(key)!r}, expected {value!r}")

    magic = executable.read_bytes()[:4]
    if magic != b"\xcf\xfa\xed\xfe":
        fail("main executable is not a little-endian 64-bit Mach-O")
    print("package metadata ok: com.th.Tangerine 2.0.2 (build 9)")


def check_report() -> None:
    if not REPORT.is_file():
        fail(f"missing report: {REPORT.relative_to(ROOT)}")
    text = REPORT.read_text(encoding="utf-8")
    required_sections = [
        "# Tangerine reverse-engineering report",
        "## Executive summary",
        "## Architecture and components",
        "### REA supplemental static pass",
        "REA's JavaScript application pass",
        "## Security assessment",
        "## Limitations and next steps",
    ]
    for section in required_sections:
        if section not in text:
            fail(f"report is missing section {section!r}")
    if re.search(r"\bappl_[A-Za-z0-9]+\b", text):
        fail("report contains an unredacted RevenueCat API key")
    print(f"report ok: {REPORT.relative_to(ROOT)}")


def check_collector() -> None:
    if not COLLECTOR.is_file():
        fail(f"missing macOS validation collector: {COLLECTOR.relative_to(ROOT)}")
    if not (COLLECTOR.stat().st_mode & stat.S_IXUSR):
        fail("macOS validation collector is not executable")

    text = COLLECTOR.read_text(encoding="utf-8")
    required_fragments = [
        "#!/usr/bin/env bash",
        "LAUNCH_MODE=0",
        "--help",
        "--launch",
        "codesign",
        "spctl",
        "appl_[A-Za-z0-9]+",
        "[REDACTED_REVENUECAT_KEY]",
        "--entitlements - --xml",
        "plutil -convert xml1 -o - -",
        "2> >(redact_stream >&2)",
    ]
    for fragment in required_fragments:
        if fragment not in text:
            fail(f"macOS validation collector is missing {fragment!r}")

    if re.search(r"\b(?:kill|pkill|killall)\b", text):
        fail("macOS validation collector contains a process-termination command")
    if "--entitlements :-" in text:
        fail("macOS validation collector uses deprecated colon entitlement output")
    if re.search(r"codesign[^\n]*--entitlements[^\n]*2>&1", text):
        fail("macOS validation collector mixes codesign diagnostics with entitlement XML")
    if re.search(r"(?m)^\s*set\s+-[^\n]*e", text):
        fail("macOS validation collector enables shell exit-on-error")
    if re.search(r"\b(?:mktemp|tee)\b", text):
        fail("macOS validation collector persists command output")

    help_result = subprocess.run(
        [str(COLLECTOR), "--help"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=5,
        check=False,
    )
    if help_result.returncode != 0:
        fail(f"macOS validation collector --help exited {help_result.returncode}")
    if re.search(r"\bappl_[A-Za-z0-9]+\b", help_result.stdout + help_result.stderr):
        fail("macOS validation collector help exposes a raw RevenueCat API key")
    print(f"collector ok: {COLLECTOR.relative_to(ROOT)}")


def check_replica_scaffold() -> None:
    required_files = [
        REPLICA / "Package.swift",
        REPLICA / "README.md",
        REPLICA / "Sources" / "TangerineReplicaApp" / "Models.swift",
        REPLICA / "Sources" / "TangerineReplicaApp" / "MainView.swift",
        REPLICA / "Sources" / "TangerineReplicaApp" / "SettingsView.swift",
        REPLICA / "Sources" / "TangerineReplicaApp" / "StatusItemController.swift",
        REPLICA / "Sources" / "TangerineReplicaApp" / "TangerineReplicaApp.swift",
    ]
    for path in required_files:
        if not path.is_file():
            fail(f"missing replica scaffold file: {path.relative_to(ROOT)}")

    package = (REPLICA / "Package.swift").read_text(encoding="utf-8")
    source = "\n".join(
        path.read_text(encoding="utf-8")
        for path in required_files
        if path.name != "Package.swift"
    )
    for fragment in [
        ".macOS(.v13)",
        "NSStatusBar.system.statusItem",
        "NSHostingController",
        "ConversionAction",
        "hasCompletedWelcome",
        "conversionFanTheme",
        "Copy Path",
        "Backend not connected",
        "DragModifier",
        "currentEventModifier",
        "activeModifier",
        "Hold Shift, Command, or Control",
        "SettingsLink",
        "if #available(macOS 14.0, *)",
        "showSettingsWindow:",
    ]:
        haystack = package if fragment == ".macOS(.v13)" else source
        if fragment not in haystack:
            fail(f"replica scaffold is missing {fragment!r}")
    if re.search(r"\bappl_[A-Za-z0-9]+\b", source):
        fail("replica scaffold contains an unredacted RevenueCat API key")
    if "openSettings" in source:
        fail("replica scaffold uses the macOS 14-only openSettings environment value")
    print(f"replica scaffold ok: {REPLICA.relative_to(ROOT)}")


def main() -> int:
    archives = sorted(
        path
        for path in (ROOT / ".opencode").rglob("*Tangerine.zip")
        if path.is_file()
    ) if (ROOT / ".opencode").exists() else []
    if archives:
        check_archive(archives[0])
    else:
        print("archive check skipped: no attached Tangerine.zip is present")
    check_package()
    check_collector()
    check_replica_scaffold()
    check_report()
    print("PASS: offline reverse-engineering checks completed without launching the app")
    return 0


if __name__ == "__main__":
    sys.exit(main())
