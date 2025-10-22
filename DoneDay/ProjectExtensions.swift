//
//  ProjectExtensions.swift
//  DoneDay - Розширення для роботи з проектами
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - TaskViewModel Extensions for Projects

extension TaskViewModel {
    
    // MARK: - Project Management Methods
    
    func updateProject(_ project: ProjectEntity, name: String, description: String?, area: AreaEntity?, color: String?, iconName: String?) {
        let result = projectRepository.updateProject(
            project,
            name: name,
            notes: description,
            area: area,
            color: color,
            iconName: iconName
        )
        
        switch result {
        case .success:
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func completeProject(_ project: ProjectEntity, completionOption: ProjectCompletionOption, completionNotes: String? = nil) {
        let projectTasks = getProjectTasks(project)
        
        switch completionOption {
        case .completeAll:
            for task in projectTasks where !task.isCompleted {
                let result = taskRepository.markCompleted(task)
                if case .failure(let error) = result {
                    print("Error completing task: \(error)")
                }
            }
            
        case .completeActiveOnly:
            let activeTasks = projectTasks.filter { !$0.isCompleted }
            for task in activeTasks {
                let result = taskRepository.markCompleted(task)
                if case .failure(let error) = result {
                    print("Error completing task: \(error)")
                }
            }
            
        case .moveIncompleteToInbox:
            let incompleteTasks = projectTasks.filter { !$0.isCompleted }
            for task in incompleteTasks {
                task.project = nil
                task.updatedAt = Date()
            }
        }
        
        // Complete the project
        project.isCompleted = true
        project.updatedAt = Date()
        
        // Add completion notes
        if let notes = completionNotes, !notes.isEmpty {
            let currentNotes = project.notes ?? ""
            let separator = currentNotes.isEmpty ? "" : "\n\n"
            project.notes = currentNotes + separator + "Завершено: " + notes
        }
        
        let result = projectRepository.save()
        switch result {
        case .success:
            // FRC автоматично оновить списки
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteProject(_ project: ProjectEntity, deletionOption: ProjectDeletionOption, targetProject: ProjectEntity? = nil) {
        let projectTasks = getProjectTasks(project)
        
        switch deletionOption {
        case .moveToInbox:
            for task in projectTasks {
                task.project = nil
                task.updatedAt = Date()
            }
            
        case .moveToProject:
            guard let targetProject = targetProject else { return }
            for task in projectTasks {
                task.project = targetProject
                task.updatedAt = Date()
            }
            
        case .deleteTasks:
            for task in projectTasks {
                let result = taskRepository.deleteTask(task)
                if case .failure(let error) = result {
                    print("Error deleting task: \(error)")
                }
            }
        }
        
        // Delete the project
        let deleteResult = projectRepository.deleteProject(project)
        switch deleteResult {
        case .success:
            // FRC автоматично оновить списки
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func duplicateProject(_ project: ProjectEntity) {
        let result = projectRepository.createProject(
            name: (project.name ?? "Project") + " Copy",
            notes: project.notes,
            area: project.area,
            color: project.color,
            iconName: project.iconName
        )
        
        switch result {
        case .success:
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func archiveProject(_ project: ProjectEntity) {
        project.isCompleted = true
        project.updatedAt = Date()
        
        let result = projectRepository.save()
        switch result {
        case .success:
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    // MARK: - Project Query Methods
    
    func getProjectTasks(_ project: ProjectEntity) -> [TaskEntity] {
        let allTasks = project.tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete }
    }
    
    func getProjectProgress(_ project: ProjectEntity) -> ProjectProgress {
        let tasks = getProjectTasks(project)
        return ProjectProgress(tasks: tasks)
    }
    
    func getProjectsByArea(_ area: AreaEntity) -> [ProjectEntity] {
        return projects.filter { $0.area?.objectID == area.objectID }
    }
    
    func getActiveProjects() -> [ProjectEntity] {
        return projects.filter { !$0.isCompleted }
    }
    
    func getCompletedProjects() -> [ProjectEntity] {
        let result = projectRepository.fetch(predicate: NSPredicate(format: "isCompleted == true"))
        switch result {
        case .success(let projects):
            return projects
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return []
        }
    }
    
    func getProjectsWithOverdueTasks() -> [ProjectEntity] {
        return projects.filter { project in
            let tasks = getProjectTasks(project)
            return tasks.contains { task in
                !task.isCompleted &&
                task.dueDate != nil &&
                task.dueDate! < Date()
            }
        }
    }
    
    func getProjectsByPriority() -> [ProjectEntity] {
        return projects.sorted { project1, project2 in
            let tasks1 = getProjectTasks(project1)
            let tasks2 = getProjectTasks(project2)
            
            let avgPriority1 = tasks1.isEmpty ? 0 : tasks1.map { Double($0.priority) }.reduce(0, +) / Double(tasks1.count)
            let avgPriority2 = tasks2.isEmpty ? 0 : tasks2.map { Double($0.priority) }.reduce(0, +) / Double(tasks2.count)
            
            return avgPriority1 > avgPriority2
        }
    }
    
    // MARK: - Search and Filter Methods
    
    func searchProjects(_ searchText: String) -> [ProjectEntity] {
        guard !searchText.isEmpty else { return projects }
        
        let lowercasedSearch = searchText.lowercased()
        return projects.filter { project in
            let nameMatch = project.name?.lowercased().contains(lowercasedSearch) ?? false
            let notesMatch = project.notes?.lowercased().contains(lowercasedSearch) ?? false
            let areaMatch = project.area?.name?.lowercased().contains(lowercasedSearch) ?? false
            
            return nameMatch || notesMatch || areaMatch
        }
    }
    
    func filterProjects(by filter: ProjectFilter) -> [ProjectEntity] {
        switch filter {
        case .all:
            return projects
        case .active:
            return getActiveProjects()
        case .completed:
            return getCompletedProjects()
        case .withOverdueTasks:
            return getProjectsWithOverdueTasks()
        case .byArea(let area):
            return getProjectsByArea(area)
        case .highPriority:
            return getProjectsByPriority().prefix(10).map { $0 }
        }
    }
}

// MARK: - Supporting Types

enum ProjectCompletionOption {
    case completeAll
    case completeActiveOnly
    case moveIncompleteToInbox
}

enum ProjectDeletionOption {
    case moveToInbox
    case moveToProject
    case deleteTasks
}

enum ProjectFilter {
    case all
    case active
    case completed
    case withOverdueTasks
    case byArea(AreaEntity)
    case highPriority
}

struct ProjectProgress {
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let overdueTasks: Int
    let completionPercentage: Double
    let averagePriority: Double
    
    init(tasks: [TaskEntity]) {
        self.totalTasks = tasks.count
        self.completedTasks = tasks.filter { $0.isCompleted }.count
        self.activeTasks = tasks.filter { !$0.isCompleted }.count
        self.overdueTasks = tasks.filter {
            !$0.isCompleted &&
            $0.dueDate != nil &&
            $0.dueDate! < Date()
        }.count
        
        self.completionPercentage = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        self.averagePriority = tasks.isEmpty ? 0.0 : tasks.map { Double($0.priority) }.reduce(0, +) / Double(tasks.count)
    }
}

// MARK: - ProjectEntity Extensions

extension ProjectEntity {
    
    var tasksArray: [TaskEntity] {
        let allTasks = tasks?.allObjects as? [TaskEntity] ?? []
        return allTasks.filter { !$0.isDelete }
    }
    
    var activeTasks: [TaskEntity] {
        return tasksArray.filter { !$0.isCompleted }
    }
    
    var completedTasks: [TaskEntity] {
        return tasksArray.filter { $0.isCompleted }
    }
    
    var overdueTasks: [TaskEntity] {
        return tasksArray.filter {
            !$0.isCompleted &&
            $0.dueDate != nil &&
            $0.dueDate! < Date()
        }
    }
    
    var progress: ProjectProgress {
        return ProjectProgress(tasks: tasksArray)
    }
    
    var colorValue: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        default: return .blue
        }
    }
    
    var isOverdue: Bool {
        return overdueTasks.count > 0
    }
    
    var isOnTrack: Bool {
        let progress = self.progress
        return progress.totalTasks > 0 && progress.completionPercentage >= 0.8
    }
    
    var needsAttention: Bool {
        return isOverdue || (activeTasks.count > 10)
    }
    
    var estimatedCompletion: Date? {
        guard !activeTasks.isEmpty else { return nil }
        
        let avgCompletionTime = calculateAverageCompletionTime()
        guard avgCompletionTime > 0 else { return nil }
        
        let remainingTime = avgCompletionTime * Double(activeTasks.count)
        return Date().addingTimeInterval(remainingTime)
    }
    
    private func calculateAverageCompletionTime() -> TimeInterval {
        let completedWithDates = completedTasks.filter {
            $0.createdAt != nil && $0.updatedAt != nil
        }
        
        guard !completedWithDates.isEmpty else { return 0 }
        
        let totalTime = completedWithDates.reduce(0) { sum, task in
            let interval = task.updatedAt!.timeIntervalSince(task.createdAt!)
            return sum + interval
        }
        
        return totalTime / Double(completedWithDates.count)
    }
}

// MARK: - AreaEntity Extensions

extension AreaEntity {
    
    var projectsArray: [ProjectEntity] {
        let allProjects = projects?.allObjects as? [ProjectEntity] ?? []
        return allProjects.filter { !$0.isCompleted }
    }
    
    var colorValue: Color {
        switch color {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "pink": return .pink
        default: return .purple
        }
    }
    
    var totalTasks: Int {
        return projectsArray.reduce(0) { sum, project in
            sum + project.tasksArray.count
        }
    }
    
    var completedTasks: Int {
        return projectsArray.reduce(0) { sum, project in
            sum + project.completedTasks.count
        }
    }
    
    var progressPercentage: Double {
        let total = totalTasks
        guard total > 0 else { return 0.0 }
        return Double(completedTasks) / Double(total)
    }
}

// MARK: - Core Data Extensions

extension NSManagedObjectContext {
    
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
    
    func performAndSave(_ block: @escaping () throws -> Void) {
        perform {
            do {
                try block()
                try self.saveIfNeeded()
            } catch {
                print("Core Data error: \(error)")
            }
        }
    }
}

// MARK: - Project Analytics

struct ProjectAnalytics {
    let projects: [ProjectEntity]
    
    var totalProjects: Int {
        return projects.count
    }
    
    var activeProjects: Int {
        return projects.filter { !$0.isCompleted }.count
    }
    
    var completedProjects: Int {
        return projects.filter { $0.isCompleted }.count
    }
    
    var projectsWithOverdueTasks: Int {
        return projects.filter { $0.isOverdue }.count
    }
    
    var averageTasksPerProject: Double {
        let totalTasks = projects.reduce(0) { sum, project in
            sum + project.tasksArray.count
        }
        return projects.isEmpty ? 0.0 : Double(totalTasks) / Double(projects.count)
    }
    
    var averageCompletionRate: Double {
        let totalProgress = projects.reduce(0.0) { sum, project in
            sum + project.progress.completionPercentage
        }
        return projects.isEmpty ? 0.0 : totalProgress / Double(projects.count)
    }
    
    var projectsByArea: [String: Int] {
        var areaCount: [String: Int] = [:]
        for project in projects {
            let areaName = project.area?.name ?? "Без області"
            areaCount[areaName, default: 0] += 1
        }
        return areaCount
    }
    
    var mostProductiveArea: String? {
        return projectsByArea.max(by: { $0.value < $1.value })?.key
    }
    
    var projectsNeedingAttention: [ProjectEntity] {
        return projects.filter { $0.needsAttention }
    }
    
    var onTrackProjects: [ProjectEntity] {
        return projects.filter { $0.isOnTrack }
    }
}

// MARK: - Date Extensions for Projects

extension Date {
    
    func daysFromNow() -> Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
    
    func weeksFromNow() -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: Date(), to: self).weekOfYear ?? 0
    }
}
