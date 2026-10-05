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
        store.pause(); advance(30)
        expect(abs(store.todayWork-30)<0.01,"Pause never counted")
        store.editWork(0); expect(store.model.work == 1 && !store.model.running,"Active lower bound, keeps paused")
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
        let ledgerBeforeEdit = store.todayWork, elapsedBeforeEdit = store.model.elapsed
        store.editWork(65,checkpoint:false)
        expect(store.model.elapsed == elapsedBeforeEdit && store.todayWork == ledgerBeforeEdit,"Dragging never rewinds elapsed or changes ledger")
        store.persist()
        let released = try db.load()!
        expect(released.work == 65,"Drag release checkpoints duration")
        print("PASS: ledger, task groups, pause, zero phases, transitions, restart, sleep, limits, midnight, drag")
    }
}
