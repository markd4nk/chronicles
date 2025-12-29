//
//  PaywallView.swift
//  Chronicles
//
//  Subscription paywall with plan selection
//

import SwiftUI

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: Subscription.PlanType = .yearly
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Papper.spacing.xl) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(PapperColors.neutral400)
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    
                    // Header
                    VStack(spacing: Papper.spacing.md) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(PapperColors.neutral700)
                        
                        Text("Unlock Chronicles")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(PapperColors.neutral800)
                        
                        Text("Start your journaling journey with\na 3-day free trial")
                            .font(Papper.typography.body)
                            .foregroundColor(PapperColors.neutral600)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Features
                    VStack(spacing: Papper.spacing.sm) {
                        ForEach(SubscriptionFeature.features) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    
                    // Plan Selection
                    VStack(spacing: Papper.spacing.sm) {
                        PlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            action: { selectedPlan = .yearly }
                        )
                        
                        PlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            action: { selectedPlan = .monthly }
                        )
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    
                    // Subscribe Button
                    VStack(spacing: Papper.spacing.md) {
                        Button(action: subscribe) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                VStack(spacing: 2) {
                                    Text("Start Free Trial")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("3 days free, then \(selectedPlan.price)/\(selectedPlan == .yearly ? "year" : "month")")
                                        .font(.system(size: 12))
                                        .opacity(0.9)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(PapperColors.neutral700)
                        .cornerRadius(14)
                        .disabled(isLoading)
                        
                        // Restore Purchases
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PapperColors.neutral600)
                        }
                        
                        // Terms
                        Text("Cancel anytime. Subscription auto-renews.")
                            .font(.system(size: 11))
                            .foregroundColor(PapperColors.neutral500)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.bottom, Papper.spacing.xxxl)
                }
            }
        }
    }
    
    private func subscribe() {
        isLoading = true
        
        Task {
            do {
                try await subscriptionService.startFreeTrial()
                dismiss()
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                try await subscriptionService.restorePurchases()
                if subscriptionService.isSubscribed {
                    dismiss()
                }
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: SubscriptionFeature
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            ZStack {
                Circle()
                    .fill(PapperColors.neutral100)
                    .frame(width: 40, height: 40)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundColor(PapperColors.neutral600)
            }
            
            Spacer()
        }
        .padding(Papper.spacing.sm)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: Subscription.PlanType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Papper.spacing.xs) {
                        Text(plan.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(PapperColors.neutral800)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(PapperColors.green400)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.pricePerMonth)
                        .font(.system(size: 14))
                        .foregroundColor(PapperColors.neutral600)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text(plan == .yearly ? "per year" : "per month")
                        .font(.system(size: 12))
                        .foregroundColor(PapperColors.neutral500)
                }
            }
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? PapperColors.neutral700 : PapperColors.neutral300, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
#endif

