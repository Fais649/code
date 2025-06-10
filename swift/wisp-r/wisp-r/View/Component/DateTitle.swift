import SwiftData
import SwiftUI

struct DateTitle: View {
    enum StackStyle {
        case vstack, hstack
    }

    var style: StackStyle = .vstack
    let date: Date

    var formattedDate: String {
        date.formatted(.dateTime.weekday(.short).day().month())
    }

    var relativeDate: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        switch diff {
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        case -1:
            return "Yesterday"
        case let d where d > 1:
            return "In \(d) days"
        case let d where d < -1:
            return "\(-d) days ago"
        default:
            return date.formatted(.dateTime.weekday().day().month())
        }
    }

    @ViewBuilder
    var todayIcon: some View {
        if date.isToday {
            Icon.day
        }
    }

    var body: some View {
        switch style {
        case .hstack:
            HStack {
                Text(relativeDate)
                todayIcon
                Spacer()
                Text(formattedDate)
                Image(systemName: "chevron.right")
            }
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(relativeDate)
                Text(formattedDate)
            }
        }

    }
}
