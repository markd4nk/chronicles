//
//  TemplatesListView.swift
//  Chronicles
//
//  Manage journal templates
//

import SwiftUI

struct TemplatesListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateTemplate = false
    @State private var editingTemplate: JournalTemplate?
    
    var userTemplates: [JournalTemplate] {
        viewModel.templates.filter { !$0.isBuiltIn }
    }
    
    var builtInTemplates: [JournalTemplate] {
        JournalTemplate.builtInTemplates
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Papper.spacing.xl) {
                    // Built-in Templates
                    VStack(alignment: .leading, spacing: Papper.spacing.md) {
                        Text("BUILT-IN TEMPLATES")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PapperColors.neutral500)
                            .padding(.leading, 4)
                        
                        ForEach(builtInTemplates) { template in
                            TemplateCard(template: template, isBuiltIn: true)
                        }
                    }
                    
                    // User Templates
                    VStack(alignment: .leading, spacing: Papper.spacing.md) {
                        HStack {
                            Text("YOUR TEMPLATES")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(PapperColors.neutral500)
                            
                            Spacer()
                            
                            Button(action: { showCreateTemplate = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("New")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(PapperColors.neutral700)
                            }
                        }
                        .padding(.leading, 4)
                        
                        if userTemplates.isEmpty {
                            // Empty state
                            VStack(spacing: Papper.spacing.md) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 40))
                                    .foregroundColor(PapperColors.neutral400)
                                
                                Text("No custom templates yet")
                                    .font(Papper.typography.body)
                                    .foregroundColor(PapperColors.neutral600)
                                
                                Button(action: { showCreateTemplate = true }) {
                                    Text("Create Template")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, Papper.spacing.lg)
                                        .padding(.vertical, Papper.spacing.xs)
                                        .background(PapperColors.neutral700)
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Papper.spacing.xxl)
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(16)
                        } else {
                            ForEach(userTemplates) { template in
                                TemplateCard(
                                    template: template,
                                    isBuiltIn: false,
                                    onEdit: { editingTemplate = template }
                                )
                            }
                        }
                    }
                }
                .padding(Papper.spacing.lg)
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(PapperColors.neutral700)
            }
        }
        .sheet(isPresented: $showCreateTemplate) {
            CreateTemplateView()
        }
        .sheet(item: $editingTemplate) { template in
            EditTemplateView(template: template)
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: JournalTemplate
    let isBuiltIn: Bool
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(PapperColors.neutral100)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 20))
                        .foregroundColor(PapperColors.neutral700)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    if isBuiltIn {
                        Text("Built-in")
                            .font(.system(size: 11))
                            .foregroundColor(PapperColors.neutral500)
                    }
                }
                
                Spacer()
                
                if !isBuiltIn, let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(PapperColors.neutral600)
                    }
                }
            }
            
            // Prompts Preview
            VStack(alignment: .leading, spacing: 6) {
                ForEach(template.prompts.prefix(3), id: \.self) { prompt in
                    HStack(alignment: .top, spacing: Papper.spacing.xs) {
                        Circle()
                            .fill(PapperColors.neutral400)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(prompt)
                            .font(.system(size: 13))
                            .foregroundColor(PapperColors.neutral600)
                            .lineLimit(1)
                    }
                }
                
                if template.prompts.count > 3 {
                    Text("+ \(template.prompts.count - 3) more")
                        .font(.system(size: 12))
                        .foregroundColor(PapperColors.neutral500)
                        .padding(.leading, Papper.spacing.sm)
                }
            }
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Create Template View

