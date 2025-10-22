//
//  DoneDayApp.swift
//  DoneDay - Головний файл додатку
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import CoreData

@main
struct DoneDayApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var taskViewModel = TaskViewModel()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskViewModel)
                .withErrorHandling()
        }
    }
}
