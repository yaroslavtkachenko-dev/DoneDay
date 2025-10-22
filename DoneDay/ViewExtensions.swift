//
//  ViewExtensions.swift
//  DoneDay - Адаптивні розширення для SwiftUI компонентів
//
//  Created by Yaroslav Tkachenko on 28.09.2025.
//

import SwiftUI

// MARK: - Device Size Classes

enum DeviceSize {
    case compact    // iPhone в portrait, маленькі телефони
    case regular    // iPhone в landscape, iPad
    case large      // iPad в landscape, великі екрани
    
    static func current(width: CGFloat) -> DeviceSize {
        switch width {
        case 0..<428:
            return .compact
        case 428..<768:
            return .regular
        case 768...:
            return .large
        default:
            return .regular
        }
    }
}

// MARK: - Adaptive Values Helper

struct AdaptiveValues {
    let deviceSize: DeviceSize
    
    // Padding values
    var screenPadding: CGFloat {
        switch deviceSize {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        }
    }
    
    var cardPadding: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 16
        case .large: return 20
        }
    }
    
    var sectionSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        }
    }
    
    var itemSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 12
        case .large: return 16
        }
    }
    
    // Grid columns
    var gridColumns: Int {
        switch deviceSize {
        case .compact: return 1
        case .regular: return 2
        case .large: return 3
        }
    }
    
    var projectGridColumns: Int {
        switch deviceSize {
        case .compact: return 1
        case .regular: return 2
        case .large: return 4
        }
    }
    
    // Font sizes (relative to system)
    var titleScale: CGFloat {
        switch deviceSize {
        case .compact: return 1.0
        case .regular: return 1.1
        case .large: return 1.2
        }
    }
    
    // Icon sizes
    var iconSize: CGFloat {
        switch deviceSize {
        case .compact: return 40
        case .regular: return 48
        case .large: return 56
        }
    }
    
    var smallIconSize: CGFloat {
        switch deviceSize {
        case .compact: return 24
        case .regular: return 28
        case .large: return 32
        }
    }
    
    // Corner radius
    var cornerRadius: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 14
        case .large: return 16
        }
    }
    
    var smallCornerRadius: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 10
        case .large: return 12
        }
    }
}

// MARK: - Environment Key for Adaptive Values

private struct AdaptiveValuesKey: EnvironmentKey {
    static let defaultValue = AdaptiveValues(deviceSize: .regular)
}

extension EnvironmentValues {
    var adaptiveValues: AdaptiveValues {
        get { self[AdaptiveValuesKey.self] }
        set { self[AdaptiveValuesKey.self] = newValue }
    }
}

// MARK: - Adaptive Container View Modifier

struct AdaptiveContainer: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let deviceSize = DeviceSize.current(width: geometry.size.width)
            let adaptiveValues = AdaptiveValues(deviceSize: deviceSize)
            
            content
                .environment(\.adaptiveValues, adaptiveValues)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension View {
    func adaptiveContainer() -> some View {
        modifier(AdaptiveContainer())
    }
}

// MARK: - Adaptive Padding

extension View {
    func adaptivePadding(_ edges: Edge.Set = .all, multiplier: CGFloat = 1.0) -> some View {
        modifier(AdaptivePaddingModifier(edges: edges, multiplier: multiplier))
    }
    
    func adaptiveScreenPadding() -> some View {
        modifier(AdaptiveScreenPaddingModifier())
    }
}

struct AdaptivePaddingModifier: ViewModifier {
    @Environment(\.adaptiveValues) var adaptiveValues
    let edges: Edge.Set
    let multiplier: CGFloat
    
    func body(content: Content) -> some View {
        content.padding(edges, adaptiveValues.cardPadding * multiplier)
    }
}

struct AdaptiveScreenPaddingModifier: ViewModifier {
    @Environment(\.adaptiveValues) var adaptiveValues
    
    func body(content: Content) -> some View {
        content.padding(.horizontal, adaptiveValues.screenPadding)
    }
}

// MARK: - Adaptive Spacing

extension View {
    func adaptiveSpacing() -> CGFloat {
        // Повертає адаптивний відступ для VStack/HStack
        return 16 // За замовчуванням, буде перевизначено через environment
    }
}

struct AdaptiveVStack<Content: View>: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let alignment: HorizontalAlignment
    let content: () -> Content
    
    init(alignment: HorizontalAlignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: adaptiveValues.sectionSpacing) {
            content()
        }
    }
}

struct AdaptiveHStack<Content: View>: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let alignment: VerticalAlignment
    let content: () -> Content
    
    init(alignment: VerticalAlignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: alignment, spacing: adaptiveValues.itemSpacing) {
            content()
        }
    }
}

// MARK: - Adaptive Grid

struct AdaptiveGrid<Item: Identifiable, Content: View>: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let items: [Item]
    let columnsOverride: Int?
    let content: (Item) -> Content
    
    init(items: [Item], columns: Int? = nil, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.columnsOverride = columns
        self.content = content
    }
    
    private var columns: [GridItem] {
        let columnCount = columnsOverride ?? adaptiveValues.gridColumns
        return Array(repeating: GridItem(.flexible(), spacing: adaptiveValues.itemSpacing), count: columnCount)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: adaptiveValues.itemSpacing) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

// MARK: - Adaptive Fonts

extension View {
    func adaptiveTitle() -> some View {
        modifier(AdaptiveTitleModifier())
    }
    
