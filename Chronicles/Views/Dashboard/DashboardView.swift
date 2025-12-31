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
    @State private var showCreateCustomWidget = false
    @State private var widgetToRemove: DashboardWidget?
    @State private var showRemoveConfirmation = false
    
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
                        if viewModel.isLoading && viewModel.activeWidgets.isEmpty {
                            widgetsSkeletonLoader
                        } else if viewModel.activeWidgets.isEmpty {
                            emptyWidgetsState
                        } else {
                            widgetsGrid
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.top, Papper.spacing.md)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refresh()
                }
                
                // Error Toast
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        errorToast(message: errorMessage)
                            .padding(.bottom, 120)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: viewModel.errorMessage)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                }
            }
            .sheet(item: $selectedWidget) { widget in
                CreateEntryFromWidgetView(widget: widget, viewModel: viewModel)
            }
            .sheet(isPresented: $showCreateCustomWidget) {
                CreateCustomWidgetView(viewModel: viewModel)
            }
            .alert("Remove Widget", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {
                    widgetToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let widget = widgetToRemove {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.removeWidget(widget)
                        }
                    }
                    widgetToRemove = nil
                }
            } message: {
                Text("Are you sure you want to remove this widget from your dashboard?")
            }
        }
    }
    
    // MARK: - Error Toast
    
    private func errorToast(message: String) -> some View {
        HStack(spacing: Papper.spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(PapperColors.neutral800)
            
            Spacer()
            
            Button {
                viewModel.clearError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PapperColors.neutral500)
            }
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Papper.spacing.lg)
    }
    
    // MARK: - Skeleton Loader
    
    private var widgetsSkeletonLoader: some View {
        VStack(spacing: Papper.spacing.md) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Papper.spacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonWidgetCard()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyWidgetsState: some View {
        VStack(spacing: Papper.spacing.lg) {
            VStack(spacing: Papper.spacing.md) {
                HStack {
                    Text("Today's Focus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Spacer()
                }
                
                VStack(spacing: Papper.spacing.md) {
                    Image(systemName: "rectangle.grid.2x2")
                        .font(.system(size: 48))
                        .foregroundColor(PapperColors.neutral300)
                    
                    Text("No widgets yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral600)
                    
                    Text("Create custom widgets to track your daily journaling habits")
                        .font(.system(size: 14))
                        .foregroundColor(PapperColors.neutral500)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showCreateCustomWidget = true
                    } label: {
                        HStack(spacing: Papper.spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Widget")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Papper.spacing.lg)
                        .padding(.vertical, Papper.spacing.sm)
                        .background(PapperColors.neutral700)
                        .cornerRadius(20)
                    }
                    .padding(.top, Papper.spacing.sm)
                }
                .padding(Papper.spacing.xl)
                .frame(maxWidth: .infinity)
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
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
                        canRemove: viewModel.canRemoveWidget,
                        onTap: { selectedWidget = widget },
                        onRemove: {
                            widgetToRemove = widget
                            showRemoveConfirmation = true
                        },
                        onAddMore: {
                            showCreateCustomWidget = true
                        }
                    )
                }
            }
        }
    }
    
}

// MARK: - Quick Entry Widget Card

struct QuickEntryWidgetCard: View {
    let widget: DashboardWidget
    let isCompleted: Bool
    let canRemove: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    let onAddMore: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Light haptic feedback on tap
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        } label: {
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
                    
                    // Custom widget indicator
                    if widget.isCustom {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: widget.color).opacity(0.6))
                    }
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(PapperColors.green400)
                            .transition(.scale.combined(with: .opacity))
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
            .shadow(color: Color.black.opacity(isPressed ? 0.08 : 0.04), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .contextMenu {
            // Remove option (only if more than 1 widget)
            if canRemove {
                Button(role: .destructive) {
                    // Medium haptic for destructive action
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onRemove()
                } label: {
                    Label("Remove Widget", systemImage: "minus.circle")
                }
            }
            
            // Add More option
            Button {
                // Light haptic for action
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onAddMore()
            } label: {
                Label("Add New Widget", systemImage: "plus.circle")
            }
        }
        .animation(.spring(response: 0.3), value: isCompleted)
    }
}

// MARK: - Create Entry From Widget

struct CreateEntryFromWidgetView: View {
    let widget: DashboardWidget
    @ObservedObject var viewModel: DashboardViewModel
    @StateObject private var journalViewModel = JournalViewModel()
    @ObservedObject private var firebaseService = FirebaseService.shared
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
                                
                                Text(widget.isCustom ? "Custom widget" : "Quick entry template")
                                    .font(Papper.typography.bodySmall)
                                    .foregroundColor(PapperColors.neutral500)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: widget.color).opacity(0.1))
                        .cornerRadius(12)
                        
                        // Question/Prompt (for custom widgets)
                        if widget.isCustom, let question = widget.question, !question.isEmpty {
                            VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                                Text("Prompt")
                                    .font(Papper.typography.bodySmall)
                                    .foregroundColor(PapperColors.neutral500)
                                
                                Text(question)
                                    .font(.system(size: 15))
                                    .foregroundColor(PapperColors.neutral700)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: widget.color).opacity(0.05))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Journal Selection (disabled for custom widgets with pre-set journal)
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Journal")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral500)
                            
                            if widget.isCustom && widget.journalId != nil {
                                // Show pre-selected journal for custom widget
                                HStack {
                                    if let journal = selectedJournal {
                                        Circle()
                                            .fill(journal.displayColor)
                                            .frame(width: 8, height: 8)
                                        Text(journal.name)
                                            .foregroundColor(PapperColors.neutral800)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(PapperColors.neutral400)
                                }
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                            } else {
                                Menu {
                                    ForEach(journalViewModel.journals) { journal in
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
            .task {
                // Setup based on widget type
                title = widget.title
                
                // For custom widgets with pre-set journal
                if widget.isCustom, let journalId = widget.journalId {
                    selectedJournal = journalViewModel.journals.first { $0.id == journalId }
                    
                    // Pre-fill template text if available
                    if let templateText = widget.templateText, !templateText.isEmpty {
                        content = templateText
                    }
                } else {
                    selectedJournal = journalViewModel.journals.first
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let journal = selectedJournal else { return }
        isSaving = true
        
        Task {
            await journalViewModel.createEntry(
                journalId: journal.id,
                title: title,
                content: content,
                inputMethod: .write,
                templateId: widget.templateId
            )
            
            // Refresh today's entries to update widget completion status
            await viewModel.loadTodaysEntries()
            
            dismiss()
        }
    }
}

// MARK: - Skeleton Widget Card

struct SkeletonWidgetCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.sm) {
            HStack {
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 40, height: 40)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 10)
            }
        }
        .padding(Papper.spacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                PapperColors.neutral200.opacity(isAnimating ? 0.3 : 0.6),
                PapperColors.neutral200.opacity(isAnimating ? 0.6 : 0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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
