//
//  DoneDayTests.swift
//  DoneDayTests - Юніт-тести
//
//  Created by Yaroslav Tkachenko on 02.10.2025.
//

import XCTest
import CoreData
@testable import DoneDay

// MARK: - Test Base Class

class DoneDayTestCase: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Створюємо in-memory Core Data stack для тестів
        let container = NSPersistentContainer(name: "DoneDay")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = container.viewContext
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        try super.tearDownWithError()
    }
}

// MARK: - Repository Tests

class TaskRepositoryTests: DoneDayTestCase {
    
    var repository: TaskRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = TaskRepository(context: testContext)
    }
    
    func testCreateTask_Success() {
        // Given
        let title = "Test Task"
        let description = "Test Description"
        
        // When
        let result = repository.createTask(title: title, description: description)
        
        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.title, title)
            XCTAssertEqual(task.notes, description)
            XCTAssertFalse(task.isCompleted)
            XCTAssertNotNil(task.id)
            XCTAssertNotNil(task.createdAt)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateTask_EmptyTitle_Failure() {
        // Given
        let emptyTitle = ""
        
        // When
        let result = repository.createTask(title: emptyTitle)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for empty title")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("назва") ?? false)
        }
    }
    
    func testUpdateTask_Success() {
        // Given
        let createResult = repository.createTask(title: "Original Title")
        guard case .success(let task) = createResult else {
            XCTFail("Failed to create task")
            return
        }
        
        // When
        let newTitle = "Updated Title"
        let updateResult = repository.updateTask(task, title: newTitle)
        
        // Then
        switch updateResult {
        case .success(let updatedTask):
            XCTAssertEqual(updatedTask.title, newTitle)
            XCTAssertNotNil(updatedTask.updatedAt)
        case .failure(let error):
            XCTFail("Update failed: \(error)")
        }
    }
    
    func testMarkCompleted_Success() {
        // Given
        let createResult = repository.createTask(title: "Task to Complete")
        guard case .success(let task) = createResult else {
            XCTFail("Failed to create task")
            return
        }
        
        // When
        let result = repository.markCompleted(task)
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(task.isCompleted)
            XCTAssertNotNil(task.completedAt)
        case .failure(let error):
            XCTFail("Mark completed failed: \(error)")
        }
    }
    
    func testDeleteTask_Success() {
        // Given
        let createResult = repository.createTask(title: "Task to Delete")
        guard case .success(let task) = createResult else {
            XCTFail("Failed to create task")
            return
        }
        
        // When
        let deleteResult = repository.deleteTask(task)
        
        // Then
        switch deleteResult {
        case .success:
            let fetchResult = repository.fetch()
            if case .success(let tasks) = fetchResult {
                XCTAssertFalse(tasks.contains(task))
            }
        case .failure(let error):
            XCTFail("Delete failed: \(error)")
        }
    }
    
    func testFetchActiveTasks() {
        // Given
        _ = repository.createTask(title: "Active Task 1")
        _ = repository.createTask(title: "Active Task 2")
        
        let completedResult = repository.createTask(title: "Completed Task")
        if case .success(let completedTask) = completedResult {
            _ = repository.markCompleted(completedTask)
        }
        
        // When
        let result = repository.fetchActiveTasks()
        
        // Then
        switch result {
        case .success(let tasks):
            XCTAssertEqual(tasks.count, 2)
            XCTAssertTrue(tasks.allSatisfy { !$0.isCompleted })
        case .failure(let error):
            XCTFail("Fetch failed: \(error)")
        }
    }
}

// MARK: - Project Repository Tests

class ProjectRepositoryTests: DoneDayTestCase {
    
