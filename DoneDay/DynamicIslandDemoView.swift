//
//  DynamicIslandDemoView.swift
//  DoneDay
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

struct DynamicIslandDemoView: View {
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Інструкція
            Text("Наведіть курсор на Dynamic Island")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            // Dynamic Island
            DynamicIslandContent(
                isExpanded: $isExpanded,
                todayTasksCount: 3,
                completedTodayCount: 5,
                streakDays: 7
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isHovered = hovering
                    isExpanded = hovering
                }
            }
            
            Spacer()
            
            // Специфікації
            VStack(alignment: .leading, spacing: 8) {
                Text("Collapsed: 192x32px")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Expanded: 700x50px")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Animation: Spring (0.5s, 0.8 damping)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    DynamicIslandDemoView()
        .frame(width: 800, height: 600)
}
