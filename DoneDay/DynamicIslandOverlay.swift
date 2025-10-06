//
//  DynamicIslandOverlay.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct DynamicIslandOverlay: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var isExpanded = false
    @State private var isHovered = false
    
    private var todayTasksCount: Int {
        return taskViewModel.getTodayTasks().filter { !$0.isCompleted }.count
    }
    
    private var completedTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return taskViewModel.tasks.filter { task in
            guard task.isCompleted && !task.isDelete else { return false }
            if let completedDate = task.completedAt {
                return Calendar.current.isDate(completedDate, inSameDayAs: today)
            }
            return false
        }.count
    }
    
    private var streakDays: Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        for _ in 0..<30 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasCompletedTasks = taskViewModel.tasks.contains { task in
                guard task.isCompleted && !task.isDelete else { return false }
                if let completedDate = task.completedAt {
                    return completedDate >= dayStart && completedDate < dayEnd
                }
                return false
            }
            
            if hasCompletedTasks {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            DynamicIslandContent(
                isExpanded: $isExpanded,
                todayTasksCount: todayTasksCount,
                completedTodayCount: completedTodayCount,
                streakDays: streakDays
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isHovered = hovering
                    isExpanded = hovering
                }
            }
            
            Spacer()
        }
    }
}

struct DynamicIslandContent: View {
    @Binding var isExpanded: Bool
    let todayTasksCount: Int
    let completedTodayCount: Int
    let streakDays: Int
    
    var body: some View {
        HStack(spacing: 0) {
            if isExpanded {
                // Розгорнутий стан
                ExpandedDynamicIsland(
                    todayTasksCount: todayTasksCount,
                    completedTodayCount: completedTodayCount,
                    streakDays: streakDays
                )
            } else {
                // Згорнутий стан
                CollapsedDynamicIsland()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
    }
}

struct CollapsedDynamicIsland: View {
    var body: some View {
        HStack {
            Spacer()
            
            // Проста біла крапка в центрі
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
            
            Spacer()
        }
        .frame(width: 192, height: 32)
        .background(.black)
        .clipShape(Capsule())
    }
}

struct ExpandedDynamicIsland: View {
    let todayTasksCount: Int
    let completedTodayCount: Int
    let streakDays: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Ліва секція - кнопки режимів
            HStack(spacing: 12) {
                // Deep Work кнопка
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 12, weight: .medium))
                        Text("Deep Work")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // DND кнопка
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 12, weight: .medium))
                        Text("DND")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Центральна секція - таймер
            HStack(spacing: 12) {
                // Прогрес бар
                ZStack {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 4)
                        .clipShape(Capsule())
                    
                    // Play кнопка
                    Button(action: {}) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Таймер
                Text("90:00")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Права секція - статистика
            HStack(spacing: 12) {
                // Розділювач
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1, height: 20)
                
                // 7 DAYS (замість streak)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    Text("\(streakDays) DAYS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 3/8 TASKS (замість завдань)
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    Text("\(completedTodayCount)/\(todayTasksCount + completedTodayCount) TASKS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Add кнопка
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 700, height: 50)
        .background(.black)
        .clipShape(Capsule())
    }
}

#Preview {
    let viewModel = TaskViewModel()
    return DynamicIslandOverlay(taskViewModel: viewModel)
        .environmentObject(viewModel)
        .frame(width: 800, height: 100)
        .background(Color(NSColor.windowBackgroundColor))
}
