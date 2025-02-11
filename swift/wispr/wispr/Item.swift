import AppIntents
import EventKit
import Foundation
import PhotosUI
import SFSymbolsPicker
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

enum ItemType: String, Identifiable, Codable, CaseIterable {
    var id: ItemType { self }
    case note, task, event, activity, image, log

    var imageName: String {
        switch self {
        case .note:
            "text.word.spacing"
        case .task:
            "checkmark.circle"
        case .event:
            "clock"
        case .activity:
            "timer"
        default:
            "bell.slash"
        }
    }
}

struct ItemRecord: Codable, Transferable {
    var id: UUID
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

extension UTType {
    static let item = UTType(exportedAs: "punk.systems.item")
}

@Model
final class Tag: Identifiable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var symbol: String = "circle.fill"

    init(name: String, color: UIColor, symbol: String = "circle.fill") {
        self.name = name
        colorHex = color.toHex() ?? ""
        self.symbol = symbol
    }
}

struct NoteData: Identifiable, Codable {
    var id: UUID = .init()
    var text: String
}

struct TaskData: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var completedAt: Date?
}

struct LocationData: Identifiable, Codable {
    var id: UUID = .init()
    var link: String?
}

struct NotificationData: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var text: String
    var linkedItem: UUID?
}

struct EventData: Identifiable, Codable {
    var id: UUID = .init()
    var eventIdentifier: String?
    var startDate: Date
    var endDate: Date
}

struct AudioData: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var url: URL
    var transcript: String

    init(_ date: Date = Date(), url: URL? = nil, transcript: String = "") {
        self.date = date
        if let u = url {
            self.url = u
        } else {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
            self.url = audioFilename
        }

        self.transcript = transcript
    }
}

struct ItemQuery: EntityQuery {
    func entities(for identifiers: [Item.ID]) async throws -> [Item] {
        var entities: [Item] = []
        let items = await fetchItemsByIds(identifiers)

        for item in items {
            entities.append(item)
        }

        return entities
    }

    func fetchItemsByIds(_ ids: [UUID]) async -> [Item] {
        let context =  ModelContext(SharedState.sharedModelContainer)
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { ids.contains($0.id) })
        guard let items = try? context.fetch(desc) else {
            return []
        }

        return items
    }

    func fetchItemById(_ id: UUID) async -> Item? {
        let context =   ModelContext(SharedState.sharedModelContainer)
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { id == $0.id })
        guard let item = try? context.fetch(desc).first else {
            return nil
        }

        return item
    }
}

@Model
final class Item: Codable, Transferable, AppEntity {
    @Attribute(.unique) var id: UUID

