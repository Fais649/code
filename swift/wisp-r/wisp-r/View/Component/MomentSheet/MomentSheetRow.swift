import SwiftData
import SwiftUI

struct MomentSheetRow: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState.Binding var focused: FocusedField?
    let moment: Moment

    func enterAction(moment: Moment) -> EnterableTextField<Moment>.Refocus {
        if moment.text.isEmpty {
            modelContext.delete(moment)
            moment.parent?.children.removeAll { $0.id == moment.id }
            return .no
        } else {
            let child = Moment(
                position: moment.parent?.children.count ?? moment.children.count,
                parent: moment.parent ?? moment
            )
            child.isTask = moment.isTask
            modelContext.insert(child)
            moment.parent?.children.append(child) ?? moment.children.append(child)
            return .yes
        }
    }

    var body: some View {
        HStack {
            if moment.isTask {
                ToggleButton(
                    toggled: moment.isCompleted,
                    action: {
                        if let parent = moment.parent {
                            moment.isCompleted.toggle()
                            if !moment.isCompleted, parent.isCompleted != moment.isCompleted {
                                parent.isCompleted = false
                            }
                            return moment.isCompleted
                        } else {
                            moment.isCompleted.toggle()
                            for c in moment.children {
                                c.isCompleted = moment.isCompleted
                            }
                            return moment.isCompleted
                        }
                    },
                    toggledIcon: "square.fill",
                    notToggledIcon: moment.parent == nil ? "square" : "square.dotted"
                )
            }

            EnterableTextField(
                focused: $focused, model: moment, action: enterAction
            )
        }
    }
}