struct CreateTemplateView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "doc.text.fill"
    @State private var prompts: [String] = [""]
    @State private var selectedJournal: Journal?
    @State private var isSaving = false
    
    let iconOptions = ["doc.text.fill", "sun.horizon.fill", "moon.stars.fill", "heart.fill", "target", "lightbulb.fill", "brain.head.profile", "star.fill"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Papper.spacing.xl) {
                        // Name & Icon
                        VStack(alignment: .leading, spacing: Papper.spacing.md) {
                            Text("Template Name")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            TextField("e.g., Morning Reflection", text: $name)
                                .font(.system(size: 16))
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                            
                            Text("Icon")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Papper.spacing.md) {
                                ForEach(iconOptions, id: \.self) { iconOption in
                                    Button(action: { icon = iconOption }) {
                                        ZStack {
                                            Circle()
                                                .fill(icon == iconOption ? PapperColors.neutral700 : PapperColors.neutral100)
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: iconOption)
                                                .font(.system(size: 22))
                                                .foregroundColor(icon == iconOption ? .white : PapperColors.neutral700)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(12)
                        }
                        
                        // Journal
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Journal (Optional)")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            Menu {
                                Button("All Journals") {
                                    selectedJournal = nil
                                }
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
                                        Text("All Journals")
                                            .foregroundColor(PapperColors.neutral800)
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
                        
                        // Prompts
                        VStack(alignment: .leading, spacing: Papper.spacing.md) {
                            Text("Prompts")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            ForEach(Array(prompts.enumerated()), id: \.offset) { index, _ in
                                HStack {
                                    TextField("Enter prompt \(index + 1)", text: $prompts[index])
                                        .font(.system(size: 15))
                                        .padding()
                                        .background(PapperColors.surfaceBackgroundPlain)
                                        .cornerRadius(10)
                                    
                                    if prompts.count > 1 {
                                        Button(action: { prompts.remove(at: index) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(PapperColors.pink600)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: { prompts.append("") }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Prompt")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PapperColors.neutral700)
                            }
                        }
                    }
                    .padding(Papper.spacing.lg)
                }
            }
            .navigationTitle("New Template")
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
                        saveTemplate()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(name.isEmpty || prompts.filter { !$0.isEmpty }.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let template = JournalTemplate(
            id: UUID().uuidString,
            userId: AuthService.shared.currentUser?.id ?? "",
            journalId: selectedJournal?.id ?? "",
            name: name,
            prompts: prompts.filter { !$0.isEmpty },
            structure: "",
            icon: icon,
            createdAt: Date(),
            updatedAt: Date(),
            isBuiltIn: false
        )
        
        isSaving = true
        
        Task {
            try? await FirebaseService.shared.createTemplate(template)
            dismiss()
        }
    }
}

// MARK: - Edit Template View

struct EditTemplateView: View {
    let template: JournalTemplate
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = ""
    @State private var prompts: [String] = []
    @State private var showDeleteAlert = false
    @State private var isSaving = false
    
    let iconOptions = ["doc.text.fill", "sun.horizon.fill", "moon.stars.fill", "heart.fill", "target", "lightbulb.fill", "brain.head.profile", "star.fill"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Papper.spacing.xl) {
                        // Name & Icon
                        VStack(alignment: .leading, spacing: Papper.spacing.md) {
                            Text("Template Name")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            TextField("Template name", text: $name)
                                .font(.system(size: 16))
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                            
                            Text("Icon")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Papper.spacing.md) {
                                ForEach(iconOptions, id: \.self) { iconOption in
                                    Button(action: { icon = iconOption }) {
                                        ZStack {
                                            Circle()
                                                .fill(icon == iconOption ? PapperColors.neutral700 : PapperColors.neutral100)
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: iconOption)
                                                .font(.system(size: 22))
                                                .foregroundColor(icon == iconOption ? .white : PapperColors.neutral700)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(12)
                        }
                        
                        // Prompts
                        VStack(alignment: .leading, spacing: Papper.spacing.md) {
                            Text("Prompts")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            ForEach(Array(prompts.enumerated()), id: \.offset) { index, _ in
                                HStack {
                                    TextField("Enter prompt", text: $prompts[index])
                                        .font(.system(size: 15))
                                        .padding()
                                        .background(PapperColors.surfaceBackgroundPlain)
                                        .cornerRadius(10)
                                    
                                    if prompts.count > 1 {
                                        Button(action: { prompts.remove(at: index) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(PapperColors.pink600)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: { prompts.append("") }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Prompt")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PapperColors.neutral700)
                            }
                        }
                        
                        // Delete
                        Button(action: { showDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Template")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PapperColors.pink600)
                            .frame(maxWidth: .infinity)
                            .padding(Papper.spacing.md)
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(12)
                        }
                    }
                    .padding(Papper.spacing.lg)
                }
            }
            .navigationTitle("Edit Template")
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
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(name.isEmpty || prompts.filter { !$0.isEmpty }.isEmpty || isSaving)
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteTemplate()
                }
            }
            .onAppear {
                name = template.name
                icon = template.icon
                prompts = template.prompts
            }
        }
    }
    
    private func saveChanges() {
        var updated = template
        updated.name = name
        updated.icon = icon
        updated.prompts = prompts.filter { !$0.isEmpty }
        updated.updatedAt = Date()
        
        isSaving = true
        
        Task {
            try? await FirebaseService.shared.updateTemplate(updated)
            dismiss()
        }
    }
    
    private func deleteTemplate() {
        Task {
            try? await FirebaseService.shared.deleteTemplate(template.id)
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TemplatesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TemplatesListView()
        }
    }
}
#endif

