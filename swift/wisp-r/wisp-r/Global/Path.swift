import Foundation

enum Path: Hashable {
    case daysScreen(_ date: Date = Date())
    case pinnedScreen
    case timelineScreen(timeline: Timeline?, momentType: MomentType = .all)
    case navigationListScreen, settingsScreen
}
