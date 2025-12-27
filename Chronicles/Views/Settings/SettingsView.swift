//
//  SettingsView.swift
//  Chronicles
//
//  Settings screen with all app preferences
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var showSignOutAlert = false
    @State private var showTemplates = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Papper.spacing.xl) {
                // Profile Section
                profileSection
                
                // Quick Stats
                statsSection
                
                // Security Section
                securitySection
                
                // Subscription Section
                subscriptionSection
                
                // Templates Section
                templatesSection
                
                // Notifications Section
                notificationsSection
                
                // About Section
                aboutSection
                
                // Sign Out
                signOutSection
            }
            .padding(.horizontal, Papper.spacing.lg)
            .padding(.vertical, Papper.spacing.md)
        }
        .background(Color(hex: "#faf8f3").ignoresSafeArea())
        .navigationTitle("Settings")
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showTemplates) {
            NavigationView {
                TemplatesListView()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(spacing: Papper.spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(PapperColors.neutral100)
                    .frame(width: 80, height: 80)
                
                Text(String(authService.currentUser?.firstName.prefix(1) ?? "U"))
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            // Name & Email
            VStack(spacing: Papper.spacing.xxs) {
                Text(authService.currentUser?.displayName ?? "User")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text(authService.currentUser?.email ?? "")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Papper.spacing.xl)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: Papper.spacing.md) {
            SettingsStatCard(
                icon: "flame.fill",
                value: "\(authService.currentUser?.currentStreak ?? 0)",
                label: "Streak",
                color: PapperColors.neutral700
            )
            
            SettingsStatCard(
                icon: "doc.text.fill",
                value: "\(authService.currentUser?.totalEntries ?? 0)",
                label: "Entries",
                color: PapperColors.neutral700
            )
            
            SettingsStatCard(
                icon: "trophy.fill",
                value: "\(authService.currentUser?.longestStreak ?? 0)",
                label: "Best",
                color: PapperColors.neutral700
            )
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        SettingsSection(title: "Security") {
            NavigationLink(destination: SecuritySettingsView()) {
                SettingsRow(
                    icon: "faceid",
                    title: "App Lock",
                    subtitle: "Face ID & Passcode",
                    showChevron: true
                )
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription") {
            VStack(spacing: Papper.spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: Papper.spacing.xxs) {
                        Text(subscriptionService.isInTrial ? "Free Trial" : "Premium Member")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PapperColors.neutral800)
                        
                        if subscriptionService.isInTrial {
                            Text("\(subscriptionService.currentSubscription?.trialDaysRemaining ?? 0) days remaining")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                        } else {
                            Text("Auto-renews yearly")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                        }
                    }
                    
                    Spacer()
                    
                    Text(subscriptionService.isSubscribed ? "Active" : "Inactive")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(subscriptionService.isSubscribed ? PapperColors.green400 : PapperColors.pink600)
                        .padding(.horizontal, Papper.spacing.sm)
                        .padding(.vertical, 4)
                        .background((subscriptionService.isSubscribed ? PapperColors.green400 : PapperColors.pink600).opacity(0.15))
                        .cornerRadius(8)
                }
                
                Divider()
                    .padding(.vertical, Papper.spacing.xs)
                
                Button(action: {}) {
                    Text("Manage Subscription")
                        .font(Papper.typography.body)
                        .foregroundColor(PapperColors.neutral700)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Templates Section
    
    private var templatesSection: some View {
        SettingsSection(title: "Journal") {
            Button(action: { showTemplates = true }) {
                SettingsRow(
                    icon: "doc.on.doc.fill",
                    title: "Templates",
                    subtitle: "Create and manage templates",
                    showChevron: true
                )
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "sun.horizon.fill",
                    title: "Morning Reminder",
                    subtitle: notificationService.morningReminderTime.timeString,
                    isOn: Binding(
                        get: { notificationService.morningReminderEnabled },
                        set: { notificationService.setMorningReminder(enabled: $0, time: notificationService.morningReminderTime) }
                    )
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsToggleRow(
                    icon: "moon.stars.fill",
                    title: "Evening Reminder",
                    subtitle: notificationService.eveningReminderTime.timeString,
                    isOn: Binding(
                        get: { notificationService.eveningReminderEnabled },
                        set: { notificationService.setEveningReminder(enabled: $0, time: notificationService.eveningReminderTime) }
                    )
                )
            }
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    value: "1.0.0"
                )
                
                Divider()
                    .padding(.leading, 52)
                
                Button(action: {}) {
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        showChevron: true
                    )
                }
                
                Divider()
                    .padding(.leading, 52)
                
                Button(action: {}) {
                    SettingsRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        showChevron: true
                    )
                }
                
                Divider()
                    .padding(.leading, 52)
                
                Button(action: {}) {
                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Contact Support",
                        showChevron: true
                    )
                }
            }
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        Button(action: { showSignOutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(PapperColors.pink600)
            .frame(maxWidth: .infinity)
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .padding(.bottom, Papper.spacing.xl)
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.sm) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(PapperColors.neutral500)
                .padding(.leading, 4)
            
            content
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: Papper.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(PapperColors.neutral800)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral500)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PapperColors.neutral400)
            }
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: Papper.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(PapperColors.neutral800)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(PapperColors.neutral700)
                .labelsHidden()
        }
        .padding(Papper.spacing.md)
    }
}

struct SettingsStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Papper.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(PapperColors.neutral800)
            
            Text(label)
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral600)
        }
        .frame(maxWidth: .infinity)
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
#endif
