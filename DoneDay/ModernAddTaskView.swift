//
//  ModernAddTaskView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct ModernAddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    let taskViewModel: TaskViewModel
    let preselectedProject: ProjectEntity?
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedProject: ProjectEntity?
    @State private var selectedArea: AreaEntity?
    @State private var priority: Int = 0
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var startDate: Date?
    @State private var hasStartDate = false
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    TaskFormHeader()
                    
                    // Task Details
                    TaskDetailsSection(title: $title, description: $description)
                    
                    // Priority Section
                    PrioritySection(priority: $priority)
                    
                    // Organization Section
                    OrganizationSection(
                        selectedProject: $selectedProject,
                        selectedArea: $selectedArea,
                        projects: taskViewModel.projects,
                        areas: taskViewModel.areas
                    )
                    
                    // Dates Section
                    DatesSection(
                        hasDueDate: $hasDueDate,
                        dueDate: $dueDate,
                        hasStartDate: $hasStartDate,
                        startDate: $startDate
                    )
                    
                    Spacer(minLength: 100)
                }
                .adaptivePadding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func createTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        taskViewModel.addTask(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? "" : trimmedDescription,
            project: selectedProject,
            area: selectedArea
        )
        
        // Set additional properties after creation if needed
        // This would require extending the TaskRepository
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Task Form Header

struct TaskFormHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Circle()
                .fill(.blue.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text("New Task")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create a new task to organize your work")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Task Details Section

struct TaskDetailsSection: View {
    @Binding var title: String
    @Binding var description: String
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Details", icon: "doc.text")
            
            VStack(spacing: 12) {
                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("What needs to be done?", text: $title)
                        .textFieldStyle(ModernTextFieldStyle())
                        .focused($isTitleFocused)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Add more details...", text: $description, axis: .vertical)
                        .textFieldStyle(ModernTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .adaptivePadding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
    }
}

// MARK: - Priority Section

struct PrioritySection: View {
    @Binding var priority: Int
    
    private let priorities = [
        (0, "None", Color.gray, "minus"),
        (1, "Low", Color.yellow, "exclamationmark"),
        (2, "Medium", Color.orange, "exclamationmark.2"),
        (3, "High", Color.red, "exclamationmark.3")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Priority", icon: "exclamationmark.triangle")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(priorities, id: \.0) { priorityValue, name, color, icon in
                    PriorityOption(
                        name: name,
                        color: color,
                        icon: icon,
                        isSelected: priority == priorityValue
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            priority = priorityValue
                        }
                    }
                }
            }
            .adaptivePadding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct PriorityOption: View {
    let name: String
    let color: Color
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Organization Section

struct OrganizationSection: View {
    @Binding var selectedProject: ProjectEntity?
    @Binding var selectedArea: AreaEntity?
    let projects: [ProjectEntity]
    let areas: [AreaEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Organization", icon: "folder")
            
            VStack(spacing: 12) {
                // Project picker
                OrganizationPicker(
                    title: "Project",
                    icon: "folder.fill",
                    color: .blue,
                    selection: Binding(
                        get: { selectedProject?.name ?? "None" },
                        set: { _ in }
                    ),
                    options: ["None"] + projects.map { $0.name ?? "Unnamed" }
                ) { index in
                    selectedProject = index == 0 ? nil : projects[index - 1]
                }
                
                // Area picker
                OrganizationPicker(
                    title: "Area",
                    icon: "tag.fill",
                    color: .purple,
                    selection: Binding(
                        get: { selectedArea?.name ?? "None" },
                        set: { _ in }
                    ),
                    options: ["None"] + areas.map { $0.name ?? "Unnamed" }
                ) { index in
                    selectedArea = index == 0 ? nil : areas[index - 1]
                }
            }
            .adaptivePadding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct OrganizationPicker: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var selection: String
    let options: [String]
    let onSelectionChange: (Int) -> Void
    
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
                
                Menu {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Button(option) {
                            selection = option
                            onSelectionChange(index)
                        }
                    }
                } label: {
                    HStack {
                        Text(selection)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Dates Section

struct DatesSection: View {
    @Binding var hasDueDate: Bool
    @Binding var dueDate: Date?
    @Binding var hasStartDate: Bool
    @Binding var startDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Scheduling", icon: "calendar")
            
            VStack(spacing: 16) {
                // Due date
                DateToggleSection(
                    title: "Due Date",
                    icon: "clock",
                    color: .orange,
                    isEnabled: $hasDueDate,
                    date: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    showPicker: hasDueDate
                )
                
                // Start date
                DateToggleSection(
                    title: "Start Date",
                    icon: "play.circle",
                    color: .green,
                    isEnabled: $hasStartDate,
                    date: Binding(
                        get: { startDate ?? Date() },
                        set: { startDate = $0 }
                    ),
                    showPicker: hasStartDate
                )
            }
            .adaptivePadding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct DateToggleSection: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isEnabled: Bool
    @Binding var date: Date
    let showPicker: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
            
            if showPicker {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

// MARK: - Modern Text Field Style

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    }
            }
    }
}

// MARK: - Modern Edit Task View

struct ModernEditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    let task: TaskEntity
    let taskViewModel: TaskViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var selectedProject: ProjectEntity?
    @State private var selectedArea: AreaEntity?
    @State private var priority: Int
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    
    init(task: TaskEntity, taskViewModel: TaskViewModel) {
        self.task = task
        self.taskViewModel = taskViewModel
        
        _title = State(initialValue: task.title ?? "")
        _description = State(initialValue: task.notes ?? "")
        _selectedProject = State(initialValue: task.project)
        _selectedArea = State(initialValue: task.area)
        _priority = State(initialValue: Int(task.priority))
        _dueDate = State(initialValue: task.dueDate)
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Edit Header
                    EditTaskHeader()
                    
                    // Same sections as add task but with edit functionality
                    TaskDetailsSection(title: $title, description: $description)
                    PrioritySection(priority: $priority)
                    OrganizationSection(
                        selectedProject: $selectedProject,
                        selectedArea: $selectedArea,
                        projects: taskViewModel.projects,
                        areas: taskViewModel.areas
                    )
                    
                    // Due date only for simplicity
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Due Date", icon: "calendar")
                        
                        DateToggleSection(
                            title: "Set Due Date",
                            icon: "clock",
                            color: .orange,
                            isEnabled: $hasDueDate,
                            date: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            showPicker: hasDueDate
                        )
                        .adaptivePadding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .adaptivePadding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update task properties
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.notes = description.trimmingCharacters(in: .whitespacesAndNewlines)
        task.project = selectedProject
        task.area = selectedArea
        task.priority = Int16(priority)
        task.dueDate = hasDueDate ? dueDate : nil
        task.updatedAt = Date()
        
        // Save through repository
        do {
            try DataManager.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

struct EditTaskHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(.orange.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "pencil")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text("Edit Task")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Update your task details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let viewModel = TaskViewModel()
    return ModernAddTaskView(taskViewModel: viewModel, preselectedProject: nil)
        .environmentObject(viewModel)
}
