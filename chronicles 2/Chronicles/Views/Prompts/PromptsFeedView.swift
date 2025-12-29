//
//  PromptsFeedView.swift
//  Chronicles
//
//  TikTok-style swipeable prompts feed
//

import SwiftUI

struct PromptsFeedView: View {
    @StateObject private var viewModel = PromptsViewModel()
    @State private var showCreateEntry = false
    @State private var selectedPrompt: JournalPrompt?
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Prompts Feed
                if viewModel.prompts.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(Array(viewModel.prompts.enumerated()), id: \.element.id) { index, prompt in
                            PromptCardView(
                                prompt: prompt,
                                onLike: {
                                    Task {
                                        await viewModel.likePrompt(prompt)
                                    }
                                },
                                onShare: {
                                    Task {
                                        await viewModel.sharePrompt(prompt)
                                    }
                                },
                                onWriteItOut: {
                                    selectedPrompt = prompt
                                    showCreateEntry = true
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .sheet(isPresented: $showCreateEntry) {
            if let prompt = selectedPrompt {
                CreateEntryFromPromptView(prompt: prompt)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            
            // For You Button
            Button(action: { viewModel.toggleForYou() }) {
                Text("For You")
                    .font(.system(size: 16, weight: viewModel.showForYou ? .bold : .medium))
                    .foregroundColor(viewModel.showForYou ? PapperColors.neutral800 : PapperColors.neutral500)
            }
            
            Spacer()
        }
        .padding(.vertical, Papper.spacing.md)
        .background(Color(hex: "#faf8f3"))
    }
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            Text("No prompts yet")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prompt Card View

struct PromptCardView: View {
    let prompt: JournalPrompt
    let onLike: () -> Void
    let onShare: () -> Void
    let onWriteItOut: () -> Void
    
    var body: some View {
        ZStack {
            // Background Card
            VStack(spacing: Papper.spacing.xxl) {
                Spacer()
                
                // Category Icon
                ZStack {
                    Circle()
                        .fill(PapperColors.neutral100)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: prompt.category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(PapperColors.neutral700)
                }
                
                // Prompt Content
                VStack(spacing: Papper.spacing.lg) {
                    Text(prompt.question)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(PapperColors.neutral800)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Text(prompt.hint)
                        .font(.system(size: 16))
                        .foregroundColor(PapperColors.neutral600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, Papper.spacing.xl)
                
                Spacer()
                
                // Action Bar
                HStack(spacing: Papper.spacing.xxl) {
                    // Share Button
                    Button(action: onShare) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                            Text("\(prompt.shares)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(PapperColors.neutral600)
                    }
                    
                    // Write It Out Button
                    Button(action: onWriteItOut) {
                        HStack(spacing: Papper.spacing.xs) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Write it Out")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Papper.spacing.xl)
                        .padding(.vertical, Papper.spacing.sm)
                        .background(PapperColors.neutral700)
                        .cornerRadius(25)
                    }
                    
                    // Like Button
                    Button(action: onLike) {
                        VStack(spacing: 4) {
                            Image(systemName: prompt.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(prompt.isLiked ? PapperColors.pink600 : PapperColors.neutral600)
                            Text("\(prompt.likes)")
                                .font(.system(size: 12))
                                .foregroundColor(PapperColors.neutral600)
                        }
                    }
                }
                .padding(.bottom, Papper.spacing.xxxl)
            }
            .padding(.horizontal, Papper.spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PapperColors.surfaceBackgroundPlain)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
                .padding(.horizontal, Papper.spacing.md)
                .padding(.vertical, Papper.spacing.md)
        )
    }
}

// MARK: - Create Entry From Prompt

struct CreateEntryFromPromptView: View {
    let prompt: JournalPrompt
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedJournal: Journal?
    @State private var content = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Papper.spacing.xl) {
                        // Prompt Display
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Prompt")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral500)
                            
                            Text(prompt.question)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(PapperColors.neutral800)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PapperColors.neutral100)
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
                        
                        // Content
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Your response")
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
            .navigationTitle("Write Entry")
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
                title: String(prompt.question.prefix(50)),
                content: content,
                inputMethod: .write,
                promptId: prompt.id
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PromptsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        PromptsFeedView()
    }
}
#endif

