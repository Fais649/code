import EventKit
import EventKitUI
import MapKit
import SwiftData
import SwiftUI

struct MomentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState var focused: FocusedField?
    let moment: Moment

    @State private var anyEmptyFocused = false

    var body: some View {
        VStack(spacing: Spacing.zero) {
            if let images = moment.images {
                MomentSheetImageRow(images: images)
            }

            if let audio = moment.audio {
                AudioPlayerView(audioData: audio)
            }

            List {
                HStack {
                    MomentSheetRow(focused: $focused, moment: moment)
                        .onPreferenceChange(EmptyFocusedKey.self) { value in
                            anyEmptyFocused = value
                        }

                    if let event = moment.event {
                        Spacer()
                        VStack {
                            Text(event.startTimeString)
                            Text(event.endTimeString)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                ForEach(moment.children) { child in
                    MomentSheetRow(focused: $focused, moment: child)
                }
                .onMove { indexSet, newIndex in
                    MomentStore.move(
                        moment.children, from: indexSet, to: newIndex, in: modelContext)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .overlay(alignment: .bottom) {
                MomentSheetToolbar(
                    focused: $focused,
                    anyEmptyFocused: $anyEmptyFocused,
                    moment: moment
                )
            }
        }
        .presentationDetents([.fraction(0.5), .fraction(1)])
        .presentationBackground {
            Default.sheetBackground(for: moment.color)
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }
}
