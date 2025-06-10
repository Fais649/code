import SwiftData
import SwiftUI

struct MomentRow: View {
    @Binding var sheetMoment: Moment?
    let moment: Moment
    var prefix: Int = 5

    var remainder: Int {
        moment.children.count - prefix
    }

    var body: some View {
        Button {
            sheetMoment = moment
        } label: {
            VStack(spacing: Spacing.zero) {
                ZStack {
                    if let images = moment.images {
                        MomentImageRow(images: images)
                            .clipped()
                    }

                    VStack(alignment: .leading, spacing: Spacing.zero) {
                        if moment.images != nil {
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: Spacing.s) {
                            HStack {
                                if moment.isTask {
                                    Button {
                                        moment.isCompleted.toggle()

                                        for c in moment.children {
                                            c.isCompleted = moment.isCompleted
                                        }
                                    } label: {
                                        Image(
                                            systemName: moment.isCompleted
                                                ? "square.fill" : "square")
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(moment.text)
                                Spacer()

                                if let event = moment.event, !event.isAllDay {
                                    VStack(spacing: 0) {
                                        Text(event.startTimeString)
                                        Text(event.endTimeString)
                                    }
                                }
                            }
                            ForEach(
                                moment.children
                                    .sorted { a, b in
                                        if a.isCompleted == b.isCompleted {
                                            return a.position < b.position
                                        }
                                        return !a.isCompleted
                                    }
                                    .prefix(prefix)
                            ) { child in
                                HStack {
                                    if child.isTask {
                                        Button {
                                            child.isCompleted.toggle()
                                        } label: {
                                            Image(
                                                systemName: child.isCompleted
                                                    ? "square.fill" : "square.dotted")
                                        }.buttonStyle(.plain)
                                    }
                                    Text(child.text)
                                    Spacer()
                                }
                            }

                            if moment.audio != nil {
                                Image(systemName: "play.circle.fill")
                            }

                            if remainder > 0 {
                                HStack {
                                    Spacer()
                                    Text("+ \(remainder)")
                                }
                            }
                        }
                        .background {
                            if moment.images != nil {
                                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                            }
                        }
                    }
                }
            }
        }
        .foregroundStyle(moment.foregroundColor)
        .listRowBackground(Default.rowBackground(for: moment.color))
        .animation(.smooth, value: moment.images == nil)
    }
}
