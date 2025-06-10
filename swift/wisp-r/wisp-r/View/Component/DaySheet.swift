import SwiftData
import SwiftUI

struct DaySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ritual.position) var rituals: [Ritual]

    var body: some View {
        List {
            Section(
                header: HStack {
                    Text("Rituals")
                    Spacer()
                    Button {
                        let newRitual = Ritual(position: rituals.count)
                        modelContext.insert(newRitual)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            ) {
                RitualStack(rituals: rituals)
            }
        }
    }
}
