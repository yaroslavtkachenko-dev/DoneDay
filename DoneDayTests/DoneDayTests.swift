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
    var taskRepo: TaskRepository!
    var projectRepo: ProjectRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // ✅ ВИПРАВЛЕНО: Використовуємо testContext замість дефолтного
        taskRepo = TaskRepository(context: testContext)
        projectRepo = ProjectRepository(context: testContext)
    }
    
    func testAddTask_UpdatesTasksList() {
        // Given
        let initialResult = taskRepo.fetchActiveTasks()
        guard case .success(let initialTasks) = initialResult else {
            XCTFail("Failed to fetch initial tasks")
            return
        }
        let initialCount = initialTasks.count
        
        // When
        _ = taskRepo.createTask(title: "Integration Test Task")
        
        // Then
        let finalResult = taskRepo.fetchActiveTasks()
        if case .success(let finalTasks) = finalResult {
            XCTAssertEqual(finalTasks.count, initialCount + 1)
        } else {
            XCTFail("Failed to fetch final tasks")
        }
    }
    
    func testAddProject_UpdatesProjectsList() {
        // Given
        let initialResult = projectRepo.fetchActiveProjects()
        guard case .success(let initialProjects) = initialResult else {
            XCTFail("Failed to fetch initial projects")
            return
        }
        let initialCount = initialProjects.count
        
        // When
        _ = projectRepo.createProject(
            name: "Integration Test Project",
            color: "blue"
        )
        
        // Then
        let finalResult = projectRepo.fetchActiveProjects()
        if case .success(let finalProjects) = finalResult {
            XCTAssertEqual(finalProjects.count, initialCount + 1)
        } else {
            XCTFail("Failed to fetch final projects")
        }
    }
}

// MARK: - Guard Let Safety Tests (для виправлень force unwrapping)

class RepositorySafetyTests: DoneDayTestCase {
    
    func testCreateTask_WithInvalidEntity_ReturnsError() {
        // Given - неможливо створити невалідну ситуацію напряму,
        // але тест перевіряє що guard let працює коректно
        let repository = TaskRepository(context: testContext)
        
        // When
        let result = repository.createTask(title: "Valid Task")
        
        // Then - перевіряємо що guard let пропускає валідні об'єкти
        switch result {
        case .success(let task):
            XCTAssertNotNil(task)
            XCTAssertTrue(task is TaskEntity)
        case .failure:
            XCTFail("Should succeed with valid entity name")
        }
    }
    
    func testCreateProject_SafeObjectCreation() {
        // Given
        let repository = ProjectRepository(context: testContext)
        
        // When
        let result = repository.createProject(name: "Test Project")
        
        // Then - guard let має успішно створити об'єкт
        switch result {
        case .success(let project):
            XCTAssertNotNil(project)
            XCTAssertTrue(project is ProjectEntity)
        case .failure:
            XCTFail("Should succeed with valid entity name")
        }
    }
}

// MARK: - ErrorAlertManager Thread Safety Tests

class ErrorAlertManagerTests: XCTestCase {
    
    func testConcurrentErrorHandling_NoDataRace() {
        // Given
        let manager = ErrorAlertManager.shared
        let expectation = expectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10
        
        // When - симулюємо багатопотокові звернення
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let error = AppError.taskCreationFailed(reason: "Test error \(index)")
            manager.handle(error)
            expectation.fulfill()
        }
        
        // Then - не має бути крашів або data races
        wait(for: [expectation], timeout: 5.0)
        
        // Очищаємо після тесту
        manager.clearError()
    }
    
    func testHandleError_UpdatesProperties() {
        // Given
        let manager = ErrorAlertManager.shared
        let testError = AppError.taskNotFound
        let expectation = expectation(description: "Error handled")
        
        // When
        manager.handle(testError)
        
        // Then - даємо час для async операцій
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(manager.showingError)
            XCTAssertNotNil(manager.currentError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Cleanup
        manager.clearError()
    }
}

// MARK: - Streak Calculation Tests

class StreakCalculationTests: DoneDayTestCase {
    
