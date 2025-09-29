//
//  ModernTaskDetailView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct ModernTaskDetailView: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with completion toggle
                TaskDetailHeader(task: task, taskViewModel: taskViewModel)
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title ?? "No Title")
                        .font(.title)
                        .fontWeight(.bold)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Priority
                if task.priority > 0 {
                    TaskDetailPriority(priority: task.priority)
                }
                
                // Organization
                TaskDetailOrganization(task: task)
                
                // Dates
                TaskDetailDates(task: task)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(.regularMaterial)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditView = true
                }
                .fontWeight(.medium)
            }
        }
        .sheet(isPresented: $showingEditView) {
            ModernEditTaskView(task: task, taskViewModel: taskViewModel)
        }
    }
}

// MARK: - Task Detail Header

struct TaskDetailHeader: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    taskViewModel.toggleTaskCompletion(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? .green : .gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 32, height: 32)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(.green)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.isCompleted ? "Completed" : "Not completed")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if task.isCompleted, let completedAt = task.completedAt {
                    Text("Completed \(completedAt, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

// MARK: - Task Detail Priority

struct TaskDetailPriority: View {
    let priority: Int16
    
    private var priorityInfo: (text: String, color: Color, icon: String) {
        switch priority {
        case 1: return ("Low Priority", .yellow, "exclamationmark")
        case 2: return ("Medium Priority", .orange, "exclamationmark.2")
        case 3: return ("High Priority", .red, "exclamationmark.3")
        default: return ("No Priority", .gray, "minus")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priority")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                Image(systemName: priorityInfo.icon)
                    .font(.title2)
                    .foregroundColor(priorityInfo.color)
                
                Text(priorityInfo.text)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(priorityInfo.color.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(priorityInfo.color.opacity(0.3), lineWidth: 1)
                    }
            }
        }
    }
}

// MARK: - Task Detail Organization

struct TaskDetailOrganization: View {
    let task: TaskEntity
    
    var body: some View {
        if task.project != nil || task.area != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("Organization")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    if let project = task.project {
                        OrganizationRow(
                            icon: "folder.fill",
                            title: "Project",
                            value: project.name ?? "Unnamed Project",
                            color: .blue
                        )
                    }
                    
                    if let area = task.area {
                        OrganizationRow(
                            icon: "tag.fill",
                            title: "Area",
                            value: area.name ?? "Unnamed Area",
                            color: .purple
                        )
                    }
                }
            }
        }
    }
}

struct OrganizationRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

// MARK: - Task Detail Dates

struct TaskDetailDates: View {
    let task: TaskEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dates")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let createdAt = task.createdAt {
                    DateRow(
                        icon: "calendar.badge.plus",
                        title: "Created",
                        date: createdAt,
                        color: .green
                    )
                }
                
                if let dueDate = task.dueDate {
                    DateRow(
                        icon: "clock",
                        title: "Due",
                        date: dueDate,
                        color: dueDate < Date() ? .red : .orange
                    )
                }
                
                if let updatedAt = task.updatedAt {
                    DateRow(
                        icon: "arrow.clockwise",
                        title: "Updated",
                        date: updatedAt,
                        color: .blue
                    )
                }
                
                if let completedAt = task.completedAt {
                    DateRow(
                        icon: "checkmark.circle",
                        title: "Completed",
                        date: completedAt,
                        color: .green
                    )
                }
            }
        }
    }
}

struct DateRow: View {
    let icon: String
    let title: String
    let date: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text(date, formatter: dateFormatter)
                        .font(.body)
                    Text(date, formatter: timeFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(date, formatter: relativeDateFormatter)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

// MARK: - Formatters

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    NavigationView {
        ModernTaskDetailView(
            task: TaskEntity(),
            taskViewModel: TaskViewModel()
        )
    }
}
