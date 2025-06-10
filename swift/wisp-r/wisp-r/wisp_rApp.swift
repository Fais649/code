//
//  wisp_rApp.swift
//  wisp-r
//
//  Created by Faisal Alalaiwat on 01.06.25.
//

import SwiftData
import SwiftUI

@main
struct wisp_rApp: App {
    var sharedModelContainer: ModelContainer = {
        ValueTransformer.setValueTransformer(
            UIColorValueTransformer(), forName: NSValueTransformerName("UIColorValueTransformer")
        )

        let schema = Schema([
            Moment.self,
            Day.self,
            Event.self,
            Images.self,
            ImageData.self,
            Audio.self,
            Timeline.self,
            Ritual.self,
            RitualRecord.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
