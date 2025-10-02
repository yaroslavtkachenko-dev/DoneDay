//
//  ContentView.swift
//  DoneDay - З правильним натисканням як у ProjectDetailView
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var taskToEdit: TaskEntity?
    @State private var selectedTask: TaskEntity? // ✅ Для відкриття деталей
    @State private var taskToDelete: TaskEntity? // ✅ Для видалення
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
                HeaderView(
                    taskViewModel: taskViewModel,
                    selectedFilter: selectedFilter, 
                    taskCount: filteredTasks.count
                )
                FilterPillsView(selectedFilter: $selectedFilter)
                
                if filteredTasks.isEmpty {
                    EmptyStateView(filter: selectedFilter)
                } else {
                    // ✅ ІДЕНТИЧНО як у ProjectDetailView
                    List(selection: $selectedTask) {
                        ForEach(filteredTasks, id: \.objectID) { task in
                            TaskCardWithActions(
                                task: task,
                        taskViewModel: taskViewModel,
                                projectColor: task.project?.colorValue ?? .blue,
                                onTap: {
                                    print("🖱️ Task tapped: \(task.title ?? "Без назви")")
                                    selectedTask = task // ✅ Відкрити деталі
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
            // ✅ Detail view показує вибране завдання
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
                
            // Права секція - бейджі
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
        .adaptivePadding()
    }
}

// MARK: - Filter Pills View

struct FilterPillsView: View {
    @Binding var selectedFilter: ContentView.TaskFilter
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveBottomPadding: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContentView.TaskFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .adaptivePadding()
        }
        .padding(.bottom, adaptiveBottomPadding)
    }
}

struct FilterPill: View {
    let filter: ContentView.TaskFilter
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

// MARK: - Tag Chip (helper view)

struct TagChip: View {
    let tag: TagEntity
    
    var body: some View {
        Text(tag.name ?? "")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tag.colorValue.opacity(0.2))
            .foregroundColor(tag.colorValue)
            .clipShape(Capsule())
    }
}

// MARK: - Extensions для TagEntity (ProjectEntity вже визначено в ProjectExtensions.swift)

extension TagEntity {
    var colorValue: Color {
        switch color {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

#Preview {
    ContentView()
}
