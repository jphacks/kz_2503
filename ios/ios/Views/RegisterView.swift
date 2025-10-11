//
//  RegisterView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct RegisterView: View {
    let email: String
    @StateObject private var viewModel: RegisterViewModel
    
    init(email: String) {
        self.email = email
        self._viewModel = StateObject(wrappedValue: RegisterViewModel(email: email))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 100)
            
            // アプリ名
            Text("WinCook")
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            // タイトル
            Text("新規登録")
                .font(.title2)
                .foregroundColor(.black)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                // パスワード入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("パスワードを入力")
                        .font(.body)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    SecureField("パスワード", text: $viewModel.password)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .frame(maxWidth: 310)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                )
                        )
                }
                
                // 確認用パスワード入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("確認用パスワードを入力")
                        .font(.body)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    SecureField("確認用", text: $viewModel.confirmPassword)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .frame(maxWidth: 310)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                )
                        )
                }
            }
            .padding(.horizontal, 50)
            
            Spacer()
            
            // 新規登録ボタン
            Button(action: {
                Task {
                    await viewModel.register()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isLoading ? "登録中..." : "新規登録")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: 200)
                .frame(height: 50)
                .background(viewModel.isLoading ? Color.gray : Color.theme)
                .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            
            Spacer(minLength: 100)
        }
        .background(Color.white)
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.navigationDestination) { destination in
            switch destination {
            case .profileSetting:
                ProfileSettingView()
            }
        }
        .overlay(
            // 結果表示
            VStack {
                if viewModel.showResult {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: resultIcon)
                                .foregroundColor(resultColor)
                                .font(.title2)
                            
                            Text(viewModel.resultMessage)
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(resultColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(resultColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        Button("閉じる") {
                            viewModel.clearResult()
                        }
                        .font(.caption)
                        .foregroundColor(resultColor)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showResult)
        )
    }
    
    // MARK: - Computed Properties
    private var resultIcon: String {
        switch viewModel.resultType {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .none:
            return ""
        }
    }
    
    private var resultColor: Color {
        switch viewModel.resultType {
        case .success:
            return .green
        case .error:
            return .red
        case .none:
            return .clear
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(email: "user@example.com")
    }
}
