//
//  ProjectManagementView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Project Deletion with Task Reassignment View

struct ProjectDeletionView: View {
    @Environment(\.presentationMode) var presentationMode
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    
    @State private var selectedOption: DeletionOption = .moveToInbox
    @State private var selectedProject: ProjectEntity?
    @State private var isDeleting = false
    
    private var projectTasks: [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete && !$0.isCompleted }
    }
    
    private var availableProjects: [ProjectEntity] {
        taskViewModel.projects.filter { $0.objectID != project.objectID && !$0.isCompleted }
    }
    
    enum DeletionOption: String, CaseIterable {
        case moveToInbox = "inbox"
        case moveToProject = "project"
        case deleteTasks = "delete"
        
        var title: String {
            switch self {
            case .moveToInbox: return "Перемістити в Inbox"
            case .moveToProject: return "Перемістити в інший проект"
            case .deleteTasks: return "Видалити всі завдання"
            }
        }
        
        var description: String {
            switch self {
            case .moveToInbox: return "Завдання будуть переміщені в загальний список"
            case .moveToProject: return "Завдання будуть переміщені в обраний проект"
            case .deleteTasks: return "Всі завдання проекту будуть видалені назавжди"
            }
        }
        
        var icon: String {
            switch self {
            case .moveToInbox: return "tray.fill"
            case .moveToProject: return "folder.fill"
            case .deleteTasks: return "trash.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .moveToInbox: return .blue
            case .moveToProject: return .green
            case .deleteTasks: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ProjectDeletionHeader(project: project, taskCount: projectTasks.count)
                    
                    // Options
                    ProjectDeletionOptions(
                        selectedOption: $selectedOption,
                        selectedProject: $selectedProject,
                        availableProjects: availableProjects,
                        projectTasks: projectTasks
                    )
                    
                    // Task preview
                    if !projectTasks.isEmpty {
                        TasksPreviewSection(tasks: projectTasks)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Видалити проект") {
                        deleteProject()
                    }
                    .foregroundColor(.red)
                    .disabled(isDeleting || (selectedOption == .moveToProject && selectedProject == nil))
                }
            }
        }
        .disabled(isDeleting)
    }
    
    private func deleteProject() {
        isDeleting = true
        
        // Handle tasks based on selected option
        switch selectedOption {
        case .moveToInbox:
            for task in projectTasks {
                task.project = nil
                task.updatedAt = Date()
            }
            
        case .moveToProject:
            guard let targetProject = selectedProject else { return }
            for task in projectTasks {
                task.project = targetProject
                task.updatedAt = Date()
            }
            
        case .deleteTasks:
            for task in projectTasks {
                task.isDelete = true
                task.updatedAt = Date()
            }
        }
        
        // Delete the project
        PersistenceController.shared.context.delete(project)
        
        let saveResult = PersistenceController.shared.save()
        switch saveResult {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            isDeleting = false
        }
    }
}

