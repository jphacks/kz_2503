import SwiftUI

struct MessageRow: View {
    let message: Message
    let onSpeak: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .assistant {
                bubble(message.text, isUser: false, showSpeak: onSpeak != nil)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                bubble(message.text, isUser: true, showSpeak: false)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func bubble(_ text: String, isUser: Bool, showSpeak: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text).font(.body)
            if showSpeak, let onSpeak {
                Button(action: onSpeak) {
                    Label("読み上げ", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isUser ? Color.accentColor : Color.secondary.opacity(0.15))
        )
        .foregroundStyle(isUser ? Color.white : Color.primary)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
    }
}
