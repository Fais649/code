import SwiftData
import SwiftUI

struct TimelineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState var focused: FocusedField?
    let timeline: Timeline
    @State var color: Color
    @State private var showColorPickerSheet: Bool = false
    @State private var anyEmptyFocused: Bool = false

    func enterAction(timeline: Timeline) -> EnterableTextField<Timeline>.Refocus {
        if timeline.name.isEmpty {
            modelContext.delete(timeline)
            timeline.parent?.children.removeAll {
                $0.id == timeline.id
            }
            return .no
        } else {
            let child = Timeline(parent: timeline.parent ?? timeline)
            timeline.parent?.children.append(child) ?? timeline.children.append(child)
            modelContext.insert(child)
            return .yes
        }
    }

    var body: some View {
        VStack {
            List {
                EnterableTextField(
                    focused: $focused,
                    model: timeline,
                    action: enterAction
                ).listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(timeline.children, id: \.id) { timeline in
                    EnterableTextField(
                        focused: $focused,
                        model: timeline,
                        action: enterAction
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .onPreferenceChange(EmptyFocusedKey.self) { value in
            anyEmptyFocused = value
        }
        .presentationBackground {
            Default.screenBackground(for: timeline.color)
        }
        .overlay(alignment: .bottom) {
            SheetToolbar(focused: $focused, color: timeline.color) {
            } leading: {
                Button {
                    showColorPickerSheet.toggle()
                } label: {
                    Image(systemName: "swatchpalette.fill")
                }
            } trailing: {
                SheetBackButton(
                    focused: $focused,
                    anyEmptyFocused: anyEmptyFocused,
                    shouldDismiss: { focused == nil },
                    shouldDelete: { timeline.name.isEmpty },
                    deleteAction: {
                        modelContext.delete(timeline)
                        try? modelContext.save()
                    })
            }
        }.sheet(isPresented: $showColorPickerSheet) {
            ColorPickerSheet(selectedColor: color) { newColor in
                timeline.setColor(newColor)
            }
        }
    }
}
