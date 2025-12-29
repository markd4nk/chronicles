//
//  DashboardView.swift
//  Chronicles
//
//  Dashboard/Home view matching chronicles-preview.html design
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false
    @State private var showCreateEntry = false
    @State private var selectedWidget: DashboardWidget?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Papper.spacing.xl) {
                        // Header
                        headerSection
                        
                        // Welcome Card
                        welcomeCard
                        
                        // Quick Entry Widgets (2x2 Grid)
                        widgetsGrid
                        
                        // Recent Entries
                        if !viewModel.recentEntries.isEmpty {
                            recentEntriesSection
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.top, Papper.spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                }
            }
            .sheet(item: $selectedWidget) { widget in
                CreateEntryFromWidgetView(widget: widget)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            // Streak Badge
            HStack(spacing: Papper.spacing.xs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(PapperColors.neutral700)
                
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.horizontal, Papper.spacing.sm)
            .padding(.vertical, Papper.spacing.xs)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            // Settings Button
            Button(action: { showSettings = true }) {
                ZStack {
                    Circle()
                        .fill(PapperColors.surfaceBackgroundPlain)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(PapperColors.neutral700)
                }
            }
        }
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text(viewModel.greeting + ",")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(PapperColors.neutral600)
            
            Text(viewModel.userName)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(PapperColors.neutral800)
            
            Text(viewModel.formattedDate)
                .font(.system(size: 13))
                .foregroundColor(PapperColors.neutral500)
                .padding(.top, Papper.spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Papper.spacing.lg)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Widgets Grid (2x2)
    
    private var widgetsGrid: some View {
        VStack(spacing: Papper.spacing.md) {
            // Section Header
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Spacer()
            }
            
            // 2x2 Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Papper.spacing.md) {
                ForEach(viewModel.activeWidgets) { widget in
                    QuickEntryWidgetCard(
                        widget: widget,
                        isCompleted: viewModel.isWidgetCompleted(widget),
                        onTap: { selectedWidget = widget }
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Entries
    
    private var recentEntriesSection: some View {
        VStack(spacing: Papper.spacing.md) {
            HStack {
                Text("Recent Entries")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Spacer()
                
                NavigationLink(destination: EntriesListView()) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PapperColors.neutral600)
                }
            }
            
            ForEach(viewModel.recentEntries.prefix(3)) { entry in
                RecentEntryCard(entry: entry)
            }
        }
    }
}

// MARK: - Quick Entry Widget Card

struct QuickEntryWidgetCard: View {
    let widget: DashboardWidget
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                // Icon & Status
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: widget.color).opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: widget.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: widget.color))
                    }
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(PapperColors.green400)
                    }
                }
                
                Spacer()
                
                // Title & Status
                VStack(alignment: .leading, spacing: 2) {
                    Text(widget.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(isCompleted ? "Completed" : "Tap to start")
                        .font(.system(size: 11))
                        .foregroundColor(isCompleted ? PapperColors.green400 : PapperColors.neutral500)
                }
            }
            .padding(Papper.spacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Entry Card

struct RecentEntryCard: View {
    let entry: JournalEntry
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some View {
        NavigationLink(destination: JournalEntryView(entry: entry)) {
            HStack(spacing: Papper.spacing.md) {
                // Color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: viewModel.getJournalColor(for: entry)))
                    .frame(width: 4, height: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(PapperColors.neutral800)
                        .lineLimit(1)
                    
                    Text(entry.shortPreview)
                        .font(.system(size: 13))
                        .foregroundColor(PapperColors.neutral600)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time
                Text(entry.createdAt.timeString)
                    .font(.system(size: 12))
                    .foregroundColor(PapperColors.neutral500)
            }
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Entry From Widget

struct CreateEntryFromWidgetView: View {
    let widget: DashboardWidget
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedJournal: Journal?
    @State private var title = ""
    @State private var content = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Papper.spacing.xl) {
                        // Template Info
                        HStack(spacing: Papper.spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: widget.color).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: widget.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: widget.color))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(widget.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(PapperColors.neutral800)
                                
                                Text("Quick entry template")
                                    .font(Papper.typography.bodySmall)
                                    .foregroundColor(PapperColors.neutral500)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: widget.color).opacity(0.1))
                        .cornerRadius(12)
                        
                        // Journal Selection
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Journal")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral500)
                            
                            Menu {
                                ForEach(viewModel.journals) { journal in
                                    Button(action: { selectedJournal = journal }) {
                                        HStack {
                                            Circle()
                                                .fill(journal.displayColor)
                                                .frame(width: 8, height: 8)
                                            Text(journal.name)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if let journal = selectedJournal {
                                        Circle()
                                            .fill(journal.displayColor)
                                            .frame(width: 8, height: 8)
                                        Text(journal.name)
                                            .foregroundColor(PapperColors.neutral800)
                                    } else {
                                        Text("Select a journal")
                                            .foregroundColor(PapperColors.neutral500)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(PapperColors.neutral400)
                                }
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Title
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Title")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral500)
                            
                            TextField("Entry title", text: $title)
                                .font(.system(size: 16))
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Content")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral500)
                            
                            TextEditor(text: $content)
                                .font(.system(size: 16))
                                .frame(minHeight: 200)
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                        }
                    }
                    .padding(Papper.spacing.lg)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(selectedJournal == nil || content.isEmpty || isSaving)
                }
            }
            .onAppear {
                title = widget.title
                selectedJournal = viewModel.journals.first
            }
        }
    }
    
    private func saveEntry() {
        guard let journal = selectedJournal else { return }
        isSaving = true
        
        Task {
            await viewModel.createEntry(
                journalId: journal.id,
                title: title,
                content: content,
                inputMethod: .write,
                templateId: widget.templateId
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