    @Relationship(deleteRule: .noAction) var tags: [Tag] = []

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: noteData.text))
    }

    var queryIntentParameter: IntentParameter<Item> {
        IntentParameter<Item>(query: Item.defaultQuery)
    }

    var defaultIntentParameter: IntentParameter<Item> {
        let i = IntentParameter<Item>(title: "Item", default: self)
        i.wrappedValue = self
        return i
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
    static var defaultQuery = ItemQuery()

    var parent: Item?
    @Relationship(inverse: \Item.parent) var children: [Item] = []
    var position: Int
    var timestamp: Date
    var archived: Bool = false

    var noteData: NoteData = NoteData(text: "")
    var taskData: TaskData?
    var eventData: EventData?
    var audioData: AudioData?

    var notificationData: NotificationData?

    var hasNote: Bool {
        !noteData.text.isEmpty
    }

    var isTask: Bool {
        taskData != nil
    }

    var isEvent: Bool {
        eventData != nil
    }

    var hasTags: Bool {
        !tags.isEmpty
    }

    var hasImage: Bool {
        externalData != nil
    }

    var hasAudio: Bool {
        audioData?.url != nil
    }

    @Attribute(.externalStorage) var externalData: Data?

    var record: ItemRecord {
        ItemRecord(id: id)
    }

    @ViewBuilder
    func imageView(image: Image? = nil) -> some View {
        if let image = image {
            image.resizable().scaledToFit()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else if let image = loadImage() {
            image.resizable().scaledToFit()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    func loadImage() -> Image? {
        if let data = externalData {
            if let image = UIImage(data: data) {
                return Image(uiImage: image)
            }
        }
        return nil
    }

    init(
        id: UUID = UUID(),
        position: Int = 0,
        timestamp: Date = .init(),
        tags: [Tag] = [],
        externalData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.externalData = externalData

        self.position = position
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id
        case position
        case timestamp
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
        ProxyRepresentation(exporting: \.noteData.text)
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        position = try values.decode(Int.self, forKey: .position)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

struct ItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(
        CalendarService.self
    ) private var calendarService: CalendarService
    var items: [Item]

    @State var listId: UUID = .init()
    @State var focusedItem: Item?
    @State var flashError: Bool = false
    @State var movedItem: Item?
    @State var movedToItem: Item?

    var body: some View {
        ZStack {
            list
            if flashError {
                errorFlash
            }
        }
    }

    @ViewBuilder
    var list: some View {
        VStack {
            List {
                ForEach(items, id: \.self) { item in
                    itemRow(item)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(item)
                                    try! modelContext.save()
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .tint(.black)
                        }
                }
                .onMove(perform: handleMove)
            }.id(listId)
                .opacity(flashError ? 0.1 : 1)
                .listRowSpacing(4)
        }.padding(0).safeAreaPadding(0)
    }

    @ViewBuilder
    func itemRow(_ item: Item) -> some View {
        ItemRow(item: item)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onChange(of: item.eventData?.startDate) {
                withAnimation {
                    dynamicallyReorderList(item: item)
                }
            }.onAppear {
                if var event = item.eventData, let id = event.eventIdentifier,
                   let ek = calendarService.eventStore.event(withIdentifier: id)
                {
                    event.startDate = ek.startDate
                    event.endDate = ek.endDate
                    item.noteData.text = ek.title
                    item.eventData = event
                }
            }
    }

    @ViewBuilder
    var errorFlash: some View {
        VStack {
            Image(systemName: "xmark")
                .font(.system(size: 128))
            Text("Can't change event order!")
        }
        .frame(alignment: .center)
    }

    func handleDelete(_ indexSet: IndexSet) {
        for index in indexSet {
            let item = items[index]
            modelContext.delete(item)
        }
        try! modelContext.save()
    }

    func handleMove(_ indexSet: IndexSet, _ newIndex: Int) {
        for index in indexSet {
            let count = items.count
            let movedItem = items[index]
            self.movedItem = movedItem

            if let movedEventData = movedItem.eventData {
                for i in 0 ..< newIndex {
                    let item = items[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate < itemEventData.startDate {
                            withAnimation {
                                flashError = true
                                listId = UUID()
                            }
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 1) {
                                    withAnimation {
                                        flashError = false
                                    }
                                }
                            print("bad order above")
                            return
                        }
                    }
                }

                for i in newIndex ..< count {
                    let item = items[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate > itemEventData.startDate {
                            withAnimation {
                                flashError = true
                                listId = UUID()
                            }
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 1) {
                                    withAnimation {
                                        flashError = false
                                    }
                                }
                            print("bad order below")
                            return
                        }
                    }
                }
            }
        }

        var itms = items
        itms.move(fromOffsets: indexSet, toOffset: newIndex)

        for (index, item) in itms.enumerated() {
            item.position = index
        }

        try! modelContext.save()
    }

    func dynamicallyReorderList(item: Item) {
        guard let itemEventData = item.eventData else {
            return
        }

        let oldIndex = items.firstIndex(of: item)!
        if let newIndex = items.firstIndex(where: {
            if let eventData = $0.eventData {
                return $0.id != item.id && $0.eventData != nil && eventData.startDate > itemEventData.startDate
            } else {
                return false
            }
        }) {
            var itms = items
            itms.move(fromOffsets: [oldIndex], toOffset: newIndex)
            for (index, itm) in itms.enumerated() {
                itm.position = index
            }
        } else {
            item.position = items.count
        }
    }
}

struct ItemRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item
    @State var expand: Bool = true
    @FocusState var focus: Bool
    @State var show: Bool = false

    var body: some View {
        if item.children.isEmpty {
            ItemRowLabel(item: item)
        } else {
            DisclosureGroup(isExpanded: $expand) {
                ForEach(item.children) { child in
                    ItemRowLabel(item: child)
                }
            } label: {
                ItemRowLabel(item: item)
            }.tint(.white)
        }
    }
}

