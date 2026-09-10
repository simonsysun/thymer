import SwiftUI

struct PhaseNoticeContent: View {
    let message: String
    let isRest: Bool
    var body: some View {
        HStack(spacing:12) {
            Image(systemName:isRest ? "cup.and.saucer" : "timer")
            Text(message).fixedSize()
        }
        .font(.system(size:14,weight:.medium))
        .foregroundStyle(isRest ? Color.mint : Color.primary)
        .padding(.horizontal,18).padding(.vertical,16)
        .background(.regularMaterial,in:RoundedRectangle(cornerRadius:18))
    }
}
