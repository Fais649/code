import SwiftData
import SwiftUI

struct CircleButton<Label: View>: View {
    var action: () -> Void
    var label: () -> Label

    var body: some View {
        Button {
            action()
        } label: {
            label()
        }
    }
}
