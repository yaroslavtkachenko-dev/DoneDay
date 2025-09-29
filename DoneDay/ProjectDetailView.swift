//
//  ProjectDetailView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import Charts

struct ProjectDetailView: View {
    let project: ProjectEntity
    let taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditProject = false
    @State private var showingDeleteAlert = false
    @State private var showingCompleteAlert = false
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    
    private var projectTasks: [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete }
    }
    
    private var taskStatistics: ProjectTaskStatistics {
        ProjectTaskStatistics(tasks: projectTasks)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ProjectDetailHeader(
                    project: project,
                    statistics: taskStatistics,
                    onEdit: { showingEditProject = true },
                    onComplete: { showingCompleteAlert = true },
                    onDelete: { showingDeleteAlert = true }
                )
                
                // Tabs
                ProjectDetailTabs(selectedTab: $selectedTab)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Overview tab
                    ProjectOverviewTab(
                        project: project,
                        statistics: taskStatistics,
                        tasks: projectTasks
                    )
                    .tag(0)
                    
                    // Tasks tab
                    ProjectTasksTab(
                        tasks: projectTasks,
                        taskViewModel: taskViewModel
                    )
                    .tag(1)
                    
                    // Analytics tab
                    ProjectAnalyticsTab(
                        statistics: taskStatistics,
                        tasks: projectTasks
                    )
                    .tag(2)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    
                    Button {
                        showingAddTask = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Додати завдання")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.blue.gradient)
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding()
                .background(.clear)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddTask = true
                        } label: {
                            Label("Додати завдання", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingEditProject = true
                        } label: {
                            Label("Редагувати проект", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        if !project.isCompleted {
                            Button {
                                showingCompleteAlert = true
                            } label: {
                                Label("Завершити проект", systemImage: "checkmark.circle")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Видалити проект", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProject) {
            AddEditProjectView(taskViewModel: taskViewModel, project: project)
        }
        .sheet(isPresented: $showingAddTask) {
            ModernAddTaskView(taskViewModel: taskViewModel, preselectedProject: project)
        }
        .alert("Завершити проект", isPresented: $showingCompleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Завершити") {
                completeProject()
            }
        } message: {
            Text("Ви впевнені, що хочете завершити цей проект? Всі незавершені завдання будуть автоматично завершені.")
        }
        .alert("Видалити проект", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("Ви впевнені, що хочете видалити цей проект? Всі завдання проекту будуть переміщені в Inbox.")
        }
    }
    
    private func completeProject() {
        project.isCompleted = true
        
        // Complete all incomplete tasks
        for task in projectTasks where !task.isCompleted {
            task.isCompleted = true
            task.updatedAt = Date()
        }
        
        do {
            try DataManager.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error completing project: \(error)")
        }
    }
    
    private func deleteProject() {
        // Move all tasks to inbox (remove project assignment)
        for task in projectTasks {
            task.project = nil
            task.updatedAt = Date()
        }
        
        // Delete the project
        DataManager.shared.context.delete(project)
        
        do {
            try DataManager.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting project: \(error)")
        }
    }
}

// MARK: - Project Detail Header

struct ProjectDetailHeader: View {
    let project: ProjectEntity
    let statistics: ProjectTaskStatistics
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Project info
            HStack(spacing: 16) {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Без назви")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let area = project.area {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text(area.name ?? "Область")
                                .font(.subheadline)
                        }
                        .foregroundColor(.purple)
                    }
                    
                    if let notes = project.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Actions menu
                Menu {
                    Button("Редагувати", action: onEdit)
                    
                    if !project.isCompleted {
                        Button("Завершити проект", action: onComplete)
                    }
                    
                    Divider()
                    
                    Button("Видалити", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Statistics cards
            HStack(spacing: 12) {
                StatCard(
                    title: "Всього",
                    value: "\(statistics.totalTasks)",
                    color: .blue,
                    icon: "list.bullet"
                )
                
                StatCard(
                    title: "Завершено",
                    value: "\(statistics.completedTasks)",
                    color: .green,
                    icon: "checkmark.circle"
                )
                
                StatCard(
                    title: "Прострочено",
                    value: "\(statistics.overdueTasks)",
                    color: .red,
                    icon: "exclamationmark.triangle"
                )
                
                StatCard(
                    title: "Прогрес",
                    value: "\(statistics.completionPercentage)%",
                    color: .orange,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Project Detail Tabs

struct ProjectDetailTabs: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        ("Огляд", "chart.bar"),
        ("Завдання", "list.bullet"),
        ("Аналітика", "chart.pie")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.1)
                            .font(.title3)
                        Text(tab.0)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue.opacity(0.1))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Project Overview Tab

struct ProjectOverviewTab: View {
    let project: ProjectEntity
    let statistics: ProjectTaskStatistics
    let tasks: [TaskEntity]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress overview
                ProjectProgressCard(statistics: statistics)
                
                // Recent tasks
                RecentTasksCard(tasks: Array(tasks.prefix(5)))
                
                // Quick stats
                QuickStatsCard(statistics: statistics, project: project)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
    }
}

struct ProjectProgressCard: View {
    let statistics: ProjectTaskStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Загальний прогрес")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Main progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Завершення проекту")
                            .font(.subheadline)
                        Spacer()
                        Text("\(statistics.completionPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: Double(statistics.completionPercentage) / 100.0)
                        .tint(.blue)
                        .scaleEffect(y: 1.5)
                }
                
                // Task breakdown
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(statistics.completedTasks)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Завершено")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(statistics.activeTasks)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("В роботі")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(statistics.overdueTasks)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Прострочено")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct RecentTasksCard: View {
    let tasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Останні завдання")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Переглянути всі")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if tasks.isEmpty {
                Text("Немає завдань")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks, id: \.objectID) { task in
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(task.isCompleted ? .green : .gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 16, height: 16)
                                .overlay {
                                    if task.isCompleted {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 16, height: 16)
                                            .overlay {
                                                Image(systemName: "checkmark")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                    }
                                }
                            
                            Text(task.title ?? "Без назви")
                                .font(.subheadline)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .secondary : .primary)
                            
                            Spacer()
                            
                            if let dueDate = task.dueDate, !task.isCompleted {
                                Text(dueDate, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(dueDate < Date() ? .red : .secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickStatsCard: View {
    let statistics: ProjectTaskStatistics
    let project: ProjectEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Швидка статистика")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Label("Середній час виконання", systemImage: "clock")
                        .font(.subheadline)
                    Spacer()
                    Text(statistics.averageCompletionTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Label("Найвища пріоритетність", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Spacer()
                    Text("\(statistics.highPriorityTasks) завдань")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Label("Створено", systemImage: "calendar.badge.plus")
                        .font(.subheadline)
                    Spacer()
                    Text(project.createdAt ?? Date(), style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Project Tasks Tab

struct ProjectTasksTab: View {
    let tasks: [TaskEntity]
    let taskViewModel: TaskViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks, id: \.objectID) { task in
                    ModernTaskRowView(task: task, taskViewModel: taskViewModel)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Project Analytics Tab

struct ProjectAnalyticsTab: View {
    let statistics: ProjectTaskStatistics
    let tasks: [TaskEntity]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Completion chart
                CompletionChartCard(statistics: statistics)
                
                // Priority distribution
                PriorityDistributionCard(tasks: tasks)
                
                // Timeline
                ProjectTimelineCard(tasks: tasks)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
    }
}

struct CompletionChartCard: View {
    let statistics: ProjectTaskStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Розподіл завдань")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Pie chart representation (simplified)
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: Double(statistics.completionPercentage) / 100.0)
                        .stroke(.blue, lineWidth: 20)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(statistics.completionPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                        Text("Завершено: \(statistics.completedTasks)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Circle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Залишилось: \(statistics.activeTasks)")
                            .font(.subheadline)
                    }
                    
                    if statistics.overdueTasks > 0 {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text("Прострочено: \(statistics.overdueTasks)")
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PriorityDistributionCard: View {
    let tasks: [TaskEntity]
    
    private var priorityCount: [Int: Int] {
        var count = [0: 0, 1: 0, 2: 0, 3: 0]
        for task in tasks {
            count[Int(task.priority), default: 0] += 1
        }
        return count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Розподіл за пріоритетом")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                PriorityBar(title: "Високий", count: priorityCount[3] ?? 0, color: .red)
                PriorityBar(title: "Середній", count: priorityCount[2] ?? 0, color: .orange)
                PriorityBar(title: "Низький", count: priorityCount[1] ?? 0, color: .yellow)
                PriorityBar(title: "Без пріоритету", count: priorityCount[0] ?? 0, color: .gray)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PriorityBar: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.3))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(4, CGFloat(count * 5)), height: 8)
                }
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 20, alignment: .trailing)
        }
    }
}

struct ProjectTimelineCard: View {
    let tasks: [TaskEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Часова лінія")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(tasks.filter { $0.dueDate != nil }.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }.prefix(5), id: \.objectID) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(task.isCompleted ? .green : (task.dueDate! < Date() ? .red : .blue))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title ?? "Без назви")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let dueDate = task.dueDate {
                                Text(dueDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Project Task Statistics

struct ProjectTaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let overdueTasks: Int
    let highPriorityTasks: Int
    let completionPercentage: Int
    let averageCompletionTime: String
    
    init(tasks: [TaskEntity]) {
        self.totalTasks = tasks.count
        self.completedTasks = tasks.filter { $0.isCompleted }.count
        self.activeTasks = tasks.filter { !$0.isCompleted }.count
        self.overdueTasks = tasks.filter { !$0.isCompleted && $0.dueDate != nil && $0.dueDate! < Date() }.count
        self.highPriorityTasks = tasks.filter { $0.priority >= 2 }.count
        self.completionPercentage = totalTasks > 0 ? Int((Double(completedTasks) / Double(totalTasks)) * 100) : 0
        
        // Calculate average completion time
        let completedTasksWithDates = tasks.filter { $0.isCompleted && $0.createdAt != nil && $0.updatedAt != nil }
        if !completedTasksWithDates.isEmpty {
            let totalTime = completedTasksWithDates.reduce(0) { sum, task in
                let interval = task.updatedAt!.timeIntervalSince(task.createdAt!)
                return sum + interval
            }
            let averageTime = totalTime / Double(completedTasksWithDates.count)
            let days = Int(averageTime / 86400)
            self.averageCompletionTime = days > 0 ? "\(days) днів" : "< 1 дня"
        } else {
            self.averageCompletionTime = "Немає даних"
        }
    }
}

#Preview {
    ProjectDetailView(
        project: ProjectEntity(),
        taskViewModel: TaskViewModel()
    )
}
