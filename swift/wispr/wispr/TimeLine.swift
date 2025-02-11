import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Observable
class TimeLine {
    var id: UUID = .init()
    var items: [Item]
    var today: Day
    var activeDay: Day
    var firstDay: Day
    var lastDay: Day
    var days: [Day]

    init(date: Date = Date(), items: [Item] = []) {
        self.items = items
        var cal = Calendar.current
        cal.firstWeekday = 2

        let days = (-365 ... 365).map { dayInt in
            let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
            var day = Day(offset: dayInt, date: time)
            guard let itms = try? items.filter(day.itemPredicate) else {
                return day
            }

            day.items.insert(contentsOf: itms.sorted(by: { $0.position < $1.position }), at: 0)
            return day
        }

        self.days = days
        firstDay = days.first!
        lastDay = days.last!
        let today = days.first(where: { $0.offset == 0 })!

        self.today = today
        activeDay = today
    }

    var itemPredicate: Predicate<Item> {
        let start = today.date
        let end = today.date.advanced(by: 604_800)
        return #Predicate<Item> { start <= $0.timestamp && end > $0.timestamp }
    }

    func refreshDays(date: Date) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let days = (-365 ... 365).map { dayInt in
            let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
            var day = Day(offset: dayInt, date: time)
            guard let itms = try? self.items.filter(day.itemPredicate) else {
                return day
            }

            day.items.insert(contentsOf: itms, at: 0)
            return day
        }

        self.days = days
        firstDay = days.first!
        lastDay = days.last!
        activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
    }

    func updateDays(date: Date) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let newDate = date

        if newDate < firstDay.date || newDate > lastDay.date {
            let days = (-365 ... 365).map { dayInt in
                let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
                var day = Day(offset: dayInt, date: time)
                guard let itms = try? self.items.filter(day.itemPredicate) else {
                    return day
                }

                day.items.insert(contentsOf: itms, at: 0)
                return day
            }

            self.days = days
            firstDay = days.first!
            lastDay = days.last!
            activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
        } else {
            activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
        }
    }
}

struct TimeLineView: View {
    @Environment(\.modelContext) private var modelContext

    @Namespace var namespace
    @Binding var path: [NavDestination]
    @Binding var date: Date

    @State var firstLoad: Bool = true
    @State var todayHidden: Bool = false
    @State var selectDay: Bool = false
    @Query var items: [Item]
    @State var listId: UUID = .init()
    @State var showAllDays: Bool = false

    @State var hideAll: Bool = false

    let todayDate: Date = Calendar.current.startOfDay(for: Date())

    var days: [Date: [Item]] {
        var days: [Date: [Item]] = [:]
        for dayInt in -365 ... 365 {
            let date = Calendar.current.startOfDay(for: date)
            let start = date.advanced(by: TimeInterval(dayInt * 86400))
            let end = start.advanced(by: TimeInterval(86400))
            days[start] = items.filter { start <= $0.timestamp && $0.timestamp < end }.sorted(by: { $0.position < $1.position })
        }
        return days
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                List(days.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    if showAllDays || !value.isEmpty {
                        listRow(key, value)
                    }
                }.opacity(hideAll ? 0 : 1)
                    .animation(.snappy(duration: 0.1), value: hideAll)
                    .onAppear {
                        listAppear(proxy: proxy)
                    }.overlay(alignment: .bottomTrailing) {
                        Button {
                            withAnimation {
                                hideAll.toggle()
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    showAllDays.toggle()
                                }
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    listAppear(proxy: proxy)
                                }
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                hideAll.toggle()
                            }
                        } label: {
                            Image(systemName: showAllDays ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        }
                        .frame(width: 50, height: 50)
                        .padding()
                        .tint(.white)
                    }
            }
            .listRowSpacing(10)
        }
        .toolbarBackgroundVisibility(.hidden, for: .bottomBar)
        .toolbarBackground(.clear, for: .bottomBar)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    func getXOffset(_ date: Date) -> CGFloat {
        if !Calendar.current.isDateInToday(date) {
            return date < Date() ? -20 : 20
        }

        return 0
    }

    func getScale(_ date: Date) -> CGFloat {
        if !Calendar.current.isDateInToday(date) {
            return 0.9
        }

        return 1
    }

    func getScaleAnchor(_ date: Date) -> UnitPoint {
        if !Calendar.current.isDateInToday(date) {
            return date < Date() ? .leading : .trailing
        }

        return .center
    }

    @ViewBuilder
    func listRow(_ date: Date, _ items: [Item]) -> some View {
        Button {
            self.date = date
            self.path.removeAll()
        } label: {
            HStack {
                if Calendar.current.isDateInToday(date) {
                    Image(systemName: "play.fill")
                        .tint(.white)
                }
                DayHeader(date: date, isEmpty: items.isEmpty)
                    .font(.custom("GohuFont11NFM", size: 14))
            }
            rowBody(date, items)
                .padding(.leading)
                .font(.custom("GohuFont11NFM", size: 14))
        }
        .opacity(Calendar.current.isDateInToday(date) || date > Date() ? 1 : 0.6)
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    func rowBody(_: Date, _ items: [Item]) -> some View {
        VStack {
            ForEach(items) { item in
                ItemRowLabel(item: item)
                    .onChange(of: item.position) {
                        try! modelContext.save()
                    }
                    .disabled(true)
            }
        }
    }

    fileprivate func listRowAppear(date: Date) {
        if firstLoad && date == todayDate {
            withAnimation {
                self.date = todayDate
                self.firstLoad = false
            }
        }
    }

    fileprivate func listRowDisappear(date: Date) {
        if date == todayDate {
            todayHidden = true
        }
    }

    fileprivate func listAppear(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(todayDate, anchor: .top)
        }
    }
}
