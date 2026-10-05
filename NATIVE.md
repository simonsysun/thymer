# Native app — 0.1.0

A local-first macOS 26 menu-bar app built with SwiftUI, AppKit and the system
SQLite library. No web view, server, account, analytics, package dependencies,
or paid Apple Developer membership is needed to build locally.

## Build and run

Requires Xcode 26 command-line tools (Swift 6.2 or later), macOS 26, and Python 3
for generating the bundled chime. The build targets the current Mac's CPU.

```sh
./scripts/check.sh
./scripts/build.sh
open 'dist/Work Rest Timer.app'
```

The build uses an ad-hoc signature, not Developer ID or notarization. This is a
local source-build release; downloaded binaries will not have the trusted
Gatekeeper distribution experience of a Developer ID/notarized app. Do not
disable system security to install it. Official background:
https://developer.apple.com/developer-id/

The app lives in the menu bar, without a Dock icon. Settings → Quit or Cmd-Q
while its panel is active closes it. Move the built app to Applications if desired.
The existing HTML and earlier native studies remain in `prototype/` for reference.

## Recording rules

- Work hand: inner, shorter. Moving it preserves the Rest duration.
- Cycle hand: outer, mint. Moving it keeps Work fixed until Rest reaches zero;
  moving further back shortens Work. Both durations may be zero, but a cycle
  with both zero cannot run. The default limit is two hours per phase.
- Play/pause does not reset the current phase. Reset keeps saved history and
  duration presets, resets elapsed time, and pauses.
- Active durations cannot be shortened below elapsed time. Edits in a completed
  phase affect the next cycle. Work changes during Rest never rewrite past work.
- Editing the task reveals Continue / New. Continue keeps the record group and
  saves a new name snapshot; New creates a group without resetting the timer.
  Either may be used with the same task name. Calendar merges contiguous
  same-group work segments and joins their distinct names with ` + `.
- Rest records always say Rest. Renaming during Rest affects subsequent Work;
  the ongoing Rest retains its original group.
- Sleep, display sleep, session deactivation, and a long process suspension pause
  recording. Resume is manual. A crash/relaunch restores the last committed timer
  paused; no downtime is inferred. A sudden crash can lose roughly the last
  second since recording checkpoints every second.
- The app shows one brief nonactivating desktop notice at a phase transition.
  Sound is independent. Auto-start off waits at the end of Rest (or Work with
  Rest zero). Waiting remains visible in the menu-bar status even after the
  notice dismisses. This is an in-app notice, not Notification Center history.
- Today's total excludes Rest. The day timeline is read-only; +/- and trackpad
  pinch change scale. The Animations preference follows macOS Reduce Motion until explicitly changed
  for this app. Animated navigation uses short, non-bouncy slides; otherwise it
  uses a brief fade. Zoom anchors under the pointer (pinch) or viewport center
  (buttons); the header folds progressively with scrolling.

## Storage and boundaries

Database: `~/Library/Application Support/Work Rest Timer/records.sqlite`.
SQLite WAL and full synchronous transactions atomically checkpoint state and
record ends. `entries` contains `id`, `group_id`, `task`, `phase`, `start`, `end`.
Times are UTC Unix seconds. Duration is derived from end minus start. Local day
queries clip records across midnight and account for daylight-saving day length.
Settings and timer state are in a JSON row in `state`; schema version is 1.
No data leaves the Mac. To back up manually, quit the app before copying the
whole data directory. Never copy just the database while it is open in WAL mode.

A database write error pauses recording and shows Retry / Quit. Retry reloads
the last committed state; it does not invent uncommitted time.

`Sources/TimerModel.swift` owns phase rules. `TimerStore.swift` owns monotonic
clock accounting, lifecycle and persistence coordination. `Database.swift`
owns SQL transactions. Views do not write records. `DialDrag.swift` preserves
the experimentally verified circular-drag/boundary behavior from the preview.

## Isolated verification

`./scripts/check.sh` creates and removes its own temporary database. It checks
pause, name snapshots/groups, phase boundaries, zero durations, sleep gaps,
relaunch, limits, cross-midnight clipping and drag recapture.

To inspect a separate test instance without touching normal data:

```sh
WORK_REST_DATA_DIR="$(mktemp -d /tmp/work-rest-preview.XXXXXX)" \
  'dist/Work Rest Timer.app/Contents/MacOS/work-rest-timer' --qa-window
```

This explicit mode adds a normal window using the same production views.
Quit that instance when finished. Do not run multiple instances against the
same database. There are no sample records in a normal install.

## Not in this release

Automatic updates, cloud sync, editing records, export UI, launch-at-login,
Notification Center integration and signed/notarized binary distribution.
The optional phase-confirmation idea remains in TODO; it is not implemented.

## Implementation references

TomatoBar (https://github.com/ivoronin/TomatoBar) confirms the small native
menu-bar app/lifecycle approach. Its UI and source are not copied; our dial,
record-group semantics and SQLite ledger are specific to this project.

### Native interaction refinements

Elapsed dial shading remains visible throughout dragging. Dragging changes only
the endpoints; it does not clear the clock or ledger. Minute changes during a
drag stay in memory between one-second checkpoints and are flushed on release,
so mouse events do not each trigger a disk transaction. Calendar geometry uses
one top origin for hours, events and the current-time indicator. The current
time line also updates while the timer is paused.
