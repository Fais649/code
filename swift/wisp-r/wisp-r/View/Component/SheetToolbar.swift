import SwiftData
import SwiftUI

struct SheetToolbar<TopLeading: View, Leading: View, Trailing: View>: View {
    @FocusState.Binding var focused: FocusedField?
    let color: Color

    init(
        focused: FocusState<FocusedField?>.Binding,
        color: Color,
        @ViewBuilder topLeading: @escaping () -> TopLeading,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        _focused = focused
        self.color = color
        self.topLeading = topLeading
        self.leading = leading
        self.trailing = trailing
    }

    @ViewBuilder var topLeading: () -> TopLeading
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                topLeading()
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)

            HStack(spacing: Spacing.ss) {
                leading()
                Spacer()
                trailing()
            }
            .padding(Spacing.m)
            .background(Default.toolbarBackground(for: color))
            .clipShape(.rect(cornerRadius: focused == nil ? Spacing.m : Spacing.zero))
        }
        .padding(focused == nil ? Spacing.m : Spacing.zero)
        .animation(.smooth, value: focused == nil)
    }
}
