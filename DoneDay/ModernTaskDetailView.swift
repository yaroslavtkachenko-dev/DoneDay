//
//  ModernTaskDetailView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 30.09.2025.
//

import SwiftUI

struct ModernTaskDetailView: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    // Editing states
    @State private var isEditingTitle = false
    @State private var editedTitle: String
    @State private var editedNotes: String
    @State private var selectedPriority: Int
    @State private var selectedProject: ProjectEntity?
    @State private var selectedArea: AreaEntity?
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    init(task: TaskEntity, taskViewModel: TaskViewModel) {
        self.task = task
        self.taskViewModel = taskViewModel
        
        // Initialize states
        _editedTitle = State(initialValue: task.title ?? "")
        _editedNotes = State(initialValue: task.notes ?? "")
        _selectedPriority = State(initialValue: Int(task.priority))
        _selectedProject = State(initialValue: task.project)
        _selectedArea = State(initialValue: task.area)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with completion toggle
                TaskDetailHeaderInteractive(
                    task: task,
                    taskViewModel: taskViewModel,
                    onClose: { dismiss() }
                )
                
                // Editable Title
                EditableTitleSection(
                    title: $editedTitle,
                    isEditing: $isEditingTitle,
                    isCompleted: task.isCompleted,
                    onSave: saveTitle
                )
                
                // Editable Notes
                EditableNotesSection(
                    notes: $editedNotes,
                    onSave: saveNotes
                )
                
                // Priority Selector
                InteractivePrioritySection(
                    priority: $selectedPriority,
                    onChange: savePriority
                )
                
                // Due Date Section - Новий дизайн
                NewDateSection(
                    hasDueDate: $hasDueDate,
                    date: $dueDate,
                    onChange: saveDate
                )
                
                // Organization (Project & Area)
                InteractiveOrganizationSection(
                    selectedProject: $selectedProject,
                    selectedArea: $selectedArea,
                    projects: taskViewModel.projects,
                    areas: taskViewModel.areas,
                    onChange: saveOrganization
                )
                
                // Metadata (Created, Updated)
                MetadataSection(task: task)
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("")
    }
    
    // MARK: - Save Functions
    
    private func saveTitle() {
        task.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        task.updatedAt = Date()
        saveChanges()
    }
    
    private func saveNotes() {
        task.notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.updatedAt = Date()
        saveChanges()
    }
    
    private func savePriority() {
        task.priority = Int16(selectedPriority)
        task.updatedAt = Date()
        saveChanges()
    }
    
    private func saveDate() {
        task.dueDate = hasDueDate ? dueDate : nil
        task.updatedAt = Date()
        saveChanges()
    }
    
    private func saveOrganization() {
        task.project = selectedProject
        task.area = selectedArea
        task.updatedAt = Date()
        saveChanges()
    }
    
    private func saveChanges() {
        do {
            try DataManager.shared.save()
            taskViewModel.loadTasks()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

// MARK: - Interactive Header

struct TaskDetailHeaderInteractive: View {
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    let onClose: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Top bar with delete button only
            HStack {
                Spacer()
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            // Completion button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    taskViewModel.toggleTaskCompletion(task)
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 32, height: 32)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.isCompleted ? "Завершено" : "Не завершено")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if task.isCompleted, let completedAt = task.completedAt {
                            Text(formatRelativeDate(completedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("Видалити завдання?", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive) {
                taskViewModel.deleteTask(task)
                onClose()
            }
        } message: {
            Text("Цю дію неможливо скасувати")
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "uk")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Editable Title Section

struct EditableTitleSection: View {
    @Binding var title: String
    @Binding var isEditing: Bool
    let isCompleted: Bool
    let onSave: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("Назва завдання", text: $title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .focused($isFocused)
                    .onSubmit {
                        isEditing = false
                        onSave()
                    }
                    .onAppear {
                        isFocused = true
                    }
            } else {
                Button(action: { isEditing = true }) {
                    Text(title.isEmpty ? "Без назви" : title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Editable Notes Section

struct EditableNotesSection: View {
    @Binding var notes: String
    let onSave: () -> Void
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Опис", systemImage: "text.alignleft")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !isEditing {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isEditing {
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                
                HStack {
                    Button("Скасувати") {
                        isEditing = false
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Зберегти") {
                        isEditing = false
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            } else {
                if notes.isEmpty {
                    Button(action: { isEditing = true }) {
                        Text("Додати опис...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button(action: { isEditing = true }) {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Interactive Priority Section

struct InteractivePrioritySection: View {
    @Binding var priority: Int
    let onChange: () -> Void
    
    private let priorities = [
        (value: 0, label: "Без пріоритету", color: Color.gray, icon: "minus.circle"),
        (value: 1, label: "Низький", color: Color.yellow, icon: "exclamationmark"),
        (value: 2, label: "Середній", color: Color.orange, icon: "exclamationmark.2"),
        (value: 3, label: "Високий", color: Color.red, icon: "exclamationmark.3")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Пріоритет", systemImage: "flag.fill")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(priorities, id: \.value) { item in
                    Button {
                        priority = item.value
                        onChange()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundColor(item.color)
                                .frame(width: 24)
                            
                            Text(item.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if priority == item.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background {
                            if priority == item.value {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(item.color.opacity(0.1))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(item.color.opacity(0.3), lineWidth: 1.5)
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Interactive Date Section (УЛЬТРА-КОМПАКТНА)

struct InteractiveDateSection: View {
    @Binding var hasDueDate: Bool
    @Binding var date: Date
    let onChange: () -> Void
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var showSavedIndicator = false
    
    init(hasDueDate: Binding<Bool>, date: Binding<Date>, onChange: @escaping () -> Void) {
        self._hasDueDate = hasDueDate
        self._date = date
        self.onChange = onChange
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date.wrappedValue)
        _selectedYear = State(initialValue: components.year ?? 2025)
        _selectedMonth = State(initialValue: components.month ?? 1)
        _selectedDay = State(initialValue: components.day ?? 1)
        _selectedHour = State(initialValue: components.hour ?? 12)
        _selectedMinute = State(initialValue: components.minute ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Label("Термін виконання", systemImage: "calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if showSavedIndicator {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("✓")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Toggle("", isOn: Binding(
                    get: { hasDueDate },
                    set: { newValue in
                        hasDueDate = newValue
                        onChange()
                        showSaveIndicator()
                    }
                ))
                .labelsHidden()
            }
            
            if hasDueDate {
                VStack(spacing: 10) {
                    // Дата і Швидкі кнопки в одному рядку
                    HStack(spacing: 6) {
                        CompactDateRow(
                            day: $selectedDay,
                            month: $selectedMonth,
                            year: $selectedYear,
                            onChange: { updateDate(); showSaveIndicator() }
                        )
                        
                        // Швидкі кнопки (дуже маленькі)
                        HStack(spacing: 4) {
                            MiniQuickButton(icon: "sun.max.fill", color: .orange) {
                                setQuickDate(days: 0)
                            }
                            MiniQuickButton(icon: "sunrise.fill", color: .blue) {
                                setQuickDate(days: 1)
                            }
                            MiniQuickButton(icon: "calendar", color: .purple) {
                                setQuickDate(days: 7)
                            }
                        }
                    }
                    
                    // Час (компактний)
                    UltraCompactTimeRow(
                        hour: $selectedHour,
                        minute: $selectedMinute,
                        onChange: { updateDate(); showSaveIndicator() }
                    )
                    
                    // Результат (мінімальний)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(formatSelectedDate())
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                Text("Без терміну")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func setQuickDate(days: Int) {
        let calendar = Calendar.current
        let newDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let components = calendar.dateComponents([.year, .month, .day], from: newDate)
        
        selectedYear = components.year ?? 2025
        selectedMonth = components.month ?? 1
        selectedDay = components.day ?? 1
        selectedHour = 12
        selectedMinute = 0
        updateDate()
        showSaveIndicator()
    }
    
    private func updateDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        components.hour = selectedHour
        components.minute = selectedMinute
        
        if let newDate = Calendar.current.date(from: components) {
            date = newDate
                            onChange()
        }
    }
    
    private func showSaveIndicator() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            showSavedIndicator = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeOut(duration: 0.2)) {
                showSavedIndicator = false
            }
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "uk")
        return formatter.string(from: date)
    }
}

// MARK: - Mini Quick Button (дуже маленькі)

struct MiniQuickButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Date Row (залишається як є)

struct CompactDateRow: View {
    @Binding var day: Int
    @Binding var month: Int
    @Binding var year: Int
    let onChange: () -> Void
    
    private let months = [
        "Січ", "Лют", "Бер", "Кві", "Тра", "Чер",
        "Лип", "Сер", "Вер", "Жов", "Лис", "Гру"
    ]
    
    private var daysInMonth: Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 31
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // День
            Menu {
                ForEach(1...daysInMonth, id: \.self) { d in
                    Button("\(d)") {
                        day = d
                            onChange()
                        }
                }
            } label: {
                HStack(spacing: 3) {
                    Text("\(day)")
                        .font(.body)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            
            // Місяць
            Menu {
                ForEach(1...12, id: \.self) { m in
                    Button(months[m-1]) {
                        month = m
                        if day > daysInMonth {
                            day = daysInMonth
                        }
                            onChange()
                        }
                    }
            } label: {
                HStack(spacing: 3) {
                    Text(months[month-1])
                        .font(.body)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            
            // Рік
            Menu {
                ForEach((year-2)...(year+5), id: \.self) { y in
                    Button("\(y)") {
                        year = y
                        onChange()
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text("\(year)")
                    .font(.body)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Ultra Compact Time Row (ПРОСТІША ВЕРСІЯ)

struct UltraCompactTimeRow: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Години (dropdown)
            Menu {
                ForEach(0..<24, id: \.self) { h in
                    Button(String(format: "%02d", h)) {
                        hour = h
                        onChange()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(String(format: "%02d", hour))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)
                    .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Text(":")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            // Хвилини (dropdown)
            Menu {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Button(String(format: "%02d", m)) {
                        minute = m
                        onChange()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(String(format: "%02d", minute))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Швидкі кнопки часу
            HStack(spacing: 6) {
                SimpleTimeButton(title: "9") { hour = 9; minute = 0; onChange() }
                SimpleTimeButton(title: "12") { hour = 12; minute = 0; onChange() }
                SimpleTimeButton(title: "15") { hour = 15; minute = 0; onChange() }
                SimpleTimeButton(title: "18") { hour = 18; minute = 0; onChange() }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SimpleTimeButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 28, height: 24)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Interactive Organization Section

struct InteractiveOrganizationSection: View {
    @Binding var selectedProject: ProjectEntity?
    @Binding var selectedArea: AreaEntity?
    let projects: [ProjectEntity]
    let areas: [AreaEntity]
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Організація", systemImage: "folder")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Project Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Проект")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Menu {
                    Button("Без проекту") {
                        selectedProject = nil
                        onChange()
                    }
                    
                    if !projects.isEmpty {
                        Divider()
                        ForEach(projects, id: \.objectID) { project in
                            Button {
                                selectedProject = project
                                onChange()
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(project.colorValue)
                                        .frame(width: 12, height: 12)
                                    Text(project.name ?? "Без назви")
                                    if selectedProject?.objectID == project.objectID {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let project = selectedProject {
                            Circle()
                                .fill(project.colorValue)
                                .frame(width: 12, height: 12)
                            Text(project.name ?? "Без назви")
                                .font(.body)
                        } else {
                            Text("Оберіть проект")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            // Area Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Область")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Menu {
                    Button("Без області") {
                        selectedArea = nil
                        onChange()
                    }
                    
                    if !areas.isEmpty {
                        Divider()
                        ForEach(areas, id: \.objectID) { area in
                            Button {
                                selectedArea = area
                                onChange()
                            } label: {
                                HStack {
                                    Image(systemName: area.iconName ?? "tag.fill")
                                    Text(area.name ?? "Без назви")
                                    if selectedArea?.objectID == area.objectID {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let area = selectedArea {
                            Image(systemName: area.iconName ?? "tag.fill")
                                .foregroundColor(area.colorValue)
                            Text(area.name ?? "Без назви")
                                .font(.body)
                        } else {
                            Text("Оберіть область")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Metadata Section

struct MetadataSection: View {
    let task: TaskEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Інформація", systemImage: "info.circle")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let createdAt = task.createdAt {
                    MetadataRow(
                        icon: "calendar.badge.plus",
                        title: "Створено",
                        value: formatDate(createdAt),
                        color: .green
                    )
                }
                
                if let updatedAt = task.updatedAt {
                    MetadataRow(
                        icon: "arrow.clockwise",
                        title: "Оновлено",
                        value: formatDate(updatedAt),
                        color: .blue
                    )
                }
                
                if task.isCompleted, let completedAt = task.completedAt {
                    MetadataRow(
                        icon: "checkmark.circle.fill",
                        title: "Завершено",
                        value: formatDate(completedAt),
                        color: .green
                    )
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk")
        return formatter.string(from: date)
    }
}

struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Нова версія NewDateSection з Wheel Picker

struct NewDateSection: View {
    @Binding var hasDueDate: Bool
    @Binding var date: Date
    let onChange: () -> Void
    
    @State private var showingMonthPicker = false
    
    private let monthNames = ["Січ", "Лют", "Бер", "Кві", "Тра", "Чер", 
                             "Лип", "Сер", "Вер", "Жов", "Лис", "Гру"]
    private let monthNamesFull = ["Січень", "Лютий", "Березень", "Квітень", "Травень", "Червень",
                                 "Липень", "Серпень", "Вересень", "Жовтень", "Листопад", "Грудень"]
    
    private var calendar: Calendar { Calendar.current }
    private var day: Int { calendar.component(.day, from: date) }
    private var month: Int { calendar.component(.month, from: date) }
    private var year: Int { calendar.component(.year, from: date) }
    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header з toggle
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .font(.headline)
                
                Text("Термін виконання")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("", isOn: $hasDueDate)
                    .labelsHidden()
                    .onChange(of: hasDueDate) { _ in
                        onChange()
                    }
            }
            
            if hasDueDate {
                VStack(spacing: 16) {
                    // Швидкі дати
                    HStack(spacing: 8) {
                        QuickDateButton(title: "Сьогодні", isToday: true) {
                            setToday()
                        }
                        QuickDateButton(title: "Завтра", isToday: false) {
                            setTomorrow()
                        }
                    }
                    
                    // Основний рядок з датою і часом
                    HStack(spacing: 16) {
                        // Дата
                        HStack(spacing: 8) {
                            NavButton(icon: "chevron.left") {
                                changeDate(by: -1)
                            }
                            
                            Button(action: { showingMonthPicker = true }) {
                                VStack(spacing: 2) {
                                    Text("\(day) \(monthNames[month - 1])")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("\(year)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            
                            NavButton(icon: "chevron.right") {
                                changeDate(by: 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 48)
                        
                        // Час
                        HStack(spacing: 8) {
                            NavButton(icon: "chevron.left") {
                                changeHour(by: -1)
                            }
                            
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 24, weight: .light))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .frame(width: 56, height: 40)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(10)
                            
                            NavButton(icon: "chevron.right") {
                                changeHour(by: 1)
                            }
                            
                            Text(":")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.secondary)
                            
                            NavButton(icon: "chevron.left") {
                                changeMinute(by: -5)
                            }
                            
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 24, weight: .light))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .frame(width: 56, height: 40)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(10)
                            
                            NavButton(icon: "chevron.right") {
                                changeMinute(by: 5)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                    
                    // Швидкі години
                    HStack(spacing: 8) {
                        ForEach([9, 12, 15, 18], id: \.self) { h in
                            TimeButton(hour: h, isSelected: hour == h && minute == 0) {
                                setTime(hour: h, minute: 0)
                            }
                        }
                    }
                    
                    // Підказка
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text("Клікни на дату → обери місяць і рік зі списку")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(16)
        .sheet(isPresented: $showingMonthPicker) {
            WheelMonthYearPicker(
                date: $date,
                monthNames: monthNamesFull,
                onSave: {
                    showingMonthPicker = false
                    onChange()
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func setToday() {
        let now = Date()
        var components = calendar.dateComponents([.hour, .minute], from: date)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        components.year = todayComponents.year
        components.month = todayComponents.month
        components.day = todayComponents.day
        if let newDate = calendar.date(from: components) {
            date = newDate
            onChange()
        }
    }
    
    private func setTomorrow() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var components = calendar.dateComponents([.hour, .minute], from: date)
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.year = tomorrowComponents.year
        components.month = tomorrowComponents.month
        components.day = tomorrowComponents.day
        if let newDate = calendar.date(from: components) {
            date = newDate
            onChange()
        }
    }
    
    private func changeDate(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: date) {
            date = newDate
            onChange()
        }
    }
    
    private func changeHour(by hours: Int) {
        if let newDate = calendar.date(byAdding: .hour, value: hours, to: date) {
            date = newDate
            onChange()
        }
    }
    
    private func changeMinute(by minutes: Int) {
        if let newDate = calendar.date(byAdding: .minute, value: minutes, to: date) {
            date = newDate
            onChange()
        }
    }
    
    private func setTime(hour: Int, minute: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        if let newDate = calendar.date(from: components) {
            date = newDate
            onChange()
        }
    }
}

// MARK: - Компоненти для NewDateSection

struct QuickDateButton: View {
    let title: String
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct NavButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

struct TimeButton: View {
    let hour: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(hour):00")
                .font(.system(size: 14))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wheel Month Year Picker

struct WheelMonthYearPicker: View {
    @Binding var date: Date
    let monthNames: [String]
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    private var calendar: Calendar { Calendar.current }
    private var selectedMonth: Int { calendar.component(.month, from: date) }
    private var selectedYear: Int { calendar.component(.year, from: date) }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Оберіть місяць і рік")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Місяці
            VStack(alignment: .leading, spacing: 12) {
                Text("МІСЯЦЬ")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 12) {
                    ForEach(0..<12, id: \.self) { index in
                        Button(action: { setMonth(index + 1) }) {
                            Text(monthNames[index])
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedMonth == index + 1 ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedMonth == index + 1 ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Роки
            VStack(alignment: .leading, spacing: 12) {
                Text("РІК")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                
                HStack(spacing: 12) {
                    ForEach([2024, 2025, 2026, 2027, 2028], id: \.self) { year in
                        Button(action: { setYear(year) }) {
                            Text("\(year)")
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedYear == year ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedYear == year ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Кнопка Готово
            Button(action: {
                onSave()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Готово")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 500, height: 600)
        .background(.regularMaterial)
    }
    
    private func setMonth(_ month: Int) {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.month = month
        if let newDate = calendar.date(from: components) {
            date = newDate
        }
    }
    
    private func setYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.year = year
        if let newDate = calendar.date(from: components) {
            date = newDate
        }
    }
}


