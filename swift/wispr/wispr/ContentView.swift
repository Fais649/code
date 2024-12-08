//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.11.24.
//

import SwiftData
import SwiftUI

struct DayView: View {
    @State var conductor: Conductor

    init(modelContext: ModelContext) {
        let cond = Conductor(modelContext: modelContext)
        _conductor = State(initialValue: cond)
    }

    var body: some View {
        ScrollView {
            DayListView(conductor: conductor)
                .environment(conductor)
        }
    }
}

struct DayListView: View {
    @Environment(Conductor.self) var conductor: Conductor
    @Query var primeItems: [Item]

    @State var isTarget: Bool = false

    init(conductor: Conductor) {
        _primeItems = Query(filter: conductor.activeDay.dayPredicate(), sort: \.eventStartDate)
    }

    var body: some View {
        VStack {
            ForEach(primeItems) { item in
                ItemView(item: item)
                    .if(item.type != .event) { view in
                        view.draggable(item.record) {
                            Text("LOl")
                        }
                    }
                    .frame(minHeight: 60)
                    .dropDestination(for: ItemRecord.self) { itemRecords, _ in
                        withAnimation {
                            guard let movedItem = itemRecords.first else {
                                return false
                            }

                            let fromModel = primeItems.first { $0.id == movedItem.id }!
                            let toModel = item
                            fromModel.parent = item

                            let fromIndex = primeItems.firstIndex(of: fromModel)!
                            var toIndex = primeItems.firstIndex(of: toModel)!

                            var localItems: [Item] = primeItems.sorted(by: {
                                $0.orderId < $1.orderId
                            })

                            toIndex = fromIndex < toIndex ? toIndex : toIndex + 1
                            localItems.move(fromOffsets: [fromIndex], toOffset: toIndex)

                            for (index, itm) in localItems.enumerated() {
                                itm.orderId = index
                            }
                            try? conductor.modelContext.save()
                            return true
                        }
                    } isTargeted: { isTargeted in
                        isTarget = isTargeted
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    conductor.activeDay.step(by: -1, type: .day)
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    addItem(.event)
                } label: {
                    Image(systemName: "calendar")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    addItem(.todo)
                } label: {
                    Image(systemName: "checkmark.square")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Text(conductor.activeDay.start.formatted(date: .abbreviated, time: .omitted))
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    conductor.activeDay.step(by: 1, type: .day)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }

    private func addItem(_ type: ItemType) {
        var data = ItemData.todo(Todo())
        if type == .event {
            data = ItemData.event(Event(startDate: Date(), endDate: Date()))
        }

        withAnimation {
            let newItem = Item(
                timestamp: conductor.activeDay.start,
                orderId: try! primeItems.filter(conductor.activeDay.dayPredicate()).count,
                type: type, data: data
            )
            conductor.modelContext.insert(newItem)
            try? conductor.modelContext.save()
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ItemView: View {
    @Environment(Conductor.self) var conductor: Conductor
    @State var item: Item
    @State var showChildren: Bool = false

    var body: some View {
        DisclosureGroup {
            VStack {
                if !item.children.isEmpty {
                    ForEach(item.children.sorted(by: { $0.orderId < $1.orderId })) { child in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black)
                            .frame(minHeight: 40)
                            .overlay {
                                HStack {
                                    Text(child.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    Text("\(child.type.rawValue)::")
                                    Text("\(child.orderId)")
                                }
                                .foregroundStyle(.white)
                            }
                    }
                }
                Button { addChild() } label: {
                    Text("new Child")
                }

            }.padding()
                .foregroundStyle(item.type == .event ? .white : .black)
        } label: {
            HStack {
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                Text(item.data.isEvent ? item.data.event!.startDate.formatted(date: .omitted, time: .shortened) : "NO STARt")
                Spacer()
                Text("\(item.type.rawValue)::")
                Text("\(item.orderId)")
            }
        }.background {
            Color.black.ignoresSafeArea()
        }.disclosureGroupStyle(.automatic)
    }

    private func addChild() {
        let data = ItemData.todo(Todo())
        withAnimation {
            let newItem = Item(
                timestamp: conductor.activeDay.start,
                orderId: item.children.count,
                type: .todo, data: data
            )
            newItem.parent = item
            conductor.modelContext.insert(newItem)
            try? conductor.modelContext.save()

            item.children.append(newItem)
        }
    }
}
