//
//  RegisterViewModel.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var resultType: ResultType = .none
    @Published var registrationSuccess: Bool = false
    @Published var navigationDestination: NavigationDestination? = nil
    
    private let registerRepository = RegisterRepository()
    private let userIdRepository = UserIdRepository()
    let email: String
    private let defaultUsername = "名無し"
    
    init(email: String) {
        self.email = email
    }
    
    enum ResultType {
        case none
        case success
        case error
    }
    
    enum NavigationDestination: Hashable {
        case profileSetting
    }
    
    func register() async {
        // バリデーション
        guard !password.isEmpty else {
            showResult(message: "パスワードを入力してください", type: .error)
            return
        }
        
        guard !confirmPassword.isEmpty else {
            showResult(message: "確認用パスワードを入力してください", type: .error)
            return
        }
        
        guard password == confirmPassword else {
            showResult(message: "パスワードが一致しません", type: .error)
            return
        }
        
        guard password.count >= 6 else {
            showResult(message: "パスワードは6文字以上で入力してください", type: .error)
            return
        }
        
        isLoading = true
        showResult = false
        
        let result = await registerRepository.register(
            username: defaultUsername,
            password: password,
            email: email
        )
        
        isLoading = false
        
        switch result {
        case .success(let userId):
            // ユーザーIDをSwiftDataに保存
            userIdRepository.saveUserId(userId)
            showResult(message: "新規登録が完了しました！ユーザーID: \(userId)", type: .success)
            registrationSuccess = true
            // プロフィール設定画面に遷移
            navigationDestination = .profileSetting
            
        case .error(let message):
            showResult(message: message, type: .error)
        }
    }
    
    private func showResult(message: String, type: ResultType) {
        resultMessage = message
        resultType = type
        showResult = true
    }
    
    func clearResult() {
        showResult = false
        resultMessage = ""
        resultType = .none
    }
    
    func resetNavigation() {
        navigationDestination = nil
    }
}
