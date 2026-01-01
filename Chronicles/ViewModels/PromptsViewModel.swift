//
//  PromptsViewModel.swift
//  Chronicles
//
//  Prompts feed view model
//

import Foundation
import Combine

@MainActor
class PromptsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var prompts: [JournalPrompt] = []
    @Published var likedPrompts: [JournalPrompt] = []
    @Published var currentIndex = 0
    @Published var selectedCategory: JournalPrompt.PromptCategory?
    @Published var isLoading = false
    @Published var showLikedOnly = false
    @Published var isLoadingMore = false
    @Published var hasMorePrompts = true
    @Published var isLoadingPrompts = true  // Track initial prompts loading state
    
    // For infinite scroll - track if we've reached the end
    private var hasReachedEnd = false
    private var isInitialLoad = true
    
    // Computed property for filtered prompts
    var filteredPrompts: [JournalPrompt] {
        if showLikedOnly {
            let liked = prompts.filter { $0.isLiked }
            // For liked tab, create infinite loop by duplicating if needed
            if liked.count > 0 && liked.count < 20 {
                var looped = liked
                while looped.count < 100 {
                    looped.append(contentsOf: liked)
                }
                return looped
            }
            return liked
        }
        return prompts
    }
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        Task {
            await loadInitialPrompts()
        }
    }
    
    private func setupBindings() {
        // Bind to prompts loading state
        firebaseService.$isLoadingPrompts
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoadingPrompts)
        
        firebaseService.$prompts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedPrompts in
                guard let self = self else { return }
                
                // If we already have prompts, just update the like/share counts
                // without reshuffling the order
                if !self.prompts.isEmpty {
                    for updatedPrompt in updatedPrompts {
                        if let index = self.prompts.firstIndex(where: { $0.id == updatedPrompt.id }) {
                            self.prompts[index].isLiked = updatedPrompt.isLiked
                            self.prompts[index].likes = updatedPrompt.likes
                            self.prompts[index].shares = updatedPrompt.shares
                        }
                    }
                } else {
                    // Initial load - shuffle the prompts
                    self.prompts = updatedPrompts.shuffled()
                }
                self.updateLikedPrompts()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Prompts
    
    func loadInitialPrompts() async {
        isLoading = true
        defer { isLoading = false }
        
        // Prompts are already loaded via FirebaseService binding
        // Just shuffle them
        if !prompts.isEmpty {
            prompts.shuffle()
            updateLikedPrompts()
        }
    }
    
    /// Load more prompts for infinite scroll
    func loadMorePrompts() async {
        guard !isLoadingMore && hasMorePrompts && !showLikedOnly else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let newPrompts = try await firebaseService.fetchNextPromptsBatch(category: selectedCategory)
            
            if newPrompts.isEmpty {
                // Reached the end, loop back to beginning
                hasReachedEnd = true
                await resetAndShuffle()
            } else {
                // Append new prompts (avoid duplicates)
                let existingIds = Set(prompts.map { $0.id })
                let uniqueNew = newPrompts.filter { !existingIds.contains($0.id) }
                prompts.append(contentsOf: uniqueNew)
            }
        } catch {
            // Handle silently
        }
    }
    
    /// Reset pagination and shuffle (called when reaching end or on tab return)
    func resetAndShuffle() async {
        // #region agent log
        let startTime = Date()
        // #endregion
        await firebaseService.resetPromptsPagination()
        prompts.shuffle()
        hasReachedEnd = false
        hasMorePrompts = true
        // #region agent log
        Task { @MainActor in
            var request = URLRequest(url: URL(string: "http://127.0.0.1:7243/ingest/c77dc5f7-b92e-4545-af23-f0f74127ea45")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let duration = Date().timeIntervalSince(startTime) * 1000
            let payload: [String: Any] = ["location": "PromptsViewModel.swift:resetAndShuffle", "message": "Reset and shuffle completed", "data": ["durationMs": duration, "newPromptCount": self.prompts.count], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "hypothesisId": "B"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: request)
        }
        // #endregion
    }
    
    /// Check if we're near the end and should load more
    func checkIfNearEnd(currentIndex: Int) {
        let threshold = prompts.count - 5
        if currentIndex >= threshold && !isLoadingMore && !hasReachedEnd {
            Task {
                await loadMorePrompts()
            }
        }
    }
    
    // MARK: - Navigation
    
    var currentPrompt: JournalPrompt? {
        guard currentIndex >= 0, currentIndex < prompts.count else { return nil }
        return prompts[currentIndex]
    }
    
    func nextPrompt() {
        if currentIndex < prompts.count - 1 {
            currentIndex += 1
        }
    }
    
    func previousPrompt() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    func goToPrompt(at index: Int) {
        guard index >= 0, index < prompts.count else { return }
        currentIndex = index
    }
    
    // MARK: - Interactions
    
    func likePrompt(_ prompt: JournalPrompt) async {
        do {
            try await firebaseService.likePrompt(prompt.id)
            updateLikedPrompts()
        } catch {
            // Handle silently
        }
    }
    
    func sharePrompt(_ prompt: JournalPrompt) async {
        do {
            try await firebaseService.sharePrompt(prompt.id)
        } catch {
            // Handle silently
        }
    }
    
    private func updateLikedPrompts() {
        likedPrompts = prompts.filter { $0.isLiked }
    }
    
    // MARK: - Categories
    
    func selectCategory(_ category: JournalPrompt.PromptCategory?) {
        selectedCategory = category
        currentIndex = 0
        
        Task {
            await resetAndShuffle()
        }
    }
    
    // MARK: - Tab Switching
    
    func onTabAppear() {
        // #region agent log
        Task { @MainActor in
            var request = URLRequest(url: URL(string: "http://127.0.0.1:7243/ingest/c77dc5f7-b92e-4545-af23-f0f74127ea45")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload: [String: Any] = ["location": "PromptsViewModel.swift:onTabAppear", "message": "Prompts tab appeared", "data": ["isInitialLoad": self.isInitialLoad, "willShuffle": !self.isInitialLoad, "promptCount": self.prompts.count], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "hypothesisId": "B"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: request)
        }
        // #endregion
        // Shuffle when returning to tab
        if !isInitialLoad {
            Task {
                await resetAndShuffle()
            }
        }
        isInitialLoad = false
    }
    
}

