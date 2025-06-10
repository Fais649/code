import SwiftData
import SwiftUI

struct MomentSheetToolbar: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @FocusState.Binding var focused: FocusedField?

    @Binding var anyEmptyFocused: Bool
    @Bindable var moment: Moment

    var locationName: String {
        moment.location?.name ?? ""
    }

    var body: some View {
        SheetToolbar(focused: $focused, color: moment.color) {
            // if focused == nil {
            //     HStack {
            //         LocationPickerSheetButton(initialName: locationName) {
            //             selectedName, selectedCoordinate in
            //
            //             if let l = moment.location {
            //                 l.name = selectedName
            //                 if let long = selectedCoordinate?.longitude,
            //                     let lat = selectedCoordinate?.latitude
            //                 {
            //                     l.lat = lat
            //                     l.long = long
            //                 }
            //             } else {
            //                 let l = Location(
            //                     name: selectedName,
            //                     lat: selectedCoordinate?.latitude,
            //                     long: selectedCoordinate?.longitude
            //                 )
            //                 modelContext.insert(l)
            //                 moment.location = l
            //             }
            //             try? modelContext.save()
            //         }
            //
            //         if let l = moment.location {
            //             Text(l.name)
            //         }
            //         Spacer()
            //     }
            // }
        } leading: {
            if moment.pinned {
                EmptyView()
            } else {

                DualDatePickerSheetButton(moment: moment)
            }

            TimelinesSheetButton(selectedTimeline: moment.timeline) { selectedTimeline in
                moment.timeline = selectedTimeline
            }
        } trailing: {
            MomentSheetToolbarMenu(moment: moment)

            Button {
                moment.isTask.toggle()
                if moment.parent == nil {
                    for c in moment.children {
                        c.isTask = moment.isTask
                    }
                }
            } label: {
                Image(systemName: moment.isTask ? "square.fill" : "square.dotted")
            }

            SheetBackButton(
                focused: $focused,
                anyEmptyFocused: anyEmptyFocused,
                shouldDismiss: { focused == nil },
                shouldDelete: { moment.text.isEmpty },
                deleteAction: {
                    if let e = moment.event {
                        EKCalendarService.delete(e, in: modelContext)
                    }
                    modelContext.delete(moment)
                    try? modelContext.save()
                })
        }
        .animation(
            .smooth,
            value: [
                anyEmptyFocused, focused == nil, moment.images == nil,
                moment.audio == nil, moment.isTask,
            ]
        )
    }
}
