//
//  AreasListView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct AreasListView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var isGridView = true
    @State private var showingAddArea = false
    @State private var selectedArea: AreaEntity?
    @State private var searchText = ""
    @State private var sortOption: AreaSortOption = .name
    @State private var showingColorPicker = false
    @State private var selectedColorFilter: String = "all"
    @State private var showingIconPicker = false
    
    private var filteredAreas: [AreaEntity] {
        var areas = taskViewModel.areas
        
        // Apply search filter
        if !searchText.isEmpty {
            areas = areas.filter { area in
                area.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                area.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Apply color filter
        if selectedColorFilter != "all" {
            areas = areas.filter { area in
                area.color == selectedColorFilter
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .name:
            areas = areas.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .projectCount:
            areas = areas.sorted { $0.projectsArray.count > $1.projectsArray.count }
        case .taskCount:
            areas = areas.sorted { $0.totalTasks > $1.totalTasks }
        case .progress:
            areas = areas.sorted { $0.progressPercentage > $1.progressPercentage }
        case .dateCreated:
            areas = areas.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        }
        
        return areas
    }
    
    private var availableColors: [String] {
        let allColors = Array(Set(taskViewModel.areas.compactMap { $0.color }))
        return ["all"] + allColors.sorted()
    }
    
    enum AreaSortOption: String, CaseIterable {
        case name = "За назвою"
        case projectCount = "За кількістю проектів"
        case taskCount = "За кількістю завдань"
        case progress = "За прогресом"
        case dateCreated = "За датою створення"
        
        var icon: String {
            switch self {
            case .name: return "textformat"
            case .projectCount: return "folder"
            case .taskCount: return "list.bullet"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .dateCreated: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                AreasHeaderView(
                    areaCount: taskViewModel.areas.count,
                    filteredCount: filteredAreas.count
                )
                
                // Controls
                AreasControlsView(
                    searchText: $searchText,
                    isGridView: $isGridView,
                    sortOption: $sortOption,
                    onAddArea: { showingAddArea = true }
                )
                
                // Areas content
                if filteredAreas.isEmpty {
                    AreasEmptyStateView(hasSearch: !searchText.isEmpty)
                } else {
                    AreasContentView(
                        areas: filteredAreas,
                        isGridView: isGridView,
                        taskViewModel: taskViewModel,
                        onAreaTap: { area in
                            selectedArea = area
                        }
                    )
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .navigationTitle("Області")
            .sheet(isPresented: $showingAddArea) {
                AddAreaView(taskViewModel: taskViewModel)
            }
            .sheet(item: $selectedArea) { area in
                // Placeholder for AreaDetailView - пока просто показуємо інформацію про область
                VStack {
                    Text(area.name ?? "Без назви")
                        .font(.title)
                    Text("Детальний перегляд області")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// MARK: - Areas Header View

struct AreasHeaderView: View {
    let areaCount: Int
    let filteredCount: Int
    
    private var statsData: [(String, String, Color)] {
        [
            ("Всього областей", "\(areaCount)", .blue),
            ("Показано", "\(filteredCount)", .green),
            ("Активних", "\(areaCount)", .orange) // Could be refined with actual active count
        ]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваші області")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Організуйте проекти за сферами життя")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Decorative areas stack
                HStack(spacing: -8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill([Color.purple, Color.blue, Color.green][index].gradient)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: ["tag.fill", "house.fill", "briefcase.fill"][index])
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            .background {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 34, height: 34)
                            }
                    }
                }
            }
            
            // Quick stats
            HStack(spacing: 16) {
                ForEach(Array(statsData.enumerated()), id: \.offset) { _, stat in
                    AreaStatCard(
                        title: stat.0,
                        value: stat.1,
                        color: stat.2
                    )
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
    }
}

struct AreaStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Areas Controls View

struct AreasControlsView: View {
    @Binding var searchText: String
    @Binding var isGridView: Bool
    @Binding var sortOption: AreasListView.AreaSortOption
    let onAddArea: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Пошук областей...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("Очистити") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Controls row
            HStack {
                // View toggle
                HStack(spacing: 0) {
                    ViewToggleButton(
                        icon: "list.bullet",
                        isSelected: !isGridView,
                        action: { isGridView = false }
                    )
                    
                    ViewToggleButton(
                        icon: "square.grid.2x2",
                        isSelected: isGridView,
                        action: { isGridView = true }
                    )
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Sort menu
                Menu {
                    ForEach(AreasListView.AreaSortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                                if sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: sortOption.icon)
                        Text("Сортування")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer()
                
                // Add area button
                Button(action: onAddArea) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Нова область")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

struct ViewToggleButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 44, height: 32)
                .background(isSelected ? .purple : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Areas Content View

struct AreasContentView: View {
    let areas: [AreaEntity]
    let isGridView: Bool
    let taskViewModel: TaskViewModel
    let onAreaTap: (AreaEntity) -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var adaptiveGridColumns: [GridItem] {
        let columnsCount = horizontalSizeClass == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnsCount)
    }
    
    private var adaptiveSpacing: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }
    
    var body: some View {
        ScrollView {
            if isGridView {
                LazyVGrid(columns: adaptiveGridColumns, spacing: adaptiveSpacing) {
                    ForEach(areas, id: \.objectID) { area in
                        AreaGridCard(
                            area: area,
                            taskViewModel: taskViewModel,
                            onTap: { onAreaTap(area) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(areas, id: \.objectID) { area in
                        AreaListCard(
                            area: area,
                            taskViewModel: taskViewModel,
                            onTap: { onAreaTap(area) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Area Grid Card

struct AreaGridCard: View {
    let area: AreaEntity
    let taskViewModel: TaskViewModel
    let onTap: () -> Void
    
    private var areaStats: (projects: Int, tasks: Int, progress: Double) {
        let projects = area.projectsArray.count
        let tasks = area.totalTasks
        let progress = area.progressPercentage
        return (projects, tasks, progress)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and color
                HStack {
                    Circle()
                        .fill(area.colorValue.gradient)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: area.iconName ?? "tag.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .shadow(color: area.colorValue.opacity(0.3), radius: 4, y: 2)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(areaStats.projects)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("проектів")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Area info
                VStack(alignment: .leading, spacing: 8) {
                    Text(area.name ?? "Без назви")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let notes = area.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    
                    // Quick stats
                    HStack(spacing: 12) {
                        StatBubble(
                            value: "\(areaStats.tasks)",
                            label: "завдань",
                            color: area.colorValue
                        )
                        
                        StatBubble(
                            value: "\(Int(areaStats.progress * 100))%",
                            label: "прогрес",
                            color: areaStats.progress > 0.7 ? .green : .orange
                        )
                    }
                }
                
                Spacer()
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Прогрес")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(areaStats.progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(area.colorValue)
                    }
                    
                    ProgressView(value: areaStats.progress)
                        .tint(area.colorValue)
                        .scaleEffect(y: 1.2)
                }
            }
            .padding(16)
            .frame(minHeight: 200, maxHeight: 240)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(area.colorValue.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Area List Card

struct AreaListCard: View {
    let area: AreaEntity
    let taskViewModel: TaskViewModel
    let onTap: () -> Void
    
    private var areaStats: (projects: Int, tasks: Int, completed: Int, progress: Double) {
        let projects = area.projectsArray.count
        let tasks = area.totalTasks
        let completed = area.completedTasks
        let progress = area.progressPercentage
        return (projects, tasks, completed, progress)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(area.colorValue.gradient)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: area.iconName ?? "tag.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .shadow(color: area.colorValue.opacity(0.3), radius: 4, y: 2)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(area.name ?? "Без назви")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(areaStats.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(area.colorValue)
                    }
                    
                    if let notes = area.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Stats row
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption)
                            Text("\(areaStats.projects) проектів")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption)
                            Text("\(areaStats.tasks) завдань")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        
                        if areaStats.completed > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                Text("\(areaStats.completed) готово")
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                    
                    // Progress bar
                    ProgressView(value: areaStats.progress)
                        .tint(area.colorValue)
                        .scaleEffect(y: 1.5)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(area.colorValue.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Areas Empty State

struct AreasEmptyStateView: View {
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: hasSearch ? "magnifyingglass" : "tag.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 12) {
                Text(hasSearch ? "Нічого не знайдено" : "Ще немає областей")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasSearch ?
                     "Спробуйте змінити пошуковий запит або створіть нову область" :
                     "Створіть області для організації проектів за сферами життя")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                if !hasSearch {
                    VStack(spacing: 8) {
                        Text("Приклади областей:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 16)
                        
                        HStack(spacing: 12) {
                            ExampleAreaChip(name: "Робота", icon: "briefcase.fill", color: .blue)
                            ExampleAreaChip(name: "Особисте", icon: "heart.fill", color: .red)
                            ExampleAreaChip(name: "Здоров'я", icon: "heart.text.square", color: .green)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExampleAreaChip: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    AreasListView()
}
