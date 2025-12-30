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
    
    // Computed property for filtered prompts
    var filteredPrompts: [JournalPrompt] {
        showLikedOnly ? prompts.filter { $0.isLiked } : prompts
    }
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
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
    
    func loadPrompts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            prompts = try await firebaseService.fetchPrompts(category: selectedCategory)
            prompts.shuffle()
        } catch {
            // Handle silently
        }
    }
    
    func loadForYouPrompts() async {
        isLoading = true
        defer { isLoading = false }
        
        // In production, this would use AI to personalize
        // For now, just shuffle all prompts
        do {
            prompts = try await firebaseService.fetchPrompts()
            prompts.shuffle()
        } catch {
            // Handle silently
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
            await loadPrompts()
        }
    }
    
}