struct ItemRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item
    @FocusState var focus: Bool
    @State var initialText: String = ""

    @Namespace var namespace

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
            VStack {
                TimelineView(.everyMinute) { time in
                    HStack {
                        VStack {
                            if item.hasImage {
                                Spacer()
                            }

                            HStack {
                                TaskDataRowLabel(item: $item)
                                NoteDataRowLabel(item: $item)
                                EventDataRowLabel(item: $item, currentTime: time.date)
                            }
                            .padding(.vertical, item.isEvent || item.hasImage ? 10 : 4)
                            .padding(.horizontal, item.isEvent ? 32 : 20)
                            .tint(isActiveItem(item, time.date) ? .black : .white)
                            .frame(alignment: .bottom)
                        }
                    }
                    .background {
                        if item.hasImage {
                            ImageDataRowLabel(item: $item, namespace: namespace)
                        }

                        RoundedRectangle(cornerRadius: 8)
                            .stroke(item.isEvent ? .white : .clear)
                            .fill(isActiveItem(item, time.date) ? .white : .clear).padding(2)
                            .padding(.horizontal, 12)
                    }
                    .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
                    .scaleEffect(isEventPast(item, time.date) ? 0.9 : 1, anchor: .center)
                }
            }
        }
        .onAppear { focus = item.noteData.text.isEmpty }
    }
}

struct EditItemForm: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item
    @Binding var date: Date

    init(item: Item, date: Binding<Date>) {
        self.item = item
        _date = date
    }

    var body: some View {
        ItemForm(item: $item, date: $date, position: item.position)
    }
}

struct ItemForm: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService

    @Binding var item: Item
    @Binding var date: Date

    @Query var tags: [Tag]

    @State var showTag: Bool = false
    @State var tagSearchTerm: String = ""
    @State private var image: Image?

    init(item: Binding<Item>, date: Binding<Date>, position _: Int) {
        _item = item
        _date = date
    }

    var tagSearchResults: [Tag] {
        if tagSearchTerm.isEmpty {
            return tags.filter { !item.tags.contains($0) }
        } else {
            return tags.filter { $0.name.contains(tagSearchTerm) && !item.tags.contains($0) }
        }
    }

    @FocusState var noteFocus: Bool
    @FocusState var childFocus: Bool
    @FocusState var tagSearchFocus: Bool

    var body: some View {
        VStack {
            if image != nil {
                item.imageView(image: image)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            withAnimation {
                                item.externalData = nil
                                image = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }.padding()
                    }
            }

            HStack {
                if item.isTask {
                    TaskDataRow(item: $item)
                }

                NoteDataRow(item: $item)
                    .focused($noteFocus)
                    .onSubmit {
                        if item.isTask {
                            let child = Item(
                                position: item.children.count,
                                timestamp: item.timestamp
                            )

                            child.taskData = TaskData()
                            withAnimation {
                                item.children.append(child)
                            }
                        }
                    }.onDisappear {
                        for child in item.children {
                            if !child.hasNote {
                                modelContext.delete(child)
                            }
                        }
                    }
            }
            .listRowBackground(Color.clear)

            if item.hasAudio {
                AudioRecordingView(item: $item)
            }

            if item.hasTags {
                TagDataRow(item: $item)
            }

            ForEach(item.children) { child in
                ChecklistDataRow(parent: $item, child: child)
                    .focused($childFocus)
                    .onDisappear {
                        noteFocus = true
                    }
            }
        }
        .onChange(of: item.isTask) {
            if !item.isTask {
                var string = item.noteData.text

                for child in item.children {
                    string += "\n" + child.noteData.text
                    modelContext.delete(child)
                }

                withAnimation {
                    item.children = []
                    item.noteData.text = string
                }
            } else {
                let strings = item.noteData.text.components(separatedBy: "\n")
                for (index, str) in strings.enumerated() {
                    if index == 0 {
                        item.noteData.text = str
                    } else {
                        let child = Item(position: item.children.count, timestamp: item.timestamp)
                        child.noteData.text = str
                        child.taskData = TaskData()
                        item.children.append(child)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    ImageDataButton(item: $item, image: $image)
                    AudioDataButton(item: $item)
                    TagDataButton(show: $showTag)
                    TaskDataButton(item: $item)
                    EventDataButton(item: $item)

                    if let e = item.eventData {
                        EventDataRow(
                            item: $item,
                            eventData: e
                        )
                    }
                }
            }
        }
        .onAppear {
            if item.eventData != nil {
                calendarService.requestAccessToCalendar()
                item.eventData = .init(
                    startDate: item.timestamp,
                    endDate: item.timestamp
                        .advanced(by: 3600)
                )
            }
        }.onChange(of: date) {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
            comps.hour = Calendar.current.component(.hour, from: item.timestamp)
            comps.minute = Calendar.current.component(.minute, from: item.timestamp)
            let d = Calendar.current.date(from: comps)
            item.timestamp = d ?? item.timestamp
        }
        .tint(.white)
    }
}