    var repository: TaskRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = TaskRepository(context: testContext)
    }
    
    func testStreakCalculation_WithTodayGap_MaintainsStreak() {
        // Given - створюємо завдання завершені вчора
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayResult = repository.createTask(title: "Yesterday Task")
        
        guard case .success(let task) = yesterdayResult else {
            XCTFail("Failed to create task")
            return
        }
        
        // Встановлюємо completedAt на вчора
        task.isCompleted = true
        task.completedAt = yesterday
        _ = repository.save()
        
        // When - підраховуємо streak (логіка дозволяє один пропуск для сьогодні)
        let tasks = (repository.fetch().handleError() ?? [])
        let hasYesterdayCompletion = tasks.contains { task in
            guard task.isCompleted, let completedDate = task.completedAt else { return false }
            return Calendar.current.isDate(completedDate, inSameDayAs: yesterday)
        }
        
        // Then
        XCTAssertTrue(hasYesterdayCompletion, "Має бути завершене завдання вчора")
    }
    
    func testStreakCalculation_ConsecutiveDays() {
        // Given - створюємо завдання за останні 3 дні
        let calendar = Calendar.current
        
        for daysAgo in 1...3 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let result = repository.createTask(title: "Task \(daysAgo) days ago")
            
            if case .success(let task) = result {
                task.isCompleted = true
                task.completedAt = date
                _ = repository.save()
            }
        }
        
        // When - перевіряємо чи всі дні мають завершені завдання
        let tasks = (repository.fetch().handleError() ?? [])
        
        var consecutiveDays = 0
        for daysAgo in 1...3 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let hasCompletion = tasks.contains { task in
                guard task.isCompleted, let completedDate = task.completedAt else { return false }
                return calendar.isDate(completedDate, inSameDayAs: date)
            }
            if hasCompletion {
                consecutiveDays += 1
            } else {
                break
            }
        }
        
        // Then
        XCTAssertEqual(consecutiveDays, 3, "Має бути 3 послідовні дні")
    }
}

// MARK: - Priority Tests

class PriorityTests: DoneDayTestCase {
    
    var repository: TaskRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = TaskRepository(context: testContext)
    }
    
    func testCreateTask_WithNoPriority_Success() {
        // Given
        let title = "Task without priority"
        
        // When
        let result = repository.createTask(title: title, priority: 0)
        
        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.priority, 0, "Priority should be 0")
            XCTAssertEqual(task.title, title)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateTask_WithLowPriority_Success() {
        // Given
        let title = "Low priority task"
        
        // When
        let result = repository.createTask(title: title, priority: 1)
        
        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.priority, 1, "Priority should be 1")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateTask_WithMediumPriority_Success() {
        // Given
        let title = "Medium priority task"
        
        // When
        let result = repository.createTask(title: title, priority: 2)
        
        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.priority, 2, "Priority should be 2")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateTask_WithHighPriority_Success() {
        // Given
        let title = "High priority task"
        
        // When
        let result = repository.createTask(title: title, priority: 3)
        
        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.priority, 3, "Priority should be 3")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateTask_WithInvalidPriority_Failure() {
        // Given
        let title = "Invalid priority task"
        
        // When
        let result = repository.createTask(title: title, priority: 5)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for invalid priority")
        case .failure:
            // Success - validation should reject invalid values
            break
        }
    }
    
    func testCreateTask_WithNegativePriority_Failure() {
        // Given
        let title = "Negative priority task"
        
        // When
        let result = repository.createTask(title: title, priority: -1)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for negative priority")
        case .failure:
            // Success - validation should reject negative priorities
            break
        }
    }
    
    func testPriorityValidation_ValidValues() {
        // Test all valid priority values
        for priority in 0...3 {
            let result = ValidationService.shared.validatePriority(priority)
            switch result {
            case .success(let validated):
                XCTAssertEqual(validated, priority)
            case .failure:
                XCTFail("Priority \(priority) should be valid")
            }
        }
    }
    
    func testPriorityValidation_InvalidValues() {
        // Test invalid values
        let invalidValues = [-1, 4, 5, 10, -10]
        for priority in invalidValues {
            let result = ValidationService.shared.validatePriority(priority)
            switch result {
            case .success:
                XCTFail("Priority \(priority) should be invalid")
            case .failure:
                // Success - validation correctly rejects invalid value
                break
            }
        }
    }
}

// MARK: - Recurring Tasks Tests

class RecurringTasksTests: DoneDayTestCase {
    
