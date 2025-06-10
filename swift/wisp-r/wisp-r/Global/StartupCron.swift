import SwiftData
import SwiftUI

struct StartupCron {
    @AppStorage("didRunStartupCron") var didRunStartupCron: Bool = false
    func run(in modelContext: ModelContext) async {
        // StartupCron.refreshDays(in: modelContext)
        if !didRunStartupCron {
            let dayCount = try? modelContext.fetchCount(FetchDescriptor<Day>())
            StartupCron.ensureAllDaysExist(in: modelContext, dayCount: dayCount ?? 0)
        }

        didRunStartupCron = true
    }

    private static func ensureAllDaysExist(in modelContext: ModelContext, dayCount: Int) {
        guard dayCount == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard
            let startDate = calendar.date(byAdding: .year, value: -1, to: today),
            let endDate = calendar.date(byAdding: .year, value: 1, to: today)
        else { return }

        var current = startDate
        while current <= endDate {
            let newDay = Day(date: current, moments: [])
            modelContext.insert(newDay)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        try? modelContext.save()
    }

    private static func deleteEmptyMoments(in modelContext: ModelContext) {
        guard
            let moments = try? modelContext.fetch(
                FetchDescriptor<Moment>(predicate: #Predicate<Moment> { $0.text == "" }))
        else { return }
        for i in moments {
            modelContext.delete(i)
        }
    }

    private static func deleteTimelines(in modelContext: ModelContext) {
        guard
            let moments = try? modelContext.fetch(
                FetchDescriptor<Timeline>(predicate: #Predicate<Timeline> { $0.name == "" }))
        else { return }
        for i in moments {
            modelContext.delete(i)

        }
    }

    private static func refreshDays(in modelContext: ModelContext) {
        guard
            let moments = try? modelContext.fetch(
                FetchDescriptor<Moment>())
        else { return }
        for i in moments {
            modelContext.delete(i)
        }

        guard
            let days = try? modelContext.fetch(
                FetchDescriptor<Day>())
        else { return }
        for i in days {
            modelContext.delete(i)
        }
        try? modelContext.save()

        let dayCount = try? modelContext.fetchCount(FetchDescriptor<Day>())
        StartupCron.ensureAllDaysExist(in: modelContext, dayCount: dayCount ?? 0)
    }
}
