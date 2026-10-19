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

## Deliverable

Read `reports/tangerine-reverse-engineering.md`. It records evidence hashes,
the recovered architecture, feature map, data and network flows, security
observations, and the exact limits of this static analysis.
