//
//  ContentView.swift
//  wisp-r
//
//  Created by Faisal Alalaiwat on 01.06.25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: Path? = .daysScreen()
    @State private var loading: Bool = true

    var body: some View {
        NavigationSplitView {
            if loading {
                ProgressView().progressViewStyle(.circular)
            } else {
                NavigationListScreen(path: $path)
            }
        } detail: {
            Group {
                if loading {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    NavigationDetailScreen(path: $path)
                }
            }.navigationBarBackButtonHidden()
        }
        .background(Default.screenBackground())
        .foregroundStyle(Default.foregroundColor)
        .tint(Default.foregroundColor)
        .task {
            let c = StartupCron()
            await c.run(in: modelContext)
            await syncCalendars()
            loading = false
        }
        .toolbarBackground(.hidden, for: .bottomBar)
    }

    func syncCalendars() async {
        if Permission.hasCalendarAccessPermission {
            EKCalendarService.importEKCalendars(in: modelContext)
        } else {
            if await Permission.requestAccessToCalendar() {
                EKCalendarService.importEKCalendars(in: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
}


