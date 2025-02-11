//
//  Widget.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 11.02.25.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct WidgetView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemLarge:
            LargeWidget()
                .font(.custom("GohuFont11NFM", size: 14))

        case .systemMedium:
            MediumWidget()
                .font(.custom("GohuFont11NFM", size: 12))

        default:
            SmallWidget()
        }
    }
}

struct SmallWidget: View {
    var body: some View {
        Text("smol")
    }
}

struct LargeWidget: View {
    @Query var items: [Item]

    var todaysItems: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: SharedState.date)
        let end = start.advanced(by: 86400)
        return items.filter { start < $0.timestamp && $0.timestamp < end }.sorted(by: { first, second in first.position < second.position })
    }

    var body: some View {
        VStack {
            HStack {
                Button(intent: ShowTodayIntent()) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10) // Set desired frame
                }.buttonStyle(.plain).foregroundStyle(.white)
            }
            if todaysItems.isEmpty {
                Spacer()
                Text("Maidenless")
                    .foregroundStyle(.white)
                Spacer()
            } else {
                WidgetItemList(items: todaysItems)
            }

            HStack {
                Spacer()
                Button(intent: ShowYesterdayIntent()) {
                    Image(systemName: "chevron.left")
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .frame(alignment: .center)

                Button(intent: ShowTodayIntent()) {
                    Spacer()
                    Text(SharedState.date.formatted(date: .abbreviated, time: .omitted))
                        .frame(alignment: .top)
                        .foregroundStyle(.white)
                    Spacer()
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .frame(alignment: .center)

                Button(intent: ShowTomorrowIntent()) {
                    Image(systemName: "chevron.right")
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .frame(alignment: .center)

                Spacer()
                Spacer()

                Button(intent: NewTaskIntent()) {
                    Image(systemName: "plus")
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .widgetURL(URL(string: "wispr//NewTask"))
                    .frame(alignment: .trailing)
                Spacer()
            }.padding()
        }
    }
}

struct WidgetItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    var items: [Item]

    var body: some View {
        VStack {
            ForEach(items.prefix(5), id: \.self) { item in
                itemRow(item)
            }
            Spacer()
        }.padding()
    }

    @ViewBuilder
    func itemRow(_ item: Item) -> some View {
        WidgetItemRowLabel(item: item)
    }
}

struct MediumWidget: View {
    @Query var items: [Item]
    @State var date: Date = .init()

    var events: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.eventData != nil && (start < $0.timestamp && $0.timestamp < end) }
    }

    var tasks: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.taskData != nil && (start < $0.timestamp && $0.timestamp < end) }
    }

    var notes: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.taskData == nil && $0.eventData == nil && (start < $0.timestamp && $0.timestamp < end) }
    }

    var body: some View {
        VStack {
            Spacer()

            GeometryReader { geo in
                HStack {
                    VStack(spacing: 4) {
                        if tasks.isEmpty {
                            HStack {
                                Text("No Tasks")
                                    .foregroundStyle(.gray)
                            }
                        }
                        ForEach(tasks) { item in
                            WidgetItemRowLabel(item: item)
                        }

                        Spacer()
                    }.frame(width: geo.size.width * 0.32)

                    VStack(spacing: 4) {
                        if events.isEmpty {
                            Text("No Events")
                                .frame(alignment: .center)
                                .foregroundStyle(.gray)
                        }
                        ForEach(events) { item in
                            WidgetItemRowLabel(item: item)
                        }
                    }.frame(width: geo.size.width * 0.667)
                }
            }
            Spacer()

            HStack {
                Spacer()
                Button(intent: NewTaskIntent()) {
                    Image(systemName: "plus")
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .widgetURL(URL(string: "wispr//NewTask"))
            }
        }.padding(3)
            .padding(.horizontal, 6)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .top) {
                    Image("Logo")
                        .resizable() // Make the image resizable if needed
                        .scaledToFit() // Adjust the content mode
                        .frame(width: 8, height: 8) // Set desired frame
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .frame(alignment: .top)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
    }
}

