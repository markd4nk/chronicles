//
//  AIReflectView.swift
//  Chronicles
//
//  AI Reflect/Analyze feature - conversational interface
//

import SwiftUI
import Combine

struct AIReflectView: View {
    @StateObject private var viewModel = AIReflectViewModel()
    @State private var showJournalSelection = false
    @State private var showHistory = false
    @State private var showNewConversationAlert = false
    @FocusState private var isInputFocused: Bool
    
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
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
                
                // Only show New Chat button when in chat interface (not on start screen)
                if viewModel.currentConversation != nil || viewModel.analysisSummary != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { 
                            // Show confirmation if there's an active conversation
                            showNewConversationAlert = true
                        }) {
                            Text("New Chat")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PapperColors.neutral700)
                        }
                    }
                }
            }
            .sheet(isPresented: $showJournalSelection) {
                JournalAnalysisSelectionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHistory) {
                ConversationHistoryView(viewModel: viewModel)
            }
            .alert("Start New Analysis?", isPresented: $showNewConversationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Start New", role: .destructive) {
                    withAnimation {
                        viewModel.startNewConversation()
                    }
                }
            } message: {
                Text("This will end your current conversation and start a new analysis.")
            }
        }
    }
    
    // MARK: - Start Screen
    
    private var startScreen: some View {
        VStack(spacing: Papper.spacing.xl) {
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
                Text("Reflect")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Analyze your journals and discover\npatterns, insights, and growth")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            // Start Analysis Button - positioned higher
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
            .padding(.top, Papper.spacing.xxl)
            
            Spacer()
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
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    // Dismiss keyboard when tapping on messages area (iMessage-like behavior)
                    isInputFocused = false
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
        VStack(spacing: 0) {
            // Divider line
            Rectangle()
                .fill(PapperColors.neutral300)
                .frame(height: 1)
            
            HStack(spacing: Papper.spacing.md) {
                // Input field with prominent styling
                HStack {
                    TextField("Share your thoughts...", text: $viewModel.inputText)
                        .font(.system(size: 16))
                        .focused($isInputFocused)
                }
                .padding(.horizontal, Papper.spacing.md)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(PapperColors.neutral300, lineWidth: 1)
                )
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.inputText.isEmpty ? PapperColors.neutral300 : PapperColors.neutral700)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isGenerating)
            }
            .padding(.horizontal, Papper.spacing.lg)
            .padding(.top, Papper.spacing.md)
            .padding(.bottom, 70) // Extra padding to clear custom tab bar
        }
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

// MARK: - Analysis Loading View

struct AnalysisLoadingView: View {
    @State private var progress: Double = 0
    @State private var currentQuoteIndex: Int = 0
    