struct ChecklistDataButton: View {
    @Binding var item: Item

    var body: some View {
        Button {
            if item.children.isEmpty {
                withAnimation {
                    let child = Item(
                        position: item.children.count,
                        timestamp: item.timestamp
                    )

                    child.taskData = TaskData()
                    item.children.append(child)

                    if !item.isTask {
                        item.taskData = TaskData()
                    }
                }
            } else {
                withAnimation {
                    item.children = []
                }
            }
        } label: {
            Image(systemName: item.children.isEmpty ? "checklist" : "checklist.checked")
        }
    }
}

struct ChecklistDataRow: View {
    @Binding var parent: Item
    @State var child: Item
    @FocusState var focused: Bool

    var body: some View {
        HStack {
            if child.isTask {
                TaskDataRow(item: $child)
            }

            TextField("...", text: $child.noteData.text)
                .onAppear {
                    focused = true
                }
                .focused($focused)
                .onSubmit {
                    withAnimation {
                        let c = Item(
                            position: parent.children.count,
                            timestamp: parent.timestamp
                        )

                        c.taskData = TaskData()
                        parent.children.append(c)
                    }
                }
        }
    }
}

@Observable
class DayDetailsConductor {
    var showDatePicker: Bool = false
    var editItem: Item?
    var isEditingItem: Bool {
        editItem != nil
    }

    init() {}
}

struct NoteDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor

    @Binding var item: Item
    @FocusState var focus: Bool

    var body: some View {
        TextField("...", text: $item.noteData.text, axis: .vertical)
            .lineLimit(20)
            .onAppear { focus = true }
            .focused($focus)
            .multilineTextAlignment(.leading)
            .textFieldStyle(.roundedBorder)

        if item.hasNote {
            HStack {
                Button {
                    focus = false
                    if item.hasNote {
                        modelContext.insert(item)
                    } else {
                        modelContext.delete(item)
                    }

                    withAnimation {
                        conductor.editItem = nil
                        SharedState.editItem = nil
                    }
                } label: {
                    Image(systemName: "chevron.up.circle.fill")
                }
            }.animation(.smooth, value: item.hasNote)
        }
    }
}

struct NoteDataRowLabel: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var item: Item

    var body: some View {
        Button {
            withAnimation {
                conductor.editItem = item
            }
        } label: {
            HStack {
                Text(item.noteData.text)
                Spacer()
            }
        }
        .disabled(conductor.isEditingItem)
        .buttonStyle(.plain)
        .scaleEffect(item.taskData?.completedAt != nil ? 0.8 : 1, anchor: .leading)
    }
}

struct TaskDataButton: View {
    @Binding var item: Item

    var body: some View {
        Button {
            if item.isTask {
                withAnimation {
                    item.taskData = nil
                }
            } else {
                withAnimation {
                    let taskData = TaskData()
                    item.taskData = taskData
                }
            }
        } label: {
            Image(systemName: item.isTask ? "checkmark.circle.fill" : "checkmark.circle")
        }
    }
}

struct TaskDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var item: Item

    var body: some View {
        if var task = item.taskData {
            Button {
                if task.completedAt == nil {
                    withAnimation {
                        task.completedAt = Date()
                    }
                } else {
                    withAnimation {
                        task.completedAt = nil
                    }
                }
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Image(systemName: task.completedAt == nil ? "square" : "square.fill")
            }
        }
    }
}

struct TaskDataRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var item: Item

    var body: some View {
        if item.isTask, var task = item.taskData {
            Button {
                if task.completedAt == nil {
                    task.completedAt = Date()
                    withAnimation {
                        item.taskData = task

                        for child in item.children {
                            child.taskData?.completedAt = Date()
                        }
                    }
                } else {
                    task.completedAt = nil
                    withAnimation {
                        item.taskData = task
                        for child in item.children {
                            child.taskData?.completedAt = nil
                        }
                    }
                }
                WidgetCenter.shared.reloadAllTimelines()
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Image(systemName: task.completedAt == nil ? "square" : "square.fill")
            }.buttonStyle(.plain)
        }
    }
}

struct EventDataButton: View {
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var item: Item

