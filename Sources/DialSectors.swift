import Foundation

// Render elapsed and remaining intervals separately. An elapsed overlay on a
// complete multi-turn disk would also erase remaining time at the same bearing.
struct DialInterval {
    let start: Double
    let span: Double
    var end: Double { start + span }
}
struct DialSectors {
    let workUsed: DialInterval
    let workLeft: DialInterval
    let restUsed: DialInterval
    let restLeft: DialInterval

    init(work: Double, rest: Double, phase: Phase, elapsed: Double) {
        let spent = max(0, elapsed / 60)
        let usedWork = phase == .work ? min(work, spent) : (phase == .rest || phase == .waiting ? work : 0)
        let usedRest = phase == .rest ? min(rest, spent) : (phase == .waiting ? rest : 0)
        workUsed = DialInterval(start: 0, span: usedWork)
        workLeft = DialInterval(start: usedWork, span: max(0, work - usedWork))
        restUsed = DialInterval(start: work, span: usedRest)
        restLeft = DialInterval(start: work + usedRest, span: max(0, rest - usedRest))
    }
}
