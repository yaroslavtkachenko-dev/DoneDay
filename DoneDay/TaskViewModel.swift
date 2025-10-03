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
    
    // MARK: - Repositories (Using Improved versions with Result<Success, Error>)
    let taskRepository: ImprovedTaskRepository
    let projectRepository: ImprovedProjectRepository
    let areaRepository: AreaRepository
    let tagRepository: TagRepository
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.taskRepository = ImprovedTaskRepository()
        self.projectRepository = ImprovedProjectRepository()
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
        let result = taskRepository.fetchActiveTasks()
        switch result {
        case .success(let fetchedTasks):
            tasks = fetchedTasks.sorted { (task1: TaskEntity, task2: TaskEntity) in
                // Сортуємо за sortOrder
                return task1.sortOrder < task2.sortOrder
            }
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            tasks = []
        }
    }
    
    func loadProjects() {
        let result = projectRepository.fetchActiveProjects()
        switch result {
        case .success(let fetchedProjects):
            projects = fetchedProjects
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            projects = []
        }
    }
    
    func loadAreas() {
        areas = areaRepository.fetchAllAreas()
    }
    
    func loadTags() {
        tags = tagRepository.fetchAllTags()
    }
    
    // MARK: - Task Actions
    
    func addTask(title: String = "New Task", description: String = "", project: ProjectEntity? = nil, area: AreaEntity? = nil) {
        let result = taskRepository.createTask(
            title: title,
            description: description,
            area: area,
            project: project
        )
        
        switch result {
        case .success(let task):
            print("✅ Task created: \(task.title ?? "")")
            loadTasks()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func toggleTaskCompletion(_ task: TaskEntity) {
        let result: Result<Void, AppError>
        
        if task.isCompleted {
            result = taskRepository.markIncomplete(task)
        } else {
            result = taskRepository.markCompleted(task)
        }
        
        switch result {
        case .success:
            loadTasks()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTask(_ task: TaskEntity) {
        let result = taskRepository.deleteTask(task)
        
        switch result {
        case .success:
            loadTasks()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            deleteTask(tasks[index])
        }
    }
    
    // MARK: - Smart Lists
    
    func getTodayTasks() -> [TaskEntity] {
        let result = taskRepository.fetchTodayTasks()
        switch result {
        case .success(let tasks):
            return tasks.sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return []
        }
    }
    
    func getUpcomingTasks() -> [TaskEntity] {
        let result = taskRepository.fetchUpcomingTasks()
        switch result {
        case .success(let tasks):
            return tasks.sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return []
        }
    }
    
    func getInboxTasks() -> [TaskEntity] {
        let result = taskRepository.fetchInboxTasks()
        switch result {
        case .success(let tasks):
            return tasks.sorted { (task1: TaskEntity, task2: TaskEntity) in
                return task1.sortOrder < task2.sortOrder
            }
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return []
        }
    }
    
    func getCompletedTasks() -> [TaskEntity] {
        let result = taskRepository.fetchCompletedTasks()
        switch result {
        case .success(let tasks):
            return tasks
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return []
        }
    }
    
    // MARK: - Project Actions
    
    func addProject(name: String, description: String = "", area: AreaEntity? = nil, color: String = "blue", iconName: String = "folder.fill") -> ProjectEntity? {
        let result = projectRepository.createProject(
            name: name,
            notes: description,
            area: area,
            color: color,
            iconName: iconName
        )
        
        switch result {
        case .success(let project):
            print("✅ Project created: \(project.name ?? "")")
            loadProjects()
            return project
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
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
