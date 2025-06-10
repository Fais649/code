import SwiftData
import SwiftUI

struct Screen<Content: View, SheetModel: PersistentModel, SheetView: View>: View {
    @State private var sheetModel: SheetModel?
    @ViewBuilder let content: () -> Content
    @ViewBuilder let sheetView: (SheetModel) -> SheetView

    var body: some View {
        VStack {
            content()
        }.sheet(item: $sheetModel) { model in
            sheetView(model)
        }
    }
}
