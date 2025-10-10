//
//  ProjectsCoordinatorView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Main Projects Coordinator

struct ProjectsCoordinatorView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var selectedTab = 0
    @State private var showingProjectsList = false
    @State private var showingAddProject = false
    @State private var selectedProject: ProjectEntity?
    @State private var showingProjectDetail = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                // Projects Overview
                ProjectsOverviewTab(
                    taskViewModel: taskViewModel,
                    onProjectTap: { project in
                        selectedProject = project
                        showingProjectDetail = true
                    },
                    onShowAllProjects: {
                        showingProjectsList = true
                    },
                    onAddProject: {
                        showingAddProject = true
                    }
                )
                .tag(0)
                .tabItem {
                    Label("Огляд", systemImage: "chart.bar")
                }
                
                // All Projects
                ProjectsListView()
                    .environmentObject(taskViewModel)
                    .tag(1)
                    .tabItem {
                        Label("Проекти", systemImage: "folder")
                    }
                
                // Analytics
                ProjectsAnalyticsTab(taskViewModel: taskViewModel)
                    .tag(2)
                    .tabItem {
                        Label("Аналітика", systemImage: "chart.pie")
                    }
                
                // Settings
                ProjectsSettingsTab(taskViewModel: taskViewModel)
                    .tag(3)
                    .tabItem {
                        Label("Налаштування", systemImage: "gearshape")
                    }
            }
            .navigationDestination(for: ProjectEntity.self) { project in
                ProjectDetailView(project: project, taskViewModel: taskViewModel)
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddEditProjectView(taskViewModel: taskViewModel)
                .compactModalSize()
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project, taskViewModel: taskViewModel)
                .adaptiveModalSize()
        }
        .sheet(isPresented: $showingProjectsList) {
            ProjectsListView()
                .environmentObject(taskViewModel)
                .adaptiveModalSize()
        }
    }
}

// MARK: - Projects Overview Tab

struct ProjectsOverviewTab: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let onProjectTap: (ProjectEntity) -> Void
    let onShowAllProjects: () -> Void
    let onAddProject: () -> Void
    
    // State для модальних вікон
    @State private var showingTodayTasks = false
    @State private var showingCompletedTasks = false
    @State private var showingUpcomingTasks = false
    @State private var showingStreakDetails = false
    
    private var analytics: ProjectAnalytics {
        ProjectAnalytics(projects: taskViewModel.projects)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                ProjectsOverviewHeader(
                    analytics: analytics,
                    onAddProject: onAddProject,
                    onShowAllProjects: onShowAllProjects
                )
                
                // Quick Stats
                ProjectsQuickStats(
                    taskViewModel: taskViewModel,
                    onStatTap: { statType in
                        switch statType {
                        case .today:
                            showingTodayTasks = true
                        case .completed:
                            showingCompletedTasks = true
                        case .inProgress:
                            onShowAllProjects()
                        case .upcoming:
                            showingUpcomingTasks = true
                        case .streak:
                            showingStreakDetails = true
                        }
                    }
                )
                
                // Recent Projects
                RecentProjectsSection(
                    projects: Array(taskViewModel.getActiveProjects().prefix(6)),
                    onProjectTap: onProjectTap
                )
                
                // Projects Needing Attention
                if !analytics.projectsNeedingAttention.isEmpty {
                    AttentionNeededSection(
                        projects: analytics.projectsNeedingAttention,
                        onProjectTap: onProjectTap
                    )
                }
                
                // Areas Overview
                AreasOverviewSection(
                    areas: taskViewModel.areas,
                    taskViewModel: taskViewModel
                )
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Проекти")
        .sheet(isPresented: $showingTodayTasks) {
            TasksListSheet(
                title: "Завдання на сьогодні",
                tasks: taskViewModel.getTodayTasks(),
                taskViewModel: taskViewModel
            )
        }
        .sheet(isPresented: $showingCompletedTasks) {
            TasksListSheet(
                title: "Виконані завдання",
                tasks: taskViewModel.getCompletedTasks(),
                taskViewModel: taskViewModel
            )
        }
        .sheet(isPresented: $showingUpcomingTasks) {
            TasksListSheet(
                title: "Наближаються",
                tasks: taskViewModel.getUpcomingTasks(),
                taskViewModel: taskViewModel
            )
        }
        .sheet(isPresented: $showingStreakDetails) {
            StreakDetailsSheet(taskViewModel: taskViewModel)
        }
    }
}

