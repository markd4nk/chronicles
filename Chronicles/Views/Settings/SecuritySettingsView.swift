//
//  SecuritySettingsView.swift
//  Chronicles
//
//  Security settings for Face ID/Touch ID and passcode
//

import SwiftUI

struct SecuritySettingsView: View {
    @StateObject private var securityService = SecurityService.shared
    @State private var isEnabling = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Papper.spacing.xl) {
                    // Header
                    headerSection
                    
                    // Toggle
                    toggleSection
                    
                    // Info
                    infoSection
                }
                .padding(Papper.spacing.lg)
            }
        }
        .navigationTitle("App Lock")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Papper.spacing.lg) {
            ZStack {
                Circle()
                    .fill(PapperColors.neutral100)
                    .frame(width: 100, height: 100)
                
                Image(systemName: securityService.biometryIcon)
                    .font(.system(size: 44))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            VStack(spacing: Papper.spacing.xs) {
                Text(securityService.biometryName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Protect your journal with \(securityService.biometryName)")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Papper.spacing.lg)
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Require \(securityService.biometryName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text("When opening the app")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral600)
                }
                
                Spacer()
                
                if isEnabling {
                    ProgressView()
                        .tint(PapperColors.neutral700)
                } else {
                    Toggle("", isOn: Binding(
                        get: { securityService.isSecurityEnabled },
                        set: { newValue in
                            toggleSecurity(newValue)
                        }
                    ))
                    .tint(PapperColors.neutral700)
                    .labelsHidden()
                }
            }
            .padding(Papper.spacing.md)
        }
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            Text("HOW IT WORKS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(PapperColors.neutral500)
                .padding(.leading, 4)
            
            VStack(spacing: Papper.spacing.sm) {
                InfoRow(
                    icon: "lock.fill",
                    title: "Automatic Lock",
                    description: "App locks when you leave or close it"
                )
                
                InfoRow(
                    icon: "faceid",
                    title: "Quick Unlock",
                    description: "Use \(securityService.biometryName) or your device passcode"
                )
                
                InfoRow(
                    icon: "shield.fill",
                    title: "System Security",
                    description: "Uses your device's built-in security"
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSecurity(_ enabled: Bool) {
        isEnabling = true
        
        Task {
            var success: Bool
            
            if enabled {
                success = await securityService.enableSecurity()
            } else {
                success = await securityService.disableSecurity()
            }
            
            if !success {
                errorMessage = "Authentication failed. Please try again."
                showError = true
            }
            
            isEnabling = false
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            ZStack {
                Circle()
                    .fill(PapperColors.neutral100)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(PapperColors.neutral800)
                
                Text(description)
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral600)
            }
            
            Spacer()
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#if DEBUG
struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecuritySettingsView()
        }
    }
}
#endif
