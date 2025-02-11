//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import AudioKit
import AVFoundation
import AVKit
import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DayDetails(date: Date())
            .onAppear {
                WidgetCenter.shared.reloadAllTimelines()
            }
            .environment(SharedState.dayDetailsConductor)
            .preferredColorScheme(.dark)
    }
}