struct ProjectsOverviewHeader: View {
    let analytics: ProjectAnalytics
    let onAddProject: () -> Void
    let onShowAllProjects: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваші проекти")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Керування та відстеження прогресу")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Всі проекти", action: onShowAllProjects)
                        .buttonStyle(.bordered)
                    
                    Button("Новий проект", action: onAddProject)
                        .buttonStyle(.borderedProminent)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Загальний прогрес")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(analytics.averageCompletionRate * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: analytics.averageCompletionRate)
                    .tint(.blue)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ProjectsQuickStats: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let onStatTap: ((StatType) -> Void)?
    
    enum StatType {
        case today, completed, inProgress, upcoming, streak
    }
    
    // Обчислювані властивості для статистики
    private var todayTasksCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return taskViewModel.tasks.filter { task in
            guard !task.isCompleted && !task.isDelete else { return false }
            if let dueDate = task.dueDate {
                return dueDate >= today && dueDate < tomorrow
            }
            return false
        }.count
    }
    
    private var completedTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return taskViewModel.tasks.filter { task in
            guard task.isCompleted && !task.isDelete else { return false }
            if let completedDate = task.completedAt {
                return Calendar.current.isDate(completedDate, inSameDayAs: today)
            }
            return false
        }.count
    }
    
    private var inProgressCount: Int {
        return taskViewModel.projects.filter { !$0.isCompleted }.count
    }
    
    private var upcomingCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        return taskViewModel.tasks.filter { task in
            guard !task.isCompleted && !task.isDelete else { return false }
            if let dueDate = task.dueDate {
                return dueDate >= tomorrow && dueDate < nextWeek
            }
            return false
        }.count
    }
    
    private var streakDays: Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        for _ in 0..<30 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasCompletedTasks = taskViewModel.tasks.contains { task in
                guard task.isCompleted && !task.isDelete else { return false }
                if let completedDate = task.completedAt {
                    return completedDate >= dayStart && completedDate < dayEnd
                }
                return false
            }
            
            if hasCompletedTasks {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                value: "\(todayTasksCount)",
                label: "Сьогодні",
                accentColor: .blue,
                onTap: { onStatTap?(.today) }
            )
            
            QuickStatCard(
                value: "\(completedTodayCount)",
                label: "Готово",
                accentColor: .green,
                onTap: { onStatTap?(.completed) }
            )
            
            QuickStatCard(
                value: "\(inProgressCount)",
                label: "У роботі",
                accentColor: .purple,
                onTap: { onStatTap?(.inProgress) }
            )
            
            QuickStatCard(
                value: "\(upcomingCount)",
                label: "Наближається",
                accentColor: .orange,
                onTap: { onStatTap?(.upcoming) }
            )
            
            QuickStatCard(
                value: "\(streakDays)",
                label: streakDays == 1 ? "День" : (streakDays < 5 ? "Дні" : "Днів"),
                accentColor: .red,
                onTap: { onStatTap?(.streak) }
            )
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    let accentColor: Color
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Кольорова лінія зверху
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 3)
                
                // Контент
                VStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.8 : 0.3))
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

struct RecentProjectsSection: View {
    let projects: [ProjectEntity]
    let onProjectTap: (ProjectEntity) -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveGridColumns: [GridItem] {
        let columnsCount = horizontalSizeClass == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnsCount)
    }
    
    private var adaptiveSpacing: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Останні проекти")
                .font(.headline)
                .fontWeight(.semibold)
            
            if projects.isEmpty {
                EmptyProjectsMessage()
            } else {
                LazyVGrid(columns: adaptiveGridColumns, spacing: adaptiveSpacing) {
                    ForEach(projects, id: \.objectID) { project in
                        OverviewProjectCard(
                            project: project,
                            onTap: { onProjectTap(project) }
                        )
                    }
                }
            }
        }
    }
}

struct OverviewProjectCard: View {
    let project: ProjectEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Без назви")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if let area = project.area {
                        Text(area.name ?? "Область")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
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
            .frame(minHeight: 100, maxHeight: 140)
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

struct AttentionNeededSection: View {
    let projects: [ProjectEntity]
    let onProjectTap: (ProjectEntity) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Потребують уваги")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                ForEach(projects.prefix(3), id: \.objectID) { project in
                    AttentionProjectRow(
                        project: project,
                        onTap: { onProjectTap(project) }
                    )
                }
            }
        }
        .padding(20)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        }
    }
}

