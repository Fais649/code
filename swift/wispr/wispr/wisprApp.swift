//
//  wisprApp.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import SwiftData
import SwiftUI

@main
struct wisprApp: App {
    @State var calendarService: CalendarService = .init()
    @State var audioService: AudioService = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(calendarService)
                .environment(audioService)
                .preferredColorScheme(.dark)
        }
        
        .modelContainer(SharedState.sharedModelContainer)
    }
}
