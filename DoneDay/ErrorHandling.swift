//
//  ErrorHandling.swift
//  DoneDay - Система обробки помилок
//
//  Created by Yaroslav Tkachenko on 02.10.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Типи помилок

enum AppError: LocalizedError {
    // Task Errors
    case taskCreationFailed(reason: String)
    case taskUpdateFailed(reason: String)
    case taskDeletionFailed(reason: String)
    case taskNotFound
    
    // Project Errors
    case projectCreationFailed(reason: String)
    case projectUpdateFailed(reason: String)
    case projectDeletionFailed(reason: String)
    case projectNotFound
    case projectNameEmpty
    
    // Area Errors
    case areaCreationFailed(reason: String)
    case areaUpdateFailed(reason: String)
    case areaDeletionFailed(reason: String)
    
    // Data Errors
    case coreDataSaveFailed(Error)
    case coreDataFetchFailed(Error)
    case invalidData
    
    // Import/Export Errors
    case exportFailed(reason: String)
    case importFailed(reason: String)
    case fileNotFound
    case invalidFileFormat
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        // Task Errors
        case .taskCreationFailed(let reason):
            return "Не вдалося створити завдання: \(reason)"
        case .taskUpdateFailed(let reason):
            return "Не вдалося оновити завдання: \(reason)"
        case .taskDeletionFailed(let reason):
            return "Не вдалося видалити завдання: \(reason)"
        case .taskNotFound:
            return "Завдання не знайдено"
            
        // Project Errors
        case .projectCreationFailed(let reason):
            return "Не вдалося створити проект: \(reason)"
        case .projectUpdateFailed(let reason):
            return "Не вдалося оновити проект: \(reason)"
        case .projectDeletionFailed(let reason):
            return "Не вдалося видалити проект: \(reason)"
        case .projectNotFound:
            return "Проект не знайдено"
        case .projectNameEmpty:
            return "Назва проекту не може бути порожньою"
            
        // Area Errors
        case .areaCreationFailed(let reason):
            return "Не вдалося створити область: \(reason)"
        case .areaUpdateFailed(let reason):
            return "Не вдалося оновити область: \(reason)"
        case .areaDeletionFailed(let reason):
            return "Не вдалося видалити область: \(reason)"
            
        // Data Errors
        case .coreDataSaveFailed(let error):
            return "Помилка збереження даних: \(error.localizedDescription)"
        case .coreDataFetchFailed(let error):
            return "Помилка завантаження даних: \(error.localizedDescription)"
        case .invalidData:
            return "Некоректні дані"
            
        // Import/Export Errors
        case .exportFailed(let reason):
            return "Експорт не вдався: \(reason)"
        case .importFailed(let reason):
            return "Імпорт не вдався: \(reason)"
        case .fileNotFound:
            return "Файл не знайдено"
        case .invalidFileFormat:
            return "Невірний формат файлу"
        case .encodingFailed:
            return "Помилка кодування даних"
        case .decodingFailed:
            return "Помилка декодування даних"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .projectNameEmpty:
            return "Будь ласка, введіть назву проекту"
        case .coreDataSaveFailed, .coreDataFetchFailed:
            return "Спробуйте перезапустити додаток"
        case .invalidFileFormat:
            return "Переконайтеся, що файл у форматі JSON"
        case .fileNotFound:
            return "Перевірте, чи існує файл за вказаним шляхом"
        default:
            return "Спробуйте ще раз або зверніться до підтримки"
        }
    }
}

// MARK: - Error Alert Manager

class ErrorAlertManager: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    static let shared = ErrorAlertManager()
    
    private init() {}
    
    func handle(_ error: AppError) {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = error
            self?.showingError = true
            
            // Логування помилки
            print("❌ Error: \(error.errorDescription ?? "Unknown error")")
            if let suggestion = error.recoverySuggestion {
                print("💡 Suggestion: \(suggestion)")
            }
        }
    }
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            handle(appError)
        } else {
            handle(.invalidData)
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
}

// MARK: - Error Alert View Modifier

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorManager = ErrorAlertManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Помилка", isPresented: $errorManager.showingError, presenting: errorManager.currentError) { error in
                Button("OK") {
                    errorManager.clearError()
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    if let description = error.errorDescription {
                        Text(description)
                    }
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorAlertModifier())
    }
}

// MARK: - Result Extension для зручності

extension Result {
    func handleError(using manager: ErrorAlertManager = .shared) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            if let appError = error as? AppError {
                manager.handle(appError)
            } else {
                manager.handle(AppError.invalidData)
            }
            return nil
        }
    }
}

// MARK: - Validation Helpers
// Validator moved to ValidationService.swift for centralized validation
