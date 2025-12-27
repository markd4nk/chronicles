//
//  MainTabView.swift
//  Chronicles
//
//  Main 5-button tab navigation (Dashboard, AI Reflect, +, All Entries, Prompts)
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var showCreateEntry = false
    @State private var showJournalSelection = false
    
    enum Tab: Int {
        case dashboard = 0
        case reflect = 1
        case create = 2
        case entries = 3
        case prompts = 4
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                // Dashboard
                DashboardView()
                    .tag(Tab.dashboard)
                
                // AI Reflect
                AIReflectView()
                    .tag(Tab.reflect)
                
                // Placeholder for center button (never shown)
                Color.clear
                    .tag(Tab.create)
                
                // All Entries
                AllEntriesContainerView()
                    .tag(Tab.entries)
                
                // Prompts Feed
                PromptsFeedView()
                    .tag(Tab.prompts)
            }
            
            // Custom Tab Bar
            CustomTabBar(
                selectedTab: $selectedTab,
                onCreateTapped: {
                    showJournalSelection = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showJournalSelection) {
            JournalSelectionView()
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let onCreateTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Dashboard
            TabBarButton(
                icon: "house.fill",
                label: "Home",
                isSelected: selectedTab == .dashboard,
                action: { selectedTab = .dashboard }
            )
            
            // AI Reflect
            TabBarButton(
                icon: "brain.head.profile",
                label: "Reflect",
                isSelected: selectedTab == .reflect,
                action: { selectedTab = .reflect }
            )
            
            // Center Create Button
            CenterCreateButton(action: onCreateTapped)
            
            // All Entries
            TabBarButton(
                icon: "doc.text.fill",
                label: "Entries",
                isSelected: selectedTab == .entries,
                action: { selectedTab = .entries }
            )
            
            // Prompts
            TabBarButton(
                icon: "lightbulb.fill",
                label: "Prompts",
                isSelected: selectedTab == .prompts,
                action: { selectedTab = .prompts }
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(PapperColors.surfaceBackgroundPlain)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? PapperColors.neutral700 : PapperColors.neutral400)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? PapperColors.neutral700 : PapperColors.neutral400)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Center Create Button

struct CenterCreateButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(PapperColors.neutral700)
                    .frame(width: 56, height: 56)
                    .shadow(color: PapperColors.neutral700.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .offset(y: -20)
    }
}

// MARK: - All Entries Container

struct AllEntriesContainerView: View {
    @State private var selectedSubTab = 0
    @State private var showManageJournals = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Sub-tab picker
                Picker("View", selection: $selectedSubTab) {
                    Text("List").tag(0)
                    Text("Calendar").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, Papper.spacing.lg)
                .padding(.top, Papper.spacing.sm)
                
                // Content
                if selectedSubTab == 0 {
                    EntriesListView()
                } else {
                    EntriesCalendarView()
                }
            }
            .navigationTitle("All Entries")
            .background(PapperColors.surfaceBackgroundGray.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showManageJournals = true }) {
                            Label("Manage Journals", systemImage: "folder.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
            }
            .sheet(isPresented: $showManageJournals) {
                ManageJournalsView()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif
