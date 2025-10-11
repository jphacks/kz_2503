//
//  LoginView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    
    var body: some View {
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
                TextField("メールアドレス", text: $email)
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
                // TODO: 次へボタンのアクション
            }) {
                Text("次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .frame(height: 50)
                    .background(Color.theme)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            
            
            Spacer(minLength: 200)
        }
        .background(Color.white)
    }
}

#Preview {
    LoginView()
}

