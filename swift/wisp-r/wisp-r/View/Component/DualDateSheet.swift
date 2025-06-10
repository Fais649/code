import SwiftData
import SwiftUI

struct DualDateSheet: View {
    @Binding var start: Date
    @Binding var end: Date

    @State private var tab: Int = 0
    @State private var showEnd: Bool = false
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            VStack(alignment: .center) {
                DatePicker("", selection: $start)
                    .datePickerStyle(SimpleGraphicalDatePicker())
                DatePicker("", selection: $start, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.wheel)
            }
            .tag(0)

            VStack(alignment: .center) {
                DatePicker("", selection: $end)
                    .datePickerStyle(SimpleGraphicalDatePicker())
                DatePicker("", selection: $end, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.wheel)
            }
            .tag(1)
        }.tabViewStyle(.page(indexDisplayMode: .never))

        HStack(spacing: 0) {
            Button {
                tab = 0
            } label: {
                HStack {
                    Spacer()
                        .contentShape(.rect)
                    VStack(alignment: .leading) {
                        Text("Start")
                        Text(
                            start.formatted(.dateTime.hour().minute()))
                    }
                    Spacer()
                        .contentShape(.rect)
                }
            }
            .opacity(tab == 0 ? 1 : 0.2)

            Image(systemName: "arrow.forward")

            Button {
                tab = 1
            } label: {
                HStack {
                    Spacer()
                        .contentShape(.rect)
                    VStack(alignment: .leading) {
                        Text("End")
                        Text(
                            end.formatted(.dateTime.hour().minute()))
                    }
                    Spacer()
                        .contentShape(.rect)
                }
            }
            .opacity(tab == 1 ? 1 : 0.2)
        }.padding(.horizontal, Spacing.s)
    }
}

#Preview("test") {
    @Previewable
    @State var start: Date = .init()
    @Previewable
    @State var end: Date = .init()

    DualDateSheet(start: $start, end: $end)
}

struct SimpleGraphicalDatePicker: DatePickerStyle {

    @Query var days: [Day]
    @Namespace var animation

    @State private var displayDate: Date = Calendar.current.startOfDay(
        for:
            Date()
    )

    private let months: [Date] = {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: Calendar.current.component(.year, from: Date()) - 1,
            month: 1
        )
        let endComponents = DateComponents(
            year: Calendar.current.component(.year, from: Date()) + 1,
            month: 12
        )

        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(from: endComponents)!

        var dates: [Date] = []
        var current = startDate

        while current <= endDate {
            dates.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        return dates
    }()

    @State private var dual: Bool = false
    @State private var tab: Int = 0

    func makeBody(configuration: Configuration) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top) {
                    ForEach(months, id: \.self) { month in
                        VStack {
                            Text(month, formatter: monthYearFormatter)
                                .font(.headline)
                                .containerRelativeFrame(.horizontal)
                                .padding(.vertical)

                            HStack(alignment: .firstTextBaseline) {
                                ForEach(
                                    Calendar.current.shortWeekdaySymbols,
                                    id: \.self
                                ) { symbol in
                                    HStack {
                                        Spacer()
                                        Text(symbol)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            .containerRelativeFrame(.horizontal)

                            CalendarView(
                                displayDate: month,
                                configuration: configuration,
                                days: days
                            )
                        }
                        .id(
                            Calendar.current.dateComponents(
                                [.month, .year],
                                from: month
                            )
                        )
                        .containerRelativeFrame([.horizontal])
                        .padding(.vertical)
                    }
                }
                .task {
                    proxy.scrollTo(
                        Calendar.current.dateComponents(
                            [.month, .year],
                            from: configuration.selection
                        )
                    )

                    displayDate = Calendar.current
                        .startOfDay(for: configuration.selection)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }

    }

    private func shiftDisplayMonth(by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: displayDate
        ) {
            withAnimation {
                displayDate = newDate
            }
        }
    }

    private func shiftMonth(configuration: Configuration, by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: configuration.selection
        ) {
            configuration.selection = newDate
        }
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }
}
