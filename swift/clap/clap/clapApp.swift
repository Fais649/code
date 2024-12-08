//
//  clapApp.swift
//  clap
//
//  Created by Faisal Alalaiwat on 30.11.24.
//

import SwiftData
import SwiftUI

@main
struct clapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        for familyName in UIFont.familyNames {
            let fontNames = UIFont.fontNames(forFamilyName: familyName)
            print(familyName, fontNames)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.custom("GohuFont11NFM", size: 14))
        }
        .modelContainer(sharedModelContainer)
    }
}
