//
//  ProjectDetailView.swift
//  DoneDay - З ПОКРАЩЕНИМ ЧЕКБОКСОМ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Покращений чекбокс (додано в цей файл)

struct ImprovedTaskCheckbox: View {
    let isCompleted: Bool
    let action: () -> Void
    var size: CGFloat = 24
    var color: Color = .blue
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            ZStack {
                Circle()
                    .strokeBorder(
                        isCompleted ? color : Color.gray.opacity(0.3),
                        lineWidth: 2.5
                    )
                    .frame(width: size, height: size)
                
                if isCompleted {
                    Circle()
                        .fill(color)
                        .frame(width: size - 2, height: size - 2)
                        .transition(.scale.combined(with: .opacity))
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if isPressed {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .frame(width: size + 8, height: size + 8)
                        .opacity(0)
                        .scaleEffect(1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Main View

struct ProjectDetailView: View {
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddTask = false
    @State private var showingEditProject = false
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: TaskFilterType = .all
    @State private var selectedTask: TaskEntity? {
        didSet {
            print("🔍 DEBUG: selectedTask changed to: \(selectedTask?.title ?? "nil")")
        }
    }
    @State private var taskToEdit: TaskEntity?
    @State private var taskToDelete: TaskEntity?
    @State private var showingDeleteTaskAlert = false
    
    enum TaskFilterType: String, CaseIterable {
        case all = "Всі"
        case today = "Сьогодні"
        case overdue = "Прострочені"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar"
            case .overdue: return "exclamationmark.triangle"
            }
        }
    }
    
    private var projectTasks: [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete && !$0.isCompleted }
    }
    
    private var filteredTasks: [TaskEntity] {
        switch selectedFilter {
        case .all:
            return projectTasks
        case .today:
            return projectTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        case .overdue:
            return projectTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < Date()
            }
        }
    }
    
    private var completedTasks: [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete && $0.isCompleted }
    }
    
    private var progress: Double {
        let total = projectTasks.count + completedTasks.count
        guard total > 0 else { return 0 }
        return Double(completedTasks.count) / Double(total)
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                headerSection
                filterSection
                tasksSection
            }
            .background(Color.clear)
            .navigationTitle(project.name ?? "Проект")
            .safeAreaInset(edge: .bottom) {
                FloatingActionButton {
                    showingAddTask = true
                }
                .padding()
            }
        } detail: {
            if let task = selectedTask {
                ModernTaskDetailView(task: task, taskViewModel: taskViewModel)
            } else {
                Text("Оберіть завдання")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingAddTask) {
            ModernAddTaskView(taskViewModel: taskViewModel, preselectedProject: project)
        }
        .sheet(item: $taskToEdit) { task in
            NavigationStack {
                ModernEditTaskView(task: task, taskViewModel: taskViewModel)
            }
            #if os(macOS)
            .frame(minWidth: 650, idealWidth: 750, maxWidth: 900)
            .frame(minHeight: 650, idealHeight: 800, maxHeight: 1000)
            #endif
        }
        .sheet(isPresented: $showingEditProject) {
            AddEditProjectView(taskViewModel: taskViewModel, project: project)
        }
        .alert("Видалити проект?", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("Проект \"\(project.name ?? "")\" буде видалено. Завдання переміститься в Inbox.")
        }
        .alert("Видалити завдання?", isPresented: $showingDeleteTaskAlert, presenting: taskToDelete) { task in
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteTask(task)
            }
        } message: { task in
            Text("Завдання \"\(task.title ?? "")\" буде видалено")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(project.colorValue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: project.iconName ?? "folder.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Без назви")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let area = project.area {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text(area.name ?? "")
                                .font(.subheadline)
                        }
                        .foregroundColor(area.colorValue)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button {
                        showingEditProject = true
                    } label: {
                        Label("Редагувати", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Видалити", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progress)
                .tint(project.colorValue)
            
            HStack {
                Text("\(completedTasks.count) з \(projectTasks.count + completedTasks.count) завдань")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(project.colorValue)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        count: taskCount(for: filter),
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        Group {
            if filteredTasks.isEmpty {
                emptyStateView
            } else {
                List(selection: $selectedTask) {
                    ForEach(filteredTasks, id: \.objectID) { task in
                        ImprovedTaskCard(
                            task: task,
                            taskViewModel: taskViewModel,
                            projectColor: project.colorValue,
                            onTap: {
                                selectedTask = task
                            },
                            onEdit: {
                                taskToEdit = task
                            },
                            onDelete: {
                                taskToDelete = task
                                showingDeleteTaskAlert = true
                            }
                        )
                        .tag(task)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    if !completedTasks.isEmpty && selectedFilter == .all {
                        Section {
                            completedSection
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateSubtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "checkmark.circle"
        case .today: return "sun.max"
        case .overdue: return "checkmark.circle.fill"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return projectTasks.isEmpty && completedTasks.isEmpty ? "Немає завдань" : "Все готово!"
        case .today: return "Нічого на сьогодні"
        case .overdue: return "Немає прострочених"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .all: return projectTasks.isEmpty && completedTasks.isEmpty ? "Додайте перше завдання" : "Всі завдання виконані"
        case .today: return "Завдань на сьогодні немає"
        case .overdue: return "Чудова робота!"
        }
    }
    
    // MARK: - Completed Section
    
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Завершено")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(completedTasks.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            ForEach(completedTasks.prefix(3), id: \.objectID) { task in
                CompactTaskRow(
                    task: task,
                    taskViewModel: taskViewModel,
                    color: project.colorValue,
                    onTap: {
                        selectedTask = task
                    }
                )
            }
            
            if completedTasks.count > 3 {
                Text("та ще \(completedTasks.count - 3)...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func taskCount(for filter: TaskFilterType) -> Int {
        switch filter {
        case .all: return projectTasks.count
        case .today:
            return projectTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }.count
        case .overdue:
            return projectTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < Date()
            }.count
        }
    }
    
    private func deleteProject() {
        for task in projectTasks {
            task.project = nil
            task.updatedAt = Date()
        }
        
        DataManager.shared.context.delete(project)
        
        do {
            try DataManager.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting project: \(error)")
        }
    }
    
    private func deleteTask(_ task: TaskEntity) {
        taskViewModel.deleteTask(task)
        taskToDelete = nil
    }
}

// MARK: - Покращена Task Card

struct ImprovedTaskCard: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    let projectColor: Color
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Покращений чекбокс
            ImprovedTaskCheckbox(
                isCompleted: task.isCompleted,
                action: {
                    taskViewModel.toggleTaskCompletion(task)
                },
                size: 24,
                color: projectColor
            )
            
            // Контент
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title ?? "Без назви")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(dueDate < Date() ? .red : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((dueDate < Date() ? Color.red : Color.orange).opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            if let dueDate = task.dueDate, dueDate < Date(), !task.isCompleted {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1 : 0)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isHovered ? 0.08 : 0.03), radius: isHovered ? 8 : 2, y: isHovered ? 4 : 1)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Переглянути", systemImage: "eye")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Редагувати", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Видалити", systemImage: "trash")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Compact Task Row

struct CompactTaskRow: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    var color: Color = .green
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ImprovedTaskCheckbox(
                    isCompleted: task.isCompleted,
                    action: {
                        taskViewModel.toggleTaskCompletion(task)
                    },
                    size: 20,
                    color: color
                )
                
                Text(task.title ?? "Без назви")
                    .font(.system(size: 14))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background {
                        Circle()
                            .fill(.blue.gradient)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}
