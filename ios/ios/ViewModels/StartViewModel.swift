//
//  StartViewModel.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StartViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var resultType: ResultType = .none
    @Published var navigationDestination: NavigationDestination? = nil
    
    private let checkAccountRepository = CheckAccountRepository()
    
    enum ResultType {
        case none
        case success
        case accountNotFound
        case error
    }
    
    enum NavigationDestination: Hashable {
        case login(userId: String)
        case register(email: String)
    }
    
    func checkAccount() async {
        guard !email.isEmpty else {
            showResult(message: "メールアドレスを入力してください", type: .error)
            return
        }
        
        isLoading = true
        showResult = false
        
        let result = await checkAccountRepository.checkAccount(email: email)
        
        isLoading = false
        
        switch result {
        case .success(let userId):
            // アカウントが存在する場合、ログイン画面に遷移
            navigationDestination = .login(userId: userId)
            
        case .accountNotFound(let message):
            // アカウントが存在しない場合、新規登録画面に遷移
            navigationDestination = .register(email: email)
            
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
