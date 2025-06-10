import SwiftData
import SwiftUI

struct SheetBackButton: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState.Binding var focused: FocusedField?
    let anyEmptyFocused: Bool
    let shouldDismiss: () -> Bool
    let shouldDelete: () -> Bool
    let deleteAction: () -> Void

    var body: some View {
        Button {
            if shouldDismiss() {
                dismiss()
                return
            }

            focused = nil
            if shouldDelete() {
                deleteAction()
                dismiss()
            }
        } label: {
            Image(
                systemName:
                    anyEmptyFocused
                    ? "xmark"
                    : focused == nil
                        ? "chevron.down" : "keyboard.chevron.compact.down.fill")
        }
    }
}
