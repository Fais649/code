import SwiftData
import SwiftUI

struct NavigationListScreen: View {
    @Environment(\.modelContext) var modelContext
    @Binding var path: Path?
    @Query(filter: #Predicate<Timeline> { $0.parent == nil }, sort: \Timeline.name) var timelines:
        [Timeline]
    @Query(filter: MomentStore.pinnedPredicate()) var pinned: [Moment]

    @State private var editing: Bool = false
    @State private var showAllPinned: Bool = false
    @State private var sheetTimeline: Timeline?
    @State private var sheetMoment: Moment?
    @FocusState var focused: Bool
    @State private var searchText: String = ""

    fileprivate func pinnedSection() -> some View {
        Section(
            header:
                HStack {
                    Text("Pinned")

                    Spacer()

                    Button {
                        showAllPinned.toggle()
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showAllPinned ? 90 : 0))
                    }
                    .buttonStyle(.plain)
                }
        ) {
            MomentStack(
                sheetMoment: $sheetMoment,
                moments: pinned.prefix(showAllPinned ? 100 : 3).sorted(by: {
                    $0.position < $1.position
                }),
                childrenPrefix: 4,
                momentType: .pinned
            )
            .listRowBackground(Color.clear)

            if showAllPinned {
                Button {
                    let m = Moment(pinned: true, position: pinned.count)
                    modelContext.insert(m)
                    try? modelContext.save()
                    sheetMoment = m
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
    }

    fileprivate func todaySection() -> some View {
        Section {
            HStack {
                Text("Today")
                Spacer()

                Icon.day
            }
            .listRowBackground(Default.rowBackground())
            .tag(Path.daysScreen())
        }
    }

    fileprivate func momentsSection() -> some View {
        Section(
            header: HStack {
                Text("Moments")
                Spacer()
                Button {
                    path = Path.timelineScreen(timeline: nil, momentType: .all)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
        ) {
            ForEach(MomentType.allCases.filter { $0 != .all && $0 != .pinned }) { moment in
                moment.row
            }
            .listRowBackground(Color.clear)
        }
    }

    fileprivate func timelinesSection() -> some View {
        Section(
            header: TimelineSectionHeader(sheetTimeline: $sheetTimeline, editing: $editing),
        ) {
            ForEach(timelines, id: \.id) { timeline in
                Group {
                    if !editing, timeline.children.isNotEmpty {
                        DisclosureGroup {
                            ForEach(timeline.children) { child in
                                Text(child.name)
                            }
                        } label: {
                            Text(timeline.name)
                        }
                        .tag(Path.timelineScreen(timeline: timeline, momentType: .all))
                    } else if editing {
                        Button {
                            sheetTimeline = timeline
                        } label: {
                            Text(timeline.name)
                        }
                    } else {
                        Text(timeline.name)
                            .tag(Path.timelineScreen(timeline: timeline, momentType: .all))
                    }
                }
                .listRowBackground(Default.rowBackground(for: timeline.color))
                .foregroundStyle(timeline.foregroundColor)
                .tint(timeline.foregroundColor)
            }

            if editing {
                Button {
                    let t = Timeline(name: "", children: [])
                    modelContext.insert(t)
                    try? modelContext.save()
                    sheetTimeline = t
                } label: {
                    Image(systemName: "plus")
                }.listRowBackground(Color.clear)
            }
        }
    }

    fileprivate func settingsSection() -> some View {
        Section {
            HStack {
                Text("Settings")
                Spacer()
                Image(systemName: "gear")
            }
            .tag(Path.settingsScreen)
            .listRowBackground(Color.clear)
        }
    }

    var body: some View {
        List(selection: $path) {
            Group {
                if focused || searchText.isNotEmpty {
                    SearchCreatedAtScreen(
                        path: $path,
                        sheetMoment: $sheetMoment,
                        searchFilter: $searchText
                    )
                } else {
                    pinnedSection()

                    if !showAllPinned {
                        todaySection()
                        momentsSection()
                        timelinesSection()
                        settingsSection()
                    }
                }
            }
            .transition(.opacity)
        }
        .foregroundStyle(Default.foregroundColor)
        .tint(Default.foregroundColor)
        .animation(.smooth, value: focused || searchText.isNotEmpty || editing || showAllPinned)
        .animation(.smooth, value: searchText)
        .sheet(item: $sheetTimeline) { timeline in
            TimelineSheet(timeline: timeline, color: timeline.color)
        }
        .sheet(item: $sheetMoment) { moment in
            MomentSheet(moment: moment)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack {
                    Text("wisp_r")
                    Spacer()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Default.screenBackground())
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Search moments..."
        )
        .searchFocused($focused)
        .toolbarBackground(.ultraThinMaterial)
    }
}
