//
//  AddEditProjectView.swift
//  DoneDay - ВИПРАВЛЕНА ВЕРСІЯ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct AddEditProjectView: View {
    @Environment(\.presentationMode) var presentationMode
    let taskViewModel: TaskViewModel
    let project: ProjectEntity?
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedArea: AreaEntity?
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder.fill"
    @State private var showingAreaSheet = false
    
    private var isEditMode: Bool {
        project != nil
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Available colors for projects
    private let availableColors: [(String, Color)] = [
        ("blue", .blue),
        ("green", .green),
        ("red", .red),
        ("orange", .orange),
        ("purple", .purple),
        ("pink", .pink),
        ("yellow", .yellow),
        ("indigo", .indigo)
    ]
    
    // Available icons for projects
    private let availableIcons = [
        "folder.fill", "briefcase.fill", "house.fill", "heart.fill",
        "star.fill", "flag.fill", "book.fill", "car.fill",
        "bicycle", "airplane", "gamecontroller.fill", "music.note",
        "paintbrush.fill", "camera.fill", "photo.fill", "film.fill"
    ]
    
    init(taskViewModel: TaskViewModel, project: ProjectEntity? = nil) {
        self.taskViewModel = taskViewModel
        self.project = project
        
        if let project = project {
            _name = State(initialValue: project.name ?? "")
            _description = State(initialValue: project.notes ?? "")
            _selectedArea = State(initialValue: project.area)
            _selectedColor = State(initialValue: project.color ?? "blue")
            _selectedIcon = State(initialValue: project.iconName ?? "folder.fill")
        }
    }
    
    var body: some View {
        NavigationView {
            // ✅ Обмежуємо ширину контенту
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    ProjectFormHeader(isEditMode: isEditMode)
                        .padding(.top, 8)
                    
                    // Form sections
                    VStack(spacing: 16) {
                        // Basic Information
                        ProjectBasicInfoSection(
                            name: $name,
                            description: $description
                        )
                        
                        // Appearance
                        ProjectAppearanceSection(
                            selectedColor: $selectedColor,
                            selectedIcon: $selectedIcon,
                            availableColors: availableColors,
                            availableIcons: availableIcons
                        )
                        
                        // Organization
                        ProjectOrganizationSection(
                            selectedArea: $selectedArea,
                            areas: taskViewModel.areas,
                            showingAreaSheet: $showingAreaSheet,
                            taskViewModel: taskViewModel
                        )
                        
                        // Preview - компактніший
                        ProjectPreviewCompact(
                            name: name.isEmpty ? "Назва проєкту" : name,
                            selectedColor: selectedColor,
                            selectedIcon: selectedIcon,
                            availableColors: availableColors
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 600) // ✅ Обмежуємо ширину!
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Зберегти" : "Створити") {
                        saveProject()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingAreaSheet) {
            AddAreaView(taskViewModel: taskViewModel)
                .frame(width: 500, height: 600)
        }
    }
    
    private func saveProject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Перевірка валідності
        guard !trimmedName.isEmpty else {
            print("❌ Name is empty!")
            return
        }
        
        if isEditMode, let project = project {
            // РЕДАГУВАННЯ ІСНУЮЧОГО ПРОЕКТУ
            project.name = trimmedName
            project.notes = trimmedDescription.isEmpty ? "" : trimmedDescription
            project.area = selectedArea
            project.color = selectedColor
            project.iconName = selectedIcon
            project.updatedAt = Date()
            
            let saveResult = PersistenceController.shared.save()
            switch saveResult {
            case .success:
                print("✅ Project updated successfully")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                ErrorAlertManager.shared.handle(error)
            }
        } else {
            // СТВОРЕННЯ НОВОГО ПРОЕКТУ
            print("🔍 Creating project:")
            print("   Name: \(trimmedName)")
            print("   Color: \(selectedColor)")
            print("   Icon: \(selectedIcon)")
            
            if let newProject = taskViewModel.addProject(
                name: trimmedName,
                description: trimmedDescription,
                area: selectedArea,
                color: selectedColor,
                iconName: selectedIcon
            ) {
                print("✅ Project created successfully: \(newProject.name ?? "")")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("❌ Failed to create project")
            }
        }
    }
}

// MARK: - Project Form Header (компактніший)

struct ProjectFormHeader: View {
    let isEditMode: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(isEditMode ? Color.orange.gradient : Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: isEditMode ? "pencil" : "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 2) {
                Text(isEditMode ? "Редагувати проєкт" : "Новий проєкт")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(isEditMode ? "Оновіть інформацію про проєкт" : "Створіть проєкт для організації завдань")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Project Basic Info Section (виправлений)

struct ProjectBasicInfoSection: View {
    @Binding var name: String
    @Binding var description: String
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Основна інформація")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 14) {
                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Назва проєкту")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Введіть назву проєкту...", text: $name)
                        .textFieldStyle(CompactTextFieldStyle())
                        .focused($isNameFocused)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Опис")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Додайте опис проєкту...", text: $description, axis: .vertical)
                        .textFieldStyle(CompactTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Compact TextField Style

struct CompactTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
            }
    }
}

