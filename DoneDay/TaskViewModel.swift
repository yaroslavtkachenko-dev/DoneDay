//
//  TaskViewModel.swift
//  DoneDay - ViewModel для управління завданнями та проектами
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
    
    // MARK: - Repositories (Using Result<Success, Error>)
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
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleContextSave(notification: notification)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Selective Data Refresh (Performance Optimization)
    
    private func handleContextSave(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        var shouldReloadTasks = false
        var shouldReloadProjects = false
        var shouldReloadAreas = false
        var shouldReloadTags = false
        
        // Check inserted objects
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for object in insertedObjects {
                switch object {
                case is TaskEntity:
                    shouldReloadTasks = true
                case is ProjectEntity:
                    shouldReloadProjects = true
                case is AreaEntity:
                    shouldReloadAreas = true
                case is TagEntity:
                    shouldReloadTags = true
                default:
                    break
                }
            }
        }
        
        // Check updated objects
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for object in updatedObjects {
                switch object {
                case is TaskEntity:
                    shouldReloadTasks = true
                case is ProjectEntity:
                    shouldReloadProjects = true
                case is AreaEntity:
                    shouldReloadAreas = true
                case is TagEntity:
                    shouldReloadTags = true
                default:
                    break
                }
            }
        }
        
        // Check deleted objects
        if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            for object in deletedObjects {
                switch object {
                case is TaskEntity:
                    shouldReloadTasks = true
                case is ProjectEntity:
                    shouldReloadProjects = true
                case is AreaEntity:
                    shouldReloadAreas = true
                case is TagEntity:
                    shouldReloadTags = true
                default:
                    break
                }
            }
        }
        
        // Reload only changed data (Performance improvement)
        if shouldReloadTasks {
            loadTasks()
        }
        if shouldReloadProjects {
            loadProjects()
        }
        if shouldReloadAreas {
            loadAreas()
        }
        if shouldReloadTags {
            loadTags()
        }
        
        // Log for debugging
        if shouldReloadTasks || shouldReloadProjects || shouldReloadAreas || shouldReloadTags {
            logger.debug("Selective refresh: Tasks=\(shouldReloadTasks), Projects=\(shouldReloadProjects), Areas=\(shouldReloadAreas), Tags=\(shouldReloadTags)", category: .viewModel)
        }
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
        let result = areaRepository.fetchAllAreas()
        switch result {
        case .success(let fetchedAreas):
            areas = fetchedAreas
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            areas = []
        }
    }
    
    func loadTags() {
        let result = tagRepository.fetchAllTags()
        switch result {
        case .success(let fetchedTags):
            tags = fetchedTags
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            tags = []
        }
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
            logger.success("Task created: \(task.title ?? "")", category: .viewModel)
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
            logger.success("Project created: \(project.name ?? "")", category: .viewModel)
            loadProjects()
            return project
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
            return nil
        }
    }
    
    // MARK: - Area Actions
    
    func addArea(name: String, description: String = "", iconName: String? = nil, color: String? = nil) {
        let result = areaRepository.createArea(
            name: name,
            notes: description,
            iconName: iconName,
            color: color
        )
        
        switch result {
        case .success:
            loadAreas()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    // MARK: - Tag Actions
    
    func addTag(name: String, color: String? = nil) {
        let result = tagRepository.createTag(
            name: name,
            color: color
        )
        
        switch result {
        case .success:
            loadTags()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTag(_ tag: TagEntity) {
        let result = tagRepository.deleteTag(tag)
        
        switch result {
        case .success:
            loadTags()
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
}