    func adaptiveHeadline() -> some View {
        modifier(AdaptiveHeadlineModifier())
    }
}

struct AdaptiveTitleModifier: ViewModifier {
    @Environment(\.adaptiveValues) var adaptiveValues
    
    func body(content: Content) -> some View {
        content
            .font(.system(.title, design: .default))
            .scaleEffect(adaptiveValues.titleScale, anchor: .leading)
    }
}

struct AdaptiveHeadlineModifier: ViewModifier {
    @Environment(\.adaptiveValues) var adaptiveValues
    
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .default))
    }
}

// MARK: - Adaptive Modal Sizes

extension View {
    func adaptiveSheet() -> some View {
        modifier(AdaptiveSheetModifier())
    }
    
    func adaptiveFullScreen() -> some View {
        modifier(AdaptiveFullScreenModifier())
    }
}

struct AdaptiveSheetModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone - full screen
                content
            } else {
                // iPad - sheet з обмеженою шириною
                content
                    .frame(minWidth: 600, idealWidth: 700, maxWidth: 800)
                    .frame(minHeight: 500, idealHeight: 700, maxHeight: 900)
            }
        }
    }
}

struct AdaptiveFullScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Adaptive Cards

struct AdaptiveCard<Content: View>: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(adaptiveValues.cardPadding)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: adaptiveValues.cornerRadius))
    }
}

// MARK: - Adaptive Icon

struct AdaptiveIcon: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let systemName: String
    let color: Color
    let isSmall: Bool
    
    init(systemName: String, color: Color = .blue, isSmall: Bool = false) {
        self.systemName = systemName
        self.color = color
        self.isSmall = isSmall
    }
    
    var body: some View {
        let size = isSmall ? adaptiveValues.smallIconSize : adaptiveValues.iconSize
        
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
    }
}

// MARK: - Adaptive Button

struct AdaptiveButton: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let action: () -> Void
    
    enum ButtonStyleType {
        case primary, secondary, destructive
        
        var color: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray
            case .destructive: return .red
            }
        }
    }
    
    init(title: String, icon: String? = nil, style: ButtonStyleType = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: adaptiveValues.itemSpacing / 2) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, adaptiveValues.cardPadding * 1.5)
            .padding(.vertical, adaptiveValues.cardPadding * 0.75)
            .background(style.color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: adaptiveValues.smallCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safe Area Adaptive Insets

extension View {
    func adaptiveSafeAreaInset<Content: View>(
        edge: VerticalEdge,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AdaptiveSafeAreaInsetModifier(edge: edge, spacing: spacing, content: content))
    }
    
    // MARK: - Modal Size Extensions
    
    func modalSize(width: CGFloat = 700, height: CGFloat = 800) -> some View {
        #if os(macOS)
        return self.frame(minWidth: width, minHeight: height)
        #else
        return self
        #endif
    }
    
    func compactModalSize() -> some View {
        #if os(macOS)
        return self.frame(minWidth: 500, minHeight: 600)
        #else
        return self
        #endif
    }
    
    func adaptiveModalSize() -> some View {
        #if os(macOS)
        return self.frame(minWidth: 800, minHeight: 700)
        #else
        return self
        #endif
    }
}

struct AdaptiveSafeAreaInsetModifier<InsetContent: View>: ViewModifier {
    @Environment(\.adaptiveValues) var adaptiveValues
    let edge: VerticalEdge
    let spacing: CGFloat?
    let content: () -> InsetContent
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: edge, spacing: spacing ?? adaptiveValues.itemSpacing) {
                self.content()
            }
    }
}

// MARK: - Adaptive List Row

struct AdaptiveListRow<Content: View>: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .listRowInsets(EdgeInsets(
                top: adaptiveValues.itemSpacing,
                leading: adaptiveValues.screenPadding,
                bottom: adaptiveValues.itemSpacing,
                trailing: adaptiveValues.screenPadding
            ))
    }
}

// MARK: - ПРИКЛАД ВИКОРИСТАННЯ

struct ExampleAdaptiveView: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    
    var body: some View {
        ScrollView {
            AdaptiveVStack {
                // Заголовок
                Text("Мої Проєкти")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Карточка зі статистикою
                AdaptiveCard {
                    HStack {
                        AdaptiveIcon(systemName: "folder.fill", color: .blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Активні проєкти")
                                .font(.headline)
                            Text("12 проєктів")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Сітка проєктів
                AdaptiveGrid(items: sampleProjects) { project in
                    ProjectCardView(project: project)
                }
                
                // Кнопка
                AdaptiveButton(title: "Додати проєкт", icon: "plus", style: .primary) {
                    // Action
                }
            }
            .adaptiveScreenPadding()
        }
        .adaptiveContainer() // ВАЖЛИВО: додати на root view для адаптивності!
    }
    
    // Sample data
    let sampleProjects = [
        Project(id: UUID(), name: "Проєкт 1"),
        Project(id: UUID(), name: "Проєкт 2"),
        Project(id: UUID(), name: "Проєкт 3")
    ]
}

struct Project: Identifiable {
    let id: UUID
    let name: String
}

struct ProjectCardView: View {
    @Environment(\.adaptiveValues) var adaptiveValues
    let project: Project
    
    var body: some View {
        AdaptiveCard {
            Text(project.name)
                .font(.headline)
        }
    }
}
