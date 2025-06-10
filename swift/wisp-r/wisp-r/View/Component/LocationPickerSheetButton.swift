import MapKit
import SwiftData
import SwiftUI

struct LocationPickerSheetButton: View {
    var initialName: String = ""
    var onConfirm: (_ selectedName: String, _ selectedCoordinate: CLLocationCoordinate2D?) -> Void

    @State private var showSheet: Bool = false
    var body: some View {
        Button {
            showSheet.toggle()
        } label: {
            Image(systemName: "location.fill")
        }
        .sheet(isPresented: $showSheet) {
            LocationSearchField(initialName: initialName) {
                selectedName, selectedCoordinate in
                onConfirm(selectedName, selectedCoordinate)
            }
        }
    }
}
