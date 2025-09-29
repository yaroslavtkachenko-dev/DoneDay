//
//  MainAppIntegration.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Enhanced ContentView with Projects Integration

struct EnhancedContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var showingProjectsView = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedProject: ProjectEntity?
    @State private var showingProjectDetail = false
    
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
                    selectedFilter: selectedFilter,
                    taskCount: selectedFilter == .projects ? taskViewModel.projects.count : filteredTasks.count,
                    projectsCount: taskViewModel.projects.count,
                    taskViewModel: taskViewModel,
                    onProjectsTap: { showingProjectsView = true }
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
                        TaskListView(
                            tasks: filteredTasks,
                            taskViewModel: taskViewModel,
                            onDelete: taskViewModel.deleteTasks
                        )
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("")
            .safeAreaInset(edge: .bottom) {
                EnhancedFloatingActionButton(
                    onAddTask: { showingAddTask = true },
                    onShowProjects: { showingProjectsView = true }
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
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project, taskViewModel: taskViewModel)
                    .adaptiveModalSize()
            }
            
            // Detail placeholder
            VStack {
                Image(systemName: selectedFilter == .projects ? "folder" : "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text(selectedFilter == .projects ? "Оберіть проект" : "Оберіть завдання")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Enhanced Header View

struct EnhancedHeaderView: View {
    let selectedFilter: EnhancedContentView.TaskFilter
    let taskCount: Int
    let projectsCount: Int
    let taskViewModel: TaskViewModel
    let onProjectsTap: () -> Void
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброго ранку"
        case 12..<17: return "Доброго дня"
        case 17..<22: return "Доброго вечора"
        default: return "Доброї ночі"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("DoneDay")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Projects quick access
                Button(action: onProjectsTap) {
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Text("\(projectsCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("проектів")
                                .font(.caption2)
                        }
                        Image(systemName: "folder.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.purple.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                // Profile button
                Button(action: {}) {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Text("Y")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                }
            }
            
            // Current filter info
            HStack {
                Image(systemName: selectedFilter.icon)
                    .foregroundColor(selectedFilter.color)
                
                if selectedFilter == .projects {
                    Text("\(taskCount) проектів")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(taskCount) \(selectedFilter.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                if selectedFilter != .projects {
                    QuickStatsView(taskViewModel: taskViewModel)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(.regularMaterial)
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
                                .foregroundColor(.white)
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

// MARK: - Enhanced Floating Action Button

struct EnhancedFloatingActionButton: View {
    let onAddTask: () -> Void
    let onShowProjects: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                // Secondary buttons (shown when expanded)
                if isExpanded {
                    SecondaryFAB(
                        icon: "folder.badge.plus",
                        color: .purple,
                        action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                            onShowProjects()
                        }
                    )
                    
                    SecondaryFAB(
                        icon: "plus",
                        color: .blue,
                        action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                            onAddTask()
                        }
                    )
                }
                
                // Main FAB
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background {
                            Circle()
                                .fill(.blue.gradient)
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

struct SecondaryFAB: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(color.gradient)
                        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - TaskViewModel Singleton Extension

extension TaskViewModel {
    static let shared = TaskViewModel()
}

// MARK: - Updated DoneDay App

struct UpdatedDoneDayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            EnhancedContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
        #if os(macOS)
        WindowGroup("Проекти") {
            ProjectsCoordinatorView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

// MARK: - Menu Bar Integration (macOS)

#if os(macOS)
struct DoneDayMenuBarExtra: View {
    @ObservedObject var taskViewModel = TaskViewModel.shared
    
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
    
    var body: some Scene {
        MenuBarExtra("DoneDay", systemImage: "checkmark.circle") {
            DoneDayMenuBarExtra()
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
