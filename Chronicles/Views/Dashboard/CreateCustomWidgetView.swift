//
//  CreateCustomWidgetView.swift
//  Chronicles
//
//  Create a custom widget for the dashboard
//

import SwiftUI

struct CreateCustomWidgetView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var question = ""
    @State private var selectedJournal: Journal?
    @State private var templateText = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "#F7D794"
    @State private var isSaving = false
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedJournal != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Papper.spacing.xl) {
                        // Preview Card
                        previewCard
                        
                        // Widget Title
                        titleSection
                        
                        // Question/Prompt
                        questionSection
                        
                        // Journal Selection
                        journalSection
                        
                        // Template Text (Optional)
                        templateSection
                        
                        // Icon Selection
                        iconSection
                        
                        // Color Selection
                        colorSection
                    }
                    .padding(Papper.spacing.lg)
                }
            }
            .navigationTitle("New Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createWidget()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isValid ? PapperColors.neutral700 : PapperColors.neutral400)
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Preview")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColor).opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: selectedIcon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: selectedColor))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: selectedColor).opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.isEmpty ? "Widget Title" : title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                        .lineLimit(2)
                    
                    Text("Tap to start")
                        .font(.system(size: 11))
                        .foregroundColor(PapperColors.neutral500)
                }
            }
            .padding(Papper.spacing.md)
            .frame(width: 150, height: 120, alignment: .leading)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Widget Title")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            TextField("e.g., Mood Tracker, Daily Wins", text: $title)
                .font(.system(size: 16))
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Question / Prompt")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            Text("This will be shown when you tap the widget")
                .font(.system(size: 12))
                .foregroundColor(PapperColors.neutral400)
            
            TextEditor(text: $question)
                .font(.system(size: 16))
                .frame(minHeight: 80)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Journal Section
    
    private var journalSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Journal")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            Text("Entries from this widget will be saved here")
                .font(.system(size: 12))
                .foregroundColor(PapperColors.neutral400)
            
            Menu {
                ForEach(firebaseService.journals) { journal in
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
    
    // MARK: - Template Section
    
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            HStack {
                Text("Template Text")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
                
                Text("(Optional)")
                    .font(.system(size: 12))
                    .foregroundColor(PapperColors.neutral400)
            }
            
            Text("Pre-fill the entry content with this text")
                .font(.system(size: 12))
                .foregroundColor(PapperColors.neutral400)
            
            TextEditor(text: $templateText)
                .font(.system(size: 16))
                .frame(minHeight: 60)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Icon Section
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Icon")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Papper.spacing.sm) {
                ForEach(DashboardWidget.availableIcons, id: \.self) { icon in
                    Button {
                        // Light haptic on selection
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.25)) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : PapperColors.surfaceBackgroundPlain)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : PapperColors.neutral500)
                        }
                        .overlay(
                            Circle()
                                .stroke(selectedIcon == icon ? Color(hex: selectedColor) : Color.clear, lineWidth: 2)
                        )
                        .scaleEffect(selectedIcon == icon ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Color Section
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Color")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Papper.spacing.sm) {
                ForEach(DashboardWidget.availableColors, id: \.self) { color in
                    Button {
                        // Light haptic on selection
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.25)) {
                            selectedColor = color
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                            
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? PapperColors.neutral700 : Color.clear, lineWidth: 2)
                        )
                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
        }
        .animation(.spring(response: 0.25), value: selectedColor)
    }
    
    // MARK: - Actions
    
    private func createWidget() {
        guard let journal = selectedJournal else { return }
        isSaving = true
        
        // Success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTemplate = templateText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        withAnimation(.spring(response: 0.3)) {
            _ = viewModel.createCustomWidget(
                title: trimmedTitle,
                question: trimmedQuestion,
                journalId: journal.id,
                templateText: trimmedTemplate.isEmpty ? nil : trimmedTemplate,
                icon: selectedIcon,
                color: selectedColor
            )
        }
        
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct CreateCustomWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCustomWidgetView(viewModel: DashboardViewModel())
    }
}
#endif

