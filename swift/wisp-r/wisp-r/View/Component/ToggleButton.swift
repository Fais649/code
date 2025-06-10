import SwiftData
import SwiftUI

struct ToggleButton: View {
    @State var toggled: Bool
    let action: () -> Bool
    let toggledIcon: String
    let notToggledIcon: String

    var body: some View {
        Button {
            toggled = action()
        } label: {
            Image(systemName: toggled ? toggledIcon : notToggledIcon)
        }.buttonStyle(.plain)
            .contentShape(.rect)
    }
}
