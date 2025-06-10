import SwiftUI

struct DatePickerSheetButton: View {
    @State private var showDatePicker: Bool = false
    @State var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var onSelectDate: (_ showDatePicker: Binding<Bool>, _ selectedDate: Date) -> Void

    var body: some View {
        Button {
            showDatePicker.toggle()
        } label: {
            Image(systemName: "diamond.fill")
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: selectedDate) { date in
                onSelectDate($showDatePicker, date)
            }
        }
    }
}
