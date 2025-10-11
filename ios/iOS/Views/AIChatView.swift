import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()
    
    var body: some View {
        @Bindable var bvm = vm
        
        VStack(spacing: 0) {
            HStack {
                Text("状態: \(vm.availabilityText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            
            List(vm.messages) { msg in
                MessageRow(
                    message: msg,
                    onSpeak: (msg.role == .assistant) ? { vm.speak(msg.text) } : nil
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            
            // 入力バー
            HStack(spacing: 8) {
                TextField("メッセージを入力", text: $bvm.input, axis: .vertical)
                    .padding(10)
                Button { Task { await vm.send() } } label: {
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
            
                .navigationTitle("Cooking Assistant")
                .onAppear { vm.onAppear() }
                .alert("エラー", isPresented: .constant(vm.errorMessage != nil), actions: {
                    Button("OK") { vm.errorMessage = nil }
                }, message: { Text(vm.errorMessage ?? "") })
        }
    }
}
