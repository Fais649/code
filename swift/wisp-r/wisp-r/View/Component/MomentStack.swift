import SwiftData
import SwiftUI

struct MomentStack: View {
    @Environment(\.modelContext) private var modelContext
    var searchFilter: String? = nil
    @Binding var sheetMoment: Moment?
    let moments: [Moment]
    var childrenPrefix: Int = 6
    var momentType: MomentType = .all

    var body: some View {
        ForEach(
            moments.filter { moment in
                do {
                    if let searchFilter {
                        return moment.text.isNotEmpty
                            && (searchFilter.isEmpty || moment.text.contains(searchFilter))
                    } else {
                        return try momentType.momentPredicate.evaluate(moment)
                    }
                } catch {
                    return false
                }
            }.sorted(by: { $0.position < $1.position }),
            id: \.id
        ) { moment in
            MomentRow(sheetMoment: $sheetMoment, moment: moment, prefix: childrenPrefix)
        }
        .onMove { indexSet, newIndex in
            MomentStore.move(moments, from: indexSet, to: newIndex, in: modelContext)
        }
    }
}
