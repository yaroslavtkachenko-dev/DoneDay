//
//  MainAppIntegration.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Enhanced ContentView with Projects Integration

struct EnhancedContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var showingProjectsView = false
    @State private var showingAddProject = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedProject: ProjectEntity?
    @State private var showingProjectDetail = false
    @State private var selectedTask: TaskEntity?
    @State private var taskToEdit: TaskEntity?
    
    enum TaskFilter: String, CaseIterable {
        case all = "Всі"
        case today = "Сьогодні"
        case upcoming = "Майбутні"
        case inbox = "Inbox"
        case completed = "Завершені"
        case projects = "Проекти"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar.badge.clock"
            case .upcoming: return "calendar"
            case .inbox: return "tray"
            case .completed: return "checkmark.circle"
            case .projects: return "folder"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .today: return .orange
            case .upcoming: return .blue
            case .inbox: return .gray
            case .completed: return .green
            case .projects: return .purple
            }
        }
    }
    
    private var filteredTasks: [TaskEntity] {
        switch selectedFilter {
        case .all:
            return taskViewModel.tasks
        case .today:
            return taskViewModel.getTodayTasks()
        case .upcoming:
            return taskViewModel.getUpcomingTasks()
        case .inbox:
            return taskViewModel.getInboxTasks()
        case .completed:
            return taskViewModel.getCompletedTasks()
        case .projects:
            return [] // Projects view will handle this differently
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Header with Projects
                EnhancedHeaderView(
                    taskViewModel: taskViewModel,
                    selectedFilter: selectedFilter, 
                    taskCount: selectedFilter == .projects ? taskViewModel.projects.count : filteredTasks.count
                )
                
                // Enhanced Filter Pills
                EnhancedFilterPillsView(selectedFilter: $selectedFilter)
                
                // Content based on filter
                if selectedFilter == .projects {
                    ProjectsQuickView(
                        taskViewModel: taskViewModel,
                        onProjectTap: { project in
                            selectedProject = project
                            showingProjectDetail = true
                        },
                        onShowAllProjects: { showingProjectsView = true }
                    )
                } else {
                    // Regular tasks view
                    if filteredTasks.isEmpty {
                        EnhancedEmptyStateView(filter: selectedFilter.rawValue)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTasks, id: \.objectID) { task in
                    ImprovedTaskCard(
                        task: task,
                        taskViewModel: taskViewModel,
                        projectColor: task.project?.colorValue ?? .blue,
                        onTap: {
                            print("🖱️ EnhancedContentView - Task tapped: \(task.title ?? "Без назви")")
                            selectedTask = task
                        },
                        onEdit: {
                            print("✏️ EnhancedContentView - Task edit: \(task.title ?? "Без назви")")
                            taskToEdit = task
                        },
                        onDelete: {
                            print("🗑️ EnhancedContentView - Task delete: \(task.title ?? "Без назви")")
                            taskViewModel.deleteTask(task)
                        }
                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 100) // Простір для FAB
                        }
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("")
            .safeAreaInset(edge: .bottom) {
                EnhancedFloatingActionButton(
                    onAddTask: { showingAddTask = true },
                    onShowProjects: { showingAddProject = true }
                )
                .padding()
            }
            .sheet(isPresented: $showingAddTask) {
                ModernAddTaskView(taskViewModel: taskViewModel, preselectedProject: nil)
                    .compactModalSize()
            }
            .sheet(isPresented: $showingProjectsView) {
                ProjectsCoordinatorView()
                    .environmentObject(taskViewModel)
                    .adaptiveModalSize()
            }
            .sheet(isPresented: $showingAddProject) {
                AddEditProjectView(taskViewModel: taskViewModel)
                    .compactModalSize()
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project, taskViewModel: taskViewModel)
                    .adaptiveModalSize()
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
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                ModernTaskDetailView(task: task, taskViewModel: taskViewModel)
            }
            #if os(macOS)
            .frame(minWidth: 650, idealWidth: 750, maxWidth: 900)
            .frame(minHeight: 650, idealHeight: 800, maxHeight: 1000)
            #endif
        }
            
            // Detail view
            WeeklyOverviewView(taskViewModel: taskViewModel)
        }
    }
}

// MARK: - Enhanced Header View