// MARK: - Project Appearance Section (виправлений)

struct ProjectAppearanceSection: View {
    @Binding var selectedColor: String
    @Binding var selectedIcon: String
    let availableColors: [(String, Color)]
    let availableIcons: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "paintbrush")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Зовнішній вигляд")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 14) {
                // Color selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Колір")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    // ✅ Фіксована ширина для кольорів
                    HStack(spacing: 10) {
                        ForEach(availableColors, id: \.0) { colorName, color in
                            Button {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    selectedColor = colorName
                                }
                            } label: {
                                Circle()
                                    .fill(color.gradient)
                                    .frame(width: 38, height: 38)
                                    .overlay {
                                        if selectedColor == colorName {
                                            Circle()
                                                .stroke(.white, lineWidth: 2.5)
                                                .frame(width: 42, height: 42)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Icon selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Іконка")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    // ✅ Grid з правильними відступами
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    selectedIcon = icon
                                }
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? .blue : .gray.opacity(0.1))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Project Organization Section

struct ProjectOrganizationSection: View {
    @Binding var selectedArea: AreaEntity?
    let areas: [AreaEntity]
    @Binding var showingAreaSheet: Bool
    let taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Організація")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                // Area selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Область")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Створити область") {
                            showingAreaSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Menu {
                        Button("Без області") {
                            selectedArea = nil
                        }
                        
                        if !areas.isEmpty {
                            Divider()
                            ForEach(areas, id: \.objectID) { area in
                                Button(area.name ?? "Без назви") {
                                    selectedArea = area
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.purple)
                                .font(.subheadline)
                            
                            Text(selectedArea?.name ?? "Оберіть область")
                                .font(.subheadline)
                                .foregroundColor(selectedArea == nil ? .secondary : .primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
                        }
                    }
                }
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Compact Preview (замість великого)

struct ProjectPreviewCompact: View {
    let name: String
    let selectedColor: String
    let selectedIcon: String
    let availableColors: [(String, Color)]
    
    private var colorForName: Color {
        availableColors.first { $0.0 == selectedColor }?.1 ?? .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Попередній перегляд")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // ✅ Один компактний preview
            HStack(spacing: 12) {
                Circle()
                    .fill(colorForName.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: selectedIcon)
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("0/0 завдань • 0%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForName.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

// MARK: - Add Area View (також виправлений)

struct AddAreaView: View {
    @Environment(\.presentationMode) var presentationMode
    let taskViewModel: TaskViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = "purple"
    
    private let areaIcons = [
        "tag.fill", "house.fill", "briefcase.fill", "heart.fill",
        "star.fill", "flag.fill", "book.fill", "person.fill"
    ]
    
    private let areaColors: [(String, Color)] = [
        ("purple", .purple),
        ("blue", .blue),
        ("green", .green),
        ("red", .red),
        ("orange", .orange),
        ("pink", .pink)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(.purple.gradient)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "tag.fill")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        
                        VStack(spacing: 2) {
                            Text("Нова область")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("Створіть область для групування проєктів")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Basic info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Основна інформація")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 10) {
                                TextField("Назва області...", text: $name)
                                    .textFieldStyle(CompactTextFieldStyle())
                                
                                TextField("Опис області...", text: $description, axis: .vertical)
                                    .textFieldStyle(CompactTextFieldStyle())
                                    .lineLimit(2...3)
                            }
                            .padding(14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Appearance
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Зовнішній вигляд")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                // Colors
                                HStack(spacing: 10) {
                                    ForEach(areaColors, id: \.0) { colorName, color in
                                        Button {
                                            selectedColor = colorName
                                        } label: {
                                            Circle()
                                                .fill(color.gradient)
                                                .frame(width: 38, height: 38)
                                                .overlay {
                                                    if selectedColor == colorName {
                                                        Circle()
                                                            .stroke(.white, lineWidth: 2.5)
                                                            .frame(width: 42, height: 42)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                // Icons
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                    ForEach(areaIcons, id: \.self) { icon in
                                        Button {
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.title3)
                                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                                .frame(width: 40, height: 40)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(selectedIcon == icon ? .purple : .gray.opacity(0.1))
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Створити") {
                        createArea()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createArea() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        taskViewModel.addArea(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? "" : trimmedDescription,
            iconName: selectedIcon,
            color: selectedColor
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let viewModel = TaskViewModel()
    return AddEditProjectView(taskViewModel: viewModel)
        .environmentObject(viewModel)
}
