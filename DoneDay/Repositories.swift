//
//  Repositories.swift
//  DoneDay - Репозиторії для роботи з даними (Core Data)
//
//  Created by Yaroslav Tkachenko on 02.10.2025.
//

import CoreData
import Foundation

// MARK: - Base Repository з Result<Success, Error>
// Repository Pattern - архітектурний патерн для роботи з даними
// Використовує Result<Success, Error> для безпечної обробки помилок

class BaseRepository<Entity: NSManagedObject> {
    let context: NSManagedObjectContext
    let entityName: String
    
    init(context: NSManagedObjectContext, entityName: String) {
        self.context = context
        self.entityName = entityName
    }
    
    func fetch() -> Result<[Entity], AppError> {
        return fetch(predicate: nil)
    }
    
    func fetch(predicate: NSPredicate?) -> Result<[Entity], AppError> {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = predicate
        
        do {
            let results = try context.fetch(request)
            return .success(results)
        } catch {
            return .failure(.coreDataFetchFailed(error))
        }
    }
    
    func save() -> Result<Void, AppError> {
        guard context.hasChanges else {
            return .success(())
        }
        
        do {
            try context.save()
            print("✅ \(entityName) saved successfully")
            return .success(())
        } catch {
            return .failure(.coreDataSaveFailed(error))
        }
    }
    
    func delete(_ entity: Entity) -> Result<Void, AppError> {
        context.delete(entity)
        return save()
    }
}

// MARK: - Task Repository з обробкою помилок