struct EnhancedHeaderView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let selectedFilter: EnhancedContentView.TaskFilter
    let taskCount: Int
    @StateObject private var dynamicIslandManager = DynamicIslandManager.shared
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброго ранку"
        case 12..<17: return "Доброго дня"
        case 17..<22: return "Доброго вечора"
        default: return "Доброї ночі"
        }
    }
    
    // Кількість завдань на сьогодні
    private var todayTasksCount: Int {
        return taskViewModel.getTodayTasks().filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Ліва секція
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("DoneDay")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Центральна секція - Dynamic Island кнопка
            Button(action: {
                dynamicIslandManager.toggleDynamicIsland()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: dynamicIslandManager.isVisible ? "island.fill" : "island")
                        .font(.system(size: 16, weight: .medium))
                    Text(dynamicIslandManager.isVisible ? "Приховати Island" : "Показати Island")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Права секція - бейджі
            HStack(spacing: 12) {
                QuickStatBadge(
                    value: taskCount,
                    label: taskCount == 1 ? "завдання" : "завдання"
                )
                
                QuickStatBadge(
                    value: taskViewModel.projects.count,
                    label: taskViewModel.projects.count == 1 ? "проект" : "проектів"
                )
                
                if todayTasksCount > 0 {
                    QuickStatBadge(
                        value: todayTasksCount,
                        label: "сьогодні"
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptivePadding()
    }
}

// MARK: - Quick Stat Badge

struct QuickStatBadge: View {
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Quick Stats View

struct QuickStatsView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    
    private var todayTasksCount: Int {
        taskViewModel.getTodayTasks().count
    }
    
    private var overdueTasks: Int {
        taskViewModel.tasks.filter { task in
            !task.isCompleted &&
            task.dueDate != nil &&
            task.dueDate! < Date()
        }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if todayTasksCount > 0 {
                StatBubble(
                    value: "\(todayTasksCount)",
                    label: "сьогодні",
                    color: .orange
                )
            }
            
            if overdueTasks > 0 {
                StatBubble(
                    value: "\(overdueTasks)",
                    label: "прострочено",
                    color: .red
                )
            }
        }
    }
}

struct StatBubble: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Filter Pills

struct EnhancedFilterPillsView: View {
    @Binding var selectedFilter: EnhancedContentView.TaskFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EnhancedContentView.TaskFilter.allCases, id: \.self) { filter in
                    EnhancedFilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
}

struct EnhancedFilterPill: View {
    let filter: EnhancedContentView.TaskFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(filter.color.opacity(0.2))
                        .overlay {
                            Capsule()
                                .stroke(filter.color, lineWidth: 1)
                        }
                } else {
                    Capsule()
                        .fill(.regularMaterial)
                }
            }
            .foregroundColor(isSelected ? filter.color : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Projects Quick View

struct ProjectsQuickView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let onProjectTap: (ProjectEntity) -> Void
    let onShowAllProjects: () -> Void
    
    private var activeProjects: [ProjectEntity] {
        taskViewModel.getActiveProjects().prefix(8).map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick actions
                ProjectsQuickActions(
                    onShowAllProjects: onShowAllProjects,
                    onAddProject: { /* Handle add project */ }
                )
                
                // Active projects grid
                if activeProjects.isEmpty {
                    ProjectsEmptyState()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(activeProjects, id: \.objectID) { project in
                            ProjectQuickCard(
                                project: project,
                                onTap: { onProjectTap(project) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // View all button
                if activeProjects.count >= 8 {
                    Button("Переглянути всі проекти") {
                        onShowAllProjects()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 20)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.vertical, 20)
        }
    }
}

struct ProjectsQuickActions: View {
    let onShowAllProjects: () -> Void
    let onAddProject: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ActionCard(
                icon: "folder.badge.plus",
                title: "Новий проект",
                subtitle: "Створити",
                color: .blue,
                action: onAddProject
            )
            
            ActionCard(
                icon: "folder.fill",
                title: "Всі проекти",
                subtitle: "Переглянути",
                color: .purple,
                action: onShowAllProjects
            )
        }
        .padding(.horizontal, 20)
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ProjectQuickCard: View {
    let project: ProjectEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Circle()
                        .fill(project.colorValue.gradient)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: project.iconName ?? "folder.fill")
                                .foregroundColor(.primary)
                                .font(.caption)
                        }
                    
                    Spacer()
                    
                    if project.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Без назви")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if let area = project.area {
                        Text(area.name ?? "Область")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Прогрес")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(project.completedTasks.count)/\(project.tasksArray.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: project.progress.completionPercentage)
                        .tint(project.colorValue)
                }
            }
            .padding(12)
            .frame(height: 140)
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

struct ProjectsEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Немає проектів")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Створіть свій перший проект для організації завдань")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Enhanced Floating Action Button (✅ ПОВНА РОБОЧА ВЕРСІЯ)

