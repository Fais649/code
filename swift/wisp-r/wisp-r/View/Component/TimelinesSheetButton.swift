import SwiftUI

struct TimelinesSheetButton: View {
    @State private var showTimelines: Bool = false
    @State var selectedTimeline: Timeline?

    var onSelectTimeline: (Timeline?) -> Void

    var body: some View {
        Button {
            showTimelines.toggle()
        } label: {
            Image(systemName: "circle.and.line.horizontal")
            if let selectedTimeline {
                if let p = selectedTimeline.parent {
                    Text("/ \(p.name) / \(selectedTimeline.name)")
                } else {
                    Text("/ \(selectedTimeline.name) /*")
                }
            }
        }
        .sheet(isPresented: $showTimelines) {
            TimelinesSheet(selectedTimeline: $selectedTimeline)
        }
        .onChange(of: selectedTimeline) {
            onSelectTimeline(selectedTimeline)
        }
    }
}
