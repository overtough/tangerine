# Agent instructions

## Repository scope

- This is a static reverse-engineering workspace for a user-supplied macOS `Tangerine.app`, not the app's source repository.
- The extracted app and attachment inbox are intentionally ignored; never commit `reverse-engineering/Tangerine.app/`, `.opencode/`, generated reports, or secrets copied from the artifact.
- The Linux worker must not launch the macOS app or bundled helpers. Dynamic, signing, UI, network, and conversion checks require an isolated Apple Silicon Mac running macOS 13+.

## Toolchain and checks

- Python is pinned to 3.11.2 in `.python-version`; the verification tooling uses only the standard library.
- The canonical offline check is `make test`; run it after every change. It validates archive safety, bundle identity/Mach-O magic, the macOS collector contract, and report redaction.
- Focused checks are `python3 -m py_compile tools/verify.py` and `bash -n tools/macos_validate.sh`.
- Docker is optional; `Dockerfile` uses `python:3.11.2-slim-bookworm` and runs `make test`. Do not assume Docker is installed.

## macOS handoff

- `tools/macos_validate.sh` is non-launching by default. Use `--launch --seconds N` only when explicitly testing on macOS; it never terminates processes or writes a results file.
- The collector redacts RevenueCat-shaped `appl_...` values. Preserve that behavior and never place a raw client key in reports, logs, or examples.

## REA workflow

- Provider-neutral REA CLI commands are reproducible with `npx -y rea-agents@6.7.0`; they inspect artifacts without executing Tangerine.
- The README contains the exact REA commands for artifact inventory, dyld resolution, and the two selected JavaScript bridge files. The JavaScript pass is not an app-wide runtime proof.
- REA native `inspect_plist` and `inspect_macho` operations require a macOS provider. Do not claim they ran successfully on Linux, and do not apply global REA/OpenCode setup without explicit approval.

## Change discipline

- Keep the report evidence-based: distinguish observed artifact facts, static inferences, and unresolved runtime questions.
- Preserve the pinned runtime, lockfiles, Dockerfile, README, and offline `make test` path so the repository remains rebuildable from a clean Linux machine.
- Commit each verified working step with a concise conventional commit message.
