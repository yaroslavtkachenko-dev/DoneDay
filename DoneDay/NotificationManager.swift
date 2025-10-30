//
//  NotificationManager.swift
//  DoneDay - Менеджер локальних нагадувань
//
//  Created by Yaroslav Tkachenko on 25.10.2025.
//

import Foundation
import UserNotifications
import CoreData
import Combine

// MARK: - Reminder Type

enum ReminderType {
    case beforeDueDate(minutes: Int)  // За X хвилин до dueDate
    case exactTime(date: Date)         // Конкретний час
    case none                          // Без нагадування
    
    var displayName: String {
        switch self {
        case .beforeDueDate(let minutes):
            if minutes < 60 {
                return "\(minutes) хв до дедлайну"
            } else {
                let hours = minutes / 60
                return "\(hours) год до дедлайну"
            }
        case .exactTime(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        case .none:
            return "Без нагадування"
        }
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Перевірка поточного статусу дозволу
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
                
                logger.info("Notification authorization status: \(settings.authorizationStatus.rawValue)", category: .notification)
            }
        }
    }
    
    /// Запит дозволу на відправку нотифікацій
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    logger.error("Failed to request notification authorization: \(error.localizedDescription)", category: .notification)
                    self?.isAuthorized = false
                    completion?(false)
                    return
                }
                
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if granted {
                    logger.success("Notification authorization granted", category: .notification)
                } else {
                    logger.warning("Notification authorization denied", category: .notification)
                }
                
                completion?(granted)
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// Створити нагадування для завдання
    func scheduleNotification(for task: TaskEntity) {
        print("🔔 [scheduleNotification] Called for task: \(task.title ?? "Untitled")")
        print("   reminderEnabled: \(task.reminderEnabled)")
        print("   reminderTime: \(task.reminderTime?.description ?? "nil")")
        print("   reminderOffset: \(task.reminderOffset)")
        print("   dueDate: \(task.dueDate?.description ?? "nil")")
        
        guard task.reminderEnabled else {
            logger.info("Reminder disabled for task: \(task.title ?? "Untitled")", category: .notification)
            print("❌ Reminder is disabled, skipping")
            return
        }
        
        guard isAuthorized else {
            logger.warning("Not authorized to schedule notifications", category: .notification)
            print("❌ Not authorized for notifications")
            requestAuthorization { [weak self] granted in
                if granted {
                    print("✅ Authorization granted, retrying schedule")
                    self?.scheduleNotification(for: task)
                }
            }
            return
        }
        
        print("✅ Authorized: \(isAuthorized)")
        
        // Визначити час нагадування
        let reminderDate = calculateReminderDate(for: task)
        
        print("📅 Calculated reminder date: \(reminderDate?.description ?? "nil")")
        print("📅 Current date: \(Date())")
        
        guard let date = reminderDate, date > Date() else {
            logger.warning("Invalid reminder date for task: \(task.title ?? "Untitled")", category: .notification)
            print("❌ Invalid reminder date or date is in the past!")
            if let reminderDate = reminderDate {
                print("   Reminder date: \(reminderDate)")
                print("   Is in past: \(reminderDate <= Date())")
            }
            return
        }
        
        print("✅ Valid reminder date: \(date)")
        
        // Створити контент нотифікації
        let content = createNotificationContent(for: task)
        
        // Створити тригер
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Створити унікальний ідентифікатор
        let identifier = task.notificationIdentifier ?? UUID().uuidString
        
        // Зберегти ідентифікатор в Core Data
        if task.notificationIdentifier != identifier {
            task.notificationIdentifier = identifier
            _ = PersistenceController.shared.save()
        }
        
        // Створити запит
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Додати нотифікацію
        print("➕ Adding notification request with ID: \(identifier)")
        notificationCenter.add(request) { error in
            if let error = error {
                logger.error("Failed to schedule notification: \(error.localizedDescription)", category: .notification)
                print("❌ Failed to schedule: \(error.localizedDescription)")
            } else {
                logger.success("Notification scheduled for task: \(task.title ?? "Untitled") at \(date)", category: .notification)
                print("✅ Notification scheduled successfully!")
                print("   Task: \(task.title ?? "Untitled")")
                print("   Time: \(date)")
                print("   ID: \(identifier)")
            }
        }
    }
    
    /// Розрахувати час нагадування на основі налаштувань завдання
    /// Apple Reminders Style:
    /// - reminderTime = основний час нагадування
    /// - reminderOffset = скільки хвилин РАНІШЕ нагадати (якщо > 0)
    private func calculateReminderDate(for task: TaskEntity) -> Date? {
        guard let mainReminderTime = task.reminderTime else {
            return nil
        }
        
        // Якщо offset > 0, нагадуємо РАНІШЕ основного часу
        if task.reminderOffset > 0 {
            let offsetSeconds = TimeInterval(task.reminderOffset * 60)
            return mainReminderTime.addingTimeInterval(-offsetSeconds)
        }
        
        // Якщо offset == 0, нагадуємо точно в основний час
        return mainReminderTime
    }
    
    /// Створити контент нотифікації
    private func createNotificationContent(for task: TaskEntity) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Заголовок
        content.title = "Нагадування про завдання"
        
        // Тіло повідомлення
        content.body = task.title ?? "Завдання без назви"
        
        // Субтитл з проектом
        if let projectName = task.project?.name {
            content.subtitle = "📁 \(projectName)"
        }
        
        // Звук
        content.sound = .default
        
        // Badge
        content.badge = 1
        
        // User Info для обробки натискання
        content.userInfo = [
            "taskId": task.id?.uuidString ?? "",
            "taskTitle": task.title ?? ""
        ]
        
        // Категорія для швидких дій
        content.categoryIdentifier = "TASK_REMINDER"
        
        return content
    }
    
    // MARK: - Cancel Notifications
    
    /// Скасувати нагадування для завдання
    func cancelNotification(for task: TaskEntity) {
        guard let identifier = task.notificationIdentifier else {
            logger.info("No notification identifier for task: \(task.title ?? "Untitled")", category: .notification)
            return
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.success("Notification cancelled for task: \(task.title ?? "Untitled")", category: .notification)
        
        // Очистити identifier в Core Data
        task.notificationIdentifier = nil
        _ = PersistenceController.shared.save()
    }
    
    /// Скасувати всі нагадування
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.success("All notifications cancelled", category: .notification)
    }
    
    // MARK: - Update Notifications
    
    /// Оновити нагадування (скасувати старе і створити нове)
    func updateNotification(for task: TaskEntity) {
        cancelNotification(for: task)
        
        if task.reminderEnabled {
            scheduleNotification(for: task)
        }
    }
    
    // MARK: - Sync Notifications
    
    /// Синхронізувати всі нагадування з Core Data
    func syncNotifications(tasks: [TaskEntity]) {
        logger.info("Syncing notifications for \(tasks.count) tasks", category: .notification)
        
        // Отримати всі заплановані нотифікації
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let existingIdentifiers = Set(requests.map { $0.identifier })
            
            for task in tasks {
                if task.reminderEnabled {
                    // Якщо нагадування увімкнено, але нотифікація не заплановано
                    if let identifier = task.notificationIdentifier, !existingIdentifiers.contains(identifier) {
                        self?.scheduleNotification(for: task)
                    } else if task.notificationIdentifier == nil {
                        self?.scheduleNotification(for: task)
                    }
                } else {
                    // Якщо нагадування вимкнено, але нотифікація існує
                    if let identifier = task.notificationIdentifier, existingIdentifiers.contains(identifier) {
                        self?.cancelNotification(for: task)
                    }
                }
            }
            
            logger.success("Notifications synced", category: .notification)
        }
    }
    
    // MARK: - Handle Notification Response
    
    /// Обробити натискання на нотифікацію
    func handleNotificationResponse(_ response: UNNotificationResponse, completion: @escaping (TaskEntity?) -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            logger.error("Invalid task ID in notification response", category: .notification)
            completion(nil)
            return
        }
        
        // Знайти завдання в Core Data
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            if let task = tasks.first {
                logger.success("Found task from notification: \(task.title ?? "Untitled")", category: .notification)
                completion(task)
            } else {
                logger.warning("Task not found for notification", category: .notification)
                completion(nil)
            }
        } catch {
            logger.error("Failed to fetch task: \(error.localizedDescription)", category: .notification)
            completion(nil)
        }
    }
    
    // MARK: - Debug & Utility
    
    /// Отримати список всіх запланованих нотифікацій
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Отримати список доставлених нотифікацій
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        notificationCenter.getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    
    /// Налаштувати категорії нотифікацій з швидкими діями
    func setupNotificationCategories() {
        // Дії для категорії TASK_REMINDER
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Завершити",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Відкласти на 15 хв",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        logger.success("Notification categories configured", category: .notification)
    }
}

