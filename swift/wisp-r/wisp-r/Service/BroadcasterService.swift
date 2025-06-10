import SwiftData
import SwiftUI

@Observable
final class BroadcasterService {
    enum EventType {
        case createNewEventOnActiveDay
        case showDatePickerSheet(onSelectDate: (_ newDate: Date) -> Void)
    }

    private var event: EventType? = nil

    var isEventSet: Bool {
        event != nil
    }

    func receive() -> EventType? {
        let e = event
        event = nil
        return e
    }

    func emit(_ event: EventType) {
        if isEventSet {
            self.event = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.event = event
            }
        } else {
            self.event = event
        }
    }
}