struct EnhancedFloatingActionButton: View {
    let onAddTask: () -> Void
    let onShowProjects: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                // Додаткові кнопки (показуються коли розгорнуто)
                if isExpanded {
                    // Кнопка "Проєкти"
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                        onShowProjects()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .font(.body)
                            Text("Новий проект")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    
                    // Кнопка "Нове завдання"
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                        onAddTask()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)
                            Text("Завдання")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Головна кнопка "+"
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if isExpanded {
                            // Якщо розгорнуто - закрити
                            isExpanded = false
                        } else {
                            // Якщо згорнуто - розгорнути
                            isExpanded = true
                        }
                    }
                }) {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 56, height: 56)
                        .background {
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                        .rotationEffect(.degrees(isExpanded ? 135 : 0))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - TaskViewModel Singleton Extension (DEPRECATED - Use @EnvironmentObject instead)

// extension TaskViewModel {
//     static let shared = TaskViewModel()
// }

// MARK: - Updated DoneDay App

struct UpdatedDoneDayApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var taskViewModel = TaskViewModel()

    var body: some Scene {
        WindowGroup {
            EnhancedContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskViewModel)
        }
        
        #if os(macOS)
        WindowGroup("Проекти") {
            ProjectsCoordinatorView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskViewModel)
        }
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

// MARK: - Menu Bar Integration (macOS)

#if os(macOS)
struct DoneDayMenuBarExtra: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    private var todayTasks: [TaskEntity] {
        taskViewModel.getTodayTasks()
    }
    
    private var activeProjects: [ProjectEntity] {
        taskViewModel.getActiveProjects().prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("DoneDay")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // Today's tasks
            if todayTasks.isEmpty {
                Text("Немає завдань на сьогодні")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Text("Сьогодні (\(todayTasks.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(todayTasks.prefix(3), id: \.objectID) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                        
                        Text(task.title ?? "Без назви")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            
            if !activeProjects.isEmpty {
                Divider()
                
                Text("Активні проекти")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(activeProjects, id: \.objectID) { project in
                    HStack {
                        Circle()
                            .fill(project.colorValue)
                            .frame(width: 8, height: 8)
                        
                        Text(project.name ?? "Без назви")
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(Int(project.progress.completionPercentage * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            Button("Відкрити DoneDay") {
                // Open main app window
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderless)
            
            Button("Вийти") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 280)
    }
}

struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some Scene {
        MenuBarExtra("DoneDay", systemImage: "checkmark.circle") {
            DoneDayMenuBarExtra()
                .environmentObject(taskViewModel)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }
}
#endif

#Preview {
    EnhancedContentView()
        .environmentObject(TaskViewModel())
}
// MARK: - Enhanced Views

struct EnhancedEmptyStateView: View {
    let filter: String
    
    private var emptyMessage: (icon: String, title: String, subtitle: String) {
        switch filter.lowercased() {
        case "всі":
            return ("tray", "Немає завдань", "Додайте нове завдання щоб почати")
        case "сьогодні":
            return ("calendar.badge.clock", "Немає завдань на сьогодні", "Насолоджуйтесь вільним часом!")
        case "майбутні":
            return ("calendar", "Немає майбутніх завдань", "Спланируйте щось нове")
        case "inbox":
            return ("tray", "Inbox порожній", "Всі завдання організовані!")
        case "завершені":
            return ("checkmark.circle", "Немає завершених завдань", "Виконайте завдання щоб побачити їх тут")
        default:
            return ("list.bullet", "Немає завдань", "Додайте нове завдання")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyMessage.icon)
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyMessage.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyMessage.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

