//
//  DoneDayApp.swift
//  DoneDay - Головний файл додатку
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct DoneDayApp: App {
    @NSApplicationDelegateAdaptor(NotificationAppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        // Запит дозволу на нотифікації при запуску
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                logger.success("Notifications authorized", category: .notification)
            } else {
                logger.warning("Notifications not authorized", category: .notification)
            }
        }
        
        // Налаштувати категорії нотифікацій
        NotificationManager.shared.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskViewModel)
                .environmentObject(notificationManager)
                .withErrorHandling()
        }
    }
}

// MARK: - App Delegate для обробки нотифікацій

class NotificationAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Призначити delegate для notification center
        UNUserNotificationCenter.current().delegate = self
        
        logger.success("App launched, notification delegate set", category: .notification)
        
        // Синхронізувати нагадування при запуску
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.syncAllNotifications()
        }
    }
    
    // Обробка нотифікацій коли додаток відкритий
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("Notification received while app is open", category: .notification)
        
        // Показати banner, звук і badge навіть коли додаток відкритий
        completionHandler([.banner, .sound, .badge])
    }
    
    // Обробка натискання на нотифікацію
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("User tapped on notification", category: .notification)
        
        // Обробити натискання
        NotificationManager.shared.handleNotificationResponse(response) { task in
            if let task = task {
                logger.success("Task found from notification: \(task.title ?? "Untitled")", category: .notification)
                
                // Тут можна додати навігацію до завдання
                // Наприклад, відкрити детальний вигляд завдання
                
                // Обробка швидких дій
                switch response.actionIdentifier {
                case "COMPLETE_ACTION":
                    self.completeTask(task)
                case "SNOOZE_ACTION":
                    self.snoozeTask(task, minutes: 15)
                default:
                    break
                }
            }
            
            completionHandler()
        }
    }
    
    // MARK: - Helper Methods
    
    private func syncAllNotifications() {
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == false AND reminderEnabled == true")
        
        do {
            let tasks = try context.fetch(fetchRequest)
            NotificationManager.shared.syncNotifications(tasks: tasks)
            logger.success("Synced \(tasks.count) task notifications", category: .notification)
        } catch {
            logger.error("Failed to sync notifications: \(error.localizedDescription)", category: .notification)
        }
    }
    
    private func completeTask(_ task: TaskEntity) {
        let repository = TaskRepository()
        let result = repository.markCompleted(task)
        
        switch result {
        case .success:
            logger.success("Task completed from notification: \(task.title ?? "Untitled")", category: .notification)
        case .failure(let error):
            logger.error("Failed to complete task: \(error.localizedDescription)", category: .notification)
        }
    }
    
    private func snoozeTask(_ task: TaskEntity, minutes: Int) {
        let newReminderTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        task.reminderTime = newReminderTime
        
        let saveResult = PersistenceController.shared.save()
        switch saveResult {
        case .success:
            NotificationManager.shared.updateNotification(for: task)
            logger.success("Task snoozed for \(minutes) minutes", category: .notification)
        case .failure(let error):
            logger.error("Failed to snooze task: \(error.localizedDescription)", category: .notification)
        }
    }
}
