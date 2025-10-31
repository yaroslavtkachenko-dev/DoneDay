# DoneDay

Task and project management application for iOS and macOS.

## Overview
DoneDay is a native task management application built with SwiftUI and Core Data. It provides an intuitive interface for organizing tasks and projects, with powerful reminders and modern iOS features like Dynamic Island.

## Features
- Task creation and management
- Project organization with custom colors and icons
- Smart reminders with push notifications
- Calendar view for weekly overview
- Dynamic Island integration
- Advanced filtering and search
- Dark mode support

## Technical Stack
- SwiftUI
- Core Data
- Combine
- UserNotifications
- MVVM architecture

## Requirements
- Xcode 15 or later
- Swift 5.9+
- iOS 16.0+ / macOS 13.0+

## Installation
```bash
# Clone the repository
git clone https://github.com/yaroslavlkachenko-dev/DoneDay.git
cd DoneDay

# Open the project in Xcode
open DoneDay.xcodeproj
```
Build and run the project in Xcode (⌘ + R).

## Architecture
The application follows MVVM with a clear separation of concerns:
- Views: SwiftUI-based user interface
- ViewModels: Business logic and state management
- Repositories: Data access abstraction
- Core Data: Persistent storage layer

Key files/directories:
- `DoneDay/DoneDayApp.swift`: App entry point
- `DoneDay/Repositories.swift`: Data layer and repositories
- `DoneDay/TaskViewModel.swift`: Task-related state and logic
- `DoneDay/ModernAddTaskView.swift`, `DoneDay/ModernTaskDetailView.swift`: Main task screens
- `DoneDay/NotificationManager.swift`: Notifications scheduling and permissions
- `DoneDay/ProjectExtensions.swift`: Model helpers and utilities

## Notifications
- The app uses `UserNotifications` to schedule reminders.
- On first launch, the app requests notification permissions.
- Ensure notifications are allowed in iOS/macOS Settings for full functionality.

## Dynamic Island
- Integrated for supported iPhone models.
- See `DoneDay/DynamicIsland*` files for the implementation used to surface quick task info

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License
This project is licensed under the MIT License. See `LICENSE` for details.

## Author
Yaroslav Tkachenko — [@yaroslavlkachenko-dev](https://github.com/yaroslavlkachenko-dev)