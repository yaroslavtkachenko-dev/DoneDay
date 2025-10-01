//
//  ProjectDetailView.swift
//  DoneDay - ПОВНА ВЕРСІЯ З РЕДАГУВАННЯМ, ВИДАЛЕННЯМ ТА ДЕТАЛЯМИ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddTask = false
    @State private var showingEditProject = false
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: TaskFilterType = .all
    @State private var selectedTask: TaskEntity? { // ✅ Для перегляду деталей
        didSet {
            print("🔍 DEBUG: selectedTask changed to: \(selectedTask?.title ?? "nil")")
            print("🔍 DEBUG: selectedTask objectID: \(selectedTask?.objectID.description ?? "nil")")
        }
    }
    @State private var taskToEdit: TaskEntity? // ✅ Для редагування
    @State private var taskToDelete: TaskEntity? // ✅ Для видалення
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
        let _ = print("🔍 DEBUG: ProjectDetailView body rendered - selectedTask: \(selectedTask?.title ?? "nil")")
        NavigationView {
            ZStack {
                Color(NSColor.controlBackgroundColor)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // HERO SECTION
                    heroSection
                    
                    // ФІЛЬТРИ
                    filterSection
                    
                    // ЗАВДАННЯ
                    tasksSection
                }
                
                // FAB для додавання
                fabSection
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
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
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // ✅ Додавання завдання
            .sheet(isPresented: $showingAddTask) {
                NavigationStack {
                    ModernAddTaskView(
                        taskViewModel: taskViewModel,
                        preselectedProject: project
                    )
                }
                #if os(macOS)
                .frame(minWidth: 650, idealWidth: 750, maxWidth: 900)
                .frame(minHeight: 650, idealHeight: 800, maxHeight: 1000)
                #endif
            }
            // ✅ Перегляд деталей завдання
            .sheet(item: $selectedTask) { task in
                NavigationStack {
                    ModernTaskDetailView(task: task, taskViewModel: taskViewModel)
                }
                #if os(macOS)
                .frame(minWidth: 600, idealWidth: 700, maxWidth: 850)
                .frame(minHeight: 600, idealHeight: 750, maxHeight: 900)
                #endif
                .onAppear {
                    print("🔍 DEBUG: Sheet opened for task: \(task.title ?? "Без назви")")
                    print("🔍 DEBUG: Sheet task.objectID: \(task.objectID)")
                }
                .onDisappear {
                    print("🔍 DEBUG: Sheet closed")
                }
            }
            // ✅ Редагування завдання
            .sheet(item: $taskToEdit) { task in
                NavigationStack {
                    ModernEditTaskView(task: task, taskViewModel: taskViewModel)
                }
                #if os(macOS)
                .frame(minWidth: 650, idealWidth: 750, maxWidth: 900)
                .frame(minHeight: 650, idealHeight: 800, maxHeight: 1000)
                #endif
            }
            // ✅ Редагування проекту
        .sheet(isPresented: $showingEditProject) {
            AddEditProjectView(taskViewModel: taskViewModel, project: project)
                    #if os(macOS)
                    .frame(minWidth: 600, minHeight: 700)
                    #endif
        }
            // ✅ Видалення проекту
            .alert("Видалити проект?", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteProject()
            }
        } message: {
                Text("Всі завдання будуть переміщені в Inbox")
            }
            // ✅ Видалення завдання
            .alert("Видалити завдання?", isPresented: $showingDeleteTaskAlert, presenting: taskToDelete) { task in
                Button("Скасувати", role: .cancel) { }
                Button("Видалити", role: .destructive) {
                    deleteTask(task)
                }
            } message: { task in
                Text("Завдання \"\(task.title ?? "")\" буде видалено")
            }
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
                        TaskCardWithActions(
                            task: task,
                            taskViewModel: taskViewModel,
                            projectColor: Color(red: 0.2, green: 0.4, blue: 0.8),
                            onTap: {
                                print("🔍 DEBUG: ProjectDetailView - Task tapped: \(task.title ?? "Без назви")")
                                print("🔍 DEBUG: ProjectDetailView - selectedTask before: \(selectedTask?.title ?? "nil")")
                                print("🔍 DEBUG: ProjectDetailView - task.objectID: \(task.objectID)")
                                selectedTask = task // ✅ Відкрити деталі
                                print("🔍 DEBUG: ProjectDetailView - selectedTask after: \(selectedTask?.title ?? "nil")")
                            },
                            onEdit: {
                                taskToEdit = task // ✅ Редагувати
                            },
                            onDelete: {
                                taskToDelete = task // ✅ Видалити
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
                .onChange(of: selectedTask) { _, newValue in
                    if let task = newValue {
                        print("🔍 DEBUG: ProjectDetailView - selectedTask changed to: \(task.title ?? "Без назви")")
                    }
                }
            }
        }
    }
    
    // MARK: - FAB Section
    
    private var fabSection: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button {
                    showingAddTask = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Додати")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.8),
                                Color(red: 0.15, green: 0.35, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.4, blue: 0.8),
                        Color(red: 0.15, green: 0.35, blue: 0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                
                VStack(spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 56, height: 56)
                    .overlay {
                                Image(systemName: project.iconName ?? "folder.fill")
                                    .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Без назви")
                        .font(.title2)
                        .fontWeight(.bold)
                                .foregroundColor(.white)
                    
                    if let area = project.area {
                            Text(area.name ?? "Область")
                                .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(completedTasks.count) з \(projectTasks.count + completedTasks.count)")
                            .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                            Text("\(Int(progress * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.3))
                                
                                Capsule()
                                    .fill(.white)
                                    .frame(width: geometry.size.width * progress)
                            }
                        }
                        .frame(height: 8)
            }
        }
        .padding(20)
                .padding(.bottom, 10)
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        count: countForFilter(filter),
                        isSelected: selectedFilter == filter,
                        accentColor: Color(red: 0.2, green: 0.4, blue: 0.8)
                    ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.regularMaterial)
    }
    
    private func countForFilter(_ filter: TaskFilterType) -> Int {
        switch filter {
        case .all:
            return projectTasks.count
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
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: selectedFilter == .all ? "checkmark.circle" : "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3)
                            .fontWeight(.semibold)
                
                Text(emptyStateSubtitle)
                    .font(.body)
                            .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
    
    // MARK: - Actions
    
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
    
    // ✅ Видалення завдання
    private func deleteTask(_ task: TaskEntity) {
        taskViewModel.deleteTask(task)
        taskToDelete = nil
    }
}

// MARK: - Task Card With Actions (✅ ВИПРАВЛЕНО)

struct TaskCardWithActions: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    let projectColor: Color
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    taskViewModel.toggleTaskCompletion(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(projectColor.opacity(0.3), lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(projectColor)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title ?? "Без назви")
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                // Tags and metadata
                HStack(spacing: 8) {
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
                    
                    if task.priority > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("Пріоритет")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Action indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        .contentShape(Rectangle()) // ✅ ВАЖЛИВО - робить всю область кліка активною
        .onTapGesture {  // ✅ КРИТИЧНЕ ДОДАВАННЯ!
            print("🖱️ TaskCardWithActions onTapGesture - викликано для: \(task.title ?? "Без назви")")
            onTap()
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
    }
}

// MARK: - Compact Task Row (Updated)

struct CompactTaskRow: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.body)
                
                Text(task.title ?? "Без назви")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .strikethrough()
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip (Unchanged)

struct FilterChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.3) : accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(accentColor)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
    ProjectDetailView(
        project: ProjectEntity(),
        taskViewModel: TaskViewModel()
    )
}
}