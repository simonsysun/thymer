# Pre-release check — 2026-09-09

Candidate application source: `a38cfaec30adc2b081bb19585409ca2bb1e085ba`.
Recommended first tag: `v0.1.0-beta.1`, marked as a GitHub pre-release.
Apple notarization is intentionally excluded. No release was published by this check.

## Verified

- Clean committed source builds, with no worktree-only dependencies.
- ZIP creation and extraction preserve the strict-valid ad-hoc signature, icon and chime.
- Core timer, database, notice-layout and privacy/history checks pass.
- Extracted app starts against an empty isolated database at Work 50m / Rest 10m.
- In the actual UI, paused Work edits progress through 60, 45, 30, 15 and 0 minutes; Rest stays 10m and dial colors track the settings.
- Rest-only start, pause, resume and Restart work in the production views, including the real menu popover.
- Relaunch restores paused Rest at 09:59. State and all four synthetic ledger rows compare equal before and after; SQLite integrity passes.
- All checks use disposable data. The everyday installed application and records are not test fixtures.

## Before publishing

- Package the chosen commit as an arm64 ZIP and include its SHA-256 checksum.
- Include English/Chinese notes, installation steps and known limitations; update README download links only when the release exists.
- Browser-downloaded first-open / Gatekeeper handling on a clean user account or another Mac remains unverified. Local ZIP extraction is not equivalent evidence.
- Existing installation preservation was verified during the earlier icon update; this run verifies synthetic-data relaunch, not a separate older-version migration.

Known limits: macOS 26+, Apple Silicon distribution only; no notarization,
automatic updates, export, sync or login launch. macOS may hide menu-bar items
when space is constrained. This test did not reproduce a separate startup-only
pointer displacement. No claim of universal bug absence or a new full security scan.

## Published beta — 2026-09-09

[v0.1.0-beta.1](https://github.com/simonsysun/thymer/releases/tag/v0.1.0-beta.1) was published as a pre-release from
`c69b7ac02a499db682f88c7cadfcd0bf9e8b5d5f`. The clean build was packaged as an
arm64 ZIP; ZIP and checksum assets were downloaded from GitHub and matched their
local originals byte for byte before publication. The executable minimum OS is
26.0. The first-open validation limitation above remains unchanged.
