import SwiftData
import SwiftUI

struct RitualRecordStack: View {
    let interactive: Bool
    let ritualRecords: [RitualRecord]

    var body: some View {
        ForEach(ritualRecords.sorted(by: { $0.position < $1.position }).prefix(6)) { r in
            RitualRecordButton(ritualRecord: r)
                .allowsHitTesting(interactive)
        }
    }
}
