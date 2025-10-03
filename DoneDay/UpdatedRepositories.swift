//
//  UpdatedRepositories.swift
//  DoneDay - Repository з обробкою помилок
//
//  Created by Yaroslav Tkachenko on 02.10.2025.
//

import CoreData
import Foundation

// MARK: - Base Repository з Result<Success, Error>

class ImprovedBaseRepository<Entity: NSManagedObject> {
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

class ImprovedTaskRepository: ImprovedBaseRepository<TaskEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
        super.init(context: context, entityName: "TaskEntity")
    }
    
    func createTask(
        title: String,
        description: String? = nil,
        area: AreaEntity? = nil,
        project: ProjectEntity? = nil
    ) -> Result<TaskEntity, AppError> {
        // Валідація
        do {
            try Validator.validateTask(title)
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.taskCreationFailed(reason: error.localizedDescription))
        }
        
        // Створення
        let task = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! TaskEntity
        task.id = UUID()
        task.title = title
        task.notes = description
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isCompleted = false
        task.area = area
        task.project = project
        task.sortOrder = Int32(Date().timeIntervalSince1970)
        
        // Збереження
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(task)
        case .failure(let error):
            return .failure(.taskCreationFailed(reason: error.localizedDescription))
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
        if let newTitle = title {
            do {
                try Validator.validateTask(newTitle)
            } catch let error as AppError {
                return .failure(error)
            } catch {
                return .failure(.taskUpdateFailed(reason: error.localizedDescription))
            }
        }
        
        // Оновлення
        if let title = title { task.title = title }
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
        
        let saveResult = save()
        switch saveResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.taskUpdateFailed(reason: error.localizedDescription))
        }
    }
    
    func deleteTask(_ task: TaskEntity) -> Result<Void, AppError> {
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
    
    // MARK: - Smart Lists Methods (додано для уніфікації)
    
    func fetchTodayTasks() -> Result<[TaskEntity], AppError> {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == false AND isDelete == NO", today as NSDate, tomorrow as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchUpcomingTasks(days: Int = 7) -> Result<[TaskEntity], AppError> {
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
        
        let predicate = NSPredicate(format: "dueDate > %@ AND dueDate <= %@ AND isCompleted == false AND isDelete == NO", today as NSDate, futureDate as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchInboxTasks() -> Result<[TaskEntity], AppError> {
        let predicate = NSPredicate(format: "area == nil AND project == nil AND isCompleted == false AND isDelete == NO")
        return fetch(predicate: predicate)
    }
    
    func fetchCompletedTasks() -> Result<[TaskEntity], AppError> {
        let predicate = NSPredicate(format: "isCompleted == true AND isDelete == NO")
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

class ImprovedProjectRepository: ImprovedBaseRepository<ProjectEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
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
        do {
            try Validator.validateProjectName(name)
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.projectCreationFailed(reason: error.localizedDescription))
        }
        
        // Створення
        let project = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ProjectEntity
        project.id = UUID()
        project.name = name
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
        if let newName = name {
            do {
                try Validator.validateProjectName(newName)
            } catch let error as AppError {
                return .failure(error)
            } catch {
                return .failure(.projectUpdateFailed(reason: error.localizedDescription))
            }
        }
        
        // Оновлення
        if let name = name { project.name = name }
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

// MARK: - Приклад використання в ViewModel (DEPRECATED - використовуйте методи з основного класу)

// extension TaskViewModel {
//     
//     func addTaskWithErrorHandling(
//         title: String,
//         description: String? = nil,
//         project: ProjectEntity? = nil,
//         area: AreaEntity? = nil
//     ) {
//         let improvedRepo = ImprovedTaskRepository() // ❌ Створює новий екземпляр
//         let result = improvedRepo.createTask(
//             title: title,
//             description: description,
//             area: area,
//             project: project
//         )
//         
//         switch result {
//         case .success(let task):
//             print("✅ Task created: \(task.title ?? "")")
//             loadTasks()
//         case .failure(let error):
//             ErrorAlertManager.shared.handle(error)
//         }
//     }
//     
//     func addProjectWithErrorHandling(
//         name: String,
//         description: String? = nil,
//         area: AreaEntity? = nil,
//         color: String? = nil,
//         iconName: String? = nil
//     ) {
//         let improvedRepo = ImprovedProjectRepository() // ❌ Створює новий екземпляр
//         let result = improvedRepo.createProject(
//             name: name,
//             notes: description,
//             area: area,
//             color: color,
//             iconName: iconName
//         )
//         
//         switch result {
//         case .success(let project):
//             print("✅ Project created: \(project.name ?? "")")
//             loadProjects()
//         case .failure(let error):
//             ErrorAlertManager.shared.handle(error)
//         }
//     }
// }
