import MapKit
import SwiftUI

@Observable
final class LocationSearchService: NSObject {
    var query = "" {
        didSet { search() }
    }
    var results: [MKMapItem] = []

    private func search() {
        guard query.count >= 2 else {
            results = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            DispatchQueue.main.async {
                self.results = response?.mapItems ?? []
            }
        }
    }
}

struct LocationSearchField: View {
    @Environment(\.dismiss) var dismiss
    @State var service = LocationSearchService()

    let initialName: String
    @State private var selectedName: String = ""
    @State var selectedCoordinate: CLLocationCoordinate2D?
    var onConfirm: (_ selectedName: String, _ selectedCoordinate: CLLocationCoordinate2D?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !service.results.isEmpty {
                List(service.results, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item.name ?? "")
                            .bold()
                        if let addr = item.placemark.title {
                            Text(addr)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedName = item.name ?? ""
                        selectedCoordinate = item.placemark.coordinate
                        service.results = []
                        service.query = selectedName
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
            }

            TextField("Search for location", text: $service.query)
                .padding(8)
                .background(Color(.secondarySystemFill))
                .cornerRadius(8)
                .padding(.horizontal)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()

                Button {
                    onConfirm(selectedName, selectedCoordinate)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }.task {
            selectedName = initialName
        }
    }
}
