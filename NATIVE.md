# Build and recording guide

The current MVP is a native macOS 26+ menu-bar app. It uses SwiftUI, AppKit, and
system SQLite, with no third-party runtime packages. Product overview and roadmap:
[English](README.md) · [中文](README.zh.md).

## Build

Use Xcode 26 command-line tools and Python 3 (to generate the bundled chime):

```sh
./scripts/build.sh
open 'dist/Thymer.app'
```

The script builds for the current Mac’s CPU. Local builds are ad-hoc signed, not
Developer ID signed or notarized. No downloadable release has been published.
The build number appears when hovering over the version in Settings.

Quit an older copy before opening a newly built one. Once ready to use a build,
copy `dist/Thymer.app` to Applications. Launch it normally for daily use;
Settings → Quit or Cmd-Q closes it. Reopening it brings back the panel when hidden.

## Using the dial

- The inner, short hand sets Work; the outer mint hand sets Cycle end. One turn
  is 60 minutes. Moving Work preserves Rest; moving Cycle preserves Work until
  Rest reaches zero, then shortens Work.
- Grabbing within a hand's hit area preserves its position; movement is measured
  from the grab point, so pressing beside the line does not change the duration.
- Either phase can be zero. Work=0 and Rest>0 starts Rest directly; both zero
  cannot start. Each phase defaults to a two-hour cap, which can be disabled.
- Pause preserves progress; Play resumes it. **Restart** begins a full new cycle
  immediately from the current Work/Rest settings, keeping all saved records.
- Changing either duration while paused prepares a fresh cycle and shows its
  full starting countdown. Merely grabbing a hand without changing the minutes
  preserves progress. Work can be changed to zero, including after a partial
  session; a rest-only setup displays its full Rest countdown before starting.
- Editing while running preserves elapsed time and cannot shorten the active
  phase below time already spent. Elapsed and remaining color intervals remain
  separate, including across multiple turns.
- Start and every resume show **Back to work** or **Take a break**. Pausing does
  not show a start notice. Sound is independent and can be disabled.
- Work ends → Rest automatically. Rest ends → the next cycle if Auto-start is
  enabled; otherwise the app waits. These notices do not ask for confirmation.

## Tasks and records

- **Continue** keeps the current task group and earlier name snapshots. **New**
  starts a new group without resetting the timer. Both allow the same task name.
- Rest records always say Rest. Renaming during Rest applies to the next Work;
  the ongoing Rest keeps its original group.
- Today counts Work only. The calendar shows Work and Rest separately and merges
  adjacent segments in the same group. Pinch or +/- changes timeline scale.
- Sleep, display sleep, session deactivation, and long process suspension pause
  recording. Resume is manual. Relaunch restores paused; downtime is never added.
- State and record ends are committed together roughly every second. A sudden
  crash can lose the final uncommitted second. A write error pauses recording
  and offers Retry or Quit.

Data is stored in `~/Library/Application Support/Work Rest Timer/records.sqlite`.
The original data directory and bundle identifier are retained so the Thymer rename
continues using existing records.
SQLite uses WAL; quit before copying the whole data directory for a manual backup.
Do not copy only the database file while the app is running. No account, analytics,
or network service is used. User data and screenshots do not belong in Git.

## Appearance and limits

The panel has Light, Dark, and System themes. Navigation uses short slides; the
legacy Animations field still decodes but no longer appears as a setting. The
app does not change macOS accessibility preferences.

The status bar swaps a single timer/cup/pause symbol and reserves compact space
for the countdown. macOS can still hide menu-bar items when system indicators
or other apps use the available space. Reopen the app to retrieve its panel.

The app uses a short in-app notice, not Notification Center history. Export,
record editing, sync, automatic updates, and launch-at-login are not implemented.
Mobile and agent integrations are on the [public roadmap](README.md#looking-ahead).
[Other ideas](docs/ideas.md) remain exploratory.

## Development checks

```sh
./scripts/check.sh
./scripts/check-notice.sh
python3 scripts/check-public-files.py
python3 scripts/check-public-files.py --history
```

Core checks create and remove independent temporary databases. They cover task
identity, pause, zero phases, start/resume notices, transitions, restart, sleep,
limits, midnight, drag recapture, and multi-turn color intervals. Database checks
cover literal SQL-looking text, Unicode, embedded NULs, atomic rollback, and SQLite
integrity. Notice checks
measure the native view without using a records database.

For UI verification, use a new data directory, never everyday records:

```sh
WORK_REST_DATA_DIR="$(mktemp -d /tmp/work-rest-qa.XXXXXX)" \
  'dist/Thymer.app/Contents/MacOS/work-rest-timer' --qa-window
```

The isolated window uses production views. Its Preview menu opens the actual
menu panel (Cmd-P) or phase notice (Cmd-N); these controls are absent from normal
launches. Use the real popover as well as the extra window for visual checks.
Never run two instances against one database.

## Repository layout

- `Sources/`: current native app; `Tests/` and `scripts/`: checks and builds.
- `prototype/`: earlier experiments, not the current app.
- `docs/archive/`: superseded design documents.
- `docs/handoff/`: ignored, private local handoffs; never publish this directory.

[TomatoBar](https://github.com/ivoronin/TomatoBar) informed the small native
menu-bar approach. No third-party app code or audio was copied. The short chime
is synthesized by the repository’s own generator.
