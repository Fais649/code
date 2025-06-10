import EventKit
import EventKitUI
import SwiftUI

struct CalendarEventSheet: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    let startDate: Date
    let endDate: Date
    let eventTitle: String
    let onSave: (EKEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.eventStore = EKEventStore()

        let event = EKEvent(eventStore: vc.eventStore)
        event.startDate = startDate
        event.endDate = endDate
        event.title = eventTitle

        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {
        vc.event?.startDate = startDate
        vc.event?.endDate = endDate
        vc.event?.title = eventTitle
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: CalendarEventSheet

        init(_ parent: CalendarEventSheet) {
            self.parent = parent
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction
        ) {
            if action == .saved, let e = controller.event {
                parent.onSave(e)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
