//
//  Persistence.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

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
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Graceful error handling instead of crashing the app
                print("❌ Core Data load error: \(error)")
                print("❌ Error details: \(error.userInfo)")
                
                // Handle the error gracefully through ErrorAlertManager
                DispatchQueue.main.async {
                    ErrorAlertManager.shared.handle(.coreDataFetchFailed(error))
                }
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
