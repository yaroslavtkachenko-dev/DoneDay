//
//  ProjectsListView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct ProjectsListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var isGridView = false
    @State private var showingAddProject = false
    @State private var selectedProject: ProjectEntity?
    @State private var searchText = ""
    @State private var projectToEdit: ProjectEntity?
    @State private var projectToDelete: ProjectEntity?
    @State private var showingDeleteAlert = false
    
    private var filteredProjects: [ProjectEntity] {
        if searchText.isEmpty {
            return taskViewModel.projects
        } else {
            return taskViewModel.projects.filter { project in
                project.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                ProjectsHeaderView(projectCount: taskViewModel.projects.count)
                
                // Search and controls
                ProjectsControlsView(
                    searchText: $searchText,
                    isGridView: $isGridView,
                    onAddProject: { showingAddProject = true }
                )
                
                // Projects content
                if filteredProjects.isEmpty {
                    ProjectsEmptyStateView(hasSearch: !searchText.isEmpty)
                } else {
                    ProjectsContentView(
                        projects: filteredProjects,
                        isGridView: isGridView,
                        taskViewModel: taskViewModel,
                        onProjectTap: { project in
                            selectedProject = project
                        },
                        onProjectEdit: { project in
                            projectToEdit = project
                        },
                        onProjectDelete: { project in
                            projectToDelete = project
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("Проекти")
            .sheet(isPresented: $showingAddProject) {
                AddEditProjectView(taskViewModel: taskViewModel)
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project, taskViewModel: taskViewModel)
            }
            .sheet(item: $projectToEdit) { project in
                AddEditProjectView(taskViewModel: taskViewModel, project: project)
            }
            .alert("Видалити проект?", isPresented: $showingDeleteAlert, presenting: projectToDelete) { project in
                Button("Скасувати", role: .cancel) { }
                Button("Видалити", role: .destructive) {
                    deleteProject(project)
                }
            } message: { project in
                Text("Проект \"\(project.name ?? "")\" буде видалено. Всі завдання будуть переміщені в Inbox.")
            }
        }
    }
    
    private func deleteProject(_ project: ProjectEntity) {
        // Перемістити всі завдання в inbox
        let tasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        for task in tasks {
            task.project = nil
            task.updatedAt = Date()
        }
        
        // Видалити проект
        DataManager.shared.context.delete(project)
        
        do {
            try DataManager.shared.save()
            print("✅ Project deleted successfully")
        } catch {
            print("❌ Error deleting project: \(error)")
        }
    }
}

// MARK: - Projects Header View

struct ProjectsHeaderView: View {
    let projectCount: Int
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveBottomPadding: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваші проекти")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(projectCount) активних проектів")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Stats badge
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text("\(projectCount)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
        }
        .adaptivePadding()
        .background(.regularMaterial)
    }
}

// MARK: - Projects Controls View

struct ProjectsControlsView: View {
    @Binding var searchText: String
    @Binding var isGridView: Bool
    let onAddProject: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveBottomPadding: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Пошук проектів...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("Очистити") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Controls row
            HStack {
                // View toggle
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isGridView = false
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundColor(isGridView ? .secondary : .white)
                            .frame(width: 44, height: 32)
                            .background(isGridView ? .clear : .blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isGridView = true
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(isGridView ? .white : .secondary)
                            .frame(width: 44, height: 32)
                            .background(isGridView ? .blue : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                // Add project button
                Button(action: onAddProject) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Новий проект")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .adaptivePadding()
        .padding(.bottom, adaptiveBottomPadding)
    }
}

// MARK: - Projects Content View

struct ProjectsContentView: View {
    let projects: [ProjectEntity]
    let isGridView: Bool
    let taskViewModel: TaskViewModel
    let onProjectTap: (ProjectEntity) -> Void
    let onProjectEdit: ((ProjectEntity) -> Void)?
    let onProjectDelete: ((ProjectEntity) -> Void)?
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveGridColumns: [GridItem] {
        let columnsCount = horizontalSizeClass == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnsCount)
    }
    
    private var adaptiveSpacing: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        ScrollView {
            if isGridView {
                LazyVGrid(columns: adaptiveGridColumns, spacing: adaptiveSpacing) {
                    ForEach(projects, id: \.objectID) { project in
                        ProjectGridCard(
                            project: project,
                            taskViewModel: taskViewModel,
                            onTap: { onProjectTap(project) },
                            onEdit: onProjectEdit != nil ? { onProjectEdit!(project) } : nil,
                            onDelete: onProjectDelete != nil ? { onProjectDelete!(project) } : nil
                        )
                    }
                }
                .adaptivePadding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(projects, id: \.objectID) { project in
                        ProjectListCard(
                            project: project,
                            taskViewModel: taskViewModel,
                            onTap: { onProjectTap(project) }
                        )
                    }
                }
                .adaptivePadding()
            }
        }
    }
}

// MARK: - Project Grid Card

struct ProjectGridCard: View {
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    private var taskStats: (total: Int, completed: Int, overdue: Int) {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        let activeTasks = allTasks.filter { !$0.isDelete }
        let completed = activeTasks.filter { $0.isCompleted }.count
        let overdue = activeTasks.filter {
            !$0.isCompleted &&
            $0.dueDate != nil &&
            $0.dueDate! < Date()
        }.count
        
        return (activeTasks.count, completed, overdue)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                    
                    Spacer()
                    
                    if taskStats.overdue > 0 {
                        Text("\(taskStats.overdue)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(.red)
                            .clipShape(Circle())
                    }
                }
                
                // Project info
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name ?? "Без назви")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let notes = project.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Area tag
                    if let area = project.area {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text(area.name ?? "Область")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Прогрес")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(taskStats.completed)/\(taskStats.total)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: taskStats.total > 0 ? Double(taskStats.completed) / Double(taskStats.total) : 0)
                        .tint(.blue)
                }
            }
            .padding(16)
            .frame(minHeight: 180, maxHeight: 220)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Відкрити", systemImage: "eye")
            }
            
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Редагувати", systemImage: "pencil")
                }
            }
            
            Divider()
            
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Видалити", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Project List Card

struct ProjectListCard: View {
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    let onTap: () -> Void
    
    private var taskStats: (total: Int, completed: Int, overdue: Int) {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        let activeTasks = allTasks.filter { !$0.isDelete }
        let completed = activeTasks.filter { $0.isCompleted }.count
        let overdue = activeTasks.filter {
            !$0.isCompleted &&
            $0.dueDate != nil &&
            $0.dueDate! < Date()
        }.count
        
        return (activeTasks.count, completed, overdue)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(project.name ?? "Без назви")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if taskStats.overdue > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("\(taskStats.overdue)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    if let notes = project.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Tags and stats
                    HStack {
                        if let area = project.area {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.caption2)
                                Text(area.name ?? "Область")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.purple.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text("\(taskStats.completed)/\(taskStats.total) завдань")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    ProgressView(value: taskStats.total > 0 ? Double(taskStats.completed) / Double(taskStats.total) : 0)
                        .tint(.blue)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Projects Empty State

struct ProjectsEmptyStateView: View {
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: hasSearch ? "magnifyingglass" : "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(hasSearch ? "Нічого не знайдено" : "Ще немає проектів")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasSearch ? "Спробуйте змінити пошуковий запит" : "Створіть свій перший проект для організації завдань")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    ProjectsListView()
}
