import SwiftData
import SwiftUI

@Model
final class Ritual: Identifiable {
    init(
        id: UUID = UUID(),
        position: Int = 0,
        name: String = "",
        symbolName: String = Symbol.Misc.hexagon,
        counter: CountUp = CountUp(goal: 3),
    ) {
        self.id = id
        self.position = position
        self.name = name
        self.symbolName = symbolName
        self.counter = counter
    }

    var id: UUID

    var key: String {
        id.uuidString + name.hashValue.description
            + counter.goal.hashValue.description
    }

    var name: String
    var symbolName: String
    var position: Int = 0
    var symbol: Image {
        Image(systemName: symbolName)
    }

    var counter: CountUp

    func createRecord(for day: Day) -> RitualRecord {
        RitualRecord(day: day, ritual: self)
    }
}

struct RitualStore {
    static func loadAll(in modelContext: ModelContext) -> [Ritual] {
        let desc = FetchDescriptor<Ritual>()
        let res = try? modelContext.fetch(desc)
        return res ?? []
    }

    static func generateRecords(for day: Day, in modelContext: ModelContext) {
        let rituals = loadAll(in: modelContext)

        let ritualsByID = Dictionary(uniqueKeysWithValues: rituals.map { ($0.id, $0) })

        let existing = day.ritualRecords
        let recordsByRitualID = Dictionary(
            uniqueKeysWithValues:
                existing.map { ($0.ritualID, $0) }
        )

        for ritual in rituals {
            if let record = recordsByRitualID[ritual.id] {
                record.position = ritual.position
                record.symbolName = ritual.symbolName
                record.counter.goal = ritual.counter.goal
            } else {
                let newRecord = ritual.createRecord(for: day)
                modelContext.insert(newRecord)
            }
        }

        for record in existing where ritualsByID[record.ritualID] == nil {
            modelContext.delete(record)
        }

        try? modelContext.save()
    }
}

protocol Counter: Codable {
    var remaining: Int { get }
    var isCompleted: Bool { get }
    var goal: Int { get set }
    mutating func stepCount()
    mutating func stepGoalUp()
    mutating func stepGoalDown()
}

extension Counter {
    mutating func stepGoalUp() {
        goal += 1
    }

    mutating func stepGoalDown() {
        if goal > 0 {
            goal -= 1
        }
    }
}

struct CountUp: Counter {
    init(goal: Int) {
        self.goal = goal
    }

    var goal: Int
    var count: Int = 0
    var remaining: Int {
        goal - count
    }

    var isCompleted: Bool {
        remaining == 0
    }

    mutating func reset() {
        count = 0
    }

    mutating func stepCount() {
        if !isCompleted {
            count += 1
        }
    }
}

@Model
final class RitualRecord: Identifiable {
    init(
        id: UUID = UUID(),
        day: Day,
        ritual: Ritual,
    ) {
        self.id = id
        self.ritualID = ritual.id
        self.key =
            ritual.id.uuidString + ritual.name.hashValue.description
            + ritual.counter.goal.hashValue.description

        self.position = ritual.position
        self.day = day
        self.symbolName = ritual.symbolName
        counter = ritual.counter
    }

    var id: UUID = UUID()
    var ritual: Ritual?
    var ritualID: UUID
    var position: Int
    var key: String
    var day: Day
    var counter: CountUp

    var symbolName: String = ""
    var symbol: some View {
        Image(systemName: symbolName)
            // .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(foregroundColor)
    }

    var foregroundColor: Color {
        counter.isCompleted ? Default.backgroundColor : Default.foregroundColor
    }

    var backgroundColor: Color {
        counter.isCompleted ? Default.foregroundColor : Default.backgroundColor
    }
}