struct AttentionProjectRow: View {
    let project: ProjectEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(project.colorValue.gradient)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: project.iconName ?? "folder.fill")
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name ?? "Без назви")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if project.isOverdue {
                        Text("\(project.overdueTasks.count) прострочених завдань")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("\(project.activeTasks.count) активних завдань")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AreasOverviewSection: View {
    let areas: [AreaEntity]
    let taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Області")
                .font(.headline)
                .fontWeight(.semibold)
            
            if areas.isEmpty {
                EmptyAreasMessage()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(areas, id: \.objectID) { area in
                        AreaOverviewCard(area: area)
                    }
                }
            }
        }
    }
}

struct AreaOverviewCard: View {
    let area: AreaEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: area.iconName ?? "tag.fill")
                    .foregroundColor(area.colorValue)
                    .font(.title3)
                
                Spacer()
                
                Text("\(area.projectsArray.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            Text(area.name ?? "Без назви")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            HStack {
                Text("\(area.totalTasks) завдань")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(area.progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(area.colorValue)
            }
            
            ProgressView(value: area.progressPercentage)
                .tint(area.colorValue)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(area.colorValue.opacity(0.3), lineWidth: 1)
        }
    }
}

struct EmptyProjectsMessage: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Немає проектів")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Створіть свій перший проект для організації завдань")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyAreasMessage: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("Немає областей")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Створіть області для групування проектів")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Projects Analytics Tab

struct ProjectsAnalyticsTab: View {
    @ObservedObject var taskViewModel: TaskViewModel
    
    private var analytics: ProjectAnalytics {
        ProjectAnalytics(projects: taskViewModel.projects)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Analytics Header
                AnalyticsHeader(analytics: analytics)
                
                // Charts Section
                AnalyticsChartsSection(analytics: analytics)
                
                // Insights Section
                AnalyticsInsightsSection(analytics: analytics)
                
                // Performance Section
                PerformanceSection(projects: taskViewModel.projects)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Аналітика")
    }
}

struct AnalyticsHeader: View {
    let analytics: ProjectAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Аналітика проектів")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                AnalyticsStat(
                    title: "Всього проектів",
                    value: "\(analytics.totalProjects)",
                    trend: .neutral
                )
                
                AnalyticsStat(
                    title: "Середня ефективність",
                    value: "\(Int(analytics.averageCompletionRate * 100))%",
                    trend: analytics.averageCompletionRate > 0.7 ? .positive : .negative
                )
                
                AnalyticsStat(
                    title: "Завдань на проект",
                    value: String(format: "%.1f", analytics.averageTasksPerProject),
                    trend: .neutral
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AnalyticsStat: View {
    let title: String
    let value: String
    let trend: TrendDirection
    
    enum TrendDirection {
        case positive, negative, neutral
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up"
            case .negative: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnalyticsChartsSection: View {
    let analytics: ProjectAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Розподіл проектів")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Projects by status
                VStack(alignment: .leading, spacing: 12) {
                    Text("За статусом")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        ChartBar(
                            label: "Активні",
                            value: analytics.activeProjects,
                            total: analytics.totalProjects,
                            color: .blue
                        )
                        
                        ChartBar(
                            label: "Завершені",
                            value: analytics.completedProjects,
                            total: analytics.totalProjects,
                            color: .green
                        )
                        
                        ChartBar(
                            label: "Потребують уваги",
                            value: analytics.projectsNeedingAttention.count,
                            total: analytics.totalProjects,
                            color: .orange
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Projects by area
                VStack(alignment: .leading, spacing: 12) {
                    Text("За областями")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(analytics.projectsByArea.prefix(4)), id: \.key) { area, count in
                            ChartBar(
                                label: area,
                                value: count,
                                total: analytics.totalProjects,
                                color: .purple
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ChartBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total > 0 ? Double(value) / Double(total) : 0
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.2))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(4, 100 * percentage), height: 8)
                }
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 20, alignment: .trailing)
        }
    }
}

struct AnalyticsInsightsSection: View {
    let analytics: ProjectAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let mostProductiveArea = analytics.mostProductiveArea {
                    InsightCard(
                        icon: "star.fill",
                        title: "Найпродуктивніша область",
                        subtitle: mostProductiveArea,
                        color: .yellow
                    )
                }
                
