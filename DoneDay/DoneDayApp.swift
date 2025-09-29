//
//  DoneDayApp.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData

@main
struct DoneDayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            EnhancedContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
