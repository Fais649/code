import SwiftData
import SwiftUI

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var selectedColor: Color
    let onSelect: (_ newColor: Color) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 4)

    @AppStorage("darkMode")
    var darkMode: Bool = true

    private let baseColors: [Color] = [
        .red,
        .pink,
        .orange,
        .green,
        .mint,
        .teal,
        .blue,
        .indigo,
        .purple,
        .brown,
        .white,
        .gray,
        .black,
    ]

    var body: some View {

        List {
            // HStack {
            //     Text("Dark mode")
            //     Spacer()
            //     ToggleButton(
            //         toggled: darkMode,
            //         action: {
            //             darkMode.toggle()
            //             return darkMode
            //         },
            //         toggledIcon: "lightbulb",
            //         notToggledIcon: "lightbulb.max"
            //     )
            // }

            ForEach(baseColors, id: \.self) { c in
                HStack {
                    Button("Sweet Dreams are made of these...") {
                        onSelect(c)
                        dismiss()
                    }
                    .padding(Spacing.s)
                    .background(Default.rowBackground(for: c))
                    .clipShape(.rect(cornerRadius: Spacing.s))
                }
                .padding(Spacing.s)
                .foregroundStyle(Default.foregroundColor(for: c))
                .listRowBackground(Default.screenBackground(for: c))
            }
        }
        .listRowSpacing(Spacing.s)
        .presentationBackground {
            Default.sheetBackground(for: selectedColor)
        }
    }
}

#Preview {
    @Previewable
    @State var selectedColor: Color = .white

    ColorPickerSheet(selectedColor: selectedColor) { newColor in
        selectedColor = newColor
    }
}
