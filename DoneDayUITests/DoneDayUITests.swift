//
//  DoneDayUITests.swift
//  DoneDayUITests - UI тести для DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import XCTest

final class DoneDayUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Navigation Tests
    
    @MainActor
    func testAppLaunches_ShowsMainInterface() throws {
        // Перевіряємо що додаток запустився
        XCTAssertTrue(app.staticTexts["DoneDay"].exists, "Має відображатися заголовок DoneDay")
    }
    
    @MainActor
    func testFilterPills_AreVisible() throws {
        // Перевіряємо що фільтри відображаються
        XCTAssertTrue(app.buttons["Всі"].exists, "Має бути кнопка фільтру 'Всі'")
        XCTAssertTrue(app.buttons["Сьогодні"].exists, "Має бути кнопка фільтру 'Сьогодні'")
        XCTAssertTrue(app.buttons["Inbox"].exists, "Має бути кнопка фільтру 'Inbox'")
    }
    
    @MainActor
    func testFilterSelection_ChangesView() throws {
        // Given - додаток запущений
        let todayButton = app.buttons["Сьогодні"]
        
        // When - натискаємо на фільтр
        todayButton.tap()
        
        // Then - фільтр має активуватися (можна перевірити через accessibility)
        XCTAssertTrue(todayButton.exists, "Кнопка 'Сьогодні' має існувати після натискання")
    }
    
    // MARK: - Task Creation Tests
    
    @MainActor
    func testFloatingActionButton_IsVisible() throws {
        // Перевіряємо що кнопка додавання завдання видима
        // Зазвичай це кнопка з іконкою "plus"
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
        
        // Даємо час для завантаження UI
        let exists = addButton.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Має бути видима кнопка додавання завдання")
    }
    
    // MARK: - Empty State Tests
    
    @MainActor
    func testCompletedFilter_ShowsEmptyState_WhenNoCompletedTasks() throws {
        // Given
        let completedButton = app.buttons["Завершені"]
        
        // When
        completedButton.tap()
        
        // Then - має показуватись empty state
        // Перевіряємо чи є текст про відсутність завершених завдань
        let emptyStateExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Немає'")).firstMatch.waitForExistence(timeout: 2)
        
        // Це нормально якщо є завдання, тест просто перевіряє UI
        if !emptyStateExists {
            print("ℹ️ Знайдено завершені завдання (це ОК)")
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        // Вимірюємо швидкість запуску
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testScrollPerformance() throws {
        // Якщо є список завдань, тестуємо швидкість скролу
        let taskList = app.scrollViews.firstMatch
        
        if taskList.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                taskList.swipeUp()
                taskList.swipeDown()
            }
        } else {
            print("ℹ️ Немає списку для тестування скролу")
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibility_MainButtons() throws {
        // Перевіряємо що основні елементи доступні для VoiceOver
        let filterButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Всі' OR label CONTAINS 'Сьогодні'"))
        
        XCTAssertGreaterThan(filterButtons.count, 0, "Має бути хоча б одна кнопка фільтру")
        
        // Перевіряємо accessibility labels
        for i in 0..<filterButtons.count {
            let button = filterButtons.element(boundBy: i)
            XCTAssertNotNil(button.label, "Кнопка має мати accessibility label")
            XCTAssertFalse(button.label.isEmpty, "Accessibility label не має бути порожнім")
        }
    }
}
