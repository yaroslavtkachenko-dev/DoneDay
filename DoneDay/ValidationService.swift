//
//  ValidationService.swift
//  DoneDay - Централізована система валідації
//
//  Created by Yaroslav Tkachenko on 06.10.2025.
//

import Foundation

// MARK: - Validation Rules

struct ValidationRules {
    static let minTitleLength = 1
    static let maxTitleLength = 200
    static let maxDescriptionLength = 2000
    static let maxProjectNameLength = 100
    static let maxAreaNameLength = 50
    static let maxTagNameLength = 30
}

// MARK: - Validation Service

class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // MARK: - Task Validation
    
    func validateTaskTitle(_ title: String) -> Result<String, AppError> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.taskCreationFailed(reason: "Назва завдання не може бути порожньою"))
        }
        
        guard trimmed.count >= ValidationRules.minTitleLength else {
            return .failure(.taskCreationFailed(reason: "Назва завдання занадто коротка"))
        }
        
        guard trimmed.count <= ValidationRules.maxTitleLength else {
            return .failure(.taskCreationFailed(reason: "Назва завдання занадто довга (максимум \(ValidationRules.maxTitleLength) символів)"))
        }
        
        return .success(trimmed)
    }
    
    func validateTaskDescription(_ description: String?) -> Result<String?, AppError> {
        guard let description = description else {
            return .success(nil)
        }
        
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .success(nil)
        }
        
        guard trimmed.count <= ValidationRules.maxDescriptionLength else {
            return .failure(.taskCreationFailed(reason: "Опис завдання занадто довгий (максимум \(ValidationRules.maxDescriptionLength) символів)"))
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Project Validation
    
    func validateProjectName(_ name: String) -> Result<String, AppError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.projectNameEmpty)
        }
        
        guard trimmed.count <= ValidationRules.maxProjectNameLength else {
            return .failure(.projectCreationFailed(reason: "Назва проекту занадто довга (максимум \(ValidationRules.maxProjectNameLength) символів)"))
        }
        
        return .success(trimmed)
    }
    
    func validateProjectDescription(_ description: String?) -> Result<String?, AppError> {
        guard let description = description else {
            return .success(nil)
        }
        
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .success(nil)
        }
        
        guard trimmed.count <= ValidationRules.maxDescriptionLength else {
            return .failure(.projectCreationFailed(reason: "Опис проекту занадто довгий"))
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Area Validation
    
    func validateAreaName(_ name: String) -> Result<String, AppError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.areaCreationFailed(reason: "Назва області не може бути порожньою"))
        }
        
        guard trimmed.count <= ValidationRules.maxAreaNameLength else {
            return .failure(.areaCreationFailed(reason: "Назва області занадто довга (максимум \(ValidationRules.maxAreaNameLength) символів)"))
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Tag Validation
    
    func validateTagName(_ name: String) -> Result<String, AppError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.areaCreationFailed(reason: "Назва тега не може бути порожньою"))
        }
        
        guard trimmed.count <= ValidationRules.maxTagNameLength else {
            return .failure(.areaCreationFailed(reason: "Назва тега занадто довга (максимум \(ValidationRules.maxTagNameLength) символів)"))
        }
        
        // Check for invalid characters
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_"))
        
        if trimmed.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return .failure(.areaCreationFailed(reason: "Назва тега містить недопустимі символи"))
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Date Validation
    
    func validateDueDate(_ date: Date?) -> Result<Date?, AppError> {
        guard let date = date else {
            return .success(nil)
        }
        
        // Allow past dates (for flexibility)
        return .success(date)
    }
    
    // MARK: - Priority Validation
    
    func validatePriority(_ priority: Int) -> Result<Int, AppError> {
        guard priority >= 0 && priority <= 3 else {
            return .failure(.invalidData)
        }
        return .success(priority)
    }
    
    // MARK: - Batch Validation
    
    func validateTask(title: String, description: String?, dueDate: Date?, priority: Int) -> Result<(String, String?, Date?, Int), AppError> {
        // Validate title
        let titleResult = validateTaskTitle(title)
        guard case .success(let validTitle) = titleResult else {
            if case .failure(let error) = titleResult {
                return .failure(error)
            }
            return .failure(.invalidData)
        }
        
        // Validate description
        let descriptionResult = validateTaskDescription(description)
        guard case .success(let validDescription) = descriptionResult else {
            if case .failure(let error) = descriptionResult {
                return .failure(error)
            }
            return .failure(.invalidData)
        }
        
        // Validate due date
        let dueDateResult = validateDueDate(dueDate)
        guard case .success(let validDueDate) = dueDateResult else {
            if case .failure(let error) = dueDateResult {
                return .failure(error)
            }
            return .failure(.invalidData)
        }
        
        // Validate priority
        let priorityResult = validatePriority(priority)
        guard case .success(let validPriority) = priorityResult else {
            if case .failure(let error) = priorityResult {
                return .failure(error)
            }
            return .failure(.invalidData)
        }
        
        return .success((validTitle, validDescription, validDueDate, validPriority))
    }
}

// MARK: - Legacy Validator (For backward compatibility)

struct Validator {
    static func validateProjectName(_ name: String) throws {
        let result = ValidationService.shared.validateProjectName(name)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    static func validateTask(_ title: String) throws {
        let result = ValidationService.shared.validateTaskTitle(title)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

