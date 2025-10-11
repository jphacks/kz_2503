//
//  ProfileSettingView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct ProfileSettingView: View {
    @StateObject private var viewModel: ProfileSettingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        self._viewModel = StateObject(wrappedValue: ProfileSettingViewModel())
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer(minLength: 100)
            
            // タイトル
            Text("プロフィールを作成")
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Spacer()
            
            VStack(spacing: 30) {
                // プロフィール画像
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        // カメラアイコン
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 8, y: 8)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                    .onTapGesture {
                        // TODO: 画像選択機能を実装
                    }
                }
                
                // ニックネーム入力
                VStack(spacing: 8) {
                    HStack {
                        TextField("ニックネーム", text: $viewModel.nickname)
                            .font(.body)
                            .foregroundColor(.black)
                            .textFieldStyle(.plain)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            // はじめるボタン
            Button(action: {
                Task {
                    await viewModel.updateProfile()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isLoading ? "更新中..." : "はじめる")
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
        .navigationTitle("プロフィール設定")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.navigationDestination) { destination in
            switch destination {
            case .search:
                SearchView()
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
        ProfileSettingView()
    }
}
