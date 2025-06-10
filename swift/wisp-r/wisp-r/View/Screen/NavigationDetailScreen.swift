import SwiftData
import SwiftUI

struct SheetMoment {
    var day: Day?
    var moment: Moment?
}

struct NavigationDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var path: Path?
    @Query var timelines: [Timeline]
    @Query(filter: MomentStore.pinnedPredicate()) var pinned: [Moment]
    @State private var focusedDay: Day?
    @State private var focusedDayDate: Date?
    @State private var broadcaster: BroadcasterService = .init()

    func timelinePredicate(timeline: Timeline?, momentType: MomentType) -> Predicate<Day> {
        if let timeline {
            return DayStore.timelinePredicate(timelineID: timeline.id)
        } else {
            return DayStore.momentPredicate(momentType: momentType)
        }
    }

    func timelineColor(timeline: Timeline?) -> Color {
        timeline?.color ?? Default.color
    }

    @State private var showDatePicker: Bool = false

    var body: some View {
        VStack {
            switch path {
            case let .timelineScreen(timeline, momentType):
                TimelineScreen(
                    path: $path,
                    predicate: timelinePredicate(timeline: timeline, momentType: momentType),
                    timeline: timeline,
                    momentType: momentType,
                    color: timelineColor(timeline: timeline)
                )
            case let .daysScreen(date):
                DaysScreen(initialDate: date)
            case .settingsScreen:
                SettingsScreen()
            default:
                EmptyView()
            }
        }
        .environment(broadcaster)
        .background(Default.screenBackground().containerRelativeFrame([.horizontal, .vertical]))
        .foregroundColor(Default.color)
        .animation(.smooth, value: path)
    }
}
