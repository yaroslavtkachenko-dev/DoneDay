//
//  ContentView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case inbox = "Inbox"
        case completed = "Completed"
        
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
        NavigationView {
            VStack(spacing: 0) {
                // Header with title and stats
                HeaderView(selectedFilter: selectedFilter, taskCount: filteredTasks.count)
                
                // Filter Pills
                FilterPillsView(selectedFilter: $selectedFilter)
                
                // Tasks List
                if filteredTasks.isEmpty {
                    EmptyStateView(filter: selectedFilter)
                } else {
                    TaskListView(
                        tasks: filteredTasks,
                        taskViewModel: taskViewModel,
                        onDelete: taskViewModel.deleteTasks
                    )
                }
            }
            .background(Color.clear)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
#endif
            .safeAreaInset(edge: .bottom) {
                FloatingActionButton {
                    showingAddTask = true
                }
                .padding()
            }
            .sheet(isPresented: $showingAddTask) {
                ModernAddTaskView(taskViewModel: taskViewModel, preselectedProject: nil)
            }
            
            // Detail placeholder
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text("Select a task")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    let selectedFilter: ContentView.TaskFilter
    let taskCount: Int
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            // Task count
            HStack {
                Image(systemName: selectedFilter.icon)
                    .foregroundColor(selectedFilter.color)
                Text("\(taskCount) \(selectedFilter.rawValue.lowercased())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .adaptivePadding()
        .background(.regularMaterial)
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

// MARK: - Task List View

struct TaskListView: View {
    let tasks: [TaskEntity]
    let taskViewModel: TaskViewModel
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                NavigationLink {
                    ModernTaskDetailView(task: task, taskViewModel: taskViewModel)
                } label: {
                    ModernTaskRowView(task: task, taskViewModel: taskViewModel)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }
}

// MARK: - Modern Task Row View

struct ModernTaskRowView: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    taskViewModel.toggleTaskCompletion(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? .green : .gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(.green)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title ?? "No Title")
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Priority indicator
                    if task.priority > 0 {
                        priorityIndicator(for: task.priority)
                    }
                }
                
                // Description
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Tags and metadata
                HStack(spacing: 8) {
                    if let project = task.project {
                        ModernTagView(text: project.name ?? "Project", color: .blue, icon: "folder")
                    }
                    
                    if let area = task.area {
                        ModernTagView(text: area.name ?? "Area", color: .purple, icon: "tag")
                    }
                    
                    Spacer()
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                }
            }
        }
        .adaptivePadding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        }
    }
    
    private func priorityIndicator(for priority: Int16) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<Int(priority), id: \.self) { _ in
                Circle()
                    .fill(.red)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - Modern Tag View

struct ModernTagView: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(color.opacity(0.15))
        }
        .foregroundColor(color)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let filter: ContentView.TaskFilter
    
    private var emptyMessage: (icon: String, title: String, subtitle: String) {
        switch filter {
        case .all:
            return ("tray", "No tasks yet", "Create your first task to get started")
        case .today:
            return ("sun.max", "Nothing for today", "Enjoy your free time!")
        case .upcoming:
            return ("calendar", "No upcoming tasks", "All caught up!")
        case .inbox:
            return ("tray", "Inbox is empty", "All tasks are organized")
        case .completed:
            return ("checkmark.circle", "No completed tasks", "Complete some tasks to see them here")
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

#Preview {
    ContentView()
}
