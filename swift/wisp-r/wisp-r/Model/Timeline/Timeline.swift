import SwiftData
import SwiftUI

@Model
final class Timeline: Identifiable, Enterable {
    init(
        name: String = "", parent: Timeline? = nil, children: [Timeline] = [],
        color: Color = .gray
    ) {
        self.name = name
        self.parent = parent
        self.children = children
        self.colorHex = color.toHexString
    }

    var text: String {
        get { name }
        set { name = newValue }
    }

    @Attribute(.unique)
    var id: UUID = UUID()
    var name: String = ""
    var parent: Timeline? = nil

    @Relationship(deleteRule: .cascade, inverse: \Timeline.parent)
    var children: [Timeline] = []
    var colorHex: String = ""

    func setColor(_ color: Color) {
        colorHex = color.toHexString
    }

    var color: Color {
        Color(hex: colorHex)
    }

    var foregroundColor: Color {
        Default.foregroundColor(for: color)
    }

    var background: some View {
        Rectangle().fill(color.tertiary)
    }

    var leadingTitle: some View {
        if let p = parent {
            Text("/ \(p.name) / \(name)")
        } else {
            Text("/ \(name) /*")
        }
    }

    var trailingTitle: some View {
        //Todo: Add Symbols
        EmptyView()
    }

    @ViewBuilder
    var row: some View {
        if children.isNotEmpty {
            DisclosureGroup {
                ForEach(self.children) { child in
                    Text(child.text)
                }
            } label: {
                Text(text)
            }
            .tag(Path.timelineScreen(timeline: self, momentType: .all))
            .listRowBackground(background)
        } else {
            Text(text)
                .tag(Path.timelineScreen(timeline: self, momentType: .all))
                .listRowBackground(background)
        }
    }
}
