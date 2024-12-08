//
//  wisprApp.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.11.24.
//

import SwiftData
import SwiftUI

@main
struct wisprApp: App {
    let container: ModelContainer
    var body: some Scene {
        WindowGroup {
            DayView(modelContext: container.mainContext)
        }
        .modelContainer(container)
    }

    init() {
        do {
            container = try ModelContainer(for: Item.self)
        } catch {
            fatalError("Failed to create ModelContainer for Movie.")
        }
    }
}

@Observable
@MainActor
class Conductor {
    var modelContext: ModelContext
    var activeDay: Day
    var activeWeek: Week

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let day = Day(modelContext: modelContext, date: Date())
        activeDay = day
        activeWeek = Week(modelContext: modelContext, day: day)
    }
}
