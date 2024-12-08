//
//  Models.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.11.24.
//

import EventKit
import Foundation
import SwiftData
import SwiftUI

@Model
final class Day: Identifiable {
    var id = UUID()
    var timestamp: Date
    @Relationship var todos: [Todo] = []
    @Relationship var events: [Event] = []
    @Relationship var note: Note

    init(timestamp: Date) {
        self.timestamp = timestamp
        note = Note(title: "", text: "")
    }
}

protocol Item {
    var title: String { get set }
    var uuid: UUID { get set }
}

class TodoRecord: Identifiable, Codable, Transferable {
    var id: UUID
    var uuid: UUID
    var timestamp: Date
    var title: String
    var done: Bool = false

    init(todo: Todo) {
        id = todo.id
        uuid = todo.uuid
        timestamp = todo.timestamp
        title = todo.title
        done = todo.done
    }

    enum CodingKeys: CodingKey {
        case id, uuid, timestamp, title, done
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        title = try container.decode(String.self, forKey: .title)
        done = try container.decode(Bool.self, forKey: .done)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(title, forKey: .title)
        try container.encode(done, forKey: .done)
    }
}

@Model
class Todo: Identifiable, Item {
    var id: UUID = UUID()
    var uuid: UUID = UUID()
    var timestamp: Date
    var title: String
    var done: Bool = false
    @Relationship var event: Event?

    init(timestamp: Date, title: String = "") {
        self.timestamp = timestamp
        self.title = title
    }
}

@Model
final class Event: Identifiable, Item {
    var id: String { eventIdentifier }
    var uuid = UUID()
    var eventIdentifier: String
    var start: Date
    var end: Date
    var title: String
    @Relationship(inverse: \Todo.event) var todos: [Todo] = []

    init(eventIdentifier: String, start: Date, end: Date, title: String) {
        self.start = start
        self.end = end
        self.title = title
        self.eventIdentifier = eventIdentifier
    }
}

@Model
final class Note {
    var title: String
    var text: String

    init(title: String = "", text: String = "") {
        self.title = title
        self.text = text
    }
}

@Model
final class User {
    @Relationship var activeCalendars: [ActiveCalendar] = []
    var showCompleted: Bool = true
    var showDone: Bool = true

    init() {}
}

@Model
final class ActiveCalendar {
    var id: UUID = UUID()
    var title: String
    var calendarIdentifier: String
    var sourceTitle: String

    init(calendar: EKCalendar) {
        title = calendar.title
        calendarIdentifier = calendar.calendarIdentifier
        sourceTitle = calendar.source.title
    }
}

// @Model
// final class Theme {
//     var id: UUID = UUID()
//     var backgroundColor: String
//     var primaryColor: String
//     var secondaryColor: String
//     var accentColor: String
//
//     init(backgroundColor: String, primaryColor: String, secondaryColor: String, accentColor: String) {
//         self.backgroundColor = backgroundColor
//         self.primaryColor = primaryColor
//         self.secondaryColor = secondaryColor
//         self.accentColor = accentColor
//     }
// }
