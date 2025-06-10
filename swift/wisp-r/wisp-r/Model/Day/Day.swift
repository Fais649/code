import SwiftData
import SwiftUI

@Model
final class Day {
    init(date: Date, allDayMoments: [Moment] = [], moments: [Moment]) {
        self.date = Calendar.current.startOfDay(for: date)
        self.allDayMoments = allDayMoments
        self.moments = moments
    }

    var date: Date
    var allDayMoments: [Moment]
    var moments: [Moment]

    @Relationship(deleteRule: .cascade, inverse: \RitualRecord.day)
    var ritualRecords: [RitualRecord] = []
}
