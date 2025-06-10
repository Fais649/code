import SwiftData
import SwiftUI

enum FocusedField: Hashable {
    case model(UUID)
}

protocol Enterable: PersistentModel {
    var id: UUID { get set }
    var text: String { get set }
}

struct EnterableTextField<M: Enterable>: View {
    enum Refocus {
        case yes, no
    }

    @FocusState.Binding var focused: FocusedField?
    @Bindable var model: M
    let action: (M) -> Refocus

    var body: some View {
        TextField("...", text: $model.text, axis: .vertical)
            .focused($focused, equals: .model(model.id))
            .id(model.id)
            .onChange(of: model.text) { _, newValue in
                guard newValue.contains("\n") else { return }
                model.text = newValue.replacing("\n", with: "")
                switch action(model) {
                case .yes:
                    return
                case .no:
                    focused = nil
                }
            }
            .task {
                if model.text == "" {
                    focused = .model(model.id)
                }
            }
            .preference(
                key: EmptyFocusedKey.self,
                value: focused == .model(model.id) && model.text == ""
            )
    }
}

struct EmptyFocusedKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct FocusedDayKey: PreferenceKey {
    static var defaultValue: Day? = nil
    static func reduce(value: inout Day?, nextValue: () -> Day?) {
        value = nextValue()
    }
}
