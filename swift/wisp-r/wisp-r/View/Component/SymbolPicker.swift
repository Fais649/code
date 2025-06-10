import SwiftUI

struct SymbolPicker: View {
    @Binding var selectedSymbolName: String
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    @State private var search: String = ""

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Symbol.all.filter { search.isEmpty || $0.contains(search) }, id: \.self) {
                    sym in
                    Button {
                        selectedSymbolName = sym
                    } label: {
                        Image(systemName: sym)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selectedSymbolName == sym
                                            ? Default.foregroundColor : .clear,
                                        lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
        }
        .searchable(text: $search, prompt: "Search...")
    }
}
