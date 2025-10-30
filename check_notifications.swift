// Тимчасовий debug скрипт
// Запусти в Xcode консолі або як окремий Swift скрипт

import Foundation
import UserNotifications

UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print("📋 Заплановані нотифікації: \(requests.count)")
    
    for (index, request) in requests.enumerated() {
        print("\n🔔 Нотифікація #\(index + 1):")
        print("   ID: \(request.identifier)")
        print("   Title: \(request.content.title)")
        print("   Body: \(request.content.body)")
        
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let nextDate = trigger.nextTriggerDate() {
            print("   Час: \(nextDate)")
        }
    }
    
    if requests.isEmpty {
        print("❌ Немає запланованих нотифікацій!")
    }
    
    exit(0)
}

RunLoop.main.run()

