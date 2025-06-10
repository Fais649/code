import EventKit
import SwiftData
import SwiftUI

struct DatePickerSheet: View {
    @State var selectedDate: Date
    var onChange: (Date) -> Void

    var body: some View {
        DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(GraphicalLikeDatePickerStyle())
        .presentationBackground {
            Default.sheetBackground()
        }
        .presentationDetents([.fraction(0.5)])
        .onChange(of: selectedDate) {
            onChange(selectedDate)
        }
    }
}

struct GraphicalLikeDatePickerStyle<MultiDateSelector: View>: DatePickerStyle {
    init(
        onChangeComponents: (() -> Void)? = nil,
        timeShown: (() -> Bool)? = nil,
        @ViewBuilder multiDateSelector: @escaping ()
            -> MultiDateSelector = { EmptyView() }
    ) {
        self.onChangeComponents = onChangeComponents
        self.timeShown = timeShown
        self.multiDateSelector = multiDateSelector
    }

    @Query var days: [Day]
    @Namespace var animation
    var onChangeComponents: (() -> Void)? = nil

    var dualSheet: Bool = false

    var timeShown: (() -> Bool)? = nil

    var multiDateSelector: () -> MultiDateSelector

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

    func makeBody(configuration: Configuration) -> some View {
        VStack {
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

            HStack {
                if let timeShown, timeShown() {
                    multiDateSelector()
                } else {
                    HStack {
                        Button {
                            configuration.selection = Date()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Today")
                                Spacer()
                            }
                        }.contentShape(Rectangle())

                        Button {
                            configuration.selection = Calendar.current
                                .date(
                                    byAdding: .day,
                                    value: 1,
                                    to: Calendar.current.startOfDay(for: Date())
                                )!
                        } label: {
                            HStack {
                                Spacer()
                                Text("Tomorrow")
                                Spacer()
                            }
                        }.contentShape(Rectangle())

                        Button {
                            configuration.selection = Calendar.current
                                .date(
                                    byAdding: .day,
                                    value: 7,
                                    to:
                                        Calendar.current.startOfDay(for: Date())
                                )!
                        } label: {
                            HStack {
                                Spacer()
                                Text("Next Week")
                                Spacer()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .containerRelativeFrame(.horizontal)
        }
        .containerRelativeFrame([.horizontal, .vertical])
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

struct CalendarView: View {
    let displayDate: Date
    let configuration: DatePickerStyleConfiguration

    private let monthDates: [Date]
    private let dayLookup: [Date: Day]

    init(displayDate: Date, configuration: DatePickerStyleConfiguration, days: [Day]) {
        self.displayDate = displayDate
        self.configuration = configuration

        let calendar = Calendar.current
        if let monthInterval = calendar.dateInterval(of: .month, for: displayDate) {
            var dates: [Date] = []
            var current = monthInterval.start
            while current < monthInterval.end {
                dates.append(current)
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            self.monthDates = dates
        } else {
            self.monthDates = []
        }

        var lookup: [Date: Day] = [:]
        for day in days {
            lookup[calendar.startOfDay(for: day.date)] = day
        }
        self.dayLookup = lookup
    }

    var body: some View {
        let firstWeekday =
            (Calendar.current.component(.weekday, from: monthDates.first ?? Date()) - 1)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(0..<firstWeekday, id: \.self) { _ in
                Text(" ")
            }

            ForEach(monthDates, id: \.self) { date in
                DateButton(
                    date: date,
                    day: dayLookup[Calendar.current.startOfDay(for: date)],
                    selection: configuration.selection,
                    onSelect: { newDate in
                        configuration.selection = Calendar.current.startOfDay(for: newDate)
                    }
                )
            }
        }
    }

    struct DateButton: View {
        let date: Date
        let day: Day?
        let selection: Date
        let onSelect: (Date) -> Void

        func isSelectedDate(_ date: Date) -> Bool {
            Calendar.current.isDate(date, inSameDayAs: selection)
        }
        @ViewBuilder
        func bgShape(date: Date) -> some View {
            if Calendar.current.isDateInToday(date) {
                RoundedRectangle(cornerRadius: Spacing.xs)
                    .fill(Default.backgroundColor)
                    .stroke(Default.foregroundColor, lineWidth: isSelectedDate(date) ? 1 : 0)
                    .aspectRatio(1, contentMode: .fit)
                    .rotationEffect(.degrees(45))
            } else if isSelectedDate(date) {
                Circle()
                    .fill(Default.backgroundColor)
                    .stroke(Default.foregroundColor, lineWidth: 1)
                    .aspectRatio(1, contentMode: .fit)
            }
        }

        @ViewBuilder
        func bg(date: Date) -> some View {
            bgShape(date: date)
        }

        var body: some View {
            Button {
                onSelect(date)
            } label: {
                VStack {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .padding(Spacing.s)
                        .background(bg(date: date))

                    HStack(spacing: 2) {
                        Spacer()
                        if let moments = day?.moments.prefix(3) {
                            ForEach(moments) { m in
                                Circle()
                                    .fill(m.color)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 6)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var current = interval.start
        while current < interval.end {
            dates.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current)
            else { break }
            current = next
        }
        return dates
    }
}
