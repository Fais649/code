import SwiftData
import SwiftUI

enum MomentType: String, CaseIterable, Identifiable {
    case all, pinned, note, task, event, photo, audio

    var id: String { rawValue }

    var momentPredicate: Predicate<Moment> {
        switch self {
        case .pinned:
            MomentStore.pinnedPredicate()
        case .note:
            MomentStore.notePredicate()
        case .task:
            MomentStore.taskPredicate()
        case .event:
            MomentStore.eventPredicate()
        case .photo:
            MomentStore.imagesPredicate()
        case .audio:
            MomentStore.audioPredicate()
        default:
            MomentStore.pinnedPredicate(false)
        }
    }

    @ViewBuilder
    var leadingTitle: some View {
        switch self {
        case .pinned:
            Text("Pinned")
        case .note:
            Text("Notes")
        case .task:
            Text("Tasks")
        case .event:
            Text("Events")
        case .photo:
            Text("Photos")
        case .audio:
            Text("Memos")
        default:
            Text("Timeline")
        }
    }

    @ViewBuilder
    var trailingTitle: some View {
        switch self {
        case .pinned:
            Icon.pin
        case .note:
            Icon.note
        case .task:
            Icon.task
        case .event:
            Icon.event
        case .photo:
            Icon.photo
        case .audio:
            Icon.audio
        default:
            EmptyView()
        }
    }

    var tag: Path {
        Path.timelineScreen(timeline: nil, momentType: self)
    }

    @ViewBuilder
    var row: some View {
        HStack {
            leadingTitle
            Spacer()
            trailingTitle
        }.tag(tag)
    }
}