struct ProjectDeletionHeader: View {
    let project: ProjectEntity
    let taskCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Warning icon
            Circle()
                .fill(.red.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 8) {
                Text("Видалити проект")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Ви збираєтесь видалити проект \"\(project.name ?? "Без назви")\"")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if taskCount > 0 {
                    Text("У цьому проекті \(taskCount) активних завдань. Оберіть, що з ними робити:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("У цьому проекті немає активних завдань.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ProjectDeletionOptions: View {
    @Binding var selectedOption: ProjectDeletionView.DeletionOption
    @Binding var selectedProject: ProjectEntity?
    let availableProjects: [ProjectEntity]
    let projectTasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Що робити з завданнями?")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(ProjectDeletionView.DeletionOption.allCases, id: \.self) { option in
                    DeletionOptionCard(
                        option: option,
                        isSelected: selectedOption == option,
                        isEnabled: option != .moveToProject || !availableProjects.isEmpty,
                        onSelect: {
                            selectedOption = option
                            if option != .moveToProject {
                                selectedProject = nil
                            }
                        }
                    )
                }
            }
            
            // Project selector for move to project option
            if selectedOption == .moveToProject {
                ProjectSelectorSection(
                    selectedProject: $selectedProject,
                    availableProjects: availableProjects
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DeletionOptionCard: View {
    let option: ProjectDeletionView.DeletionOption
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : option.color)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? option.color : option.color.opacity(0.1))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? option.color : .primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .stroke(option.color, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(option.color)
                                .frame(width: 12, height: 12)
                        }
                    }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? option.color.opacity(0.1) : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? option.color : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    }
            }
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct ProjectSelectorSection: View {
    @Binding var selectedProject: ProjectEntity?
    let availableProjects: [ProjectEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оберіть проект-призначення:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if availableProjects.isEmpty {
                Text("Немає доступних проектів")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(availableProjects, id: \.objectID) { project in
                        ProjectSelectCard(
                            project: project,
                            isSelected: selectedProject?.objectID == project.objectID,
                            onSelect: { selectedProject = project }
                        )
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

struct ProjectSelectCard: View {
    let project: ProjectEntity
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: project.iconName ?? "folder.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                
                Text(project.name ?? "Без назви")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? .blue.opacity(0.1) : .gray.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct TasksPreviewSection: View {
    let tasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Завдання проекту")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(tasks.count) завдань")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(tasks.prefix(5)), id: \.objectID) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)
                        
                        Text(task.title ?? "Без назви")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if task.priority > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<Int(task.priority), id: \.self) { _ in
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if tasks.count > 5 {
                    Text("і ще \(tasks.count - 5) завдань...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Project Completion Workflow View

struct ProjectCompletionView: View {
    @Environment(\.presentationMode) var presentationMode
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    
    @State private var completionOption: CompletionOption = .completeAll
    @State private var showArchive = true
    @State private var completionNotes = ""
    @State private var isCompleting = false
    
    private var projectTasks: [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete }
    }
    
    private var incompleteTasks: [TaskEntity] {
        projectTasks.filter { !$0.isCompleted }
    }
    
    enum CompletionOption: String, CaseIterable {
        case completeAll = "all"
        case completeActiveOnly = "active"
        case moveIncomplete = "move"
        
        var title: String {
            switch self {
            case .completeAll: return "Завершити всі завдання"
            case .completeActiveOnly: return "Завершити тільки активні"
            case .moveIncomplete: return "Перемістити незавершені"
            }
        }
        
        var description: String {
            switch self {
            case .completeAll: return "Всі завдання проекту будуть позначені як завершені"
            case .completeActiveOnly: return "Тільки активні завдання будуть завершені"
            case .moveIncomplete: return "Незавершені завдання переносяться в Inbox"
            }
        }
        
        var icon: String {
            switch self {
            case .completeAll: return "checkmark.circle.fill"
            case .completeActiveOnly: return "checkmark.circle"
            case .moveIncomplete: return "arrow.right.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .completeAll: return .green
            case .completeActiveOnly: return .blue
            case .moveIncomplete: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ProjectCompletionHeader(project: project)
                    
                    // Statistics
                    ProjectCompletionStats(projectTasks: projectTasks)
                    
                    // Completion options
                    ProjectCompletionOptions(
                        selectedOption: $completionOption,
                        incompleteTasks: incompleteTasks
                    )
                    
                    // Additional settings
                    ProjectCompletionSettings(
                        showArchive: $showArchive,
                        completionNotes: $completionNotes
                    )
                    
                    // Tasks preview
                    if !incompleteTasks.isEmpty {
                        IncompleteTasksPreview(tasks: incompleteTasks)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Завершити проект") {
                        completeProject()
                    }
                    .foregroundColor(.green)
                    .disabled(isCompleting)
                }
            }
        }
        .disabled(isCompleting)
    }
    
    private func completeProject() {
        isCompleting = true
        
        // Handle tasks based on completion option
        switch completionOption {
        case .completeAll:
            for task in projectTasks where !task.isCompleted {
                task.isCompleted = true
                task.updatedAt = Date()
            }
            
        case .completeActiveOnly:
            for task in incompleteTasks {
                task.isCompleted = true
                task.updatedAt = Date()
            }
            
        case .moveIncomplete:
            for task in incompleteTasks {
                task.project = nil
                task.updatedAt = Date()
            }
        }
        
        // Complete the project
        project.isCompleted = true
        project.updatedAt = Date()
        
        // Add completion notes if provided
        if !completionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let currentNotes = project.notes ?? ""
            let separator = currentNotes.isEmpty ? "" : "\n\n"
            project.notes = currentNotes + separator + "Завершено: " + completionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let saveResult = PersistenceController.shared.save()
        switch saveResult {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            isCompleting = false
        }
    }
}

struct ProjectCompletionHeader: View {
    let project: ProjectEntity
    
    var body: some View {
        VStack(spacing: 20) {
            // Success icon
            Circle()
                .fill(.green.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 8) {
                Text("Завершити проект")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Вітаємо! Ви готові завершити проект \"\(project.name ?? "Без назви")\"")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Оберіть, як завершити проект та що робити з незавершеними завданнями")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct ProjectCompletionStats: View {
    let projectTasks: [TaskEntity]
    
    private var stats: (total: Int, completed: Int, incomplete: Int, percentage: Int) {
        let total = projectTasks.count
        let completed = projectTasks.filter { $0.isCompleted }.count
        let incomplete = total - completed
        let percentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
        return (total, completed, incomplete, percentage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика проекту")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                StatBadge(
                    title: "Всього",
                    value: "\(stats.total)",
                    color: .blue,
                    icon: "list.bullet"
                )
                
                StatBadge(
                    title: "Завершено",
                    value: "\(stats.completed)",
                    color: .green,
                    icon: "checkmark.circle"
                )
                
                StatBadge(
                    title: "Залишилось",
                    value: "\(stats.incomplete)",
                    color: .orange,
                    icon: "clock"
                )
                
                StatBadge(
                    title: "Прогрес",
                    value: "\(stats.percentage)%",
                    color: .purple,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProjectCompletionOptions: View {
    @Binding var selectedOption: ProjectCompletionView.CompletionOption
    let incompleteTasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Опції завершення")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(ProjectCompletionView.CompletionOption.allCases, id: \.self) { option in
                    CompletionOptionCard(
                        option: option,
                        isSelected: selectedOption == option,
                        incompleteTasks: incompleteTasks,
                        onSelect: { selectedOption = option }
                    )
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CompletionOptionCard: View {
    let option: ProjectCompletionView.CompletionOption
    let isSelected: Bool
    let incompleteTasks: [TaskEntity]
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : option.color)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? option.color : option.color.opacity(0.1))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? option.color : .primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if option == .moveIncomplete && !incompleteTasks.isEmpty {
                        Text("Буде переміщено \(incompleteTasks.count) завдань")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .stroke(option.color, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(option.color)
                                .frame(width: 12, height: 12)
                        }
                    }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? option.color.opacity(0.1) : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? option.color : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ProjectCompletionSettings: View {
    @Binding var showArchive: Bool
    @Binding var completionNotes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Додаткові налаштування")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Archive toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Архівувати проект")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Завершений проект буде переміщено в архів")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $showArchive)
                        .labelsHidden()
                }
                
                // Completion notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Нотатки про завершення")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Додайте коментар про завершення проекту...", text: $completionNotes, axis: .vertical)
                        .textFieldStyle(ModernTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct IncompleteTasksPreview: View {
    let tasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Незавершені завдання")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(tasks.count) завдань")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(tasks.prefix(5)), id: \.objectID) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(.orange, lineWidth: 2)
                            .frame(width: 16, height: 16)
                        
                        Text(task.title ?? "Без назви")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let dueDate = task.dueDate {
                            Text(dueDate < Date() ? "Прострочено" : "До \(dueDate, style: .date)")
                                .font(.caption)
                                .foregroundColor(dueDate < Date() ? .red : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if tasks.count > 5 {
                    Text("і ще \(tasks.count - 5) завдань...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let viewModel = TaskViewModel()
    return ProjectDeletionView(
        project: ProjectEntity(),
        taskViewModel: viewModel
    )
    .environmentObject(viewModel)
}
