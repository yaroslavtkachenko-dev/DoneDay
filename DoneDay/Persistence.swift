//
//  Persistence.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import CoreData

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
        }
        
        var loadFailed = false
        var capturedError: Error?
        
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let self = self else { return }
            if let error = error as NSError? {
                loadFailed = true
                capturedError = error
                
                print("❌ Core Data load error: \(error)")
                print("❌ Error details: \(error.userInfo)")
                
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
                print("✅ Core Data store loaded successfully")
            }
        })
        
        self.isStoreLoadFailed = loadFailed
        self.loadError = capturedError
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Graceful Degradation
    
    private func setupFallbackStore() {
        print("🔄 Setting up fallback in-memory store...")
        
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
            print("✅ Fallback in-memory store created successfully")
            print("⚠️ Data will not be persisted - this is a temporary solution")
        } catch {
            print("❌ Failed to create fallback store: \(error)")
        }
    }
}
