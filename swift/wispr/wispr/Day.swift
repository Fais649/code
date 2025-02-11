//
//  Day.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 02.02.25.
//

import AudioKit
import EventKit
import PhotosUI
import SwiftData
import SwiftUI
import SwiftWhisper
import WidgetKit

struct Day: Identifiable, Hashable {
    var id: UUID = .init()
    var date: Date
    var offset: Int
    var items: [Item] = []

    init(offset: Int, date: Date = Date()) {
        self.offset = offset
        let cal = Calendar.current
        self.date = cal.startOfDay(for: date)
    }

    var itemPredicate: Predicate<Item> {
        let start = date
        let end = date.advanced(by: 86400)
        return #Predicate<Item> { start <= $0.timestamp && end > $0.timestamp }
    }
}

struct DayHeader: View {
    let date: Date
    let isEmpty: Bool

    var body: some View {
        HStack {
            Text(DateTimeString.leftDateString(date: date))
                .fixedSize()
                .frame(alignment: .leading)
            RoundedRectangle(cornerRadius: 2).frame(height: 1)
            Text(DateTimeString.rightDateString(date: date))
                .fixedSize()
                .frame(alignment: .trailing)
            Spacer()
        }
        .tint(isEmpty ? .gray : .white)
        .opacity(isEmpty ? 0.7 : 1)
        .scaleEffect(isEmpty ? 0.8 : 1, anchor: .trailing)
        .truncationMode(.middle)
        .lineLimit(1)
    }
}

enum NavDestination: String, CaseIterable {
    case day, timeline
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)

    DayDetails(date: Date())
        .modelContainer(container)
        .preferredColorScheme(.dark)
        .background(.black)
}

struct DayDetails: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor

    @Environment(\.editMode) private var editMode
    @State var isEditing: Bool = false

    @Namespace var namespace

    @State var date: Date
    @Query var items: [Item]

    var start: Date {
        Calendar.current.startOfDay(for: date)
    }

    var end: Date {
        start.advanced(by: 86400)
    }

    init(date: Date) {
        self.date = date
    }

    var dayItems: [Item] {
        items.filter { start <= $0.timestamp && $0.timestamp < end && $0.parent == nil }.sorted(by: { $0.position < $1.position })
    }

    @State var path: [NavDestination] = []
    @FocusState var toolbarFocus: Bool

    @State var newTaskLinkActive = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if !conductor.isEditingItem {
                    HStack {
                        Image("Logo")
                            .resizable() // Make the image resizable if needed
                            .scaledToFit() // Adjust the content mode
                            .frame(width: 30, height: 30) // Set desired frame
                    }
                }

                VStack {
                    ItemList(items: dayItems)
                        .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                }
                .overlay {
                    if conductor.isEditingItem || SharedState.editItem != nil {
                        VStack {
                            Button {
                                toolbarFocus = false
                                conductor.editItem = nil
                                SharedState.editItem = nil
                            } label: {
                                Color.clear
                            }
                        }
                    }
                }

                toolBar.focused($toolbarFocus)
            }
            .matchedTransitionSource(id: date, in: namespace)
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .timeline:
                    TimeLineView(path: $path, date: $date)
                        .navigationBarBackButtonHidden()
                        .navigationTransition(.zoom(sourceID: date, in: namespace))
                case .day:
                    self
                }
            }
        }
        .font(.custom("GohuFont11NFM", size: 16))
    }

    @ViewBuilder
    var toolBar: some View {
        VStack {
            TopToolbar(
                path: $path,
                date: $date,
                position: items.count
            )

            HStack {
                BottomToolbar(
                    path: $path,
                    date: $date,
                    itemCount: items.count
                ).onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }.padding()
            .tint(.white)
    }

    var dateTime: Date {
        var comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
        comps.hour = Calendar.current.component(.hour, from: Date())
        comps.minute = Calendar.current.component(.minute, from: Date())
        return Calendar.current.date(from: comps) ?? date
    }

    func dateString(date: Date) -> String {
        return date.formatted(.dateTime.weekday(.wide).day().month().year())
    }
}

struct TopToolbar: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var path: [NavDestination]
    @Binding var date: Date
    let position: Int

    var body: some View {
        if   conductor.isEditingItem || SharedState.editItem != nil {
            HStack {
                EditItemForm(
                    item: SharedState.editItem ?? conductor.editItem ??  createNewItem(),
                    date: $date
                )
            }.transition(.push(from: .bottom))
                .opacity(conductor.showDatePicker ? 0 : 1)
                .onDisappear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }

        if conductor.showDatePicker {
            HStack {
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
        }
    }
    
    func createNewItem() -> Item {
        let d = date
        var comps = Calendar.current.dateComponents([.day, .month, .year], from: d)
        comps.hour = Calendar.current.component(.hour, from: Date())
        comps.minute = Calendar.current.component(.minute, from: Date())
        let timestamp = Calendar.current.date(from: comps) ?? d
        
        let newItem = Item(
            position: position,
            timestamp: timestamp
        )
        
        withAnimation {
            conductor.editItem = newItem
        }
        
        return newItem
    }
}

struct BottomToolbar: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var path: [NavDestination]
    @Binding var date: Date
    let itemCount: Int

    @State var newItemLink = false

    var body: some View {
        HStack {
            if !conductor.isEditingItem {
                NavigationLink(value: NavDestination.timeline) {
                    Image(systemName: "calendar.day.timeline.left")
                }.onChange(of: date) {
                    path.removeAll()
                }
            }

            Spacer()

            Button {
                withAnimation {
                    date = Calendar.current.startOfDay(for: date.advanced(by: -86400))
                }
            } label: {
                Image(systemName: "chevron.left")
            }.padding(.horizontal)

            Button {
                withAnimation {
                    conductor.showDatePicker.toggle()
                }
            } label: {
                Spacer()
                header
                Spacer()
            }.onChange(of: date) {
                WidgetCenter.shared.reloadAllTimelines()
            }

            Button {
                withAnimation {
                    date = Calendar.current.startOfDay(for: date.advanced(by: 86400))
                }
            } label: {
                Image(systemName: "chevron.right")
            }.padding(.horizontal)

            Spacer()

            if !conductor.isEditingItem {
                Button {
                    createNewItem()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .padding()
        .padding(.horizontal, 50)
        .tint(.white)
    }

    func createNewItem() {
        let d = date
        var comps = Calendar.current.dateComponents([.day, .month, .year], from: d)
        comps.hour = Calendar.current.component(.hour, from: Date())
        comps.minute = Calendar.current.component(.minute, from: Date())
        let timestamp = Calendar.current.date(from: comps) ?? d

        let newItem = Item(
            position: itemCount,
            timestamp: timestamp
        )

        withAnimation {
            conductor.editItem = newItem
        }
    }

    @ViewBuilder
    var header: some View {
        HStack {
            headerLeft
            headerCenter
            headerRight
        }
        .padding(.horizontal)
        .lineLimit(1)
    }

    @ViewBuilder
    var headerLeft: some View {
        Text(DateTimeString.leftDateString(date: date))
            .fixedSize()
            .frame(alignment: .leading)
    }

    var headerCenter: some View {
        RoundedRectangle(cornerRadius: 2).frame(height: 1)
    }

    @ViewBuilder
    var headerRight: some View {
        Text(DateTimeString.rightDateString(date: date))
            .frame(alignment: .trailing)
            .fixedSize()
    }
}