class TaskRepository: BaseRepository<TaskEntity> {
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        super.init(context: context, entityName: "TaskEntity")
    }
    
    func createTask(
        title: String,
        description: String? = nil,
        area: AreaEntity? = nil,
        project: ProjectEntity? = nil,
        priority: Int = 0,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        reminderOffset: Int16 = 0
    ) -> Result<TaskEntity, AppError> {
        // Валідація
        let validationResult = ValidationService.shared.validateTaskTitle(title)
        switch validationResult {
        case .success(let validTitle):
            // Валідація пріоритету
            let priorityResult = ValidationService.shared.validatePriority(priority)
            guard case .success(let validPriority) = priorityResult else {
                if case .failure(let error) = priorityResult {
                    print("❌ [TaskRepository] Priority validation failed: \(error)")
                    return .failure(error)
                }
                return .failure(.invalidData)
            }
            
            // 🔍 DEBUG: Логування валідованого пріоритету
            print("✅ [TaskRepository] Priority validated: \(validPriority)")
            
            // Створення
            guard let task = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? TaskEntity else {
                return .failure(.taskCreationFailed(reason: "Не вдалося створити об'єкт TaskEntity"))
            }
            task.id = UUID()
            task.title = validTitle
            task.notes = description
            task.createdAt = Date()
            task.updatedAt = Date()
            task.isCompleted = false
            task.area = area
            task.project = project
            task.priority = Int16(validPriority)
            task.dueDate = dueDate
            task.startDate = startDate
            task.sortOrder = Int32(Date().timeIntervalSince1970)
            
            // Налаштування нагадувань
            task.reminderEnabled = reminderEnabled
            task.reminderTime = reminderTime
            task.reminderOffset = reminderOffset
            
            // 🔍 DEBUG: Підтвердження встановлення пріоритету
            print("🎯 [TaskRepository] Task created with priority: \(task.priority)")
            
            // Збереження
            let saveResult = save()
            switch saveResult {
            case .success:
                // Заплануват нагадування якщо увімкнено
                if reminderEnabled {
                    NotificationManager.shared.scheduleNotification(for: task)
                }
                return .success(task)
            case .failure(let error):
                return .failure(.taskCreationFailed(reason: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func updateTask(
        _ task: TaskEntity,
        title: String? = nil,
        description: String? = nil,
        project: ProjectEntity? = nil,
        area: AreaEntity? = nil
    ) -> Result<TaskEntity, AppError> {
        // Валідація якщо змінюється title
        var validTitle: String?
        if let newTitle = title {
            let validationResult = ValidationService.shared.validateTaskTitle(newTitle)
            switch validationResult {
            case .success(let validatedTitle):
                validTitle = validatedTitle
            case .failure(let error):
                return .failure(error)
            }
        }
        
        // Оновлення
        if let validTitle = validTitle { task.title = validTitle }
        if let description = description { task.notes = description }
        task.project = project
        task.area = area
        task.updatedAt = Date()
        
        // Збереження
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(task)
        case .failure(let error):
            return .failure(.taskUpdateFailed(reason: error.localizedDescription))
        }
    }
    
    func markCompleted(_ task: TaskEntity) -> Result<Void, AppError> {
        task.isCompleted = true
        task.completedAt = Date()
        task.updatedAt = Date()
        
        // Скасувати нагадування для завершеного завдання
        NotificationManager.shared.cancelNotification(for: task)
        
        // MARK: - Recurring Tasks Logic
        // Якщо завдання повторюване, створюємо наступний екземпляр
        if task.isRecurring, let nextDate = task.nextRecurrenceDate() {
            // Перевіряємо чи не перевищено recurrenceEndDate
            let shouldCreateNext: Bool
            if let endDate = task.recurrenceEndDate {
                shouldCreateNext = nextDate <= endDate
            } else {
                shouldCreateNext = true
            }
            
            if shouldCreateNext {
                // Створюємо новий екземпляр з тими самими параметрами
                let newTaskResult = createTask(
                    title: task.title ?? "Повторюване завдання",
                    description: task.notes,
                    area: task.area,
                    project: task.project,
                    priority: Int(task.priority),
                    dueDate: nextDate,
                    startDate: nil
                )
                
                // Копіюємо recurring параметри до нового завдання
                if case .success(let newTask) = newTaskResult {
                    newTask.recurrenceType = task.recurrenceType
                    newTask.recurrenceInterval = task.recurrenceInterval
                    newTask.recurrenceEndDate = task.recurrenceEndDate
                    
                    print("✅ [TaskRepository] Created next recurring task: \(newTask.title ?? "") for date: \(nextDate)")
                } else if case .failure(let error) = newTaskResult {
                    print("❌ [TaskRepository] Failed to create next recurring task: \(error)")
                }
            } else {
                print("ℹ️ [TaskRepository] Recurring task reached end date, not creating next instance")
            }
        }
        
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.taskUpdateFailed(reason: error.localizedDescription))
        }
    }
    
    func deleteTask(_ task: TaskEntity) -> Result<Void, AppError> {
        // Скасувати нагадування перед видаленням
        NotificationManager.shared.cancelNotification(for: task)
        
        let result = delete(task)
        switch result {
        case .success:
            return .success(())
        case .failure:
            return .failure(.taskDeletionFailed(reason: "Не вдалося видалити завдання"))
        }
    }
    
    func fetchActiveTasks() -> Result<[TaskEntity], AppError> {
        let predicate = NSPredicate(format: "isCompleted == false")
        return fetch(predicate: predicate)
    }
    
    // MARK: - Smart Lists Methods
    
    func fetchTodayTasks() -> Result<[TaskEntity], AppError> {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == false", today as NSDate, tomorrow as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchUpcomingTasks(days: Int = 7) -> Result<[TaskEntity], AppError> {
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
        
        let predicate = NSPredicate(format: "dueDate > %@ AND dueDate <= %@ AND isCompleted == false", today as NSDate, futureDate as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchInboxTasks() -> Result<[TaskEntity], AppError> {
        let predicate = NSPredicate(format: "area == nil AND project == nil AND isCompleted == false")
        return fetch(predicate: predicate)
    }
    
    func fetchCompletedTasks() -> Result<[TaskEntity], AppError> {
        let predicate = NSPredicate(format: "isCompleted == true")
        let sortByCompletedDate = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        let request = NSFetchRequest<TaskEntity>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortByCompletedDate
        
        do {
            let results = try context.fetch(request)
            return .success(results)
        } catch {
            return .failure(.coreDataFetchFailed(error))
        }
    }
    
    func markIncomplete(_ task: TaskEntity) -> Result<Void, AppError> {
        task.isCompleted = false
        task.completedAt = nil
        task.updatedAt = Date()
        
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.taskUpdateFailed(reason: error.localizedDescription))
        }
    }
}

// MARK: - Project Repository з обробкою помилок

class ProjectRepository: BaseRepository<ProjectEntity> {
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        super.init(context: context, entityName: "ProjectEntity")
    }
    
    func createProject(
        name: String,
        notes: String? = nil,
        area: AreaEntity? = nil,
        color: String? = nil,
        iconName: String? = nil
    ) -> Result<ProjectEntity, AppError> {
        // Валідація
        let validationResult = ValidationService.shared.validateProjectName(name)
        switch validationResult {
        case .success(let validName):
            // Створення
            guard let project = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? ProjectEntity else {
                return .failure(.projectCreationFailed(reason: "Не вдалося створити об'єкт ProjectEntity"))
            }
            project.id = UUID()
            project.name = validName
            project.notes = notes
            project.createdAt = Date()
            project.updatedAt = Date()
            project.isCompleted = false
            project.area = area
            project.color = color ?? "blue"
            project.iconName = iconName ?? "folder.fill"
            
            // Збереження
            let saveResult = save()
            switch saveResult {
            case .success:
                return .success(project)
            case .failure(let error):
                return .failure(.projectCreationFailed(reason: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func updateProject(
        _ project: ProjectEntity,
        name: String? = nil,
        notes: String? = nil,
        area: AreaEntity? = nil,
        color: String? = nil,
        iconName: String? = nil
    ) -> Result<ProjectEntity, AppError> {
        // Валідація якщо змінюється назва
        var validName: String?
        if let newName = name {
            let validationResult = ValidationService.shared.validateProjectName(newName)
            switch validationResult {
            case .success(let validatedName):
                validName = validatedName
            case .failure(let error):
                return .failure(error)
            }
        }
        
        // Оновлення
        if let validName = validName { project.name = validName }
        if let notes = notes { project.notes = notes }
        if let area = area { project.area = area }
        if let color = color { project.color = color }
        if let iconName = iconName { project.iconName = iconName }
        project.updatedAt = Date()
        
        // Збереження
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(project)
        case .failure(let error):
            return .failure(.projectUpdateFailed(reason: error.localizedDescription))
        }
    }
    
    func deleteProject(_ project: ProjectEntity) -> Result<Void, AppError> {
        let result = delete(project)
        switch result {
        case .success:
            return .success(())
        case .failure:
            return .failure(.projectDeletionFailed(reason: "Не вдалося видалити проект"))
        }
    }
    
    func fetchActiveProjects() -> Result<[ProjectEntity], AppError> {
        let predicate = NSPredicate(format: "isCompleted == false")
        return fetch(predicate: predicate)
    }
}

// MARK: - Area Repository з обробкою помилок

class AreaRepository: BaseRepository<AreaEntity> {
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        super.init(context: context, entityName: "AreaEntity")
    }
    
    func createArea(
        name: String,
        notes: String? = nil,
        iconName: String? = nil,
        color: String? = nil
    ) -> Result<AreaEntity, AppError> {
        guard let area = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? AreaEntity else {
            return .failure(.areaCreationFailed(reason: "Не вдалося створити об'єкт AreaEntity"))
        }
        area.id = UUID()
        area.name = name
        area.notes = notes
        area.iconName = iconName
        area.color = color
        area.createdAt = Date()
        area.updatedAt = Date()
        
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(area)
        case .failure(let error):
            return .failure(.areaCreationFailed(reason: error.localizedDescription))
        }
    }
    
    func fetchAllAreas() -> Result<[AreaEntity], AppError> {
        let sortByName = [NSSortDescriptor(key: "name", ascending: true)]
        let request = NSFetchRequest<AreaEntity>(entityName: entityName)
        request.sortDescriptors = sortByName
        
        do {
            let results = try context.fetch(request)
            return .success(results)
        } catch {
            return .failure(.coreDataFetchFailed(error))
        }
    }
    
    func deleteArea(_ area: AreaEntity) -> Result<Void, AppError> {
        let result = delete(area)
        switch result {
        case .success:
            return .success(())
        case .failure:
            return .failure(.areaDeletionFailed(reason: "Не вдалося видалити область"))
        }
    }
}

// MARK: - Tag Repository з обробкою помилок

class TagRepository: BaseRepository<TagEntity> {
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        super.init(context: context, entityName: "TagEntity")
    }
    
    func createTag(
        name: String,
        color: String? = nil
    ) -> Result<TagEntity, AppError> {
        guard let tag = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? TagEntity else {
            return .failure(.tagCreationFailed(reason: "Не вдалося створити об'єкт TagEntity"))
        }
        tag.id = UUID()
        tag.name = name
        tag.color = color
        tag.createdAt = Date()
        tag.updatedAt = Date()
        
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(tag)
        case .failure(let error):
            return .failure(.tagCreationFailed(reason: error.localizedDescription))
        }
    }
    
    func fetchAllTags() -> Result<[TagEntity], AppError> {
        let sortByName = [NSSortDescriptor(key: "name", ascending: true)]
        let request = NSFetchRequest<TagEntity>(entityName: entityName)
        request.sortDescriptors = sortByName
        
        do {
            let results = try context.fetch(request)
            return .success(results)
        } catch {
            return .failure(.coreDataFetchFailed(error))
        }
    }
    
    func findOrCreateTag(name: String) -> Result<TagEntity, AppError> {
        let predicate = NSPredicate(format: "name == %@", name)
        let existingResult = fetch(predicate: predicate)
        
        switch existingResult {
        case .success(let existingTags):
            if let existingTag = existingTags.first {
                return .success(existingTag)
            } else {
                return createTag(name: name)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func deleteTag(_ tag: TagEntity) -> Result<Void, AppError> {
        let result = delete(tag)
        switch result {
        case .success:
            return .success(())
        case .failure:
            return .failure(.tagDeletionFailed(reason: "Не вдалося видалити тег"))
        }
    }
}

