//
//  SplashScreenView.swift
//  DoneDay - Мінімалістичний екран завантаження
//
//  Created by Yaroslav Tkachenko on 29.09.2025.
//

import SwiftUI

// MARK: - Мінімалістичний Splash Screen

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity = 0.0
    @State private var titleOpacity = 0.0
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some View {
        ZStack {
            if isActive {
                // Головний додаток
                EnhancedContentView()
                    .environmentObject(taskViewModel)
                    .transition(.opacity)
            } else {
                // Splash Screen
                splashContent
            }
        }
    }
    
    // MARK: - Splash Content
    
    private var splashContent: some View {
        ZStack {
            // М'який приглушений градієнт
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.18),  // Темно-сірий
                    Color(red: 0.12, green: 0.12, blue: 0.15)   // Ще темніше
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Основний контент по центру
            VStack(spacing: 24) {
                // Логотип
                ZStack {
                    // М'яке світіння
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Основне коло з м'яким кольором
                    Circle()
                        .fill(Color(red: 0.2, green: 0.22, blue: 0.26))
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    
                    // Іконка з приглушеним синім
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 0.9),  // М'який синій
                                    Color(red: 0.3, green: 0.5, blue: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // Назва додатку
                VStack(spacing: 8) {
                    Text("DoneDay")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Організуйте своє життя")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        // Анімація появи логотипу
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Анімація появи тексту
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            titleOpacity = 1.0
        }
        
        // Завантаження даних у фоні
        loadAppData()
        
        // Перехід до головного екрану через 2 секунди
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isActive = true
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAppData() {
        // Тут можна додати реальне завантаження даних
        // Наприклад:
        // taskViewModel.loadAllData()
        // Синхронізація з сервером
        // Перевірка оновлень тощо
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
