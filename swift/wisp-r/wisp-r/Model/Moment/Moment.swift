import SwiftData
import SwiftUI

@Model
final class Moment: Identifiable, Enterable {
    init(
        day: Day? = nil,
        pinned: Bool = false,
        position: Int,
        text: String = "",
        parent: Moment? = nil,
        children: [Moment] = []
    ) {
        self.day = day
        self.pinned = pinned
        self.position = position
        self.text = text
        self.parent = parent
        self.children = children
        self.createdAt = Date()
    }

    @Attribute(.unique)
    var id: UUID = UUID()
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var timeline: Timeline? = nil

    @Relationship(deleteRule: .nullify, inverse: \Day.moments)
    var day: Day? = nil

    var position: Int = 0
    var parent: Moment? = nil

    @Relationship(deleteRule: .cascade, inverse: \Moment.parent)
    var children: [Moment] = []

    var text: String = ""
    var pinned: Bool = false

    var foregroundColor: Color {
        timeline?.foregroundColor ?? Default.foregroundColor
    }

    var color: Color {
        timeline?.color ?? Default.color
    }

    var isTask: Bool = false
    var isCompleted: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Location.moments)
    var location: Location?

    @Relationship(deleteRule: .cascade, inverse: \Event.moment)
    var event: Event? = nil

    var isEvent: Bool {
        event != nil
    }

    @Relationship(deleteRule: .cascade)
    var images: Images? = nil

    @Relationship(deleteRule: .cascade)
    var audio: Audio? = nil
}
