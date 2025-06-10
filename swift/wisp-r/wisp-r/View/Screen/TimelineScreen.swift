import SwiftData
import SwiftUI

struct TimelineScreen: View {
    init(
        path: Binding<Path?>,
        predicate: Predicate<Day>,
        timeline: Timeline?,
        momentType: MomentType = .all, color: Color
    ) {
        _path = path
        _days = Query(filter: predicate, sort: \.date)
        self.timeline = timeline
        self.momentType = momentType
        self.color = color
    }

    @Binding var path: Path?
    @Query var days: [Day]
    @ViewBuilder
    let timeline: Timeline?

    @ViewBuilder
    var leadingTitle: some View {
        if let timeline {
            timeline.leadingTitle
        } else {
            momentType.leadingTitle
        }
    }

    @ViewBuilder
    var trailingTitle: some View {
        if let timeline {
            timeline.trailingTitle
        } else {
            momentType.trailingTitle
        }
    }

    let color: Color
    let momentType: MomentType

    @State private var sheetMoment: Moment?

    var body: some View {
        NavigationStack {
            List {
                ForEach(days) { day in
                    Section(
                        header:
                            NavigationLink(value: Path.daysScreen(day.date)) {
                                DateTitle(style: .hstack, date: day.date)
                            }
                    ) {
                        MomentStack(
                            sheetMoment: $sheetMoment,
                            moments: day.moments,
                            momentType: momentType
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    leadingTitle
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    trailingTitle
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    BackButton()
                    Spacer()
                }
            }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case let .daysScreen(date):
                    DaysScreen(initialDate: date)
                default:
                    EmptyView()
                }
            }
        }
        .foregroundStyle(Default.foregroundColor(for: color))
        .background(Default.screenBackground(for: color))
    }
}
