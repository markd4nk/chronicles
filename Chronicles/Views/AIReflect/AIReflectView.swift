//
//  AIReflectView.swift
//  Chronicles
//
//  AI Reflect/Analyze feature - conversational interface
//

import SwiftUI

struct AIReflectView: View {
    @StateObject private var viewModel = AIReflectViewModel()
    @State private var showJournalSelection = false
    @State private var showHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                if viewModel.currentConversation == nil && viewModel.analysisSummary == nil {
                    // Start Screen
                    startScreen
                } else {
                    // Chat Interface
                    chatInterface
                }
            }
            .navigationTitle("AI Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.startNewConversation() }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
            }
            .sheet(isPresented: $showJournalSelection) {
                JournalAnalysisSelectionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHistory) {
                ConversationHistoryView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Start Screen
    
    private var startScreen: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(PapperColors.neutral100)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            // Title
            VStack(spacing: Papper.spacing.md) {
                Text("AI Reflect")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Analyze your journals and discover\npatterns, insights, and growth")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Start Analysis Button
            Button(action: { showJournalSelection = true }) {
                HStack(spacing: Papper.spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                    Text("Start Analysis")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(PapperColors.neutral700)
                .cornerRadius(14)
            }
            .padding(.horizontal, Papper.spacing.xl)
            .padding(.bottom, Papper.spacing.xxxl)
        }
        .padding(Papper.spacing.lg)
    }
    
    // MARK: - Chat Interface
    
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Papper.spacing.md) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isGenerating {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, Papper.spacing.lg)
                        }
                    }
                    .padding(.vertical, Papper.spacing.md)
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            chatInputBar
        }
    }
    
    private var chatInputBar: some View {
        HStack(spacing: Papper.spacing.sm) {
            TextField("Ask about your journals...", text: $viewModel.inputText)
                .font(.system(size: 16))
                .padding(.horizontal, Papper.spacing.md)
                .padding(.vertical, Papper.spacing.sm)
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(20)
            
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.inputText.isEmpty ? PapperColors.neutral300 : PapperColors.neutral700)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isGenerating)
        }
        .padding(.horizontal, Papper.spacing.lg)
        .padding(.vertical, Papper.spacing.md)
        .background(Color(hex: "#faf8f3"))
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: AIMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? .white : PapperColors.neutral800)
                    .padding(.horizontal, Papper.spacing.md)
                    .padding(.vertical, Papper.spacing.sm)
                    .background(isUser ? PapperColors.neutral700 : PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(16)
                
                Text(message.createdAt.timeString)
                    .font(.system(size: 10))
                    .foregroundColor(PapperColors.neutral400)
            }
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
        .padding(.horizontal, Papper.spacing.lg)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationAmount: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(PapperColors.neutral400)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animationAmount
                    )
            }
        }
        .padding(.horizontal, Papper.spacing.md)
        .padding(.vertical, Papper.spacing.sm)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .onAppear {
            animationAmount = 1.0
        }
    }
}

// MARK: - Journal Analysis Selection

struct JournalAnalysisSelectionView: View {
    @ObservedObject var viewModel: AIReflectViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Papper.spacing.lg) {
                        Text("Select journals to analyze")
                            .font(Papper.typography.body)
                            .foregroundColor(PapperColors.neutral600)
                            .padding(.top, Papper.spacing.md)
                        
                        // Select All / None
                        HStack {
                            Button("Select All") {
                                viewModel.selectAllJournals()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(PapperColors.neutral700)
                            
                            Spacer()
                            
                            Button("Deselect All") {
                                viewModel.deselectAllJournals()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(PapperColors.neutral500)
                        }
                        .padding(.horizontal, Papper.spacing.lg)
                        
                        // Journal List
                        ForEach(viewModel.availableJournals) { journal in
                            JournalSelectionRow(
                                journal: journal,
                                isSelected: viewModel.selectedJournals.contains(journal.id),
                                onToggle: { viewModel.toggleJournalSelection(journal.id) }
                            )
                        }
                        .padding(.horizontal, Papper.spacing.lg)
                    }
                    .padding(.bottom, 100)
                }
                
                // Analyze Button
                VStack {
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await viewModel.startAnalysis()
                            dismiss()
                        }
                    }) {
                        HStack(spacing: Papper.spacing.xs) {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Analyze \(viewModel.selectedJournals.count) Journal\(viewModel.selectedJournals.count == 1 ? "" : "s")")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.selectedJournals.isEmpty ? PapperColors.neutral400 : PapperColors.neutral700)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.selectedJournals.isEmpty || viewModel.isAnalyzing)
                    .padding(Papper.spacing.lg)
                    .background(Color(hex: "#faf8f3"))
                }
            }
            .navigationTitle("Select Journals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
            }
        }
    }
}

struct JournalSelectionRow: View {
    let journal: Journal
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Papper.spacing.md) {
                Circle()
                    .fill(journal.displayColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(journal.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text("\(journal.entryCount) entries")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? PapperColors.neutral700 : PapperColors.neutral300, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(PapperColors.neutral700)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(Papper.spacing.md)
            .background(isSelected ? PapperColors.neutral100 : PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
        }
    }
}

// MARK: - Conversation History

struct ConversationHistoryView: View {
    @ObservedObject var viewModel: AIReflectViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                if viewModel.conversations.isEmpty {
                    VStack(spacing: Papper.spacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(PapperColors.neutral400)
                        
                        Text("No conversations yet")
                            .font(Papper.typography.body)
                            .foregroundColor(PapperColors.neutral600)
                    }
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            ConversationRow(conversation: conversation)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    viewModel.loadConversation(conversation)
                                    dismiss()
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let conversation = viewModel.conversations[index]
                                Task {
                                    await viewModel.deleteConversation(conversation)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral700)
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: AIConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            HStack {
                Text(conversation.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PapperColors.neutral800)
                
                Spacer()
                
                Text(conversation.updatedAt.shortDateString)
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
            }
            
            Text(conversation.preview)
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
                .lineLimit(2)
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#if DEBUG
struct AIReflectView_Previews: PreviewProvider {
    static var previews: some View {
        AIReflectView()
    }
}
#endif

