//
//  AIChatView.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()

    var body: some View {
        @Bindable var bvm = vm

        VStack(spacing: 0) {
            // 状態表示
            HStack {
                Text("状態: \(vm.availabilityText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            // メッセージリスト
            List(vm.messages) { message in
                MessageRow(
                    message: message,
                    onSpeak: (message.role == .assistant) ? { vm.speak(message.text) } : nil
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))

            // 入力バー
            HStack(spacing: 8) {
                TextField("メッセージを入力", text: $bvm.input, axis: .vertical)
                    .padding(10)
                Button { 
                    Task { await vm.send() } 
                } label: {
                    Image(systemName: "paperplane.fill")
                        .padding(10)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                .disabled(vm.isSending || bvm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            .padding([.horizontal, .bottom])

            Divider()
        }
        .navigationTitle("Cooking Assistant")
        .onAppear { vm.onAppear() }
        .alert("エラー", isPresented: .constant(vm.errorMessage != nil), actions: {
            Button("OK") { vm.clearError() }
        }, message: { 
            Text(vm.errorMessage ?? "") 
        })
    }
}

struct MessageRow: View {
    let message: AIMessage
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

#Preview {
    NavigationStack {
        AIChatView()
    }
}
