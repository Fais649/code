import SwiftData
import SwiftUI

struct RitualStack: View {
    @Environment(\.modelContext) private var modelContext
    let rituals: [Ritual]

    var body: some View {
        ForEach(rituals, id: \.id) { ritual in
            RitualRow(ritual: ritual)
        }.onMove { indexSet, newIndex in
            var rs = rituals.sorted(by: { $0.position < $1.position })
            rs.move(fromOffsets: indexSet, toOffset: newIndex)

            for (i, r) in rs.enumerated() {
                r.position = i
            }

            try? modelContext.save()
        }
    }
}
