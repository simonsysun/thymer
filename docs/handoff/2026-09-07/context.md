# Native Mac timer — continuation handoff

This is the restart context requested by Simon on Sep 7, 2026 around 19:00 PDT.
Continue implementing the five issues below. This handoff turn makes no UI edits.

## Latest request — implement next

1. Clicking pause/resume briefly makes the center button translucent and flashes
   the background. Remove that opacity/material flash. Preserve a quiet tactile
   response, stable surface and clear play/pause glyph. Inspect native Button /
   glassEffect identity and implicit changes; reproduce before choosing a fix.
2. Simon asks what Animations does and whether it is useful. It was added by the
   agent to override this Mac's Reduce Motion preference. The agent has explained
   this and recommended removing this extra MVP setting. This recommendation is
   not a separately confirmed user decision; use judgment and explain briefly.
   Do not remove the desired smooth transitions along with the toggle. Do not
   change system accessibility settings. Retain compatibility with saved settings.
3. Native Settings looks cluttered and poorly aligned. Carefully inspect the
   approved HTML Settings in prototype/flat-dial/index.html, ideally render it,
   then improve the native visual layout. Keep labels short and coherent.
4. The center countdown does not identify Work vs Rest. Add a restrained,
   style-consistent green ring around the center circle during Rest, including
   paused Rest. Do not reintroduce the rejected glowing progress-front arc.
5. Tiny icon buttons are difficult to hit. Increase actual hit regions while
   keeping icons visually modest. Settings entrance and right-pointing return
   button MUST occupy the exact same position. Likewise Calendar entrance and
   left-pointing return button. Settings enters/exits right; Calendar enters/exits
   left. Use a common toolbar geometry across the three pages.

Simon explicitly requested a fresh session after saving context. Implement and
verify in the new session; do not stop at another plan or request confirmation.
Latest screenshot references, copied here from volatile screenshot paths:
- animations-toggle.png
- settings-feedback.png (native Settings is the criticized version)
- dial-feedback.png
- calendar-back.png
- settings-back.png

## What is approved

Mac only, open-source, lightweight. Local source builds do not need a paid Apple
Developer account. A real SwiftUI/AppKit menu-bar app is implemented, not a web
wrapper. English (US) UI. No verbose subtitles or explanatory UI clutter.

HTML MVP was approved; native styling still needs fidelity/polish. Current native
app is roughly 1 MB, macOS 26+, ad-hoc signed, not notarized. MIT license added.
No account, server, analytics or third-party packages. System SQLite.

Keep the existing short radial hands and endpoint circles, flat sectors and subtle
center glass. Work is INNER/SHORT; outer mint hand is CYCLE END. One revolution is
60 minutes. Work edits preserve Rest duration, moving both endpoints. Cycle edits
preserve Work until Rest reaches zero, then push Work backward. Both may be zero;
both-zero cannot start. Default cap is TWO HOURS PER PHASE, not cycle. Turning off
cap allows more turns. Float visuals, minute values. At cap pointer must recapture
actual bearing before reverse starts. Small center damping, no large dead zone.

During drag center shows Work and Rest values in their colors, no words. On release
restore play/pause and countdown. Elapsed time/consumed sectors MUST remain visible
while editing; this was fixed in last turn by removing the editing-state guard.
Do not reset time or change recorded seconds when moving hands.

Below dial: Work / Rest / Cycle three aligned columns. Task footer default Reading,
Today total (work only). Editing replaces Today with equally weighted Continue / New.
Continue preserves group and old name snapshots, New starts a group without timer
reset; same name allowed. Rest names not editable, always Rest. Renaming during Rest
affects next Work, current Rest keeps original group. No deletion of old records.

User explicitly LIKES the current Take a break notice's green color, icon and soft
sound. Preserve all three. Phase confirmation is NOT in MVP (see TODO.md); notices
are informational. Work ends -> Rest automatically, Rest ends -> next Work if
Auto-start on; otherwise waits visibly in status bar. Sound independent.

Rejected: extra UI prose; strong metallic/material imagery; bright progress-front
arcs/glowing comet near perimeter. Green center phase ring is newly requested and
is different from that rejected peripheral progress treatment.

## Source inventory / authority

- Sources/TimerModel.swift: Codable state, phase transitions, zero/cap/edit rules.
- Sources/TimerStore.swift: observable main-actor clock, ledger, persistence,
  lifecycle, task snapshots. Timer runs common run-loop modes while dragging.
- Sources/Database.swift: SQLite state+entries committed atomically, WAL/FULL.
- Sources/DialDrag.swift: proven drag damping/limit recapture from material study.
- Sources/TimerDial.swift: Canvas sectors/hands, glass center, hit selection.
- Sources/PanelView.swift: timer/footer/settings, navigation, root 360 x 488 pt.
- Sources/CalendarPage.swift: day timeline, header, event formatting.
- Sources/TimelineScroll.swift: AppKit NSScrollView bridge. Updates document height
  and scroll offset together, mouse-position pinch anchor, center button-zoom anchor.
  Header collapses progressively over 72 pt beyond initial scroll origin.
- Sources/App.swift: accessory menu-bar app, transient popover, nonactivating
  phase notice, sleep/session/display-sleep pause, isolated QA window option.
