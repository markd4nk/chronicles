//
//  AuthViewModel.swift
//  Chronicles
//
//  Authentication view model
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUser)
        
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
        
        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
    
    // MARK: - Sign In
    
    func signInWithGoogle() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                self.error = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func signInWithApple() {
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                self.error = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        authService.signOut()
    }
    
    // MARK: - User Updates
    
    func updatePreferredName(_ name: String) {
        guard var user = currentUser else { return }
        user.preferredName = name
        
        Task {
            try? await authService.updateUser(user)
        }
    }
}

