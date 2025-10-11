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
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var resultType: ResultType = .none
    
    private let checkAccountRepository = CheckAccountRepository()
    
    enum ResultType {
        case none
        case success
        case accountNotFound
        case error
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
            showResult(message: "アカウントが見つかりました。ユーザーID: \(userId)", type: .success)
            
        case .accountNotFound(let message):
            showResult(message: message, type: .accountNotFound)
            
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
}
