# Tangerine Workspace Agent Rules

These rules apply to all AI agents operating within the Tangerine reverse-engineering workspace.

## 1. Repository Scope & Confidentiality

- **Artifact Safety**: This repository is dedicated to static reverse engineering of macOS `Tangerine.app`.
- **Ignore Sensitive Binaries & Inbox**: Never commit extracted binaries (`reverse-engineering/Tangerine.app/`), `.opencode/`, temporary test artifacts, or raw secrets.
- **Credential Redaction**: Always redact RevenueCat API keys matching `appl_[A-Za-z0-9]+` (replace with `[REDACTED_REVENUECAT_KEY]`). Never output raw client keys in commits, reports, logs, or command examples.

## 2. Execution & Safety Boundaries

- **Static vs Dynamic**: In Linux and automated CI environments, never attempt to launch the macOS application or bundled helpers.
- **macOS Validation**: `tools/macos_validate.sh` is non-launching by default. Launch mode (`--launch`) must only be invoked when explicitly testing on an isolated macOS 13+ Apple Silicon machine. The script must never kill processes or persist sensitive output.
- **REA Workflow**: REA operations must use provider-neutral commands (`npx -y rea-agents@6.7.0`). Native `inspect_plist` and `inspect_macho` operations require a macOS provider and must not be claimed to have run on Linux.

## 3. Verification & Quality Gates

- **Mandatory Test**: The canonical offline check is `make test`. Run `make test` after every change to verify archive safety, package metadata, collector syntax/contracts, and report redactions.
- **Syntax Validation**: Ensure `python3 -m py_compile tools/verify.py` and `bash -n tools/macos_validate.sh` pass cleanly before committing changes.
- **Zero External Dependencies**: The repository tooling relies strictly on Python standard library (Python 3.11.2 pinned via `.python-version`). Do not add external dependencies without explicit approval.

## 4. Change Discipline & Documentation

- **Evidence-Based Reporting**: Clearly distinguish between directly observed artifact facts, static inferences, and unresolved runtime questions.
- **Conventional Commits**: Commit each verified working step with a concise conventional commit message (e.g., `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`).
- **Memory Continuity**: Consult and update `.agents/memory.md` when persistent context, project status, or major decisions change.
