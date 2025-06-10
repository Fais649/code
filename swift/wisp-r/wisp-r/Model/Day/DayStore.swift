import SwiftData
import SwiftUI

struct DayStore {
    static func momentPredicate(momentType: MomentType = .all)
        -> Predicate<Day>
    {
        let predi = momentType.momentPredicate
        return #Predicate<Day> {
            $0.moments.contains { moment in
                moment.text != "" && predi.evaluate(moment)
            }
        }
    }

    static func datePredicate(date: Date) -> Predicate<Day> {
        let date = Calendar.current.startOfDay(for: date)
        return #Predicate<Day> {
            $0.date == date
        }
    }

    static func hasMomentPredicate() -> Predicate<Day> {
        #Predicate<Day> {
            $0.moments.isEmpty == false
        }
    }

    static func noteMomentPredicate() -> Predicate<Day> {
        let momentPredicate = MomentStore.notePredicate()
        return #Predicate<Day> {
            $0.moments.contains { moment in
                return momentPredicate.evaluate(moment)
            }
        }
    }

    static func taskMomentPredicate() -> Predicate<Day> {
        let momentPredicate = MomentStore.taskPredicate()
        return #Predicate<Day> {
            $0.moments.contains { moment in
                momentPredicate.evaluate(moment)
            }
        }
    }

    static func eventMomentPredicate() -> Predicate<Day> {
        let momentPredicate = MomentStore.eventPredicate()
        return #Predicate<Day> {
            $0.moments.contains { moment in
                momentPredicate.evaluate(moment)
            }
        }
    }

    static func photoMomentPredicate() -> Predicate<Day> {
        let momentPredicate = MomentStore.imagesPredicate()
        return #Predicate<Day> {
            $0.moments.contains { moment in
                momentPredicate.evaluate(moment)
            }
        }
    }

    static func audioMomentPredicate() -> Predicate<Day> {
        let momentPredicate = MomentStore.audioPredicate()
        return #Predicate<Day> {
            $0.moments.contains { moment in
                momentPredicate.evaluate(moment)
            }
        }
    }

    static func timelinePredicate(timelineID: UUID) -> Predicate<Day> {
        let momentPredicate = MomentStore.timelinePredicate(timelineID: timelineID)
        return #Predicate<Day> {
            $0.moments.contains { moment in
                momentPredicate.evaluate(moment)
            }
        }
    }
}
