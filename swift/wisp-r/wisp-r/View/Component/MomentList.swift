import SwiftData
import SwiftUI

struct MomentList: View {
    @Environment(\.modelContext) private var modelContext
    let moments: [Moment]
    @Binding var sheetMoment: Moment?

    var body: some View {
        List {
            ForEach(moments, id: \.id) { moment in
                MomentRow(sheetMoment: $sheetMoment, moment: moment)
            }
        }
    }
}