    var repository: ProjectRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = ProjectRepository(context: testContext)
    }
    
    func testCreateProject_Success() {
        // Given
        let name = "Test Project"
        let notes = "Test Notes"
        let color = "blue"
        
        // When
        let result = repository.createProject(name: name, notes: notes, color: color)
        
        // Then
        switch result {
        case .success(let project):
            XCTAssertEqual(project.name, name)
            XCTAssertEqual(project.notes, notes)
            XCTAssertEqual(project.color, color)
            XCTAssertFalse(project.isCompleted)
            XCTAssertNotNil(project.id)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateProject_EmptyName_Failure() {
        // Given
        let emptyName = "   "
        
        // When
        let result = repository.createProject(name: emptyName)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for empty name")
        case .failure(let error):
            if case .projectNameEmpty = error {
                // Success - correct error type
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testUpdateProject_Success() {
        // Given
        let createResult = repository.createProject(name: "Original Name")
        guard case .success(let project) = createResult else {
            XCTFail("Failed to create project")
            return
        }
        
        // When
        let newName = "Updated Name"
        let updateResult = repository.updateProject(project, name: newName)
        
        // Then
        switch updateResult {
        case .success(let updatedProject):
            XCTAssertEqual(updatedProject.name, newName)
        case .failure(let error):
            XCTFail("Update failed: \(error)")
        }
    }
    
    func testFetchActiveProjects() {
        // Given
        _ = repository.createProject(name: "Active Project 1")
        _ = repository.createProject(name: "Active Project 2")
        
        if case .success(let completedProject) = repository.createProject(name: "Completed") {
            completedProject.isCompleted = true
            _ = repository.save()
        }
        
        // When
        let result = repository.fetchActiveProjects()
        
        // Then
        switch result {
        case .success(let projects):
            XCTAssertEqual(projects.count, 2)
            XCTAssertTrue(projects.allSatisfy { !$0.isCompleted })
        case .failure(let error):
            XCTFail("Fetch failed: \(error)")
        }
    }
}

// MARK: - ValidationService Tests

class ValidationServiceTests: XCTestCase {
    
    func testValidateProjectName_ValidName() {
        let result = ValidationService.shared.validateProjectName("Valid Project")
        switch result {
        case .success(let validatedName):
            XCTAssertEqual(validatedName, "Valid Project")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testValidateProjectName_EmptyName_Failure() {
        let result = ValidationService.shared.validateProjectName("")
        switch result {
        case .success:
            XCTFail("Expected failure for empty name")
        case .failure(let error):
            if case .projectNameEmpty = error {
                // Success - correct error type
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testValidateProjectName_WhitespaceName_Failure() {
        let result = ValidationService.shared.validateProjectName("   ")
        switch result {
        case .success:
            XCTFail("Expected failure for whitespace name")
        case .failure(let error):
            if case .projectNameEmpty = error {
                // Success - correct error type
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testValidateTaskTitle_ValidTitle() {
        let result = ValidationService.shared.validateTaskTitle("Valid Task")
        switch result {
        case .success(let validatedTitle):
            XCTAssertEqual(validatedTitle, "Valid Task")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testValidateTaskTitle_EmptyTitle_Failure() {
        let result = ValidationService.shared.validateTaskTitle("")
        switch result {
        case .success:
            XCTFail("Expected failure for empty title")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("назва") ?? false)
        }
    }
    
    func testValidateTaskTitle_TooLongTitle_Failure() {
        let longTitle = String(repeating: "a", count: 201) // Exceeds maxTitleLength
        let result = ValidationService.shared.validateTaskTitle(longTitle)
        switch result {
        case .success:
            XCTFail("Expected failure for too long title")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("довга") ?? false)
        }
    }
}

// MARK: - Integration Tests

class TaskViewModelIntegrationTests: DoneDayTestCase {
    
    var viewModel: TaskViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = TaskViewModel()
    }
    
    func testAddTask_UpdatesTasksList() {
        // Given
        let initialCount = viewModel.tasks.count
        
        // When
        viewModel.addTask(title: "Integration Test Task")
        
        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount + 1)
    }
    
    func testAddProject_UpdatesProjectsList() {
        // Given
        let initialCount = viewModel.projects.count
        
        // When
        _ = viewModel.addProject(
            name: "Integration Test Project",
            color: "blue"
        )
        
        // Then
        XCTAssertEqual(viewModel.projects.count, initialCount + 1)
    }
}

// MARK: - Performance Tests

class PerformanceTests: DoneDayTestCase {
    
    func testFetchPerformance() {
        // Given - створюємо 1000 завдань
        let repository = TaskRepository(context: testContext)
        for i in 1...1000 {
            _ = repository.createTask(title: "Task \(i)")
        }
        
        // Measure
        measure {
            _ = repository.fetch()
        }
    }
    
    func testCreateTaskPerformance() {
        let repository = TaskRepository(context: testContext)
        
        measure {
            for i in 1...100 {
                _ = repository.createTask(title: "Performance Task \(i)")
            }
        }
    }
}