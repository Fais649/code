//
//  Item.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.11.24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Item {
    var id: UUID = UUID()
    var orderId: Int
    var type: ItemType
    var typeRaw: Int
    var timestamp: Date

    var parent: Item?
    @Relationship(inverse: \Item.parent) var children: [Item] = []

    var data: ItemData {
        didSet {
            switch data {
            case let .event(eventData):
                eventStartDate = eventData.startDate
                eventEndDate = eventData.endDate
            default:
                eventStartDate = nil
                eventEndDate = nil
            }
        }
    }

    var record: ItemRecord {
        ItemRecord(item: self)
    }

    var eventStartDate: Date?
    var eventEndDate: Date?

    init(timestamp: Date, orderId: Int, type: ItemType, data: ItemData) {
        self.timestamp = timestamp
        self.orderId = orderId
        self.type = type
        typeRaw = type.rawValue
        self.data = data
    }
}

extension ItemData {
    var isEvent: Bool {
        if case .event = self {
            return true
        }
        return false
    }

    var event: Event? {
        if case let .event(eventData) = self {
            return eventData
        }
        return nil
    }
}

struct ItemRecord: Codable, Transferable {
    var id: UUID
    var orderId: Int
    var type: ItemType
    var typeRaw: Int {
        return type.rawValue
    }

    var timestamp: Date
    var data: ItemData

    init(item: Item) {
        id = item.id
        timestamp = item.timestamp
        orderId = item.orderId
        type = item.type
        data = item.data
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
    }
}

enum ItemType: Int, Equatable, Codable {
    case all = 0
    case todo = 1
    case note = 2
    case event = 3
}

enum ItemData: Codable, Equatable {
    case todo(Todo)
    case note(Note)
    case event(Event)
}

struct Todo: Codable, Equatable {
    var isDone: Bool = false
}

struct Note: Codable, Equatable {
    var content: String

    init(content: String) {
        self.content = content
    }
}

struct Event: Codable, Equatable {
    var startDate: Date
    var endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

@Observable
class Day {
    var modelContext: ModelContext
    var start: Date
    var components: DateComponents {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal.dateComponents([.year, .month, .day, .weekday, .weekOfMonth], from: start)
    }

    var yesterday: Date {
        return start.advanced(by: -86400)
    }

    var tomorrow: Date {
        return start.advanced(by: 86400)
    }

    init(modelContext: ModelContext, date: Date = Date()) {
        self.modelContext = modelContext
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: date)
        start = today
    }

    public func getDayOfWeek() -> Int? {
        return components.weekday
    }

    public func dayPredicate() -> Predicate<Item> {
        let type: Int = ItemType.event.rawValue
        // return #Predicate<Item> { yesterday < $0.timestamp && $0.timestamp < tomorrow && $0.typeRaw == type }
        return #Predicate<Item> { $0.parent == nil && yesterday < $0.timestamp && $0.timestamp < tomorrow }
    }

    public func step(by: Int, type: Calendar.Component) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        start = cal.date(byAdding: type, value: by, to: start)!
    }
}

@Observable
class Week {
    var modelContext: ModelContext
    var day: Day

    var startDate: Date
    var endDate: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let start = cal.startOfDay(for: startDate)
        return cal.date(byAdding: .day, value: 1, to: start) ?? startDate.advanced(by: 86400)
    }

    init(modelContext: ModelContext, day: Day) {
        self.modelContext = modelContext
        self.day = day
        var cal = Calendar.current
        cal.firstWeekday = 2
        startDate = cal.date(from: day.components)!
    }

    func getDays() -> [Day] {
        return []
    }

    func setWeek(to date: Date) {
        let cal = Calendar.current
        let startDate = cal.dateComponents([.month, .year, .weekOfYear], from: date)
        self.startDate = cal.startOfDay(for: cal.date(from: startDate) ?? Date())
    }
}

class DataSource {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    @MainActor
    static let shared = DataSource()

    @MainActor
    private init() {
        modelContainer = try! ModelContainer(
            for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false),
            ModelConfiguration(isStoredInMemoryOnly: false)
        )

        modelContext = modelContainer.mainContext
    }

    public func getModelContext() -> ModelContext {
        return modelContext
    }
}

class SwiftDataService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    @MainActor
    static let shared = SwiftDataService()

    @MainActor
    private init() {
        modelContainer = try! ModelContainer(
            for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false),
            ModelConfiguration(isStoredInMemoryOnly: false)
        )

        modelContext = modelContainer.mainContext
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