    var body: some View {
        Button {
            withAnimation {
                if let event = item.eventData {
                    if let id = event.eventIdentifier, let ekEvent =
                        calendarService.eventStore.event(withIdentifier: id)
                    {
                        calendarService.deleteEventInCalendar(event: ekEvent)
                    }
                    item.eventData = nil
                } else {
                    item.eventData = .init(
                        startDate: item.timestamp,
                        endDate: item.timestamp
                            .advanced(by: 3600)
                    )
                }
            }
        } label: { Image(systemName: item.eventData != nil ? "clock.fill" : "clock") }
    }
}

struct EventDataRow: View {
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var item: Item
    @State var event: EventData
    @State var interval: TimeInterval = 3600
    @State var deleteEvent: Bool = false

    init(item: Binding<Item>, eventData: EventData) {
        let event = eventData
        _event = State(initialValue: event)
        _item = item
    }

    var startString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startDate)
    }

    var endString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.endDate)
    }

    var body: some View {
        Text(startString)
            .overlay {
                DatePicker("start:", selection: $event.startDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: event.startDate) {
                        event.endDate = event.startDate.advanced(by: interval)
                    }
            }

        RoundedRectangle(cornerRadius: 2).background(.white).frame(width: 2, height: 15)

        Text(endString)
            .overlay {
                DatePicker("end:", selection: $event.endDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: event.endDate) {
                        if event.endDate < event.startDate {
                            event.startDate = event.endDate.advanced(by: -interval)
                        } else {
                            interval = event.endDate.timeIntervalSince(event.startDate)
                        }
                    }
            }
            .onAppear {
                if !calendarService.accessToCalendar {
                    calendarService.requestAccessToCalendar()
                }

                if event.eventIdentifier != nil {
                    interval = event.endDate.timeIntervalSince(event.startDate)
                }
            }
            .onDisappear {
                if !item.noteData.text.isEmpty, let id = item.eventData?.eventIdentifier {
                    if let ekEvent = calendarService.eventStore.event(withIdentifier: id) {
                        item.eventData = event
                        ekEvent.startDate = event.startDate
                        ekEvent.endDate = event.endDate
                        ekEvent.title = item.noteData.text
                        try? calendarService.eventStore.save(ekEvent, span: .thisEvent)
                    } else if !item.noteData.text.isEmpty, item.eventData != nil, let
                        ekEvent = calendarService.createEventInCalendar(title:
                            item.noteData.text, start: event.startDate, end: event.endDate)
                    {
                        event.eventIdentifier = ekEvent.eventIdentifier
                        item.eventData = event
                    }
                }
            }
    }
}

