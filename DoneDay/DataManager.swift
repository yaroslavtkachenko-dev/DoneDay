//
//  DataManager.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import CoreData
import Foundation
import SwiftUI

/// Core Data stack manager for DoneDay app - адаптований під існуючий PersistenceController
class DataManager {
    static let shared = DataManager()
    
    // MARK: - Core Data Stack - використовуємо існуючий PersistenceController
    
    var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    var persistentContainer: NSPersistentContainer {
        return PersistenceController.shared.container
    }
    
    // MARK: - Core Data Saving
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ Core Data save error: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Context
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Memory Management
    
    func deleteAll() {
        let entities = ["TaskEntity", "ProjectEntity", "AreaEntity", "TagEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }
        save()
    }
}
