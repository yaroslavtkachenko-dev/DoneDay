//
//  ReminderSection.swift
//  DoneDay - UI компонент для налаштування нагадувань
//
//  Created by Yaroslav Tkachenko on 25.10.2025.
//

import SwiftUI

// MARK: - Reminder Section

struct ReminderSection: View {
    @Binding var reminderEnabled: Bool
    @Binding var reminderType: ReminderOptionType
    @Binding var reminderTime: Date?
    @Binding var reminderOffset: Int16
    let dueDate: Date?
    
    @State private var showingReminderPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Нагадування", icon: "bell.fill")
            
            VStack(spacing: 16) {
                // Toggle для увімкнення нагадування
                HStack(spacing: 16) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Увімкнути нагадування")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if reminderEnabled {
                            Text(reminderDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                }
                
                // Опції нагадування (якщо увімкнено)
                if reminderEnabled {
                    Divider()
                    
                    if dueDate != nil {
                        // Опції відносно дедлайну
                        VStack(spacing: 12) {
                            ForEach(ReminderOptionType.allCases, id: \.self) { option in
                                ReminderOptionRow(
                                    option: option,
                                    isSelected: reminderType == option
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        reminderType = option
                                        updateReminderValues()
                                    }
                                }
                            }
                        }
                    } else {
                        // Якщо немає дедлайну - тільки конкретний час
                        VStack(spacing: 12) {
                            Text("Оберіть час нагадування")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DatePicker(
                                "Час нагадування",
                                selection: Binding(
                                    get: { reminderTime ?? Date() },
                                    set: { reminderTime = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }
            }
            .adaptivePadding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .onChange(of: reminderEnabled) { enabled in
            if !enabled {
                // Скинути значення при вимкненні
                reminderTime = nil
                reminderOffset = 0
            } else {
                // Встановити дефолтні значення при увімкненні
                updateReminderValues()
            }
        }
    }
    
    private var reminderDescription: String {
        if let dueDate = dueDate {
            switch reminderType {
            case .fifteenMinutes:
                return "За 15 хвилин до дедлайну"
            case .thirtyMinutes:
                return "За 30 хвилин до дедлайну"
            case .oneHour:
                return "За 1 годину до дедлайну"
            case .oneDay:
                return "За 1 день до дедлайну"
            case .exactTime:
                if let time = reminderTime {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    return formatter.string(from: time)
                }
                return "Конкретний час"
            }
        } else if let time = reminderTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: time)
        }
        return "Налаштуйте нагадування"
    }
    
    private func updateReminderValues() {
        guard let dueDate = dueDate else {
            // Якщо немає дедлайну - використовувати exactTime
            reminderType = .exactTime
            if reminderTime == nil {
                reminderTime = Date().addingTimeInterval(3600) // +1 година від зараз
            }
            return
        }
        
        switch reminderType {
        case .fifteenMinutes:
            reminderOffset = 15
            reminderTime = dueDate.addingTimeInterval(-15 * 60)
        case .thirtyMinutes:
            reminderOffset = 30
            reminderTime = dueDate.addingTimeInterval(-30 * 60)
        case .oneHour:
            reminderOffset = 60
            reminderTime = dueDate.addingTimeInterval(-60 * 60)
        case .oneDay:
            reminderOffset = 1440 // 24 години = 1440 хвилин
            reminderTime = dueDate.addingTimeInterval(-24 * 60 * 60)
        case .exactTime:
            reminderOffset = 0
            if reminderTime == nil {
                reminderTime = dueDate.addingTimeInterval(-3600) // 1 година до дедлайну за замовчуванням
            }
        }
    }
}

// MARK: - Reminder Option Type

enum ReminderOptionType: String, CaseIterable {
    case fifteenMinutes = "15 хв до"
    case thirtyMinutes = "30 хв до"
    case oneHour = "1 год до"
    case oneDay = "1 день до"
    case exactTime = "Конкретний час"
    
    var icon: String {
        switch self {
        case .fifteenMinutes: return "clock"
        case .thirtyMinutes: return "clock.fill"
        case .oneHour: return "hourglass"
        case .oneDay: return "calendar"
        case .exactTime: return "alarm"
        }
    }
    
    var color: Color {
        switch self {
        case .fifteenMinutes: return .orange
        case .thirtyMinutes: return .orange
        case .oneHour: return .blue
        case .oneDay: return .purple
        case .exactTime: return .green
        }
    }
}

// MARK: - Reminder Option Row

struct ReminderOptionRow: View {
    let option: ReminderOptionType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : option.color)
                    .frame(width: 24)
                
                Text(option.rawValue)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? option.color : option.color.opacity(0.1))
                    .overlay {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(option.color.opacity(0.3), lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminder Badge View

struct ReminderBadge: View {
    let task: TaskEntity
    
    var body: some View {
        if task.reminderEnabled {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                
                if let reminderTime = task.reminderTime {
                    Text(timeText(for: reminderTime))
                        .font(.caption2)
                }
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            }
        }
    }
    
    private func timeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        ReminderSection(
            reminderEnabled: .constant(true),
            reminderType: .constant(.fifteenMinutes),
            reminderTime: .constant(Date()),
            reminderOffset: .constant(15),
            dueDate: Date().addingTimeInterval(3600)
        )
        .padding()
    }
}

