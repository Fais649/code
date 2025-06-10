import SwiftData
import SwiftUI

struct DaysScreen: View {
    @Environment(\.modelContext) var modelContext
    @State private var broadcaster: BroadcasterService = .init()
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Day.date) var days: [Day]

    @State private var loaded: Bool = false
    @State private var showDatePicker: Bool = false
    var initialDate: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var longPressHapticTrigger: Bool = false

    func scrollTo(_ date: Date, with proxy: ScrollViewProxy) {
        proxy.scrollTo(Calendar.current.startOfDay(for: date))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .center) {
                    ForEach(days, id: \.date) { day in
                        DayVStack(day: day)
                            .containerRelativeFrame(.horizontal)
                            .opacity(loaded ? 1 : 0)
                    }
                }.scrollTargetLayout()
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .task {
                if let today = days.first(where: { $0.date.isToday }) {
                    RitualStore.generateRecords(for: today, in: modelContext)
                }

                scrollTo(initialDate, with: proxy)
                withAnimation {
                    loaded = true
                }
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    BackButton()

                    Spacer()
                        
                    Button {
                        broadcaster.emit(.createNewEventOnActiveDay)
                    } label: {
                        Image(systemName: "plus")
                    }

                    Spacer()

                    Button {
                        broadcaster.emit(
                            .showDatePickerSheet { newDate in
                                withAnimation {
                                    scrollTo(newDate, with: proxy)
                                }
                            })
                    } label: {
                        Icon.day
                            .sensoryFeedback(.success, trigger: longPressHapticTrigger)
                            .onLongPressGesture {
                                withAnimation {
                                    longPressHapticTrigger.toggle()
                                    scrollTo(Date(), with: proxy)
                                }
                            }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .environment(broadcaster)
        .foregroundStyle(Default.foregroundColor)
        .tint(Default.foregroundColor)
        .toolbarBackgroundVisibility(.hidden, for: .bottomBar)
    }
}
