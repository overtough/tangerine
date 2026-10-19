#!/usr/bin/env python3
"""Offline integrity checks for the Tangerine reverse-engineering workspace.

This tool never launches the submitted application or any bundled helper.  It
only parses the archive/package metadata and validates the report scaffold.
"""

from __future__ import annotations

import hashlib
import plistlib
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "reports" / "tangerine-reverse-engineering.md"
APP = ROOT / "reverse-engineering" / "Tangerine.app"


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
        "## Security assessment",
        "## Limitations and next steps",
    ]
    for section in required_sections:
        if section not in text:
            fail(f"report is missing section {section!r}")
    if re.search(r"\bappl_[A-Za-z0-9]+\b", text):
        fail("report contains an unredacted RevenueCat API key")
    print(f"report ok: {REPORT.relative_to(ROOT)}")


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
    check_report()
    print("PASS: offline reverse-engineering checks completed without launching the app")
    return 0


if __name__ == "__main__":
    sys.exit(main())
