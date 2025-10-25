//
//  Logger.swift
//  DoneDay - Централізована система логування
//
//  Created by Yaroslav Tkachenko on 09.10.2025.
//

import Foundation
import OSLog

// MARK: - Log Level

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .success: return .info
        }
    }
}

// MARK: - Log Category

enum LogCategory: String {
    case coreData = "CoreData"
    case repository = "Repository"
    case viewModel = "ViewModel"
    case ui = "UI"
    case validation = "Validation"
    case network = "Network"
    case notification = "Notification"
    case general = "General"
    
    var icon: String {
        switch self {
        case .coreData: return "🗄️"
        case .repository: return "📦"
        case .viewModel: return "🎯"
        case .ui: return "🎨"
        case .validation: return "✓"
        case .network: return "🌐"
        case .notification: return "🔔"
        case .general: return "📋"
        }
    }
}

// MARK: - Logger

class AppLogger {
    static let shared = AppLogger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.doneday"
    private var loggers: [LogCategory: Logger] = [:]
    
    // Config
    var isEnabled = true
    var minimumLevel: LogLevel = .debug
    
    #if DEBUG
    var logToConsole = true
    #else
    var logToConsole = false
    #endif
    
    private init() {
        // Створити logger для кожної категорії
        for category in [LogCategory.coreData, .repository, .viewModel, .ui, .validation, .network, .notification, .general] {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Main Log Method
    
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        // Console log для development
        if logToConsole {
            let consoleMessage = "\(timestamp) \(level.rawValue) [\(category.icon) \(category.rawValue)] \(message) (\(fileName):\(line))"
            print(consoleMessage)
        }
        
        // OS Log для production
        if let logger = loggers[category] {
            logger.log(level: level.osLogType, "\(message, privacy: .public)")
        }
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func success(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Specialized Logging
    
    func logCoreDataSave(success isSuccess: Bool, context: String = "") {
        if isSuccess {
            self.success("Core Data saved successfully \(context)", category: .coreData)
        } else {
            error("Core Data save failed \(context)", category: .coreData)
        }
    }
    
    func logFetch<T>(entity: String, count: Int, type: T.Type) {
        info("Fetched \(count) \(entity) entities", category: .repository)
    }
    
    func logValidation(field: String, isValid: Bool, reason: String? = nil) {
        if isValid {
            debug("Validation passed for \(field)", category: .validation)
        } else {
            warning("Validation failed for \(field): \(reason ?? "unknown reason")", category: .validation)
        }
    }
}

// MARK: - Global convenience

let logger = AppLogger.shared

