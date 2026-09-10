import AppKit
import SwiftUI

@main struct NoticeChecks {
    @MainActor static func main() {
        _ = NSApplication.shared
        for message in ["Take a break","Back to work","New cycle","Cycle complete"] {
            let view = NSHostingView(rootView:PhaseNoticeContent(message:message,isRest:message == "Take a break"))
            let size = view.fittingSize
            precondition(size.width > 100 && size.width < 240, "Notice must fit content without old trailing space")
            precondition(size.height >= 45 && size.height < 66, "Notice must retain comfortable vertical padding")
            print("PASS: \(message) \(size.width) × \(size.height)")
        }
    }
}
