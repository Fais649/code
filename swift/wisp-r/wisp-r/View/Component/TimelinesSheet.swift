import SwiftData
import SwiftUI

struct TimelinesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query(filter: #Predicate<Timeline> { $0.parent == nil }, sort: \Timeline.name)
    var timelines: [Timeline]

    @Binding var selectedTimeline: Timeline?

    @State private var editing: Bool = false
    @State private var sheetTimeline: Timeline?
    var body: some View {
        List {
            Section(header: TimelineSectionHeader(sheetTimeline: $sheetTimeline, editing: $editing))
            {
                ForEach(timelines, id: \.id) { timeline in
                    if timeline.children.isEmpty {
                        Button {
                            if editing {
                                sheetTimeline = timeline
                            } else {
                                selectedTimeline = timeline
                                dismiss()
                            }
                        } label: {
                            Text(timeline.name)
                        }
                        .swipeActions {
                            Button {
                                modelContext.delete(timeline)
                            } label: {
                                Image(systemName: "trash.fill")
                            }
                        }
                    } else {
                        DisclosureGroup {
                            ForEach(timeline.children) { child in
                                Button {
                                    if editing {
                                        sheetTimeline = child.parent
                                    } else {
                                        selectedTimeline = child
                                        dismiss()
                                    }
                                } label: {
                                    Text(child.name)
                                }
                            }
                        } label: {
                            Button {
                                if editing {
                                    sheetTimeline = timeline
                                } else {
                                    selectedTimeline = timeline
                                    dismiss()
                                }
                            } label: {
                                Text(timeline.name)
                            }
                        }
                        .listRowBackground(Default.screenBackground(for: timeline.color))
                        .swipeActions {
                            Button {
                                modelContext.delete(timeline)
                            } label: {
                                Image(systemName: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $sheetTimeline) { timeline in
            TimelineSheet(timeline: timeline, color: timeline.color)
        }
    }
}
