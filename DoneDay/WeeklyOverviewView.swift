//
//  WeeklyOverviewView.swift
//  DoneDay - Тижневий огляд завдань
//

import SwiftUI

struct WeeklyOverviewView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var currentWeekOffset: Int = 0
    @State private var showingAddTaskForDate: Date?
    @State private var taskTitle = ""
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Знаходимо понеділок поточного тижня
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        
        // Додаємо offset для навігації між тижнями
        guard let adjustedWeekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: weekStart) else {
            return []
        }
        
        // Генеруємо всі 7 днів тижня
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: adjustedWeekStart)
        }
    }
    
    private var weekRangeText: String {
        guard let firstDay = currentWeekDates.first,
              let lastDay = currentWeekDates.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMMM"
        
        return "\(formatter.string(from: firstDay)) - \(formatter.string(from: lastDay))"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Заголовок з навігацією
                headerView
                
                // Дні тижня з завданнями
                VStack(spacing: 16) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        DayCard(
                            date: date,
                            tasks: tasksForDate(date),
                            taskViewModel: taskViewModel,
                            onAddTask: {
                                showingAddTaskForDate = date
                                taskTitle = ""
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: Binding<Bool>(
            get: { showingAddTaskForDate != nil },
            set: { if !$0 { showingAddTaskForDate = nil } }
        )) {
            if let date = showingAddTaskForDate {
                QuickAddTaskView(
                    date: date,
                    taskTitle: $taskTitle,
                    taskViewModel: taskViewModel,
                    onDismiss: {
                        showingAddTaskForDate = nil
                        taskTitle = ""
                    }
                )
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Цей тиждень")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                // Навігація по тижнях
                HStack(spacing: 12) {
                    Button(action: { currentWeekOffset -= 1 }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { currentWeekOffset += 1 }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                Text(weekRangeText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(.regularMaterial)
    }
    
    private func tasksForDate(_ date: Date) -> [TaskEntity] {
        let calendar = Calendar.current
        return taskViewModel.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
}

// MARK: - Day Card

struct DayCard: View {
    let date: Date
    let tasks: [TaskEntity]
    @ObservedObject var taskViewModel: TaskViewModel
    let onAddTask: () -> Void
    @State private var isHovered = false
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }
    
    private var dayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var incompleteTasks: [TaskEntity] {
        tasks.filter { !$0.isCompleted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок дня
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isToday ? .blue : .primary)
                    
                    Text(dayDate)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Кнопка Додати (показується тільки при наведенні)
                if isHovered {
                    Button(action: onAddTask) {
                        Text("Додати")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Бейдж з кількістю завдань
                if !incompleteTasks.isEmpty {
                    Text("\(incompleteTasks.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(14)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Список завдань
            if incompleteTasks.isEmpty {
                Text("Немає завдань")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(incompleteTasks, id: \.objectID) { task in
                        TaskRowCompact(task: task, taskViewModel: taskViewModel)
                        
                        if task != incompleteTasks.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovered ? Color.blue.opacity(0.05) : Color.clear)
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Compact Task Row

struct TaskRowCompact: View {
    let task: TaskEntity
    @ObservedObject var taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                taskViewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Текст завдання
            Text(task.title ?? "Без назви")
                .font(.system(size: 14))
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
            
            Spacer()
            
            // Пріоритет
            if task.priority > 0 {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12))
                    .foregroundColor(priorityColor(task.priority))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func priorityColor(_ priority: Int16) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
}

// MARK: - Quick Add Task View

struct QuickAddTaskView: View {
    let date: Date
    @Binding var taskTitle: String
    @ObservedObject var taskViewModel: TaskViewModel
    let onDismiss: () -> Void
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }
    
    private var dayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private var isFormValid: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(dayDate)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Task Input
            VStack(alignment: .leading, spacing: 12) {
                Text("Назва завдання")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Назва завдання...", text: $taskTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 16))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Скасувати") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Додати") {
                    addTask()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .frame(width: 400)
        .onAppear {
            // Focus на текстове поле
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Тут можна додати фокус на текстове поле
            }
        }
    }
    
    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Створюємо завдання з датою виконання
        let task = taskViewModel.taskRepository.createTask(
            title: trimmedTitle,
            description: "",
            area: nil,
            project: nil
        )
        
        // Встановлюємо дату виконання
        task.dueDate = date
        task.updatedAt = Date()
        
        do {
            try taskViewModel.taskRepository.save()
            taskViewModel.loadTasks()
            onDismiss()
        } catch {
            print("Error creating task: \(error)")
        }
    }
}

// MARK: - Preview

struct WeeklyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyOverviewView(taskViewModel: TaskViewModel())
            .frame(width: 400, height: 800)
    }
}