struct WidgetItemRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    func isEventPast(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return date > eventData.endDate
        } else {
            return false
        }
    }

    var body: some View {
        HStack {
            TimelineView(.everyMinute) { time in
                HStack {
                    WidgetTaskDataRowLabel(item: $item)
                    WidgetNoteDataRowLabel(item: $item)
                    WidgetEventDataRowLabel(item: $item, currentTime: time.date)
                }
                .padding(4)
                .tint(isActiveItem(item, time.date) ? .black : .white)
                .frame(alignment: .bottom)
                .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
                .background(isActiveItem(item, time.date) ? .white : .black)
                .scaleEffect(isEventPast(item, time.date) ? 0.9 : 1, anchor: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct WidgetTaskDataRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var item: Item

    var body: some View {
        if item.isTask, let task = item.taskData {
            Button(intent: ToggleTaskCompletionIntent(task: item.defaultIntentParameter)) {
                Image(systemName: task.completedAt == nil ? "square" : "square.fill")
            }.background(.clear).buttonStyle(.plain)
        }
    }
}

struct WidgetNoteDataRowLabel: View {
    @Binding var item: Item

    var body: some View {
        Button(intent: EditItemIntent(item: item.defaultIntentParameter)) {
            HStack {
                Text(item.noteData.text)
                Spacer()
            }
        }
        .widgetURL(URL(string: "wispr//EditItem"))
        .buttonStyle(.plain)
        .scaleEffect(item.taskData?.completedAt != nil ? 0.8 : 1, anchor: .leading)
    }
}

struct WidgetEventDataRowLabel: View {
    @Binding var item: Item
    let currentTime: Date

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    var formatter: RelativeDateTimeFormatter {
        let formatter =
            RelativeDateTimeFormatter()
        return formatter
    }

    func format(_ date: Date, _: Date) -> String {
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    var body: some View {
        if let eventData = item.eventData {
            Button(intent: EditItemIntent(item: item.defaultIntentParameter)) {
                VStack {
                    HStack {
                        Spacer()
                        Text(eventData.startDate.formatted(.dateTime.hour().minute()))
                            .scaleEffect(isActiveItem(item, currentTime) ? 0.8 :
                                1, anchor: .bottomTrailing)
                    }
                    HStack {
                        Spacer()
                        if isActiveItem(item, currentTime) {
                            Image(systemName: "timer")
                        }
                        Text(eventData.endDate.formatted(.dateTime.hour().minute()))
                    }
                }
            }
            .widgetURL(URL(string: "wispr//EditItem"))
            .buttonStyle(.plain)
        }
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch App"
    static let openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ShowTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    init() {}

    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.date = Date()
        }
        return .result()
    }
}

struct ShowTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    init() {}

    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.date.addTimeInterval(86400)
        }
        return .result()
    }
}

struct ShowYesterdayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    init() {}

    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.date.addTimeInterval(-86400)
        }
        return .result()
    }
}

struct NewTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "New Task"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedState.newItem = true
        createNewItem()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    @MainActor
    func createNewItem() {
        let context = SharedState.sharedModelContainer.mainContext
        let items = getItems(context)

        let newItem = Item(
            position: items.count,
            timestamp: Date()
        )

        withAnimation {
            SharedState.editItem = newItem
        }

        context.insert(newItem)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    func getItems(_ context: ModelContext) -> [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = start.advanced(by: 86400)
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { start < $0.timestamp && $0.timestamp < end })
        do {
            return try context.fetch(desc)
        } catch {
            return []
        }
    }
}

struct EditItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Item"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Item")
    var item: Item

    func perform() async throws -> some IntentResult {
//            withAnimation {
//                SharedState.editItem = item
//            }
        return .result()
    }
}

struct ToggleTaskCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"

    @Parameter(title: "Item")
    var task: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        print("madeIT")
        let context = SharedState.sharedModelContainer.mainContext
        if task.taskData?.completedAt == nil {
            task.taskData?.completedAt = Date()
        } else {
            task.taskData?.completedAt = nil
        }

        context.insert(task)
        try context.save()

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
