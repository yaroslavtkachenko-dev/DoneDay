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
    
    // MARK: - Published Properties (Auto-updating via FRC)
    @Published var tasks: [TaskEntity] = []
    @Published var projects: [ProjectEntity] = []
    @Published var areas: [AreaEntity] = []
    @Published var tags: [TagEntity] = []
    
    // MARK: - Repositories
    let taskRepository: TaskRepository
    let projectRepository: ProjectRepository
    let areaRepository: AreaRepository
    let tagRepository: TagRepository
    
    // MARK: - Private Publishers (FRC-based)
    private let tasksPublisher: FetchedResultsPublisher<TaskEntity>
    private let projectsPublisher: FetchedResultsPublisher<ProjectEntity>
    private let areasPublisher: FetchedResultsPublisher<AreaEntity>
    private let tagsPublisher: FetchedResultsPublisher<TagEntity>
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let context = PersistenceController.shared.context
        
        // Ініціалізація repositories
        self.taskRepository = TaskRepository(context: context)
        self.projectRepository = ProjectRepository(context: context)
        self.areaRepository = AreaRepository(context: context)
        self.tagRepository = TagRepository(context: context)
        
        // Створення FRC publishers для кожної entity
        
        // Tasks: активні завдання, сортовані по sortOrder
        self.tasksPublisher = FetchedResultsPublisher(
            context: context,
            entityName: "TaskEntity",
            sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
            predicate: NSPredicate(format: "isCompleted == false AND isDelete == false")
        )
        
        // Projects: активні проекти, сортовані по назві
        self.projectsPublisher = FetchedResultsPublisher(
            context: context,
            entityName: "ProjectEntity",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
            predicate: NSPredicate(format: "isCompleted == false")
        )
        
        // Areas: всі області, сортовані по назві
        self.areasPublisher = FetchedResultsPublisher(
            context: context,
            entityName: "AreaEntity",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
            predicate: nil
        )
        
        // Tags: всі теги, сортовані по назві
        self.tagsPublisher = FetchedResultsPublisher(
            context: context,
            entityName: "TagEntity",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
            predicate: nil
        )
        
        // Підписка на автоматичні оновлення
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    
    /// Підписується на зміни з FRC publishers і оновлює @Published properties
    private func setupBindings() {
        // Tasks: коли tasksPublisher.entities змінюється → оновлюємо tasks
        tasksPublisher.$entities
            .receive(on: DispatchQueue.main)
            .assign(to: \.tasks, on: self)
            .store(in: &cancellables)
        
        // Projects
        projectsPublisher.$entities
            .receive(on: DispatchQueue.main)
            .assign(to: \.projects, on: self)
            .store(in: &cancellables)
        
        // Areas
        areasPublisher.$entities
            .receive(on: DispatchQueue.main)
            .assign(to: \.areas, on: self)
            .store(in: &cancellables)
        
        // Tags
        tagsPublisher.$entities
            .receive(on: DispatchQueue.main)
            .assign(to: \.tags, on: self)
            .store(in: &cancellables)
        
        logger.success("TaskViewModel: FRC bindings established", category: .viewModel)
    }
    
    
    // MARK: - Task Actions
    
    func addTask(
        title: String = "New Task",
        description: String = "",
        project: ProjectEntity? = nil,
        area: AreaEntity? = nil,
        priority: Int = 0,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        reminderOffset: Int16 = 0
    ) {
        // 🔍 DEBUG: Логування вхідних параметрів
        print("📥 [TaskViewModel.addTask] Received parameters:")
        print("   - title: \(title)")
        print("   - priority: \(priority)")
        print("   - dueDate: \(dueDate?.description ?? "nil")")
        
        let result = taskRepository.createTask(
            title: title,
            description: description,
            area: area,
            project: project,
            priority: priority,
            dueDate: dueDate,
            startDate: startDate,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            reminderOffset: reminderOffset
        )
        
        switch result {
        case .success(let task):
            logger.success("Task created: \(task.title ?? "") with priority: \(task.priority)", category: .viewModel)
            print("✅ [TaskViewModel.addTask] Task created successfully!")
            print("   - Task ID: \(task.id?.uuidString ?? "unknown")")
            print("   - Priority: \(task.priority)")
            // Не викликаємо loadTasks() - FRC автоматично оновить
        case .failure(let error):
            print("❌ [TaskViewModel.addTask] Failed to create task: \(error)")
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    /// Створює завдання з конкретною датою виконання
    /// - Parameters:
    ///   - title: Назва завдання
    ///   - date: Дата виконання
    ///   - description: Опис (опціонально)
    ///   - project: Проект (опціонально)
    ///   - area: Область (опціонально)
    func createTaskWithDueDate(
        title: String,
        date: Date,
        description: String = "",
        project: ProjectEntity? = nil,
        area: AreaEntity? = nil,
        priority: Int = 0
    ) {
        let result = taskRepository.createTask(
            title: title,
            description: description,
            area: area,
            project: project,
            priority: priority,
            dueDate: date
        )
        
        switch result {
        case .success(let task):
            logger.success("Task with due date created: \(task.title ?? "") with priority: \(task.priority)", category: .viewModel)
            // FRC автоматично оновить список
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
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTask(_ task: TaskEntity) {
        let result = taskRepository.deleteTask(task)
        
        switch result {
        case .success:
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { tasks[$0] }
        
        // Оптимізовано: Видаляємо всі з контексту
        for task in tasksToDelete {
            PersistenceController.shared.context.delete(task)
        }
        
        // Один save для всіх
        let result = taskRepository.save()
        switch result {
        case .success:
            logger.success("Deleted \(tasksToDelete.count) tasks", category: .viewModel)
            // FRC автоматично оновить
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    // MARK: - Smart Lists
    
    /// Завдання на сьогодні - фільтрує з уже завантажених tasks
    func getTodayTasks() -> [TaskEntity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return tasks.filter { task in  // Фільтруємо з tasks, які вже є
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Майбутні завдання (наступні 7 днів) - фільтрує з уже завантажених tasks
    func getUpcomingTasks() -> [TaskEntity] {
        let calendar = Calendar.current
        let today = Date()
        let futureDate = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return tasks.filter { task in  // Фільтруємо з tasks
            guard let dueDate = task.dueDate else { return false }
            return dueDate > today && dueDate <= futureDate
        }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Inbox завдання (без проекту та області) - фільтрує з уже завантажених tasks
    func getInboxTasks() -> [TaskEntity] {
        return tasks.filter { task in  // Фільтруємо з tasks
            task.area == nil && task.project == nil
        }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Завершені завдання - треба fetch окремо, бо FRC показує тільки активні
    /// Це єдиний метод, який ПРАВИЛЬНО робить окремий fetch
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
            // FRC автоматично оновить список
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
            // FRC автоматично оновить список
            break
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
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
    
    func deleteTag(_ tag: TagEntity) {
        let result = tagRepository.deleteTag(tag)
        
        switch result {
        case .success:
            // FRC автоматично оновить список
            break
        case .failure(let error):
            ErrorAlertManager.shared.handle(error)
        }
    }
}
