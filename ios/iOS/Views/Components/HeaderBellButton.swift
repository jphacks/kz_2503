import SwiftUI

public struct HeaderBellButton: View {
    public var action: () -> Void
    public init(action: @escaping () -> Void) { self.action = action }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "bell")          // SF Symbols
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel("通知")
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 44)
    }
}