- Sources/CSQLite/: system module map and sqlite header shim.
- scripts/build.sh / check.sh; Tests/CoreChecks.swift.
- NATIVE.md: actual native behavior/storage/build docs (read).
- prototype/flat-dial/index.html + model.mjs + drag.mjs + linkage.mjs + selection.mjs:
  approved interactive visual/interaction reference. Settings CSS around129+, markup202+.
- prototype/flat-dial/cycle-design.md: latest dial decisions.
- prototype/glass-study/: earlier two-panel native material/drag study.
- prototype/native/: OLD red-ring Chinese prototype, not current UI or rule authority.
- PRODUCT.md, DESIGN.md, REVIEW.md: older design; current code/conversation wins.

## Native data and test setup

Normal database: ~/Library/Application Support/Work Rest Timer/records.sqlite.
NEVER test against normal working data. Current user-facing QA instance uses
/private/tmp/work-rest-native-qa.X8yRhO/records.sqlite, pointer file
/private/tmp/work-rest-native-qa-dir. It now contains Simon's manual TEST records;
preserve them and do not reset or seed over them. App restores paused after restart.

Build artifact: dist/Work Rest Timer.app, executable Contents/MacOS/work-rest-timer.
Bundle ID com.simonsysun.work-rest-timer.
Current running preview exec session was 87153 in old conversation; not transferable.
Use process/UI discovery before restarting. It has a titled window
"Work Rest Timer · Isolated preview" in addition to its menu-bar item.
The user interacts with it while agents work. Keep interference minimal.

Build:
  ./scripts/check.sh
  ./scripts/build.sh
Launch isolated instance, AFTER quitting previous instance cleanly via UI:
  WORK_REST_DATA_DIR="$(cat /private/tmp/work-rest-native-qa-dir)" \
    'dist/Work Rest Timer.app/Contents/MacOS/work-rest-timer' --qa-window
Do not have two instances using this database simultaneously. Can instead COPY the
closed QA data to a fresh temp directory for your own tests; preserve user's version.
Swift macro compiler cannot run inside nested sandbox (sandbox_apply error); use
normal build/check escalation, which has been approved. Build caches are temporary.

Last checks passed: ledger/Continue/New, pause, zero stages, boundaries, rest-group
identity exactly at transition, sleep gaps, restart, cap, midnight, drag recapture,
editing preserves elapsed/ledger and release checkpoints. UI verified: Calendar
initial scroll, +/- anchor, header collapse/restore, Settings visible, focus does
not automatically edit task on opening. Physical pinch feel is mostly user-verified;
no automated pinch coverage. Mouse click transparency bug is NEW and unresolved.

Last performance refinement: dial calls editWork/editCycle(checkpoint:false), keeps
model changes in memory between 1-second clock checkpoints, flushes on release.
No per-pointer-move disk writes. Progress shading no longer hidden during edits.
Hours/events/current line share 20pt origin; current line updates while paused too.

System Reduce Motion was read via NSWorkspace and is TRUE on this Mac. Prior HTML
preview overrides motion with data-transition-preview=true. Native Settings has
optional animations Bool: nil follows system, explicit true enables slides. QA DB
was set true, but user may since have toggled it (latest screenshot appears off).
Do not assume it remains enabled. Plan the UI simplification deliberately, not by
accidentally making transitions disappear again.

## Native UI tooling

Use CUA for UI actions; do not use AppleScript/System Events to automate UI.
First call cua.getApp('com.simonsysun.work-rest-timer') loads docs/state.
App methods: getAXState, getAXStateAndScreenshot, getScreenshot, click(index),
pressKey('super+q'), scroll(index,'down',0.35), drag([x,y],[x,y]). Read AX after actions.
During page transitions diff indexes sometimes went stale; a full getAXState
({disableDiffing:true}) resolved it. Don't repeatedly scan all apps. User prefers
few UI interactions and wants to try the results personally.

HTML preview server last served http://127.0.0.1:8765/ with
python3 -m http.server 8765 --bind 127.0.0.1 --directory prototype/flat-dial.
Verify it is alive before claiming. HTML has sample data, native does not seed data.

## Git and handoff safety

Canonical checkout /Users/siyuansun/Dev/personal/projects/work-rest-timer.
Public repo https://github.com/simonsysun/work-rest-timer.
Only early preview snapshot was committed (8a2eb09..., tag preview-2026-09-07).
Native Sources, Tests, scripts, NATIVE.md, LICENSE, this handoff, later prototype
changes are currently UNCOMMITTED, many UNTRACKED. Preserve all of them. No commit
or push newly authorized. A new worktree must include CURRENT WORKING TREE, not
just main. Verify Sources and this doc exist in new checkout; if the tool omitted
untracked files, read/copy missing files from the canonical checkout rather than
starting over from the old prototype. Do not reset or delete tracked files.

Keep Chinese updates concise. Do not add work the user did not request. Do not
update harness memory (this project handoff is sufficient). No subagent necessary.

## User supplement after the handoff was written

Simon explicitly adds: “我们可以增加更多 macOS 磨砂玻璃的特点，具体需要的话
可以搜索研究。” Include this in the new session prompt. Explore appropriate native
macOS glass/material qualities; consult current Apple official documentation and
references when useful. This is permission to refine material and tactile depth,
not to return to the rejected heavy metallic mockups or opacity flashing. Keep the
UI simple, hierarchy clear and interaction feedback stable. The previous preference
for flatness does not prohibit subtle native material improvements.
