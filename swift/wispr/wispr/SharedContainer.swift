//
//  SharedContainer.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.02.25.
//
import Foundation
import SwiftData

enum SharedState {
    static var dayDetailsConductor: DayDetailsConductor = .init()
    static var newItem: Bool = false
    static var editItem: Item?
    static var date: Date = .init()

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
