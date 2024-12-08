//
//  TodoView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.11.24.
//

import SwiftUI

struct TodoView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(SharedState.self) private var sharedState
    @State var todo: Todo
    @State var isEditing: Bool
    var todoRecord: TodoRecord {
        return TodoRecord(todo: todo)
    }

    var body: some View {
        checkBox
            .swipeActions {
                deleteButton
            }
            .swipeActions(edge: .leading) {
                editButton
            }
            .onAppear {
                if todo.title.isEmpty && !isEditing {
                    dayViewModel.deleteTodo(todo: todo)
                    dayViewModel.refresh()
                    return
                }

                if todo.title.isEmpty {
                    isEditing = true
                    sharedState.activateSheet(.editTodo, item: todo)
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                if todo.title.isEmpty, isEditing {
                    dayViewModel.deleteTodo(todo: todo)
                    dayViewModel.refresh()
                }
                save()
                sharedState.activateSheet(.main)
            }) {
                TodoSheet(todo: $todo)
                    .presentationDetents([.fraction(0.15)])
                    .presentationCornerRadius(0)
                    .presentationBackground {
                        Color.black.ignoresSafeArea()
                    }
                    .padding()
            }
    }

    func save() {
        if todo.title.isEmpty {
            dayViewModel.deleteTodo(todo: todo)
        }
        sharedState.activateSheet(.main)
    }

    @ViewBuilder private var checkBox: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: {
                withAnimation {
                    todo.done.toggle()
                }
            }) {
                Image(systemName: todo.done ? "circle.fill" : "circle.dotted")
            }

            Text(todo.title)
                .padding(.leading, 5)
            Spacer()
        }
        .draggable(todoRecord.uuid.uuidString)
    }

    @ViewBuilder private var editButton: some View {
        Button {
            isEditing = true
            sharedState.activateSheet(.editTodo, item: todo)
        } label: {
            Label("", systemImage: "pencil")
        }
    }

    @ViewBuilder private var deleteButton: some View {
        Button(role: .destructive) {
            dayViewModel.deleteTodo(todo: todo)
        } label: {
            Label("", systemImage: "trash")
        }
    }
}

struct TodoSheet: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(SharedState.self) private var sharedState
    @Binding var todo: Todo
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            DottedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            TextField("new_todo;", text: $todo.title)
                .focused($focusedField, equals: .todo)
                .padding()

            HStack {
                deleteButton
                saveButton
            }
        }.onAppear {
            focusedField = .todo
        }
        .padding()
    }

    @ViewBuilder private var deleteButton: some View {
        Button(role: .destructive) {
            dayViewModel.deleteTodo(todo: todo)
            dayViewModel.refresh()
            sharedState.activateSheet(.main)
        } label: {
            Spacer()
            Label("", systemImage: "trash")
            Spacer()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder private var saveButton: some View {
        Button {
            save()
        } label: {
            Spacer()
            Label("", systemImage: "square.and.arrow.down")
            Spacer()
        }
        .foregroundStyle(.black)
        .buttonStyle(.borderedProminent)
    }

    func save() {
        if todo.title.isEmpty {
            dayViewModel.deleteTodo(todo: todo)
        }
        dayViewModel.refresh()
        sharedState.activateSheet(.main)
    }
}
