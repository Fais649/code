import SwiftUI
import KVKCalendar

struct ContentView: View {
    @State var date: Date = Date()
    @State var showDatePicker: Bool = false
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Spacer()
        }
        
        VStack {
            
            DatePicker("DATE", selection: $date,displayedComponents: .date).accessibilityAddTraits([.isButton, .isHeader]).datePickerStyle(.graphical).labelsHidden().accessibilityLabel(/*@START_MENU_TOKEN@*/"Label"/*@END_MENU_TOKEN@*/).accessibilityIdentifier(/*@START_MENU_TOKEN@*/"Identifier"/*@END_MENU_TOKEN@*/)
            
            Text("Hello, world!")
            
        }.border(.black)
    }
}
