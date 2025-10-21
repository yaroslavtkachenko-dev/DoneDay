//
//  ContentView.swift
//  DoneDay - З ПОКРАЩЕНИМ ЧЕКБОКСОМ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var taskToEdit: TaskEntity?
    @State private var selectedTask: TaskEntity?
    @State private var taskToDelete: TaskEntity?
    @State private var showingDeleteTaskAlert = false
    
    enum TaskFilter: String, CaseIterable {
        case all = "Всі"
        case today = "Сьогодні"
        case upcoming = "Майбутні"
        case inbox = "Inbox"
        case completed = "Завершені"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar.badge.clock"
            case .upcoming: return "calendar"
            case .inbox: return "tray"
            case .completed: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .today: return .orange
            case .upcoming: return .blue
            case .inbox: return .gray
            case .completed: return .green
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
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Dynamic Island
                DynamicIslandOverlay(taskViewModel: taskViewModel)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                
                HeaderView(
                    taskViewModel: taskViewModel,
                    selectedFilter: selectedFilter,
                    taskCount: filteredTasks.count
                )
                FilterPillsView(selectedFilter: $selectedFilter)
                
                if filteredTasks.isEmpty {
                    EmptyStateView(filter: selectedFilter)
                } else {
                    List(selection: $selectedTask) {
                        ForEach(filteredTasks, id: \.objectID) { task in
                            ImprovedTaskCard(
                                task: task,
                                taskViewModel: taskViewModel,
                                projectColor: task.project?.colorValue ?? .blue,
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
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }
            }
            .background(Color.clear)
            .navigationTitle("")
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
            ModernAddTaskView(taskViewModel: taskViewModel, preselectedProject: nil)
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
        .alert("Видалити завдання?", isPresented: $showingDeleteTaskAlert, presenting: taskToDelete) { task in
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                deleteTask(task)
            }
        } message: { task in
            Text("Завдання \"\(task.title ?? "")\" буде видалено")
        }
    }
    
    private func deleteTask(_ task: TaskEntity) {
        // Обнуляємо selectedTask якщо видаляємо обране завдання
        if selectedTask?.objectID == task.objectID {
            selectedTask = nil
        }
        taskViewModel.deleteTask(task)
        taskToDelete = nil
    }
}

// MARK: - Header View

struct HeaderView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let selectedFilter: ContentView.TaskFilter
    let taskCount: Int
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброго ранку"
        case 12..<17: return "Доброго дня"
        case 17..<22: return "Доброго вечора"
        default: return "Доброї ночі"
        }
    }
    
    private var todayTasksCount: Int {
        return taskViewModel.getTodayTasks().filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("DoneDay")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                QuickStatBadge(
                    value: taskCount,
                    label: taskCount == 1 ? "завдання" : "завдання"
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
        .adaptivePadding(.horizontal)
    }
}

// MARK: - Filter Pills View

struct FilterPillsView: View {
    @Binding var selectedFilter: ContentView.TaskFilter
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveBottomPadding: CGFloat {
        horizontalSizeClass == .compact ? 4 : 8
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContentView.TaskFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .padding(.bottom, adaptiveBottomPadding)
        .adaptivePadding(.horizontal)
    }
}

struct FilterPill: View {
    let filter: ContentView.TaskFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? filter.color : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : filter.color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let filter: ContentView.TaskFilter
    
    private var emptyMessage: (icon: String, title: String, subtitle: String) {
        switch filter {
        case .all:
            return ("tray", "Немає завдань", "Створіть перше завдання щоб почати")
        case .today:
            return ("sun.max", "Нічого на сьогодні", "Насолоджуйтесь вільним часом!")
        case .upcoming:
            return ("calendar", "Немає майбутніх завдань", "Все виконано!")
        case .inbox:
            return ("tray", "Inbox порожній", "Всі завдання організовані")
        case .completed:
            return ("checkmark.circle", "Немає завершених завдань", "Виконайте завдання щоб побачити їх тут")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyMessage.icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyMessage.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyMessage.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskViewModel())
}