struct EventDataRowLabel: View {
    @Binding var item: Item
    let currentTime: Date

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
            Button {
                withAnimation {
                    print("")
                }
            } label: {
                VStack {
                    if Calendar.current.isDateInToday(eventData.startDate) {
                        if eventData.startDate > currentTime {
                            HStack {
                                Spacer()
                                Text(format(eventData.startDate, currentTime))
                            }
                        } else if item.taskData?.completedAt == nil && eventData.startDate <= currentTime && currentTime < eventData.endDate {
                            TimelineView(.periodic(from: .now, by: 1)) { timer in
                                HStack(spacing: 5) {
                                    Spacer()
                                    Image(systemName: "timer")
                                    Text(timer.date, format: .timer(countingDownIn: eventData.startDate ..< eventData.endDate))
                                }
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        Text(eventData.startDate.formatted(.dateTime.hour().minute()) + " | " + eventData.endDate.formatted(.dateTime.hour().minute()))
                            .scaleEffect(item.taskData?.completedAt == nil &&
                                eventData.startDate <= currentTime &&
                                currentTime < eventData.endDate ? 0.8 : 1)
                            .fixedSize()
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct TagDataButton: View {
    @Binding var show: Bool

    var body: some View {
        Button { withAnimation { show.toggle() } } label: {
            Image(systemName: show ?
                "tag.fill" : "tag")
        }
    }
}

struct TagDataRow: View {
    @Binding var item: Item

    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(item.tags) { tag in
                        Button {
                            withAnimation {
                                item.tags.removeAll(where: { $0.id == tag.id })
                            }
                        } label: {
                            Text(tag.name)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .font(.custom("GohuFont11NFM", size: 14))
                        }
                        .background {
                            RoundedRectangle(cornerRadius:
                                20).fill(Color(uiColor: UIColor(hex:
                                tag.colorHex))).stroke(.white).opacity(0.75)
                        }
                        .tint(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(10)
    }
}

struct ImageDataButton: View {
    @Binding var item: Item
    @State private var imageItem: PhotosPickerItem?
    @Binding var image: Image?

    var body: some View {
        PhotosPicker(selection: $imageItem, matching: .images) {
            Image(systemName: image == nil ? "photo" : "photo.fill")
        }.onChange(of: imageItem) {
            Task {
                if let image = try await imageItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: image) {
                        withAnimation {
                            self.image = Image(uiImage: uiImage)
                        }
                    }
                    withAnimation {
                        item.externalData = image
                    }
                }
            }
        }
    }
}

struct ImageDataRowLabel: View {
    @Binding var item: Item
    var namespace: Namespace.ID

    var body: some View {
        NavigationLink {
            VStack {
                item.imageView()
                    .padding(2)
                    .padding(.horizontal, 12)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }.padding()
                .navigationTransition(.zoom(sourceID: item.id, in: namespace))
        } label: {
            item.imageView()
                .padding(2)
                .padding(.horizontal, 12)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .matchedTransitionSource(id: item.id, in: namespace)
        }
    }
}

struct AudioDataButton: View {
    @Binding var item: Item

    var body: some View {
        Button {
            if item.audioData == nil {
                withAnimation {
                    item.audioData = AudioData(item.timestamp)
                }
            }
        } label: {
            Image(systemName: item.hasAudio ? "microphone.fill" : "microphone")
        }
    }
}

struct AudioPlayerView: View {
    @Binding var item: Item
    let data: AudioData
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var audioSession: AVAudioSession?

    var body: some View {
        HStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "square.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
            }

            if !data.transcript.isEmpty {
                Text(data.transcript)
            }
        }
        .onAppear {
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.playback, mode: .spokenAudio)
            try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try? audioSession.setActive(true)
            self.audioSession = audioSession

            if !FileManager.default.fileExists(atPath: data.url.path()) {
                withAnimation {
                    item.audioData = nil
                }
            }

            player = AVPlayer(url: data.url)

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                   object: player?.currentItem,
                                                   queue: .main)
            { _ in
                isPlaying = false
                player?.seek(to: .zero)
            }
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }
        if isPlaying {
            player.seek(to: .zero)
            player.pause()
        } else {
            print("play")
            player.play()
        }
        isPlaying.toggle()
    }
}

struct AudioRecordingView: View {
    @Environment(AudioService.self) private var audioService: AudioService
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var item: Item

    @State private var currentTime: TimeInterval = 0
    @State private var transcript: String = ""
    @State private var hasPermission: Bool = false
    @State private var doneLoading: Bool = false
    @State private var showPlay: Bool = false

    @State var count: Int = 0

    @State var startDate: Date?

    var body: some View {
        HStack {
            if showPlay {
                if let audioData = item.audioData {
                    AudioPlayerView(item: $item, data: audioData)
                        .disabled(!item.hasAudio)
                } else {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
            } else {
                HStack {
                    Button(action: toggleRecording) {
                        Image(systemName: audioService.isRecording ?
                            "circle.fill" : "microphone.circle.fill")
                            .resizable()
                            .foregroundColor(audioService.isRecording ? .red : .white)
                    }.disabled(!audioService.hasPermission)
                        .frame(width: 30, height: 30)
                    Spacer()
                }
            }
        }.padding()
            .onAppear {
                if !audioService.hasPermission {
                    Task {
                        await audioService.requestRecordPermission()
                    }
                }
                showPlay = item.audioData != nil
            }
    }

    func toggleRecording() {
        if audioService.isRecording {
            audioService.stopRecording()
            if let url = audioService.recordedURL {
                Task {
                    audioService.extractTextFromAudio(url) { result in
                        switch result {
                        case let .success(string):
                            if var audio = item.audioData {
                                audio.transcript = string
                                item.audioData = audio
                            } else {
                                transcript = string
                                let newAudio = AudioData(url: url, transcript: transcript)
                                item.audioData = newAudio
                            }
                            doneLoading = true
                        case let .failure(error):
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        } else {
            Task {
                if let audio = item.audioData {
                    try? await audioService.setupRecorder(audioFilename: audio.url)
                    startDate = Date()
                    audioService.startRecording()
                } else {
                    let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
                    let newAudio = AudioData(url: audioFilename)
                    item.audioData = newAudio
                    try? await audioService.setupRecorder(audioFilename: audioFilename)
                    startDate = Date()
                    audioService.startRecording()
                }
            }
        }
    }
}
