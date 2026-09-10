import Foundation

func expect(_ value: @autoclosure () -> Bool, _ message:String) {
    guard value() else { fatalError(message) }
}
@main struct CoreChecks {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("work-rest-check-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at:directory) }
        let url = directory.appendingPathComponent("records.sqlite")
        let db = try Database(url:url)
        var instant = Date(timeIntervalSince1970:1788800400), monotonic = 100.0
        let store = try TimerStore(database:db,now:{instant},uptime:{monotonic})
        func advance(_ seconds:Double) {
            var left = seconds
            while left > 0 { let n = min(1,left); instant += n; monotonic += n; store.tick(); left -= n }
        }
        store.editWork(1); store.editCycle(2); store.toggle(); advance(20)
        expect(store.model.running,"Started")
        expect(abs(store.todayWork-20)<0.01,"20 work seconds persisted")
        let group = store.model.group
        store.rename("Book B",new:false); advance(10)
        expect(store.entries.count == 2 && store.model.group == group,"Continue snapshots name, retains group")
        expect(store.entries[0].task == "Reading" && store.entries[1].task == "Book B","Old name remains")
        store.editWork(0); expect(store.model.work == 1 && store.model.running,"Running edit protects elapsed time")
        store.pause(); advance(30)
        expect(abs(store.todayWork-30)<0.01,"Pause never counted")
        store.toggle(); advance(30)
        expect(store.model.phase == .rest && store.todayWork == 60,"Exact boundary")
        store.rename("Book C",new:true); advance(20)
        expect(store.model.group != group,"New creates group")
        expect(store.entries.last?.task == "Rest" && store.entries.last?.group == group,"Rest identity remains unchanged")
        store.settings { $0.autoStart = false }; advance(40)
        expect(!store.model.running && store.model.phase == .waiting,"Wait at rest end")
        expect(store.todayWork == 60 && store.todayRest == 60,"Separate totals")
        store.reset(); store.editWork(0); store.editCycle(1); store.toggle(); advance(10)
        expect(store.model.phase == .rest,"Work zero skips directly to rest")
        store.pause(); store.reset(); store.editCycle(0); store.toggle()
        expect(!store.model.running,"Both zero cannot start")
        store.editWork(1); store.editCycle(1); store.toggle(); advance(60)
        expect(store.model.phase == .waiting,"Zero rest ends safely")
        store.reset(); store.editWork(50); store.toggle(); advance(5)
        let total = store.todayWork
        instant += 3600; monotonic += 3600; store.tick()
        expect(!store.model.running && store.todayWork == total,"Sleep gap never counted")
        store.toggle(); advance(2)
        let savedTotal = store.todayWork
        let restored = try TimerStore(database:Database(url:url),now:{instant},uptime:{monotonic})
        expect(!restored.model.running && restored.todayWork == savedTotal,"Relaunch restores state paused")
        expect(restored.model.elapsed == store.model.elapsed,"Elapsed restored")
        var model = TimerModel(); model.settings.limit = false; model.setWork(240)
        expect(model.work == 240,"Multiple revolutions")
        model.settings.limit = true; model.applyLimit(); expect(model.work == 120,"Cap presets")
        model.work = 50; model.rest = 10; model.setWork(55); expect(model.rest == 10,"Work keeps rest")
        model.setCycle(40); expect(model.work == 40 && model.rest == 0,"Cycle pushes work")
        let midnight = Calendar.current.startOfDay(for:instant)
        let cross = TimeEntry(group:"cross",task:"Night",phase:.work,start:midnight.addingTimeInterval(-30),end:midnight.addingTimeInterval(30))
        try db.save(store.model,entries:[cross])
        let clipped = try db.entries(from:midnight,to:midnight.addingTimeInterval(86400)).first{$0.group == "cross"}!
        expect(clipped.duration == 30,"Midnight clip")
        var motion = DialDrag(value:120)
        _ = motion.move(angle:30,radius:134,lower:0,upper:120)
        expect(motion.move(angle:20,radius:134,lower:0,upper:120)==120,"Cap requires recapture")
        _ = motion.move(angle:0,radius:134,lower:0,upper:120)
        expect(motion.move(angle:-6,radius:134,lower:0,upper:120)==119,"Recaptured reverse")
        var grabbed = DialDrag(value:44,grabAngle:260)
        expect(grabbed.move(angle:260,radius:105,lower:0,upper:120)==44,"Grabbing beside a hand must preserve its initial position")
        expect(grabbed.move(angle:266,radius:105,lower:0,upper:120)==45,"Drag follows motion from the original grab point")
        let ledgerBeforeEdit = store.todayWork, elapsedBeforeEdit = store.model.elapsed
        store.editWork(65,checkpoint:false)
        expect(store.model.elapsed == elapsedBeforeEdit && store.todayWork == ledgerBeforeEdit,"Dragging never rewinds elapsed or changes ledger")
        store.persist()
        let released = try db.load()!
        expect(released.work == 65,"Drag release checkpoints duration")
        store.pause(); store.reset(); store.editWork(0); store.editCycle(10)
        let priorWork = store.todayWork
        store.toggle(); advance(5)
        expect(store.model.phase == .rest && store.model.work == 0,"Zero work starts Rest directly")
        expect(store.todayWork == priorWork && store.entries.last?.phase == .rest,"Rest-only timer never records Work")
        store.pause()
        var activationNotices: [String] = []
        store.onTransition = { activationNotices.append($0) }
        store.toggle()
        expect(activationNotices == ["Take a break"],"Rest resume announces its phase")
        store.toggle()
        expect(activationNotices.count == 1,"Pausing does not announce a start")
        store.toggle()
        expect(activationNotices == ["Take a break","Take a break"],"Every Rest resume has feedback")
        store.pause(); store.reset(); store.editWork(1); store.toggle()
        expect(activationNotices.last == "Back to work","Initial Work start has feedback")
        store.toggle(); store.toggle()
        expect(activationNotices.count == 4 && activationNotices.last == "Back to work","Work resume has one notice")
        store.pause(); store.reset(); store.editWork(0); store.editCycle(1); store.toggle()
        expect(activationNotices.count == 5 && activationNotices.last == "Take a break","Initial Rest-only start has feedback")
        store.pause(); store.reset(); store.editCycle(0); store.toggle()
        expect(activationNotices.count == 5,"Both-zero non-start has no notice")
        store.onTransition = nil
        var statusModel = TimerModel()
        for phase in [Phase.ready,.work,.rest,.waiting] {
            statusModel.phase = phase; statusModel.running = false
            expect(statusModel.statusSymbol == "pause.fill","Idle and paused states use one pause symbol")
        }
        statusModel.running = true; statusModel.phase = .work
        expect(statusModel.statusSymbol == "timer","Running Work uses timer symbol")
        statusModel.phase = .rest
        expect(statusModel.statusSymbol == "cup.and.saucer","Running Rest uses notice cup symbol")
        // Screenshot regression: 93m work, 40m56s elapsed. Remaining time wraps
        // through noon and must still reach the 33-minute hand bearing.
        let screenshot = DialSectors(work:93,rest:19,phase:.work,elapsed:2456)
        expect(abs(screenshot.workLeft.span * 60 - 3124) < 0.001,"Screenshot remaining is 52:04")
        expect(screenshot.workLeft.end == 93,"Remaining work ends at work hand across noon")
        for phase in [Phase.ready,.work,.rest,.waiting] {
            for work in [50.0,60,60.25,93,120,240] {
                for rest in [0.0,19,65,120] {
                    let sectors = DialSectors(work:work,rest:rest,phase:phase,elapsed:2456)
                    expect(abs(sectors.workUsed.span + sectors.workLeft.span - work) < 0.0001,"Work intervals conserve duration")
                    expect(abs(sectors.restUsed.span + sectors.restLeft.span - rest) < 0.0001,"Rest intervals conserve duration")
                    expect(abs(sectors.workLeft.end - work) < 0.0001,"Work color follows hand at every turn")
                    expect(abs(sectors.restLeft.end - work - rest) < 0.0001,"Rest color follows cycle hand at every turn")
                }
            }
        }
        // Editing a paused setup begins a fresh cycle; resume alone keeps progress.
        let setupDB = try Database(url:directory.appendingPathComponent("setup.sqlite"))
        var setup = TimerModel()
        setup.work = 44; setup.rest = 0; setup.phase = .work; setup.elapsed = 2608
        let oldEntry = TimeEntry(group:"kept",task:"Earlier task",phase:.work,start:instant.addingTimeInterval(-60),end:instant.addingTimeInterval(-30))
        try setupDB.save(setup,entries:[oldEntry])
        let editor = try TimerStore(database:setupDB,now:{instant},uptime:{monotonic})
        editor.editCycle(44)
        expect(editor.model.elapsed == 2608,"Click without duration change preserves progress")
        editor.editCycle(51)
        expect(editor.model.phase == .ready && editor.model.remaining == 2640 && editor.model.rest == 7,"Paused rest edit prepares full 44-minute Work, not stale 32 seconds")
        for phase in [Phase.work,.rest] {
            editor.model.phase = phase; editor.model.elapsed = 30; editor.model.running = false
            editor.editWork(0)
            expect(editor.model.elapsed == 0 && editor.model.phase == .ready && editor.model.work == 0,"Paused edit can move Work to zero from either phase")
            expect(editor.model.remaining == editor.model.rest * 60,"Rest-only ready view shows full rest time")
            editor.model.work = 44
        }
        var restartMessages: [String] = []
        editor.onTransition = { restartMessages.append($0) }
        for phase in [Phase.ready,.work,.rest,.waiting] {
            for running in [false,true] {
                editor.model.work = 44; editor.model.rest = 7
                editor.model.phase = phase; editor.model.elapsed = 30; editor.model.running = running
                editor.restart()
                expect(editor.model.running && editor.model.phase == .work && editor.model.remaining == 2640,"Restart begins a full cycle from any state")
                expect(restartMessages.last == "Back to work","Restart announces the phase")
            }
        }
        editor.model.work = 0; editor.restart()
        expect(editor.model.phase == .rest && editor.model.remaining == 420 && restartMessages.last == "Take a break","Rest-only restart begins full Rest")
        editor.pause(); editor.model.elapsed = 30; editor.toggle()
        expect(editor.model.elapsed == 30,"Resume without editing retains progress")
        let setupEntries = try setupDB.entries(from:instant.addingTimeInterval(-86400),to:instant.addingTimeInterval(86400))
        expect(setupEntries.count == 1 && setupEntries[0].id == oldEntry.id && setupEntries[0].duration == 30,"Restart and setup edits preserve existing history without invented time")
        var restEdit = TimerModel()
        restEdit.work = 50; restEdit.rest = 10; restEdit.phase = .rest
        restEdit.running = true; restEdit.elapsed = 300; restEdit.activeRest = 10
        restEdit.setCycle(53)
        let restSectors = DialSectors(work:restEdit.work,rest:restEdit.rest,phase:restEdit.phase,elapsed:restEdit.elapsed)
        expect(restEdit.remaining == restSectors.restLeft.span * 60,"Running cycle edit keeps countdown equal to painted Rest duration even when it pushes Work")
        // Older builds could persist a stale Rest snapshot. The configured duration
        // is the single source for both the dial and countdown after reopening.
        restEdit.activeRest = 10
        try setupDB.save(restEdit,entries:[])
        let restoredRest = try TimerStore(database:setupDB,now:{instant},uptime:{monotonic})
        expect(restoredRest.model.remaining == 60 && restoredRest.model.elapsed == 300,"Restore uses edited Rest duration without discarding progress")
        var repeatedRest = TimerModel()
        repeatedRest.work = 0; repeatedRest.rest = 1; repeatedRest.toggle()
        expect(repeatedRest.finish() == "Take a break","Each rest-only cycle announces Take a break")
        print("PASS: ledger, task groups, pause, zero phases, transitions, restart, sleep, limits, midnight, drag, multi-turn color intervals")
    }
}
