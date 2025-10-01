//
//  TaskViewModel.swift
//  DoneDay - З ТЕГАМИ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import Foundation
import CoreData
import Combine

class TaskViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var tasks: [TaskEntity] = []
    @Published var projects: [ProjectEntity] = []
    @Published var areas: [AreaEntity] = []
    @Published var tags: [TagEntity] = []
    
    // MARK: - Repositories
    let taskRepository: TaskRepository
    let projectRepository: ProjectRepository
    let areaRepository: AreaRepository
    let tagRepository: TagRepository
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.taskRepository = TaskRepository()
        self.projectRepository = ProjectRepository()
        self.areaRepository = AreaRepository()
        self.tagRepository = TagRepository()
        
        setupNotificationObserver()
        loadAllData()
    }
    
    // MARK: - Setup
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadAllData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadAllData() {
        loadTasks()
        loadProjects()
        loadAreas()
        loadTags()
    }
    
    func loadTasks() {
        tasks = taskRepository.fetchActiveTasks()
            .sorted { (task1: TaskEntity, task2: TaskEntity) in
                // Сортуємо за sortOrder
                return task1.sortOrder < task2.sortOrder
            }
    }
    
    func loadProjects() {
        projects = projectRepository.fetchActiveProjects()
    }
    
    func loadAreas() {
        areas = areaRepository.fetchAllAreas()
    }
    
    func loadTags() {
        tags = tagRepository.fetchAllTags()
    }
    
    // MARK: - Task Actions
    
    func addTask(title: String = "New Task", description: String = "", project: ProjectEntity? = nil, area: AreaEntity? = nil) {
        let _ = taskRepository.createTask(
            title: title,
            description: description,
            area: area,
            project: project
        )
        
        do {
            try taskRepository.save()
            loadTasks()
        } catch {
            print("Error creating task: \(error)")
        }
    }
    
    func toggleTaskCompletion(_ task: TaskEntity) {
        do {
            if task.isCompleted {
                try taskRepository.markIncomplete(task)
            } else {
                try taskRepository.markCompleted(task)
            }
            loadTasks()
        } catch {
            print("Error toggling task completion: \(error)")
        }
    }
    
    func deleteTask(_ task: TaskEntity) {
        do {
            try taskRepository.softDelete(task)
            loadTasks()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            deleteTask(tasks[index])
        }
    }
    
    // MARK: - Smart Lists
    
    func getTodayTasks() -> [TaskEntity] {
        return taskRepository.fetchTodayTasks()
            .sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
    }
    
    func getUpcomingTasks() -> [TaskEntity] {
        return taskRepository.fetchUpcomingTasks()
            .sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
    }
    
    func getInboxTasks() -> [TaskEntity] {
        return taskRepository.fetchInboxTasks()
            .sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
    }
    
    func getCompletedTasks() -> [TaskEntity] {
        return taskRepository.fetchCompletedTasks()
    }
    
    // MARK: - Project Actions
    
    func addProject(name: String, description: String = "", area: AreaEntity? = nil, color: String = "blue", iconName: String = "folder.fill") -> ProjectEntity? {
        let newProject = projectRepository.createProject(
            name: name,
            notes: description,
            area: area,
            color: color,
            iconName: iconName
        )
        
        do {
            try projectRepository.save()
            loadProjects()
            return newProject
        } catch {
            print("Error creating project: \(error)")
            return nil
        }
    }
    
    // MARK: - Area Actions
    
    func addArea(name: String, description: String = "", iconName: String? = nil, color: String? = nil) {
        let _ = areaRepository.createArea(
            name: name,
            notes: description,
            iconName: iconName,
            color: color
        )
        
        do {
            try areaRepository.save()
            loadAreas()
        } catch {
            print("Error creating area: \(error)")
        }
    }
    
    // MARK: - ✅ Tag Actions (НОВЕ!)
    
    func addTag(name: String, color: String? = nil) {
        let _ = tagRepository.createTag(
            name: name,
            color: color
        )
        
        do {
            try tagRepository.save()
            loadTags()
        } catch {
            print("Error creating tag: \(error)")
        }
    }
    
    func deleteTag(_ tag: TagEntity) {
        do {
            try tagRepository.delete(tag)
            loadTags()
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
}