                if analytics.averageCompletionRate > 0.8 {
                    InsightCard(
                        icon: "checkmark.circle.fill",
                        title: "Відмінна ефективність",
                        subtitle: "Ваші проекти виконуються на високому рівні",
                        color: .green
                    )
                } else if analytics.averageCompletionRate < 0.5 {
                    InsightCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Потрібне покращення",
                        subtitle: "Розгляньте можливість оптимізації процесів",
                        color: .orange
                    )
                }
                
                if analytics.projectsNeedingAttention.count > analytics.totalProjects / 3 {
                    InsightCard(
                        icon: "clock.fill",
                        title: "Багато проектів потребують уваги",
                        subtitle: "Розгляньте можливість перерозподілу ресурсів",
                        color: .red
                    )
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

struct PerformanceSection: View {
    let projects: [ProjectEntity]
    
    private var topPerformers: [ProjectEntity] {
        projects.filter { $0.progress.completionPercentage > 0.8 && !$0.tasksArray.isEmpty }
            .sorted { $0.progress.completionPercentage > $1.progress.completionPercentage }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Найуспішніші проекти")
                .font(.headline)
                .fontWeight(.semibold)
            
            if topPerformers.isEmpty {
                Text("Поки що немає проектів з високою ефективністю")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(topPerformers.enumerated()), id: \.element.objectID) { index, project in
                        PerformanceProjectRow(
                            project: project,
                            rank: index + 1
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PerformanceProjectRow: View {
    let project: ProjectEntity
    let rank: Int
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(rankColor)
                .clipShape(Circle())
            
            // Project info
            HStack(spacing: 12) {
                Circle()
                    .fill(project.colorValue.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: project.iconName ?? "folder.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name ?? "Без назви")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(project.completedTasks.count)/\(project.tasksArray.count) завдань")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(project.progress.completionPercentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Projects Settings Tab

struct ProjectsSettingsTab: View {
    @ObservedObject var taskViewModel: TaskViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Settings Header
                SettingsHeader()
                
                // General Settings
                GeneralSettingsSection()
                
                // View Preferences
                ViewPreferencesSection()
                
                // Data Management
                DataManagementSection(taskViewModel: taskViewModel)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Налаштування")
    }
}

struct SettingsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Налаштування проектів")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Персоналізуйте свій досвід роботи з проектами")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GeneralSettingsSection: View {
    @State private var autoArchiveCompleted = true
    @State private var showProgressInMenuBar = false
    @State private var defaultProjectView = "grid"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Загальні налаштування")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "archivebox",
                    title: "Автоархівування",
                    subtitle: "Автоматично архівувати завершені проекти",
                    trailing: {
                        Toggle("", isOn: $autoArchiveCompleted)
                            .labelsHidden()
                    }
                )
                
                SettingsRow(
                    icon: "menubar.rectangle",
                    title: "Прогрес в меню",
                    subtitle: "Показувати прогрес проектів в menu bar",
                    trailing: {
                        Toggle("", isOn: $showProgressInMenuBar)
                            .labelsHidden()
                    }
                )
                
                SettingsRow(
                    icon: "rectangle.grid.2x2",
                    title: "Стандартний вигляд",
                    subtitle: "Як показувати проекти за замовчуванням",
                    trailing: {
                        Picker("", selection: $defaultProjectView) {
                            Text("Сітка").tag("grid")
                            Text("Список").tag("list")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ViewPreferencesSection: View {
    @State private var showCompletedTasks = true
    @State private var groupByArea = false
    @State private var sortOrder = "manual"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Налаштування відображення")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "checkmark.circle",
                    title: "Показувати завершені",
                    subtitle: "Відображати завершені завдання в проектах",
                    trailing: {
                        Toggle("", isOn: $showCompletedTasks)
                            .labelsHidden()
                    }
                )
                
                SettingsRow(
                    icon: "tag",
                    title: "Групувати за областями",
                    subtitle: "Групувати проекти за областями",
                    trailing: {
                        Toggle("", isOn: $groupByArea)
                            .labelsHidden()
                    }
                )
                
                SettingsRow(
                    icon: "arrow.up.arrow.down",
                    title: "Сортування",
                    subtitle: "Порядок сортування проектів",
                    trailing: {
                        Picker("", selection: $sortOrder) {
                            Text("Ручне").tag("manual")
                            Text("За назвою").tag("name")
                            Text("За датою").tag("date")
                            Text("За прогресом").tag("progress")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DataManagementSection: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var showingDeleteAlert = false
    @State private var showingArchiveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Керування даними")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingsActionRow(
                    icon: "archivebox",
                    title: "Архівувати завершені",
                    subtitle: "Перемістити всі завершені проекти в архів",
                    color: .blue,
                    action: { showingArchiveAlert = true }
                )
                
                SettingsActionRow(
                    icon: "trash",
                    title: "Очистити завершені",
                    subtitle: "Видалити всі завершені проекти назавжди",
                    color: .red,
                    action: { showingDeleteAlert = true }
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("Архівувати проекти", isPresented: $showingArchiveAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Архівувати") {
                archiveCompletedProjects()
            }
        } message: {
            Text("Всі завершені проекти будуть переміщені в архів")
        }
        .alert("Видалити проекти", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteCompletedProjects()
            }
        } message: {
            Text("Всі завершені проекти будуть видалені назавжди. Цю дію неможливо скасувати.")
        }
    }
    
    private func archiveCompletedProjects() {
        let completedProjects = taskViewModel.getCompletedProjects()
        for project in completedProjects {
            taskViewModel.archiveProject(project)
        }
    }
    
    private func deleteCompletedProjects() {
        let completedProjects = taskViewModel.getCompletedProjects()
        for project in completedProjects {
            taskViewModel.deleteProject(project, deletionOption: .moveToInbox)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: () -> Trailing
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 4)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tasks List Sheet

struct TasksListSheet: View {
    let title: String
    let tasks: [TaskEntity]
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "Немає завдань",
                        systemImage: "checkmark.circle",
                        description: Text("У цій категорії немає завдань")
                    )
                } else {
                    ForEach(tasks, id: \.objectID) { task in
                        TaskRowView(task: task, taskViewModel: taskViewModel)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct TaskRowView: View {
    let task: TaskEntity
    @ObservedObject var taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                taskViewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Без назви")
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let project = task.project {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(project.colorValue)
                            .frame(width: 8, height: 8)
                        Text(project.name ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let dueDate = task.dueDate {
                let isOverdue = dueDate < Date() && !task.isCompleted
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .secondary)
            }
            
            if task.priority > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<Int(task.priority), id: \.self) { _ in
                        Image(systemName: "exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Streak Details Sheet

struct StreakDetailsSheet: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var streakDays: Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        for _ in 0..<30 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasCompletedTasks = taskViewModel.tasks.contains { task in
                guard task.isCompleted && !task.isDelete else { return false }
                if let completedDate = task.completedAt {
                    return completedDate >= dayStart && completedDate < dayEnd
                }
                return false
            }
            
            if hasCompletedTasks {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var completionHistory: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var history: [(date: Date, count: Int)] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let count = taskViewModel.tasks.filter { task in
                guard task.isCompleted && !task.isDelete else { return false }
                if let completedDate = task.completedAt {
                    return completedDate >= dayStart && completedDate < dayEnd
                }
                return false
            }.count
            
            history.append((date: dayStart, count: count))
        }
        
        return history.reversed()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Header
                    VStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("\(streakDays)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(streakDays == 1 ? "день поспіль" : (streakDays < 5 ? "дні поспіль" : "днів поспіль"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Completion History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Останні 7 днів")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(completionHistory, id: \.date) { item in
                                HStack {
                                    Text(item.date, style: .date)
                                        .font(.subheadline)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    ProgressView(value: Double(item.count), total: 10)
                                        .tint(item.count > 0 ? .green : .gray)
                                    
                                    Text("\(item.count)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Motivational Message
                    VStack(spacing: 12) {
                        if streakDays > 0 {
                            Text("Чудова робота! 🎉")
                                .font(.headline)
                            Text("Ви виконуєте завдання \(streakDays) \(streakDays == 1 ? "день" : (streakDays < 5 ? "дні" : "днів")) поспіль")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Почніть свою серію! 💪")
                                .font(.headline)
                            Text("Виконайте хоча б одне завдання сьогодні")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Статистика продуктивності")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#Preview {
    ProjectsCoordinatorView()
}
