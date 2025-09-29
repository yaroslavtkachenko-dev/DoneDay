//
//  Repository.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import CoreData
import Foundation

// MARK: - Base Repository Protocol

protocol Repository {
    associatedtype Entity: NSManagedObject
    
    func fetch() -> [Entity]
    func fetch(predicate: NSPredicate?) -> [Entity]
    func fetch(sortBy: [NSSortDescriptor]) -> [Entity]
    func create() -> Entity
    func save() throws
    func delete(_ entity: Entity) throws
}

// MARK: - Base Repository Implementation

class BaseRepository<Entity: NSManagedObject>: Repository {
    let context: NSManagedObjectContext
    let entityName: String
    
    init(context: NSManagedObjectContext, entityName: String) {
        self.context = context
        self.entityName = entityName
    }
    
    func fetch() -> [Entity] {
        return fetch(predicate: nil)
    }
    
    func fetch(predicate: NSPredicate?) -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = predicate
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error for \(entityName): \(error)")
            return []
        }
    }
    
    func fetch(sortBy: [NSSortDescriptor]) -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.sortDescriptors = sortBy
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch with sort error for \(entityName): \(error)")
            return []
        }
    }
    
    func create() -> Entity {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! Entity
    }
    
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func delete(_ entity: Entity) throws {
        context.delete(entity)
        try save()
    }
}

// MARK: - Task Repository

class TaskRepository: BaseRepository<TaskEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
        super.init(context: context, entityName: "TaskEntity")
    }
    
    // MARK: - Task-specific methods - адаптовано під вашу модель
    
    func createTask(title: String, description: String? = nil, area: AreaEntity? = nil, project: ProjectEntity? = nil) -> TaskEntity {
        let task = create()
        task.id = UUID()
        task.title = title
        task.notes = description
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isCompleted = false
        task.isDelete = false // використовуємо ваш soft delete
        task.area = area
        task.project = project
        
        // Автоматично встановлюємо sortOrder
        let maxSortOrder = fetchMaxSortOrder()
        task.sortOrder = maxSortOrder + 1
        
        return task
    }
    
    func fetchActiveTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "isDelete == NO")
        let sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: true)]
        
        let request = NSFetchRequest<TaskEntity>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch active tasks error: \(error)")
            return []
        }
    }
    
    func fetchTodayTasks() -> [TaskEntity] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == false AND isDelete == NO", today as NSDate, tomorrow as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchUpcomingTasks(days: Int = 7) -> [TaskEntity] {
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
        
        let predicate = NSPredicate(format: "dueDate > %@ AND dueDate <= %@ AND isCompleted == false AND isDelete == NO", today as NSDate, futureDate as NSDate)
        return fetch(predicate: predicate)
    }
    
    func fetchInboxTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "area == nil AND project == nil AND isCompleted == false AND isDelete == NO")
        return fetch(predicate: predicate)
    }
    
    func fetchCompletedTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "isCompleted == true AND isDelete == NO")
        let sortByCompletedDate = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        let request = NSFetchRequest<TaskEntity>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortByCompletedDate
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch completed tasks error: \(error)")
            return []
        }
    }
    
    func markCompleted(_ task: TaskEntity) throws {
        task.isCompleted = true
        task.completedAt = Date()
        task.updatedAt = Date()
        try save()
    }
    
    func markIncomplete(_ task: TaskEntity) throws {
        task.isCompleted = false
        task.completedAt = nil
        task.updatedAt = Date()
        try save()
    }
    
    func softDelete(_ task: TaskEntity) throws {
        task.isDelete = true
        task.updatedAt = Date()
        try save()
    }
    
    func restore(_ task: TaskEntity) throws {
        task.isDelete = false
        task.updatedAt = Date()
        try save()
    }
    
    private func fetchMaxSortOrder() -> Int32 {
        let request = NSFetchRequest<TaskEntity>(entityName: entityName)
        request.predicate = NSPredicate(format: "isDelete == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let tasks = try context.fetch(request)
            return tasks.first?.sortOrder ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Project Repository

class ProjectRepository: BaseRepository<ProjectEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
        super.init(context: context, entityName: "ProjectEntity")
    }
    
    func createProject(name: String, notes: String? = nil, area: AreaEntity? = nil, color: String? = nil, iconName: String? = nil) -> ProjectEntity {
        let project = create()
        project.id = UUID()
        project.name = name
        project.notes = notes
        project.createdAt = Date()
        project.updatedAt = Date()
        project.isCompleted = false
        project.area = area
        project.color = color ?? "blue"
        project.iconName = iconName ?? "folder.fill"
        return project
    }
    
    func fetchActiveProjects() -> [ProjectEntity] {
        let predicate = NSPredicate(format: "isCompleted == false")
        let sortByName = [NSSortDescriptor(key: "name", ascending: true)]
        
        let request = NSFetchRequest<ProjectEntity>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortByName
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch active projects error: \(error)")
            return []
        }
    }
    
    func fetchProjectsInArea(_ area: AreaEntity) -> [ProjectEntity] {
        let predicate = NSPredicate(format: "area == %@", area)
        return fetch(predicate: predicate)
    }
}

// MARK: - Area Repository

class AreaRepository: BaseRepository<AreaEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
        super.init(context: context, entityName: "AreaEntity")
    }
    
    func createArea(name: String, notes: String? = nil, iconName: String? = nil, color: String? = nil) -> AreaEntity {
        let area = create()
        area.id = UUID()
        area.name = name
        area.notes = notes
        area.iconName = iconName
        area.color = color
        area.createdAt = Date()
        return area
    }
    
    func fetchAllAreas() -> [AreaEntity] {
        let sortByName = [NSSortDescriptor(key: "name", ascending: true)]
        return fetch(sortBy: sortByName)
    }
}

// MARK: - Tag Repository

class TagRepository: BaseRepository<TagEntity> {
    
    init(context: NSManagedObjectContext = DataManager.shared.context) {
        super.init(context: context, entityName: "TagEntity")
    }
    
    func createTag(name: String, color: String? = nil) -> TagEntity {
        let tag = create()
        tag.id = UUID()
        tag.name = name
        tag.color = color
        tag.createdAt = Date()
        return tag
    }
    
    func fetchAllTags() -> [TagEntity] {
        let sortByName = [NSSortDescriptor(key: "name", ascending: true)]
        return fetch(sortBy: sortByName)
    }
    
    func findOrCreateTag(name: String) -> TagEntity {
        let predicate = NSPredicate(format: "name == %@", name)
        let existingTags = fetch(predicate: predicate)
        
        if let existingTag = existingTags.first {
            return existingTag
        } else {
            return createTag(name: name)
        }
    }
}
