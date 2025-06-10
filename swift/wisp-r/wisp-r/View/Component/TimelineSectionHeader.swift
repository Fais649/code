import SwiftData
import SwiftUI

struct TimelineSectionHeader: View {
    @Environment(\.modelContext) var modelContext
    @Binding var sheetTimeline: Timeline?
    @Binding var editing: Bool

    var body: some View {
        HStack {
            Button {
                editing.toggle()
            } label: {
                Text("Timelines")
                Image(systemName: editing ? "checkmark" : "pencil")
            }
            .buttonStyle(.plain)

            Spacer()

            Icon.timeline
        }
    }
}
