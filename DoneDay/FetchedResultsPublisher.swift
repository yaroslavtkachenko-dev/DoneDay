//
//  FetchedResultsPublisher.swift
//  DoneDay - Thread-safe Core Data Publisher
//
//  Created for fixing NSManagedObject in @Published
//

import Foundation
import CoreData
import Combine

/// Thread-safe publisher для Core Data entities
/// Використовує NSFetchedResultsController для автоматичних оновлень
class FetchedResultsPublisher<Entity: NSManagedObject>: NSObject, ObservableObject {
    
    /// Публічний масив entities - завжди thread-safe
    @Published private(set) var entities: [Entity] = []
    
    /// Internal setter для delegate
    internal func setEntities(_ newEntities: [Entity]) {
        self.entities = newEntities
    }
    
    /// Внутрішній FetchedResultsController
    private var fetchedResultsController: NSFetchedResultsController<Entity>
    
    /// Delegate для обходу обмежень generic класів
    private var delegate: FetchedResultsDelegate<Entity>?
    
    /// Ініціалізація з параметрами fetch request
    /// - Parameters:
    ///   - context: NSManagedObjectContext для роботи
    ///   - entityName: Назва Entity (наприклад "TaskEntity")
    ///   - sortDescriptors: Масив для сортування
    ///   - predicate: Опціональний фільтр (наприклад "isCompleted == false")
    init(
        context: NSManagedObjectContext,
        entityName: String,
        sortDescriptors: [NSSortDescriptor],
        predicate: NSPredicate? = nil
    ) {
        // Створюємо fetch request
        let fetchRequest = NSFetchRequest<Entity>(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        
        // Оптимізація: завантажувати порціями по 20
        fetchRequest.fetchBatchSize = 20
        
        // Створюємо FetchedResultsController
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil  // Без кешу для простоти
        )
        
        super.init()
        
        // Створюємо delegate після super.init()
        self.delegate = FetchedResultsDelegate(publisher: self)
        
        // Встановлюємо delegate для отримання змін
        fetchedResultsController.delegate = delegate
        
        // Виконуємо початковий fetch
        performInitialFetch()
    }
    
    /// Виконує початковий fetch даних
    private func performInitialFetch() {
        do {
            try fetchedResultsController.performFetch()
            entities = fetchedResultsController.fetchedObjects ?? []
            logger.info("FetchedResultsPublisher: Initial fetch successful, \(entities.count) entities", category: .coreData)
        } catch {
            logger.error("FetchedResultsPublisher: Initial fetch failed - \(error.localizedDescription)", category: .coreData)
            entities = []
        }
    }
    
    /// Оновлює predicate і перевиконує fetch
    /// Корисно для динамічної фільтрації
    /// - Parameter predicate: Новий predicate або nil
    func updatePredicate(_ predicate: NSPredicate?) {
        fetchedResultsController.fetchRequest.predicate = predicate
        
        do {
            try fetchedResultsController.performFetch()
            entities = fetchedResultsController.fetchedObjects ?? []
            logger.debug("FetchedResultsPublisher: Predicate updated, \(entities.count) entities", category: .coreData)
        } catch {
            logger.error("FetchedResultsPublisher: Predicate update failed - \(error.localizedDescription)", category: .coreData)
            entities = []
        }
    }
    
    /// Оновлює sort descriptors і перевиконує fetch
    /// - Parameter sortDescriptors: Нові sort descriptors
    func updateSortDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
        fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            try fetchedResultsController.performFetch()
            entities = fetchedResultsController.fetchedObjects ?? []
            logger.debug("FetchedResultsPublisher: Sort updated, \(entities.count) entities", category: .coreData)
        } catch {
            logger.error("FetchedResultsPublisher: Sort update failed - \(error.localizedDescription)", category: .coreData)
            entities = []
        }
    }
    
    /// Перевиконує fetch вручну (рідко потрібно)
    func refetch() {
        performInitialFetch()
    }
}

// MARK: - Internal Delegate Class

/// Окремий delegate клас для обходу обмежень generic класів
private class FetchedResultsDelegate<Entity: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    weak var publisher: FetchedResultsPublisher<Entity>?
    
    init(publisher: FetchedResultsPublisher<Entity>) {
        self.publisher = publisher
        super.init()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Оновлюємо entities на main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let publisher = self.publisher else { return }
            
            let newEntities = controller.fetchedObjects as? [Entity] ?? []
            publisher.setEntities(newEntities)
            
            logger.debug("FetchedResultsPublisher: Content changed, now \(newEntities.count) entities", category: .coreData)
        }
    }
}

