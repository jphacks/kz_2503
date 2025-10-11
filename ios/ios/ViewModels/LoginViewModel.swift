//
//  LoginViewModel.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var resultType: ResultType = .none
    @Published var loginSuccess: Bool = false
    @Published var navigationDestination: NavigationDestination? = nil
    
    private let loginRepository = LoginRepository()
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    enum ResultType {
        case none
        case success
        case error
    }
    
    enum NavigationDestination: Hashable {
        case search
    }
    
    func login() async {
        // バリデーション
        guard !password.isEmpty else {
            showResult(message: "パスワードを入力してください", type: .error)
            return
        }
        
        guard password.count >= 6 else {
            showResult(message: "パスワードは6文字以上で入力してください", type: .error)
            return
        }
        
        isLoading = true
        showResult = false
        
        let result = await loginRepository.login(userId: userId, password: password)
        
        isLoading = false
        
        switch result {
        case .success(let message):
            showResult(message: message, type: .success)
            loginSuccess = true
            // SearchViewに遷移
            navigationDestination = .search
            
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