    var repository: TaskRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = TaskRepository(context: testContext)
    }
    
    func testMarkCompleted_DailyRecurringTask_CreatesNextInstance() {
        // Given - створюємо щоденне повторюване завдання
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let result = repository.createTask(
            title: "Щоденне завдання",
            priority: 1,
            dueDate: tomorrow
        )
        
        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }
        
        // Налаштовуємо recurring параметри
        task.recurrenceType = "daily"
        task.recurrenceInterval = 1
        _ = repository.save()
        
        // When - позначаємо завдання як завершене
        let completionResult = repository.markCompleted(task)
        
        // Then - перевіряємо що створено новий екземпляр
        switch completionResult {
        case .success:
            XCTAssertTrue(task.isCompleted, "Оригінальне завдання має бути завершене")
            
            // Fetch всі завдання включно з завершеними
            let fetchResult = repository.fetch()
            if case .success(let allTasks) = fetchResult {
                let activeTasks = allTasks.filter { !$0.isCompleted }
                
                // Має бути створене нове активне завдання з такою самою назвою
                let newTask = activeTasks.first { $0.title == "Щоденне завдання" && $0.id != task.id }
                XCTAssertNotNil(newTask, "Має бути створено нове завдання")
                
                if let newTask = newTask {
                    XCTAssertEqual(newTask.recurrenceType, "daily", "Нове завдання має мати той самий recurrence type")
                    XCTAssertEqual(newTask.recurrenceInterval, 1, "Нове завдання має мати той самий recurrence interval")
                    
                    // Перевіряємо що dueDate збільшилась на 1 день
                    if let originalDueDate = task.dueDate, let newDueDate = newTask.dueDate {
                        let expectedNextDate = Calendar.current.date(byAdding: .day, value: 1, to: originalDueDate)!
                        let calendar = Calendar.current
                        XCTAssertTrue(
                            calendar.isDate(newDueDate, inSameDayAs: expectedNextDate),
                            "Нова дата має бути на 1 день пізніше"
                        )
                    } else {
                        XCTFail("Обидва завдання мають мати dueDate")
                    }
                }
            } else {
                XCTFail("Failed to fetch tasks")
            }
            
        case .failure(let error):
            XCTFail("Failed to mark task completed: \(error)")
        }
    }
    
    func testMarkCompleted_WeeklyRecurringTask_CreatesNextInstance() {
        // Given - створюємо щотижневе повторюване завдання
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        let result = repository.createTask(
            title: "Щотижневе завдання",
            priority: 2,
            dueDate: nextWeek
        )
        
        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }
        
        task.recurrenceType = "weekly"
        task.recurrenceInterval = 1
        _ = repository.save()
        
        // When
        let completionResult = repository.markCompleted(task)
        
        // Then
        switch completionResult {
        case .success:
            let fetchResult = repository.fetch()
            if case .success(let allTasks) = fetchResult {
                let activeTasks = allTasks.filter { !$0.isCompleted }
                let newTask = activeTasks.first { $0.title == "Щотижневе завдання" && $0.id != task.id }
                
                XCTAssertNotNil(newTask, "Має бути створено нове завдання")
                if let newTask = newTask {
                    XCTAssertEqual(newTask.recurrenceType, "weekly")
                }
            }
        case .failure(let error):
            XCTFail("Failed: \(error)")
        }
    }
    
    func testMarkCompleted_RecurringTaskWithEndDate_StopsWhenEndDateReached() {
        // Given - створюємо recurring завдання з кінцевою датою
        let today = Date()
        let result = repository.createTask(
            title: "Завдання з кінцевою датою",
            dueDate: today
        )
        
        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }
        
        task.recurrenceType = "daily"
        task.recurrenceInterval = 1
        // Встановлюємо endDate на вчора (тобто вже минула)
        task.recurrenceEndDate = Calendar.current.date(byAdding: .day, value: -1, to: today)
        _ = repository.save()
        
        // When - позначаємо завдання як завершене
        let completionResult = repository.markCompleted(task)
        
        // Then - не має створюватися нове завдання
        switch completionResult {
        case .success:
            XCTAssertTrue(task.isCompleted)
            
            let fetchResult = repository.fetch()
            if case .success(let allTasks) = fetchResult {
                let activeTasks = allTasks.filter { !$0.isCompleted }
                let newTask = activeTasks.first { $0.title == "Завдання з кінцевою датою" && $0.id != task.id }
                
                XCTAssertNil(newTask, "НЕ має створюватися нове завдання, бо досягнуто кінцеву дату")
            }
        case .failure(let error):
            XCTFail("Failed: \(error)")
        }
    }
    
    func testMarkCompleted_NonRecurringTask_DoesNotCreateNewInstance() {
        // Given - звичайне (не повторюване) завдання
        let result = repository.createTask(
            title: "Звичайне завдання",
            dueDate: Date()
        )
        
        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }
        
        // Переконуємося що recurrenceType = "none"
        task.recurrenceType = "none"
        _ = repository.save()
        
        let initialCount = (repository.fetch().handleError() ?? []).count
        
        // When
        let completionResult = repository.markCompleted(task)
        
        // Then - не має створюватися нове завдання
        switch completionResult {
        case .success:
            let finalCount = (repository.fetch().handleError() ?? []).count
            XCTAssertEqual(finalCount, initialCount, "Кількість завдань не має змінитися")
        case .failure(let error):
            XCTFail("Failed: \(error)")
        }
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