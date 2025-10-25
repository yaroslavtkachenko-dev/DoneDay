//
//  Persistence.swift
//  DoneDay - Core Data persistence layer
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import CoreData
import OSLog

class PersistenceController {
    static let shared = PersistenceController()
    
    // Flag to track if Core Data failed to load
    private(set) var isStoreLoadFailed = false
    private(set) var loadError: Error?

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample projects
        let personalProject = ProjectEntity(context: viewContext)
        personalProject.name = "Personal"
        personalProject.color = "blue"
        personalProject.iconName = "person.fill"
        
        let workProject = ProjectEntity(context: viewContext)
        workProject.name = "Work"
        workProject.color = "red"
        workProject.iconName = "briefcase.fill"
        
        // Create sample tasks
        let sampleTasks = [
            ("Complete DoneDay app", "Finish the task management app development", 2, personalProject),
            ("Buy groceries", "Milk, bread, eggs, fruits", 1, personalProject),
            ("Call mom", "", 0, personalProject),
            ("Prepare presentation", "Quarterly review presentation for Monday", 3, workProject),
            ("Review code", "Check pull requests from team", 1, workProject),
            ("Exercise", "30 minutes cardio workout", 0, personalProject)
        ]
        
        for (index, (title, notes, priority, project)) in sampleTasks.enumerated() {
            let task = TaskEntity(context: viewContext)
            task.title = title
            task.notes = notes.isEmpty ? nil : notes
            task.priority = Int16(priority)
            task.project = project
            task.sortOrder = Int32(index)
            task.isCompleted = Bool.random()
            
            if task.isCompleted {
                task.completedAt = Date().addingTimeInterval(-Double.random(in: 0...86400))
            }
            
            // Some tasks have due dates
            if index % 3 == 0 {
                task.dueDate = Date().addingTimeInterval(Double.random(in: 86400...604800)) // 1-7 days from now
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DoneDay")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Увімкнути автоматичну міграцію
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }
        
        var loadFailed = false
        var capturedError: Error?
        
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let self = self else { return }
            if let error = error as NSError? {
                loadFailed = true
                capturedError = error
                
                logger.error("Core Data load error: \(error.localizedDescription)", category: .coreData)
                logger.error("Error details: \(error.userInfo)", category: .coreData)
                
                // Handle the error gracefully through ErrorAlertManager
                DispatchQueue.main.async {
                    ErrorAlertManager.shared.handle(.coreDataFetchFailed(error))
                }
                
                // Try to recover by using in-memory store
                self.setupFallbackStore()
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
            } else {
                logger.success("Core Data store loaded successfully", category: .coreData)
            }
        })
        
        self.isStoreLoadFailed = loadFailed
        self.loadError = capturedError
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Graceful Degradation
    
    private func setupFallbackStore() {
        logger.warning("Setting up fallback in-memory store...", category: .coreData)
        
        // Create a new in-memory store as fallback
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        do {
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSInMemoryStoreType,
                configurationName: nil,
                at: nil,
                options: nil
            )
            logger.success("Fallback in-memory store created successfully", category: .coreData)
            logger.warning("Data will not be persisted - this is a temporary solution", category: .coreData)
        } catch {
            logger.error("Failed to create fallback store: \(error.localizedDescription)", category: .coreData)
        }
    }
    
    // MARK: - Core Data Operations (Merged from DataManager)
    
    /// Access to main view context
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    /// Save changes with proper error handling
    func save() -> Result<Void, AppError> {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return .success(())
        }
        
        do {
            try context.save()
            logger.logCoreDataSave(success: true)
            return .success(())
        } catch {
            logger.error("Core Data save error: \(error.localizedDescription)", category: .coreData)
            return .failure(.coreDataSaveFailed(error))
        }
    }
    
    /// Perform background task
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    /// Delete all data (use with caution)
    func deleteAll() {
        let entities = ["TaskEntity", "ProjectEntity", "AreaEntity", "TagEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                logger.error("Failed to delete \(entityName): \(error.localizedDescription)", category: .coreData)
            }
        }
        _ = save()
    }
}
