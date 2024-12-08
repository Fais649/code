//
//  EventView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.11.24.
//

import SwiftUI

struct EventView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(SharedState.self) private var sharedState
    @State var event: Event
    @State var isEditing: Bool
    @State var isTarget: Bool = false

    var body: some View {
        eventContent
            .dropDestination(for: String.self) { strings, _ in
                withAnimation {
                    print("DROP")
                    guard let movedTodo = strings.first else {
                        return false
                    }

                    dayViewModel.dropTodoOnEvent(event: event, todoUuid: movedTodo)

                    return true
                }
            } isTargeted: { isTargeted in
                isTarget = isTargeted
            }
            .onAppear {
                if event.title.isEmpty && !isEditing {
                    dayViewModel.deleteEventInCalendar(event: event)
                    dayViewModel.refresh()
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                dayViewModel.updateEventInCalendar(event: event)
                sharedState.activateSheet(.main)
            }) {
                EventSheetView(event: event)
                    .presentationBackground {
                        Color.black.ignoresSafeArea()
                    }
                    .presentationCornerRadius(0)
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder private var eventContent: some View {
        DisclosureGroup {
            if event.todos.isEmpty {
                Button("new_todo") {
                    let todo = dayViewModel.newTodo()
                    // sharedState.activateSheet(.editTodo, item: todo)
                    event.todos.append(todo)
                    // sharedState.activateSheet(.editTodo, item: todo)
                    print("NEW_TODO")
                }
            }

            ForEach(event.todos) { todo in
                TodoView(todo: todo, isEditing: todo.title.isEmpty)
            }
        } label: {
            HStack {
                Text(event.title)
                Spacer()
                Text(event.start.formatted(date: .omitted, time: .shortened))
                Text("-")
                Text(event.end.formatted(date: .omitted, time: .shortened))
            }
            .swipeActions {
                deleteButton
            }
            .swipeActions(edge: .leading) {
                editButton
            }
        }
    }

    @ViewBuilder private var editButton: some View {
        Button {
            print("LOL")
            isEditing = true
            sharedState.activateSheet(.editEvent, item: event)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
    }

    @ViewBuilder private var deleteButton: some View {
        Button(role: .destructive) {
            for todo in event.todos {
                dayViewModel.deleteTodo(todo: todo)
            }
            dayViewModel.deleteEventInCalendar(event: event)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

struct EventSheetView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(SharedState.self) private var sharedState
    @State var event: Event
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            editForm

            HStack {
                deleteButton
                saveButton
            }
            .padding(.horizontal)
            Spacer()
        }
        .onChange(of: event.start) {
            event.end = event.start.addingTimeInterval(3600)
        }
        .padding()
        .presentationDetents([.fraction(0.3)])
    }

    @ViewBuilder private var editForm: some View {
        VStack {
            DottedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.bottom, 8) // Optional padding between line and content

            TextField("title;", text: $event.title)
                .padding()
                .focused($focusedField, equals: .event)
            DatePicker("start:", selection: $event.start)
            DatePicker("end:", selection: $event.end)
        }
        .onAppear {
            focusedField = .event
        }
        .padding()
    }

    @ViewBuilder private var deleteButton: some View {
        Button(role: .destructive) {
            dayViewModel.deleteEventInCalendar(event: event)
            sharedState.activateSheet(.main)
        } label: {
            Spacer()
            Label("", systemImage: "trash")
            Spacer()
        }
        .buttonStyle(.borderedProminent)
        .foregroundStyle(.black)
    }

    @ViewBuilder private var saveButton: some View {
        Button {
            dayViewModel.updateEventInCalendar(event: event)
            sharedState.activateSheet(.main)
        } label: {
            Spacer()
            Label("", systemImage: "square.and.arrow.down")
            Spacer()
        }
        .buttonStyle(.borderedProminent)
        .foregroundStyle(.black)
    }
}