    private let inspirationalQuotes = [
        "\"The unexamined life is not worth living.\" - Socrates",
        "\"In the middle of difficulty lies opportunity.\" - Albert Einstein",
        "\"Growth begins at the end of your comfort zone.\"",
        "\"What lies behind us and what lies before us are tiny matters compared to what lies within us.\" - Ralph Waldo Emerson",
        "\"The only journey is the journey within.\" - Rainer Maria Rilke",
        "\"Reflection is the lamp of the heart.\" - Proverb",
        "\"Knowing yourself is the beginning of all wisdom.\" - Aristotle"
    ]
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            VStack(spacing: Papper.spacing.xxl) {
                Spacer()
                
                // Inspirational Quote
                VStack(spacing: Papper.spacing.lg) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 32))
                        .foregroundColor(PapperColors.neutral300)
                    
                    Text(inspirationalQuotes[currentQuoteIndex])
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(PapperColors.neutral700)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Papper.spacing.xxl)
                        .lineSpacing(6)
                }
                .padding(.horizontal, Papper.spacing.lg)
                
                Spacer()
                
                // Progress Section
                VStack(spacing: Papper.spacing.md) {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(PapperColors.neutral300)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(PapperColors.neutral700)
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.1), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, Papper.spacing.xxxl)
                    
                    // Analyzing Text
                    Text("Analyzing your journals...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PapperColors.neutral600)
                }
                .padding(.bottom, Papper.spacing.xxxl)
            }
        }
        .onReceive(timer) { _ in
            // Simulate progress (caps at 90% until actually complete)
            if progress < 0.9 {
                progress += 0.005
            }
        }
        .onAppear {
            currentQuoteIndex = Int.random(in: 0..<inspirationalQuotes.count)
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
                
                if viewModel.isAnalyzing {
                    // Show full-screen loading view
                    AnalysisLoadingView()
                        .transition(.opacity)
                } else {
                    // Journal selection content
                    journalSelectionContent
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isAnalyzing)
            .navigationTitle(viewModel.isAnalyzing ? "" : "Select Journals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isAnalyzing {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(PapperColors.neutral600)
                    }
                }
            }
            .onChange(of: viewModel.analysisSummary) { oldValue, newValue in
                // Dismiss when analysis completes
                if newValue != nil && oldValue == nil {
                    dismiss()
                }
            }
        }
    }
    
    private var journalSelectionContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Papper.spacing.lg) {
                    Text("Select journals to analyze")
                        .font(Papper.typography.body)
                        .foregroundColor(PapperColors.neutral600)
                        .padding(.top, Papper.spacing.md)
                    
                    // Deselect All / Select All
                    HStack {
                        Button("Deselect All") {
                            viewModel.deselectAllJournals()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PapperColors.neutral500)
                        
                        Spacer()
                        
                        Button("Select All") {
                            viewModel.selectAllJournals()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PapperColors.neutral700)
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
                    }
                }) {
                    HStack(spacing: Papper.spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Analyze \(viewModel.selectedJournals.count) Journal\(viewModel.selectedJournals.count == 1 ? "" : "s")")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(viewModel.selectedJournals.isEmpty ? PapperColors.neutral400 : PapperColors.neutral700)
                    .cornerRadius(14)
                }
                .disabled(viewModel.selectedJournals.isEmpty)
                .padding(Papper.spacing.lg)
                .background(Color(hex: "#faf8f3"))
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
    @State private var isEditMode = false
    @State private var selectedConversations: Set<String> = []
    @State private var showDeleteConfirmation = false
    
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
                    VStack(spacing: 0) {
                        List {
                            ForEach(viewModel.conversations) { conversation in
                                ConversationRow(
                                    conversation: conversation,
                                    isEditMode: isEditMode,
                                    isSelected: selectedConversations.contains(conversation.id)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    if isEditMode {
                                        toggleSelection(conversation.id)
                                    } else {
                                        Task {
                                            await viewModel.loadConversation(conversation)
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                if !isEditMode {
                                    for index in indexSet {
                                        let conversation = viewModel.conversations[index]
                                        Task {
                                            await viewModel.deleteConversation(conversation)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        
                        // Delete button when in edit mode with selections
                        if isEditMode && !selectedConversations.isEmpty {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack(spacing: Papper.spacing.sm) {
                                    Image(systemName: "trash")
                                    Text("Delete \(selectedConversations.count) Conversation\(selectedConversations.count == 1 ? "" : "s")")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.red)
                                .cornerRadius(14)
                            }
                            .padding(Papper.spacing.lg)
                            .background(Color(hex: "#faf8f3"))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isEditMode)
                    .animation(.easeInOut(duration: 0.2), value: selectedConversations.isEmpty)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.conversations.isEmpty {
                        Button(action: {
                            withAnimation {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedConversations.removeAll()
                                }
                            }
                        }) {
                            Image(systemName: isEditMode ? "xmark" : "trash")
                                .foregroundColor(isEditMode ? PapperColors.neutral600 : PapperColors.neutral700)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Select All" : "Done") {
                        if isEditMode {
                            // Select all or deselect all
                            if selectedConversations.count == viewModel.conversations.count {
                                selectedConversations.removeAll()
                            } else {
                                selectedConversations = Set(viewModel.conversations.map { $0.id })
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(PapperColors.neutral700)
                }
            }
            .alert("Delete Conversations?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteConversations(selectedConversations)
                        withAnimation {
                            selectedConversations.removeAll()
                            isEditMode = false
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(selectedConversations.count) conversation\(selectedConversations.count == 1 ? "" : "s")? This action cannot be undone.")
            }
        }
    }
    
    private func toggleSelection(_ id: String) {
        if selectedConversations.contains(id) {
            selectedConversations.remove(id)
        } else {
            selectedConversations.insert(id)
        }
    }
}

struct ConversationRow: View {
    let conversation: AIConversation
    var isEditMode: Bool = false
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            // Checkbox when in edit mode
            if isEditMode {
                ZStack {
                    Circle()
                        .stroke(isSelected ? PapperColors.neutral700 : PapperColors.neutral300, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(PapperColors.neutral700)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            
            VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                HStack {
                    Text(conversation.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Spacer()
                    
                    // Use lastMessageAt if available (from metadata), otherwise fall back to updatedAt
                    Text((conversation.lastMessageAt ?? conversation.updatedAt).shortDateString)
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                }
                
                HStack {
                    // Use preview which checks lastMessagePreview first (metadata), then falls back to messages array
                    Text(conversation.preview)
                        .font(Papper.typography.body)
                        .foregroundColor(PapperColors.neutral600)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Show message count from metadata if available
                    if conversation.messageCount > 0 {
                        Text("\(conversation.messageCount)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PapperColors.neutral500)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PapperColors.neutral200b)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(Papper.spacing.md)
        .background(isSelected ? PapperColors.neutral100 : PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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

