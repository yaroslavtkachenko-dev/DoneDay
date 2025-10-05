//
//  DynamicIslandWindow.swift
//  DoneDay - ПОВНА ВИПРАВЛЕНА ВЕРСІЯ
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI
import AppKit
import Combine

// MARK: - DynamicIslandWindow Class

class DynamicIslandWindow: NSWindow {
    private var hostingView: NSHostingView<SimpleDynamicIslandView>?
    private var mouseMonitor: Any?
    private var isRevealed = false
    
    // ✅ ВИПРАВЛЕНО: Позиції з врахуванням menu bar та notch
    private var hiddenY: CGFloat {
        guard let screen = NSScreen.main else { return 800 }
        // Використовуємо visibleFrame (враховує menu bar)
        // Тільки 5px видно як натяк
        return screen.visibleFrame.maxY - 5
    }
    
    private var revealedY: CGFloat {
        guard let screen = NSScreen.main else { return 750 }
        
        // Перевіряємо чи є notch на MacBook Pro
        if #available(macOS 12, *) {
            let safeTop = screen.safeAreaInsets.top
            
            if safeTop > 0 {
                // MacBook Pro з notch (32 points)
                // Мінімальний відступ для максимальної висоти
                return screen.frame.height - self.frame.height - safeTop - 2
            }
        }
        
        // Mac без notch - позиція під menu bar
        return screen.visibleFrame.maxY - self.frame.height - 2
    }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 192, height: 32),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupMouseTracking()
    }
    
    private func setupWindow() {
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        
        // ✅ ВИПРАВЛЕНО: statusBar level для menu bar-like поведінки
        self.level = .statusBar
        
        self.ignoresMouseEvents = false
        self.hasShadow = true
        self.isMovable = false
        
        // ✅ ВИПРАВЛЕНО: Додано .fullScreenAuxiliary
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        
        self.hidesOnDeactivate = false
        
        // Початкова позиція - сховано
        centerWindowHorizontally()
        hideWindow(animated: false)
        
        let hostingView = NSHostingView(rootView: SimpleDynamicIslandView())
        self.hostingView = hostingView
        self.contentView = hostingView
        
        print("🏗️ Dynamic Island ініціалізовано")
        
        // ✅ ДОДАНО: Лог для діагностики
        if #available(macOS 12, *), let screen = NSScreen.main {
            let hasNotch = screen.safeAreaInsets.top > 0
            print("📱 Notch виявлено: \(hasNotch)")
            print("📏 Safe area top: \(screen.safeAreaInsets.top)")
            print("📐 Visible frame: \(screen.visibleFrame)")
            print("📐 Full frame: \(screen.frame)")
        }
    }
    
    // ✅ НОВИЙ метод для центрування
    private func centerWindowHorizontally() {
        guard let screen = NSScreen.main else { return }
        let x = (screen.frame.width - self.frame.width) / 2
        let y = isRevealed ? revealedY : hiddenY
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func setupMouseTracking() {
        // Глобальне відстеження миші
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            guard let screen = NSScreen.main else { return }
            
            // ✅ ВИПРАВЛЕНО: Використовуємо visibleFrame для обчислення зони активації
            let visibleTop = screen.visibleFrame.maxY
            let activationZoneHeight: CGFloat = 80
            
            // Відстань від верху видимої області
            let distanceFromTop = visibleTop - mouseLocation.y
            
            if distanceFromTop < activationZoneHeight && distanceFromTop > -10 {
                // Курсор у зоні активації - показуємо
                if !self.isRevealed {
                    self.revealWindow()
                }
            } else {
                // Курсор далеко - ховаємо
                if self.isRevealed {
                    self.hideWindow(animated: true)
                }
            }
        }
    }
    
    private func revealWindow() {
        guard let screen = NSScreen.main else { return }
        isRevealed = true
        
        let x = (screen.frame.width - self.frame.width) / 2
        let targetY = revealedY
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrameOrigin(NSPoint(x: x, y: targetY))
        })
        
        print("⬇️ Dynamic Island показано на Y: \(targetY)")
    }
    
    private func hideWindow(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        isRevealed = false
        
        let x = (screen.frame.width - self.frame.width) / 2
        let targetY = hiddenY
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().setFrameOrigin(NSPoint(x: x, y: targetY))
            })
        } else {
            self.setFrameOrigin(NSPoint(x: x, y: targetY))
        }
        
        if animated {
            print("⬆️ Dynamic Island сховано на Y: \(targetY)")
        }
    }
    
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        guard let screen = NSScreen.main else {
            super.setFrame(frameRect, display: flag)
            return
        }
        
        // При зміні розміру - зберігаємо стан (показано/сховано)
        var adjustedFrame = frameRect
        let x = (screen.frame.width - frameRect.width) / 2
        
        adjustedFrame.origin = NSPoint(
            x: x,
            y: isRevealed ? revealedY : hiddenY
        )
        
        super.setFrame(adjustedFrame, display: flag)
    }
    
    override func close() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hostingView = nil
        super.close()
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hostingView = nil
        print("♻️ DynamicIslandWindow deinit")
    }
}

// MARK: - DynamicIslandManager

class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()
    
    private var dynamicIslandWindow: DynamicIslandWindow?
    @Published var isVisible = false
    
    private init() {}
    
    func showDynamicIsland() {
        guard !isVisible else { return }
        
        let window = DynamicIslandWindow()
        self.dynamicIslandWindow = window
        window.makeKeyAndOrderFront(nil)
        self.isVisible = true
        
        print("✅ Dynamic Island увімкнено (автоматично ховається)")
    }
    
    func hideDynamicIsland() {
        guard isVisible else { return }
        
        if let window = dynamicIslandWindow {
            if window.isVisible {
                window.orderOut(nil)
            }
        }
        
        dynamicIslandWindow = nil
        isVisible = false
        
        print("✅ Dynamic Island вимкнено")
    }
    
    func toggleDynamicIsland() {
        if isVisible {
            hideDynamicIsland()
        } else {
            showDynamicIsland()
        }
    }
}

// MARK: - SimpleDynamicIslandView

struct SimpleDynamicIslandView: View {
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            if isExpanded {
                ExpandedSimpleDynamicIsland()
            } else {
                CollapsedSimpleDynamicIsland()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .onHover { hovering in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Collapsed State

struct CollapsedSimpleDynamicIsland: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.2))  // Ледве помітна крапка
                .frame(width: 4, height: 4)  // Дуже маленька
        }
        .frame(width: 192, height: 32)
        .background(Color.black.opacity(0.15))  // Майже прозорий фон
        .clipShape(Capsule())
    }
}

// MARK: - Expanded State

struct ExpandedSimpleDynamicIsland: View {
    var body: some View {
        HStack(spacing: 20) {
            // Ліва секція - кнопки режимів
            HStack(spacing: 16) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Deep Work")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("90:00")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Права секція - статистика
            HStack(spacing: 16) {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1.5, height: 28)
                
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("7 DAYS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    Text("3/8")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .frame(width: 900, height: 64)
        .background(
            LinearGradient(
                colors: [Color.black, Color(white: 0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }
}

// MARK: - NSScreen Extension

extension NSScreen {
    var hasTopNotchDesign: Bool {
        guard #available(macOS 12, *) else { return false }
        return safeAreaInsets.top != 0
    }
    
    var notchHeight: CGFloat {
        guard #available(macOS 12, *) else { return 0 }
        return safeAreaInsets.top
    }
}

// MARK: - Preview

#Preview {
    SimpleDynamicIslandView()
        .frame(width: 800, height: 100)
        .background(Color(NSColor.windowBackgroundColor))
}
