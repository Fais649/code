import SwiftData
import SwiftUI

struct RitualRecordButton: View {
    @Namespace var namespace
    let ritualRecord: RitualRecord

    var body: some View {
        SegmentedCircleButton(
            count: ritualRecord.counter.count,
            goal: ritualRecord.counter.goal,
            lineWidth: 4
        ) {
            ritualRecord.counter.stepCount()
        } longPressAction: {
            ritualRecord.counter.reset()
        } label: {
            ritualRecord.symbol
        }
        .sensoryFeedback(.increase, trigger: ritualRecord.counter.count)
        .sensoryFeedback(.success, trigger: ritualRecord.counter.isCompleted)
        .animation(.smooth, value: ritualRecord.counter.count)
    }
}

struct SegmentedCircleButton<Label: View>: View {
    let count: Int
    let goal: Int
    let lineWidth: CGFloat
    let action: () -> Void
    let longPressAction: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        count: Int,
        goal: Int,
        lineWidth: CGFloat = 4,
        action: @escaping () -> Void,
        longPressAction: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.count = count
        self.goal = goal
        self.lineWidth = lineWidth
        self.action = action
        self.longPressAction = longPressAction
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                ForEach(0..<goal, id: \.self) { index in
                    Circle()
                        .trim(
                            from: Double(index) / Double(goal),
                            to: Double(index + 1) / Double(goal)
                        )
                        .stroke(
                            index < count
                                ? Default.foregroundColor
                                : Default.foregroundColor.opacity(0.2),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))  // start at top
                }

                label()
                    .padding(Spacing.sss)
            }
            .onLongPressGesture {
                longPressAction()
            }
        }
        .background(count == goal ? Default.foregroundColor : Color.clear)
        .clipShape(.circle)
    }
}
