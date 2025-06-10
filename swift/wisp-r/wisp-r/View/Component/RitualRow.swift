import SwiftData
import SwiftUI

struct RitualRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var ritual: Ritual
    @State private var showSymbolPickerSheet: Bool = false
    @FocusState var focused: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            Button {
                showSymbolPickerSheet.toggle()
            } label: {
                ritual.symbol
            }
            .buttonStyle(.plain)
            .padding(Spacing.s)
            .background(Default.backgroundColor)
            .clipShape(.circle)

            VStack(spacing: 0) {
                TextField("Name...", text: $ritual.name)
                    .lineLimit(1)
                    .focused($focused)

                Stepper {
                    Text("\(ritual.counter.goal)x per day:")
                } onIncrement: {
                    ritual.counter.stepGoalUp()
                } onDecrement: {
                    ritual.counter.stepGoalDown()
                }
            }

            if focused {
                Button {
                    focused = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.smooth, value: focused)
        .sheet(isPresented: $showSymbolPickerSheet) {
            SymbolPicker(selectedSymbolName: $ritual.symbolName)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(ritual)
            } label: {
                Image(systemName: "trash.fill")
            }
        }
    }
}
