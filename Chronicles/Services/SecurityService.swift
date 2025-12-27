//
//  SecurityService.swift
//  Chronicles
//
//  Security service for Face ID/Touch ID and passcode protection
//

import Foundation
import LocalAuthentication
import Combine

// MARK: - Security Service

class SecurityService: ObservableObject {
    static let shared = SecurityService()
    
    @Published var isSecurityEnabled = false
    @Published var isLocked = false
    @Published var biometryType: LABiometryType = .none
    @Published var canUseBiometrics = false
    
    private let context = LAContext()
    
    private init() {
        loadPreferences()
        checkBiometryAvailability()
    }
    
    // MARK: - Preferences
    
    private func loadPreferences() {
        isSecurityEnabled = UserDefaults.standard.bool(forKey: "securityEnabled")
        
        // Lock the app if security is enabled
        if isSecurityEnabled {
            isLocked = true
        }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(isSecurityEnabled, forKey: "securityEnabled")
    }
    
    // MARK: - Biometry Check
    
    func checkBiometryAvailability() {
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometryType = context.biometryType
    }
    
    var biometryName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }
    
    var biometryIcon: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }
    
    // MARK: - Enable/Disable Security
    
    func enableSecurity() async -> Bool {
        // Authenticate first to enable
        let authenticated = await authenticate(reason: "Enable app lock")
        
        if authenticated {
            await MainActor.run {
                isSecurityEnabled = true
                savePreferences()
            }
        }
        
        return authenticated
    }
    
    func disableSecurity() async -> Bool {
        // Authenticate first to disable
        let authenticated = await authenticate(reason: "Disable app lock")
        
        if authenticated {
            await MainActor.run {
                isSecurityEnabled = false
                isLocked = false
                savePreferences()
            }
        }
        
        return authenticated
    }
    
    // MARK: - Authentication
    
    func authenticate(reason: String = "Unlock Chronicles") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        
        var error: NSError?
        
        // Check if biometrics or passcode is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                await MainActor.run {
                    isLocked = false
                }
            }
            
            return success
        } catch {
            return false
        }
    }
    
    // MARK: - Lock App
    
    func lockApp() {
        if isSecurityEnabled {
            isLocked = true
        }
    }
    
    func unlockApp() async -> Bool {
        guard isLocked else { return true }
        return await authenticate()
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidBecomeActive() {
        // Check if we need to lock
        if isSecurityEnabled && isLocked {
            // App is already locked, will need authentication
        }
    }
    
    func handleAppWillResignActive() {
        // Lock the app when going to background
        if isSecurityEnabled {
            isLocked = true
        }
    }
}

// MARK: - Security Error

enum SecurityError: LocalizedError {
    case biometryNotAvailable
    case authenticationFailed
    case passcodeNotSet
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .passcodeNotSet:
            return "Please set a passcode in Settings to use this feature."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

