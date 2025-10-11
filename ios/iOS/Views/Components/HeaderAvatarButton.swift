import SwiftUI

public struct HeaderAvatarButton: View {
    public var action: () -> Void
    public init(action: @escaping () -> Void) { self.action = action }

    public var body: some View {
        Button(action: action) {
            Circle().fill(Color.secondary.opacity(0.15))
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("プロフィール")
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 44)
    }
}
