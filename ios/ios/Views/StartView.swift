//
//  StartView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct StartView: View {
    @StateObject private var viewModel = StartViewModel()
    
    var body: some View {
        NavigationStack {
        VStack(spacing: 30) {
            Spacer(minLength: 200)
            
            // アプリ名
            Text("WinCook")
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            // 説明文
            Text("新規登録またはログイン")
                .font(.title3)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 8) {
                // 入力欄のラベル
                Text("メールアドレスを入力")
                    .font(.body)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // メールアドレス入力フィールド
                TextField("メールアドレス", text: $viewModel.email)
                    .textFieldStyle(.plain) // 既存のRoundedBorderを外す
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
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                
                // 補足テキスト
                Text("すでにアカウントをお持ちか確認し、お持ちでない場合は新規登録します。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: 310, alignment: .leading)
            }
            .padding(.horizontal, 50)
            
            Spacer()
            
            // 次へボタン
            Button(action: {
                Task {
                    await viewModel.checkAccount()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isLoading ? "確認中..." : "次へ")
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
            
            
            Spacer(minLength: 200)
        }
        .background(Color.white)
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
        .navigationDestination(item: $viewModel.navigationDestination) { destination in
            switch destination {
            case .login(let userId):
                LoginView(userId: userId)
            case .register(let email):
                RegisterView(email: email)
            }
        }
        }
    }
    
    // MARK: - Computed Properties
    private var resultIcon: String {
        switch viewModel.resultType {
        case .success:
            return "checkmark.circle.fill"
        case .accountNotFound:
            return "person.crop.circle.badge.exclamationmark"
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
        case .accountNotFound:
            return .orange
        case .error:
            return .red
        case .none:
            return .clear
        }
    }
}

#Preview {
    StartView()
}
