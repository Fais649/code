import SwiftData
import SwiftUI

struct SearchScreen: View {
    @Binding var path: Path?
    @Binding var sheetMoment: Moment?
    @Binding var searchFilter: String
    @Query var days: [Day]

    var filteredDays: [Day] {
        days.filter {
            $0.moments.filter({ $0.text.isNotEmpty }).isNotEmpty
                && (searchFilter.isEmpty
                    || $0.moments.contains { moment in
                        moment.text.contains(searchFilter)
                    })
        }.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        ForEach(filteredDays) { day in
            Section(
                header:
                    Button {
                        path = .daysScreen(day.date)
                    } label: {
                        DateTitle(style: .hstack, date: day.date)
                    }
            ) {
                MomentStack(
                    searchFilter: searchFilter,
                    sheetMoment: $sheetMoment,
                    moments: day.moments,
                    momentType: .all
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Default.rowBackground())
    }
}

struct SearchCreatedAtScreen: View {
    @Binding var path: Path?
    @Binding var sheetMoment: Moment?
    @Binding var searchFilter: String
    @Query var moments: [Moment]

    var filteredMoments: [Moment] {
        moments.filter {
            searchFilter.isEmpty || $0.text.contains(searchFilter)
        }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        ForEach(filteredMoments) { moment in
            Section(
                header:
                    Button {
                        path = .daysScreen(moment.day?.date ?? moment.createdAt)
                    } label: {
                        DateTitle(style: .hstack, date: moment.day?.date ?? moment.createdAt)
                    },
                footer:
                    HStack {
                        Text(
                            "Created: \(moment.createdAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))) @ \(moment.createdAt.formatted(.dateTime.hour(.defaultDigitsNoAMPM).minute(.defaultDigits)))"
                        )
                        Spacer()
                    }

            ) { MomentRow(sheetMoment: $sheetMoment, moment: moment) }
        }
        .scrollContentBackground(.hidden)
        .background(Default.rowBackground())
    }
}
