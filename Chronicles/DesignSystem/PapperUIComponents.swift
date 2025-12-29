//
//  PapperUIComponents.swift
//  Chronicles
//
//  All UI Components from Papper Design Library
//  Contains: Buttons, Checkboxes, Cards, Lists, Tab Bar, Icons, and more
//

import SwiftUI

// ============================================================================
// MARK: - Icons
// ============================================================================

/// All icons from Papper Design Library using exact SF Symbol characters
enum PapperIcon: String, CaseIterable {
    case printer, addTask, addCircle, description, connect, warning, link, bin, reset
    case duplicate, archive, calendar, bell, check
    case discovery, new, scan, paper, checkCircle, save
    case infinity, list, handwriting, qr, qrScan, sparks
    case handle, binTask
    
    var character: String {
        switch self {
        case .printer: return "\u{100398}"
        case .addTask: return "\u{1003E9}"
        case .addCircle: return "\u{10004C}"
        case .description: return "\u{100278}"
        case .connect: return "\u{101018}"
        case .warning: return "\u{10062F}"
        case .link: return "\u{100263}"
        case .bin, .binTask: return "\u{100211}"
        case .reset: return "\u{101088}"
        case .duplicate: return "\u{100407}"
        case .archive: return "\u{10022D}"
        case .calendar: return "\u{100249}"
        case .bell: return "\u{1002D9}"
        case .check, .checkCircle: return "\u{100062}"
        case .discovery: return "\u{1003F9}"
        case .new: return "\u{1010A0}"
        case .scan: return "\u{1003BE}"
        case .paper: return "\u{100926}"
        case .save: return "\u{100204}"
        case .infinity: return "\u{100BE0}"
        case .list: return "\u{1007CF}"
        case .handwriting: return "\u{100664}"
        case .qr: return "\u{100582}"
        case .qrScan: return "\u{1003BB}"
        case .sparks: return "\u{1001BF}"
        case .handle: return "\u{1004DA}"
        }
    }
    
    var category: IconCategory {
        switch self {
        case .printer, .addTask, .addCircle, .description, .connect, .warning, .link, .bin, .reset, .duplicate, .archive, .calendar, .bell, .check:
            return .button
        case .discovery, .new, .scan, .paper, .checkCircle, .save:
            return .tab
        case .infinity, .list, .handwriting, .qr, .qrScan, .sparks:
            return .paywall
        case .handle, .binTask:
            return .task
        }
    }
    
    enum IconCategory {
        case button, tab, paywall, task
        
        var containerSize: CGFloat {
            switch self {
            case .button, .task: return 22
            case .tab: return 30
            case .paywall: return 28
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .button: return 15
            case .tab: return 20
            case .paywall: return 16
            case .task: return 17
            }
        }
        
        var hasGlow: Bool { self == .tab }
    }
    
    var sfSymbolName: String {
        switch self {
        case .printer: return "printer"
        case .addTask: return "plus.rectangle.on.rectangle"
        case .addCircle: return "plus.circle"
        case .description: return "doc.text"
        case .connect, .link: return "link"
        case .warning: return "exclamationmark.triangle"
        case .bin, .binTask: return "trash"
        case .reset: return "arrow.counterclockwise"
        case .duplicate: return "doc.on.doc"
        case .archive: return "archivebox"
        case .calendar: return "calendar"
        case .bell: return "bell"
        case .check, .checkCircle: return "checkmark.circle"
        case .discovery: return "square.stack.3d.up"
        case .new: return "plus.circle"
        case .scan: return "camera.viewfinder"
        case .paper: return "doc.text"
        case .save: return "square.and.arrow.down"
        case .infinity: return "infinity"
        case .list: return "list.bullet"
        case .handwriting: return "hand.draw"
        case .qr: return "qrcode"
        case .qrScan: return "qrcode.viewfinder"
        case .sparks: return "sparkles"
        case .handle: return "line.3.horizontal"
        }
    }
    
    static func fromString(_ name: String) -> PapperIcon {
        switch name.lowercased() {
        case "printer": return .printer
        case "add-task", "addtask": return .addTask
        case "add-circle", "addcircle": return .addCircle
        case "description": return .description
        case "connect": return .connect
        case "warning": return .warning
        case "link": return .link
        case "bin": return .bin
        case "reset": return .reset
        case "duplicate": return .duplicate
        case "archive": return .archive
        case "calendar": return .calendar
        case "bell": return .bell
        case "check": return .check
        case "discovery": return .discovery
        case "new": return .new
        case "scan": return .scan
        case "paper": return .paper
        case "check-circle", "checkcircle": return .checkCircle
        case "save": return .save
        case "infinity": return .infinity
        case "list": return .list
        case "handwriting": return .handwriting
        case "qr": return .qr
        case "qr-scan", "qrscan": return .qrScan
        case "sparks": return .sparks
        case "handle": return .handle
        case "bin-task", "bintask": return .binTask
        default: return .check
        }
    }
}

struct PapperIconView: View {
    let icon: PapperIcon
    var size: CGFloat?
    var color: Color?
    var rotation: Angle = .zero
    
    var body: some View {
        Text(icon.character)
            .font(.system(size: size ?? icon.category.fontSize))
            .foregroundColor(color ?? defaultColor)
            .rotationEffect(icon == .handle ? .degrees(-90) : rotation)
            .frame(width: size ?? icon.category.containerSize, height: size ?? icon.category.containerSize)
            .if(icon.category.hasGlow) { view in
                view.shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
            }
    }
    
    private var defaultColor: Color {
        switch icon.category {
        case .button: return PapperColors.iconPrimary
        case .tab: return PapperColors.surfaceBackgroundGray
        case .paywall: return PapperColors.fontsPaywall
        case .task: return PapperColors.iconSecondary
        }
    }
}

// ============================================================================
// MARK: - Checkbox
// ============================================================================

enum PapperCheckboxShape { case circle, square }
enum PapperCheckboxSize {
    case large, medium, small
    
    var value: CGFloat {
        switch self {
        case .large: return 32
        case .medium: return 26
        case .small: return 20
        }
    }
    
    var xMarkSize: CGFloat {
        switch self {
        case .large: return 10
        case .medium: return 8
        case .small: return 6
        }
    }
    
    var fillSize: CGFloat {
        switch self {
        case .large: return 20
        case .medium: return 16
        case .small: return 12
        }
    }
}

struct PapperCheckbox: View {
    @Binding var isChecked: Bool
    let shape: PapperCheckboxShape
    let size: PapperCheckboxSize
    let color: Color?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(isChecked: Binding<Bool>, shape: PapperCheckboxShape = .circle, size: PapperCheckboxSize = .large, color: Color? = nil) {
        self._isChecked = isChecked
        self.shape = shape
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isChecked.toggle() }
        } label: {
            ZStack {
                backgroundShape
                if isChecked { checkMark.transition(.scale.combined(with: .opacity)) }
            }
            .frame(width: size.value, height: size.value)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var backgroundShape: some View {
        switch shape {
        case .circle:
            Circle().stroke(borderColor, lineWidth: 2)
        case .square:
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: size.value - 2, height: size.value - 2)
        }
    }
    
    @ViewBuilder
    private var checkMark: some View {
        switch shape {
        case .circle:
            XMarkShape()
                .stroke(borderColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: size.xMarkSize, height: size.xMarkSize)
        case .square:
            RoundedRectangle(cornerRadius: 4)
                .fill(borderColor)
                .frame(width: size.fillSize, height: size.fillSize)
        }
    }
    
    private var borderColor: Color {
        color ?? (colorScheme == .dark ? PapperColors.pink400 : PapperColors.neutral700)
    }
}

struct XMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct PapperCheckboxStatic: View {
    let isChecked: Bool
    let shape: PapperCheckboxShape
    let size: PapperCheckboxSize
    let color: Color?
    
    init(isChecked: Bool = false, shape: PapperCheckboxShape = .circle, size: PapperCheckboxSize = .large, color: Color? = nil) {
        self.isChecked = isChecked
        self.shape = shape
        self.size = size
        self.color = color
    }
    
    var body: some View {
        PapperCheckbox(isChecked: .constant(isChecked), shape: shape, size: size, color: color).disabled(true)
    }
}

// ============================================================================
// MARK: - Quick Action Button
// ============================================================================

enum PapperQuickActionType { case filled, withBorder, noBorder, price, primary, warning }

struct PapperQuickActionButton: View {
    let title: String
    let icon: String?
    let type: PapperQuickActionType
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    init(_ title: String, icon: String? = nil, type: PapperQuickActionType = .filled, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                        .frame(width: 22, height: 22)
                }
                Text(title)
                    .font(.custom("NewYorkMedium-Regular", size: type == .price ? 11 : 13))
                    .fontWeight(type == .primary || type == .warning ? .semibold : .regular)
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, type == .price ? 8 : (type == .noBorder ? 4 : 12))
            .padding(.vertical, type == .price ? 5 : 7)
            .background(backgroundColor)
            .cornerRadius(15)
            .overlay(borderOverlay)
        }
        .buttonStyle(.plain)
    }
    
    private var iconColor: Color {
        switch type {
        case .filled: return colorScheme == .dark ? PapperColors.neutral100 : PapperColors.neutral700.opacity(0.8)
        case .withBorder, .noBorder: return PapperColors.neutral700.opacity(0.8)
        case .price: return PapperColors.neutral900
        case .primary: return PapperColors.purple400
        case .warning: return .white
        }
    }
    
    private var textColor: Color { iconColor }
    
    private var backgroundColor: Color {
        switch type {
        case .filled: return colorScheme == .dark ? PapperColors.neutral600 : PapperColors.neutral700
        case .withBorder: return colorScheme == .dark ? PapperColors.neutral800.opacity(0.5) : PapperColors.surfaceBackgroundGray
        case .noBorder: return .clear
        case .price: return PapperColors.peach200.opacity(0.5)
        case .primary: return PapperColors.peach200
        case .warning: return PapperColors.pink600
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if type == .withBorder {
            RoundedRectangle(cornerRadius: 15).stroke(PapperColors.borderActive, lineWidth: 1)
        }
    }
}

// ============================================================================
// MARK: - Action Button
// ============================================================================

enum PapperActionButtonType { case save, action, custom }

struct PapperActionButton: View {
    let type: PapperActionButtonType
    let icon: String?
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    init(type: PapperActionButtonType = .action, icon: String? = nil, action: @escaping () -> Void) {
        self.type = type
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: buttonIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private var buttonIcon: String {
        icon ?? (type == .save ? "checkmark" : (type == .action ? "xmark" : "circle"))
    }
    
    private var iconColor: Color {
        type == .save ? PapperColors.fontMain : (colorScheme == .dark ? .white : PapperColors.neutral1000)
    }
    
    private var backgroundColor: Color {
        type == .save ? .clear : (colorScheme == .dark ? PapperColors.surfaceButtonsPrimary : PapperColors.surfaceButtonsQuickAction)
    }
    
    static func save(action: @escaping () -> Void) -> PapperActionButton { PapperActionButton(type: .save, action: action) }
    static func close(action: @escaping () -> Void) -> PapperActionButton { PapperActionButton(type: .action, icon: "xmark", action: action) }
    static func custom(icon: String, action: @escaping () -> Void) -> PapperActionButton { PapperActionButton(type: .custom, icon: icon, action: action) }
}

// ============================================================================
// MARK: - Big Button
// ============================================================================

enum PapperBigButtonShape { case long, round, withBorder }

struct PapperBigButton: View {
    let title: String?
    let icon: String
    let shape: PapperBigButtonShape
    let action: () -> Void
    
    init(title: String? = nil, icon: String, shape: PapperBigButtonShape = .long, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.shape = shape
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                    .frame(width: 30, height: 30)
                
                if let title = title, shape == .long || shape == .withBorder {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
            }
            .padding(.horizontal, shape == .long ? 65 : (shape == .round ? 10 : 20))
            .padding(.vertical, 10)
            .frame(width: shape == .round ? 50 : 203, height: 50)
            .background(backgroundView)
            .cornerRadius(25)
            .overlay(shape == .withBorder ? RoundedRectangle(cornerRadius: 25).stroke(.white, lineWidth: 10) : nil)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(Color(red: 100/255, green: 109/255, blue: 109/255).opacity(0.8))
        }
    }
    
    static func create(_ title: String = "Create", icon: String = "plus.circle", action: @escaping () -> Void = {}) -> PapperBigButton {
        PapperBigButton(title: title, icon: icon, shape: .long, action: action)
    }
    
    static func round(icon: String, action: @escaping () -> Void = {}) -> PapperBigButton {
        PapperBigButton(title: nil, icon: icon, shape: .round, action: action)
    }
}

// ============================================================================
// MARK: - Tab Button
// ============================================================================

struct PapperTabItem: Identifiable {
    let id: String
    let icon: String
    let label: String?
    
    init(id: String = UUID().uuidString, icon: String, label: String? = nil) {
        self.id = id
        self.icon = icon
        self.label = label
    }
}

struct PapperTabButton: View {
    let items: [PapperTabItem]
    @Binding var selectedIndex: Int
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                tabItemView(item: item, isSelected: index == selectedIndex)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedIndex = index }
                    }
            }
        }
        .padding(10)
        .background(tabBackground)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func tabItemView(item: PapperTabItem, isSelected: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
            
            if isSelected, let label = item.label {
                Text(label).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            }
        }
        .padding(.horizontal, isSelected && item.label != nil ? 65 : 10)
        .padding(.vertical, 10)
        .frame(height: 50)
        .background(Color(red: 100/255, green: 109/255, blue: 109/255).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    @ViewBuilder
    private var tabBackground: some View {
        ZStack {
            colorScheme == .dark ? PapperColors.neutral800 : Color.white.opacity(0.6)
            Rectangle().fill(.ultraThinMaterial).opacity(0.3)
        }
    }
}

// ============================================================================
// MARK: - Tab Bar
// ============================================================================

enum PapperTabPage {
    case main, scan, discovery
    
    var leftIcon: String {
        switch self {
        case .main, .discovery: return "square.stack.3d.up"
        case .scan: return "house"
        }
    }
    var centerIcon: String { "plus.circle" }
    var centerTitle: String { "Create" }
    var rightIcon: String { "camera.viewfinder" }
}

struct PapperTabBar: View {
    @Binding var activePage: PapperTabPage
    let onLeftTap: () -> Void
    let onCenterTap: () -> Void
    let onRightTap: () -> Void
    
    init(activePage: Binding<PapperTabPage> = .constant(.main), onLeftTap: @escaping () -> Void = {}, onCenterTap: @escaping () -> Void = {}, onRightTap: @escaping () -> Void = {}) {
        self._activePage = activePage
        self.onLeftTap = onLeftTap
        self.onCenterTap = onCenterTap
        self.onRightTap = onRightTap
    }
    
    var body: some View {
        HStack(spacing: 10) {
            TabBarButton(icon: activePage.leftIcon, action: onLeftTap)
            TabBarButton(icon: activePage.centerIcon, title: activePage.centerTitle, isWide: true, action: onCenterTap)
            TabBarButton(icon: activePage.rightIcon, action: onRightTap)
        }
        .padding(10)
    }
}

private struct TabBarButton: View {
    let icon: String
    let title: String?
    let isWide: Bool
    let action: () -> Void
    
    init(icon: String, title: String? = nil, isWide: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isWide = isWide
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                    .frame(width: 30, height: 30)
                
                if let title = title, isWide {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
            }
            .frame(width: isWide ? 203 : 50, height: 50)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 25).fill(Color(red: 100/255, green: 109/255, blue: 109/255).opacity(0.8))
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// ============================================================================
// MARK: - Save Button & Close Button
// ============================================================================

struct PapperSaveButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text("\u{100062}")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PapperColors.fontMain)
                .frame(width: 30, height: 30)
                .background(colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : PapperColors.surfaceFirstLayer)
                .cornerRadius(22)
        }
        .buttonStyle(.plain)
    }
}

struct PapperCloseButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : PapperColors.neutral700)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? PapperColors.neutral600 : PapperColors.surfaceBackgroundGray)
                        .overlay(Circle().stroke(PapperColors.borderActive, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}

// ============================================================================
// MARK: - Handle
// ============================================================================

struct PapperHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.6))
            .frame(width: 39, height: 4)
    }
}

struct PapperDragHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(PapperColors.white60)
            .frame(width: 39, height: 4)
    }
}

// ============================================================================
// MARK: - Task Models
// ============================================================================

struct PapperTaskModel: Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var isChecked: Bool
    var showButtons: Bool
    
    init(id: UUID = UUID(), title: String, description: String? = nil, isChecked: Bool = false, showButtons: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.isChecked = isChecked
        self.showButtons = showButtons
    }
}

struct TodayTask: Identifiable {
    let id: UUID
    var title: String
    var taskCount: Int
    var isChecked: Bool
    var hasMore: Bool
    
    init(id: UUID = UUID(), title: String, taskCount: Int = 1, isChecked: Bool = false, hasMore: Bool = true) {
        self.id = id
        self.title = title
        self.taskCount = taskCount
        self.isChecked = isChecked
        self.hasMore = hasMore
    }
}

// ============================================================================
// MARK: - Task Card
// ============================================================================

struct PapperTaskCard: View {
    @Binding var isChecked: Bool
    let title: String
    let hasBorder: Bool
    let hasShade: Bool
    let hasMoreIndicator: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    init(isChecked: Binding<Bool>, title: String, hasBorder: Bool = true, hasShade: Bool = false, hasMoreIndicator: Bool = true) {
        self._isChecked = isChecked
        self.title = title
        self.hasBorder = hasBorder
        self.hasShade = hasShade
        self.hasMoreIndicator = hasMoreIndicator
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : PapperColors.surfaceSecondLayer)
            
            HStack(spacing: 10) {
                PapperCheckbox(isChecked: $isChecked, shape: .square, size: .large)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.fontMain)
                    .lineLimit(2)
                    .frame(width: 166, alignment: .leading)
            }
            .padding(.leading, 16)
            .padding(.trailing, 42)
            .padding(.vertical, 20)
            
            if hasBorder {
                RoundedRectangle(cornerRadius: 16).stroke(PapperColors.borderActive, lineWidth: 2)
            }
            
            if hasMoreIndicator {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(PapperColors.neutral400).frame(width: 4, height: 4)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 266, height: 97)
    }
}

// ============================================================================
// MARK: - Task Item
// ============================================================================

struct PapperTaskItem: View {
    let title: String
    let description: String?
    @Binding var isChecked: Bool
    let onTap: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, description: String? = nil, isChecked: Binding<Bool>, onTap: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self._isChecked = isChecked
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            PapperCheckbox(isChecked: $isChecked, shape: .circle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PapperColors.fontMain)
                    .strikethrough(isChecked, color: PapperColors.fontSecondary)
                
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(PapperColors.fontSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if onDelete != nil {
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(PapperColors.iconSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? PapperColors.peach400.opacity(0.3) : PapperColors.peach200)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// ============================================================================
// MARK: - Today Card
// ============================================================================

enum PapperCardColor: CaseIterable {
    case grayblue, pink, lavanda, peach
    
    var color: Color {
        switch self {
        case .grayblue: return PapperColors.grayblue200
        case .pink: return PapperColors.pink200
        case .lavanda: return PapperColors.lavanda200
        case .peach: return PapperColors.peach200
        }
    }
}

struct PapperTodayTaskCard: View {
    let title: String
    let taskCount: Int
    let cardColor: PapperCardColor
    @Binding var isChecked: Bool
    let showMoreIndicator: Bool
    
    init(title: String, taskCount: Int = 1, cardColor: PapperCardColor = .peach, isChecked: Binding<Bool>, showMoreIndicator: Bool = true) {
        self.title = title
        self.taskCount = taskCount
        self.cardColor = cardColor
        self._isChecked = isChecked
        self.showMoreIndicator = showMoreIndicator
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16).fill(cardColor.color)
            RoundedRectangle(cornerRadius: 16).stroke(PapperColors.borderActive, lineWidth: 2)
            
            HStack(spacing: 10) {
                PapperCheckbox(isChecked: $isChecked, shape: .square, size: .large)
                Text("\(taskCount) task")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.fontMain)
                    .lineLimit(1)
            }
            .padding(.leading, 16)
            .padding(.trailing, 42)
            .padding(.vertical, 20)
            
            if showMoreIndicator {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(PapperColors.neutral400).frame(width: 4, height: 4)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 266, height: 97)
    }
}

struct PapperPager: View {
    let totalPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Rectangle()
                    .fill(index == currentPage ? PapperColors.neutral700 : Color.white)
                    .frame(height: 2)
            }
        }
        .padding(.vertical, 10)
    }
}

struct PapperTodayCard: View {
    let date: Date
    @Binding var tasks: [TodayTask]
    @State private var currentPage = 0
    
    let onPrint: () -> Void
    let onNotifications: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    init(date: Date = Date(), tasks: Binding<[TodayTask]>, onPrint: @escaping () -> Void = {}, onNotifications: @escaping () -> Void = {}) {
        self.date = date
        self._tasks = tasks
        self.onPrint = onPrint
        self.onNotifications = onNotifications
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today")
                .font(.custom("Hacky-ExtraBold", size: 32))
                .foregroundColor(PapperColors.fontMain)
            
            Text(dateString)
                .font(.custom("NewYorkMedium-Regular", size: 13))
                .foregroundColor(PapperColors.fontSecondary)
                .padding(.vertical, 5)
            
            PapperPager(totalPages: tasks.count, currentPage: currentPage).frame(width: 302)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        PapperTodayTaskCard(
                            title: task.title,
                            taskCount: task.taskCount,
                            cardColor: PapperCardColor.allCases[index % PapperCardColor.allCases.count],
                            isChecked: $tasks[index].isChecked,
                            showMoreIndicator: task.hasMore
                        )
                    }
                }
            }
            .frame(height: 97)
            
            HStack(spacing: 10) {
                PapperQuickActionButton("Print it", icon: "printer", type: .noBorder, action: onPrint)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
                
                PapperQuickActionButton("Notifications", icon: "bell", type: .noBorder, action: onNotifications)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : Color.white.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// ============================================================================
// MARK: - Settings Row
// ============================================================================

enum PapperSettingType {
    case frequency, color
    var label: String {
        switch self {
        case .frequency: return "Frequency:"
        case .color: return "Color:"
        }
    }
}

struct PapperSettingsRow: View {
    let type: PapperSettingType
    let value: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(type.label)
                .font(.custom("NewYorkMedium-Regular", size: 13))
                .foregroundColor(PapperColors.fontAccent)
            
            Button(action: action) {
                Text(value)
                    .font(.custom("NewYorkMedium-Regular", size: 13))
                    .foregroundColor(PapperColors.fontSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(PapperColors.surfaceFirstLayer)
                    .cornerRadius(15)
            }
            .buttonStyle(.plain)
        }
    }
}

// ============================================================================
// MARK: - Dividers
// ============================================================================

struct DashedDivider: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 5))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 5))
            }
            .stroke(PapperColors.neutral400, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .frame(height: 10)
    }
}

struct PapperTaskDivider: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 5))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 5))
            }
            .stroke(PapperColors.neutral400, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .frame(height: 10)
    }
}

// ============================================================================
// MARK: - Cutouts
// ============================================================================

struct PapperCutout: View {
    var body: some View {
        Circle().fill(PapperColors.neutral700).frame(width: 10, height: 10)
    }
}

struct PapperImportantCutout: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(Color.clear).frame(width: 56, height: 56)
            PapperCutout().offset(x: -23, y: -23)
        }
    }
}

// ============================================================================
// MARK: - Checker Components
// ============================================================================

struct CheckboxGrid: View {
    @Binding var checkedStates: [Bool]
    let columns: Int
    let checkboxSize: CGFloat
    let gap: CGFloat
    
    var body: some View {
        let gridColumns = Array(repeating: GridItem(.fixed(checkboxSize), spacing: gap), count: columns)
        
        LazyVGrid(columns: gridColumns, spacing: gap) {
            ForEach(0..<checkedStates.count, id: \.self) { index in
                PapperCheckbox(isChecked: $checkedStates[index], shape: .circle, size: .large)
            }
        }
    }
}

struct PapperCheckerCard: View {
    let title: String
    let description: String?
    @Binding var checkedStates: [Bool]
    let columns: Int
    let onPrint: () -> Void
    let onAddCircle: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, description: String? = nil, checkedStates: Binding<[Bool]>, columns: Int = 7, onPrint: @escaping () -> Void = {}, onAddCircle: @escaping () -> Void = {}) {
        self.title = title
        self.description = description
        self._checkedStates = checkedStates
        self.columns = columns
        self.onPrint = onPrint
        self.onAddCircle = onAddCircle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom("Hacky-ExtraBold", size: 32))
                .foregroundColor(PapperColors.fontMain)
            
            if let description = description {
                Text(description)
                    .font(.custom("NewYorkMedium-Regular", size: 13))
                    .foregroundColor(PapperColors.fontSecondary)
                    .padding(.vertical, 5)
            }
            
            CheckboxGrid(checkedStates: $checkedStates, columns: columns, checkboxSize: 32, gap: 10)
                .frame(width: 303)
                .padding(.horizontal, 9)
                .padding(.top, 10)
            
            HStack(spacing: 10) {
                PapperQuickActionButton("Print it", icon: "printer", type: .noBorder, action: onPrint)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
                
                PapperQuickActionButton("Add circle", icon: "plus.circle", type: .noBorder, action: onAddCircle)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : PapperColors.surfaceSecondLayer)
        )
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// ============================================================================
// MARK: - Discovery Components
// ============================================================================

enum PapperDiscoveryCardSize {
    case oneThird, oneHalf, twoThirds, full
    
    var width: CGFloat {
        switch self {
        case .oneThird: return 110
        case .oneHalf: return 165
        case .twoThirds: return 220
        case .full: return 333
        }
    }
    
    var height: CGFloat { 125 }
    
    var fontSize: CGFloat {
        switch self {
        case .oneThird: return 11
        default: return 13
        }
    }
}

struct PapperDiscoveryChecklistCard: View {
    let name: String
    let size: PapperDiscoveryCardSize
    let backgroundColor: Color
    let picture: Image?
    let action: (() -> Void)?
    
    init(name: String, size: PapperDiscoveryCardSize = .oneHalf, backgroundColor: Color = PapperColors.pink200, picture: Image? = nil, action: (() -> Void)? = nil) {
        self.name = name
        self.size = size
        self.backgroundColor = backgroundColor
        self.picture = picture
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(name)
                    .font(.system(size: size.fontSize, weight: .regular))
                    .foregroundColor(PapperColors.fontAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 26)
                    .padding(.horizontal, 14)
                
                Spacer()
                
                if let pic = picture {
                    pic.resizable().scaledToFit().frame(width: 86).padding(.trailing, 14)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor.opacity(0.5))
                        .frame(width: 86, height: 60)
                        .padding(.trailing, 14)
                }
            }
            .frame(width: size.width, height: size.height)
            .background(backgroundColor)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct PapperDiscoveryPackStack: View {
    let title: String
    let cards: [[DiscoveryCardData]]
    let action: ((Int, Int) -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    struct DiscoveryCardData {
        let name: String
        let size: PapperDiscoveryCardSize
        let backgroundColor: Color
        let picture: Image?
        
        init(name: String, size: PapperDiscoveryCardSize = .oneHalf, backgroundColor: Color = PapperColors.pink200, picture: Image? = nil) {
            self.name = name
            self.size = size
            self.backgroundColor = backgroundColor
            self.picture = picture
        }
    }
    
    init(title: String, cards: [[DiscoveryCardData]], action: ((Int, Int) -> Void)? = nil) {
        self.title = title
        self.cards = cards
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(PapperTypography.discoveryTitle())
                .foregroundColor(PapperColors.fontNonColor)
            
            ForEach(Array(cards.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 3) {
                    ForEach(Array(row.enumerated()), id: \.offset) { cardIndex, cardData in
                        PapperDiscoveryChecklistCard(
                            name: cardData.name,
                            size: cardData.size,
                            backgroundColor: cardData.backgroundColor,
                            picture: cardData.picture,
                            action: { action?(rowIndex, cardIndex) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
        .padding(.bottom, 25)
        .background(colorScheme == .dark ? PapperColors.surfaceFirstLayerDark : PapperColors.surfaceDiscoveryFirstLayer)
        .cornerRadius(35)
    }
}

struct PapperTasksAmountButton: View {
    let amount: Int
    let label: String
    let action: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(amount: Int, label: String, action: (() -> Void)? = nil) {
        self.amount = amount
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(amount)")
                    .font(.custom("Hacky-ExtraBold", size: 32))
                    .foregroundColor(PapperColors.fontFancy)
                
                Text(label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(PapperColors.fontSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : PapperColors.surfaceBackgroundGray)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct PapperDiscoveryHeader: View {
    let taskAmounts: [(amount: Int, label: String)]
    let onAmountTap: ((Int) -> Void)?
    
    init(taskAmounts: [(amount: Int, label: String)] = [(12, "Today"), (45, "This week"), (128, "This month")], onAmountTap: ((Int) -> Void)? = nil) {
        self.taskAmounts = taskAmounts
        self.onAmountTap = onAmountTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Accomplished")
                .font(.system(size: 35, weight: .regular))
                .foregroundColor(PapperColors.fontMain)
                .padding(.leading, 22)
                .padding(.top, 17)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(taskAmounts.enumerated()), id: \.offset) { index, item in
                        PapperTasksAmountButton(amount: item.amount, label: item.label, action: { onAmountTap?(index) })
                    }
                }
                .padding(.horizontal, 3)
            }
            .padding(.top, 6)
        }
    }
}

// ============================================================================
// MARK: - Create Screen Components
// ============================================================================

enum PapperCreateTabType: String, CaseIterable {
    case list = "List"
    case checker = "Checker"
    case task = "Task"
}

struct PapperTabNew: View {
    let tabType: PapperCreateTabType
    let isActive: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(tabType.rawValue)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? PapperColors.fontMain : PapperColors.fontNonColor)
                .padding(.horizontal, 16)
                .padding(.vertical, isActive ? 6 : 8)
                .background(isActive ? (colorScheme == .dark ? PapperColors.surfaceSecondLayerDark : PapperColors.surfaceDiscoveryFirstLayer) : Color.clear)
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}

struct PapperCreateTabMenu: View {
    @Binding var selectedTab: PapperCreateTabType
    let onSave: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                ForEach(PapperCreateTabType.allCases, id: \.self) { tab in
                    PapperTabNew(tabType: tab, isActive: selectedTab == tab, action: { selectedTab = tab })
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(colorScheme == .dark ? PapperColors.neutral800 : PapperColors.surfacePaywallGray)
            .cornerRadius(27)
            
            Spacer()
            
            PapperSaveButton(action: onSave)
        }
    }
}

struct PapperNewListButton: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("+").font(.system(size: 16, weight: .semibold))
                Text("List").font(.system(size: 13, weight: .regular, design: .serif))
            }
            .foregroundColor(PapperColors.fontSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colorScheme == .dark ? PapperColors.surfaceFirstLayerDark : PapperColors.surfaceFirstLayer)
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(PapperColors.iconPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(width: 47, height: 30)
    }
}

struct PapperListSelectorButton: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(isSelected ? PapperColors.fontButtons : PapperColors.fontSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? PapperColors.surfaceButtonsPrimary : (colorScheme == .dark ? PapperColors.surfaceFirstLayerDark : PapperColors.surfaceFirstLayer))
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? Color.clear : PapperColors.iconPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct PapperListSelectorCarousel: View {
    let lists: [String]
    @Binding var selectedList: String?
    let onNewList: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(lists, id: \.self) { list in
                    PapperListSelectorButton(name: list, isSelected: selectedList == list, action: { selectedList = list })
                }
                PapperNewListButton(action: onNewList)
            }
            .padding(.horizontal, 4)
        }
    }
}

// ============================================================================
// MARK: - Onboarding Components
// ============================================================================

struct PapperHowToIcon: View {
    enum IconType: String { case discovery, create, scan }
    
    let iconType: IconType
    var size: CGFloat = 35
    
    private var backgroundColor: Color {
        switch iconType {
        case .discovery: return Papper.colors.lavanda200
        case .create: return Papper.colors.mint200
        case .scan: return Papper.colors.peach200
        }
    }
    
    private var icon: PapperIcon {
        switch iconType {
        case .discovery: return .discovery
        case .create: return .new
        case .scan: return .scan
        }
    }
    
    var body: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(PapperIconView(icon: icon, size: size * 0.6).foregroundColor(Papper.colors.fontMain))
    }
}

struct PapperPagerIndicator: View {
    let totalPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Rectangle()
                    .fill(index == currentPage ? Papper.colors.neutral700 : Color.white)
                    .frame(height: 2)
            }
        }
    }
}

struct PapperAnalyzingCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Papper.colors.neutral700)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isAnimating)
                }
            }
            
            Text("Analyzing...")
                .font(.custom("NewYorkMedium-Bold", size: 16))
                .foregroundColor(Papper.colors.fontMain)
            
            Text("AI is processing your request")
                .font(.custom("NewYork-Regular", size: 13))
                .foregroundColor(Papper.colors.fontSecondary)
        }
        .padding(24)
        .frame(width: 342, height: 158)
        .background(Papper.colors.surfaceFirstLayer)
        .cornerRadius(35)
        .onAppear { isAnimating = true }
    }
}

struct PapperPromoBanner: View {
    let message: String
    var isWarning: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            if isWarning {
                PapperIconView(icon: .warning, size: 20).foregroundColor(Papper.colors.pink600)
            }
            
            Text(message)
                .font(.custom("NewYork-Regular", size: 13))
                .foregroundColor(isWarning ? Papper.colors.pink600 : Papper.colors.fontMain)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Papper.colors.fontSecondary)
            }
        }
        .padding(16)
        .background(isWarning ? Papper.colors.pink200 : Papper.colors.surfaceFirstLayer)
        .cornerRadius(20)
    }
}

// ============================================================================
// MARK: - Paywall Components
// ============================================================================

struct PapperPaywallPriceCard: View {
    enum Plan: String { case monthly = "Monthly", annually = "Annually", lifetime = "Lifetime" }
    
    let plan: Plan
    let price: String
    let subtitle: String
    let priceLabel: String
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(plan.rawValue)
                .font(.custom("NewYorkMedium-Bold", size: 13))
                .foregroundColor(Papper.colors.fontsPaywall)
            
            Text(subtitle)
                .font(.custom("NewYork-Regular", size: 11))
                .foregroundColor(Papper.colors.fontsPaywall)
                .multilineTextAlignment(.center)
                .frame(width: 90)
            
            VStack(spacing: 4) {
                Text(price)
                    .font(.custom("Hacky-ExtraBold", size: 32))
                    .foregroundColor(Papper.colors.fontsPaywall)
                
                Text(priceLabel)
                    .font(.custom("NewYork-Regular", size: 11))
                    .foregroundColor(Papper.colors.fontsPaywall)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Papper.colors.surfaceButtonsQuickAction)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Papper.colors.neutral550b, lineWidth: 1))
                    .cornerRadius(15)
            }
        }
        .frame(width: 110, height: 156)
        .background(isSelected ? Papper.colors.peach200 : Color.clear)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Papper.colors.borderActive : Color.clear, lineWidth: 2))
    }
}

struct PapperPaywallTextElement: View {
    let iconName: String
    let text: String
    var topAlign: Bool = false
    
    var body: some View {
        HStack(alignment: topAlign ? .top : .center, spacing: 10) {
            PapperIconView(icon: .fromString(iconName))
                .frame(width: 28, height: 19)
                .foregroundColor(Papper.colors.fontMain)
            
            Text(text)
                .font(.custom("NewYork-Regular", size: 13))
                .foregroundColor(Papper.colors.fontSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct PapperDiscoveryPicture: View {
    enum Picture: String { case bottle, cabinet, sun, xmas, gift }
    
    let picture: Picture
    
    private var backgroundColor: Color {
        switch picture {
        case .bottle: return Papper.colors.mint200
        case .cabinet: return Papper.colors.lavanda200
        case .sun: return Papper.colors.yellow200
        case .xmas, .gift: return Papper.colors.pink200
        }
    }
    
    private var icon: String {
        switch picture {
        case .bottle: return "drop.fill"
        case .cabinet: return "cabinet.fill"
        case .sun: return "sun.max.fill"
        case .xmas, .gift: return "gift.fill"
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(backgroundColor)
            .frame(width: 92, height: 92)
            .overlay(Image(systemName: icon).font(.system(size: 36)).foregroundColor(Papper.colors.fontMain.opacity(0.6)))
    }
}

struct PapperSyncCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.custom("Hacky-SemiBold", size: 32))
                .foregroundColor(Papper.colors.fontMain)
            
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(gradient: Gradient(colors: [Papper.colors.blue200, Papper.colors.mint200]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 53, height: 53)
                    .overlay(Image(systemName: "checklist").font(.system(size: 24)).foregroundColor(.white))
                
                Text(subtitle)
                    .font(.custom("SF Pro", size: 16))
                    .foregroundColor(Papper.colors.fontMain)
                    .frame(width: 126, alignment: .leading)
                
                Spacer()
                
                Button(action: action) {
                    HStack(spacing: 2) {
                        PapperIconView(icon: .connect).frame(width: 15, height: 15)
                        Text("Connect").font(.custom("NewYorkMedium-Bold", size: 13))
                    }
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                    .padding(.trailing, 20)
                    .padding(.vertical, 4)
                    .background(Papper.colors.surfaceButtonsPrimary)
                    .cornerRadius(15)
                }
            }
        }
        .padding(20)
        .background(Papper.colors.surfaceFirstLayer)
        .cornerRadius(35)
        .overlay(
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Papper.colors.fontMain)
            }
            .frame(width: 30, height: 30)
            .background(Papper.colors.surfaceButtonsQuickAction)
            .cornerRadius(22)
            .padding(17),
            alignment: .topTrailing
        )
    }
}

// ============================================================================
// MARK: - Printout Components
// ============================================================================

struct PapperPrintoutSpecs {
    static let paperWidth: CGFloat = 595
    static let paperHeight: CGFloat = 842
    static let qrFrameSize: CGFloat = 131
    static let qrCodeSize: CGFloat = 88
    static let logoSize: CGFloat = 25
    static let titleFontSize: CGFloat = 60
    static let descriptionFontSize: CGFloat = 11
    static let taskTitleFontSize: CGFloat = 8
    static let taskDescriptionFontSize: CGFloat = 8
    static let paperCheckboxCircleSize: CGFloat = 30
    static let paperCheckboxSquareSize: CGFloat = 13
    static let columnWidth: CGFloat = 254
    static let columnWidthSingle: CGFloat = 311
    static let topMargin: CGFloat = 54
    static let sideMargin: CGFloat = 26
    static let bodyTop: CGFloat = 270
}

struct PapperPaperCheckboxCircle: View {
    let isChecked: Bool
    
    var body: some View {
        ZStack {
            Circle().stroke(Color.black, lineWidth: 1)
            if isChecked {
                XMarkPaper().stroke(Color.black, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 8.5, height: 8.5)
            }
        }
        .frame(width: 30, height: 30)
    }
}

private struct XMarkPaper: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct PapperPaperCheckboxSquare: View {
    let isChecked: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1)
            if isChecked {
                RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 9, height: 9)
            }
        }
        .frame(width: 13, height: 13)
    }
}

struct PapperPaperTask: View {
    let title: String
    let description: String?
    let isChecked: Bool
    
    init(title: String, description: String? = nil, isChecked: Bool = false) {
        self.title = title
        self.description = description
        self.isChecked = isChecked
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PapperPaperCheckboxSquare(isChecked: isChecked)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.black)
                
                if let desc = description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 8, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct PapperLogo: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.black)
            Text("P").font(.system(size: 14, weight: .bold, design: .serif)).foregroundColor(.white)
        }
        .frame(width: 25, height: 25)
    }
}

// ============================================================================
// MARK: - Component Type Aliases (for Papper namespace)
// ============================================================================

extension Papper {
    typealias QuickActionButton = PapperQuickActionButton
    typealias BigButton = PapperBigButton
    typealias TabButton = PapperTabButton
    typealias ActionButton = PapperActionButton
    typealias SaveButton = PapperSaveButton
    typealias Checkbox = PapperCheckbox
    typealias CheckboxStatic = PapperCheckboxStatic
    typealias TaskItem = PapperTaskItem
    typealias TaskCard = PapperTaskCard
    typealias Handle = PapperHandle
    typealias TodayCard = PapperTodayCard
    typealias Icon = PapperIcon
    typealias IconView = PapperIconView
    typealias PaywallPriceCard = PapperPaywallPriceCard
    typealias PaywallTextElement = PapperPaywallTextElement
    typealias SyncCard = PapperSyncCard
    typealias DiscoveryPicture = PapperDiscoveryPicture
    typealias TasksAmountButton = PapperTasksAmountButton
    typealias DiscoveryPackStack = PapperDiscoveryPackStack
    typealias DiscoveryChecklistCard = PapperDiscoveryChecklistCard
    typealias DiscoveryHeader = PapperDiscoveryHeader
    typealias CreateTabMenu = PapperCreateTabMenu
    typealias TabNew = PapperTabNew
    typealias NewListButton = PapperNewListButton
    typealias ListSelectorCarousel = PapperListSelectorCarousel
    typealias ListSelectorButton = PapperListSelectorButton
    typealias HowToIcon = PapperHowToIcon
    typealias PagerIndicator = PapperPagerIndicator
    typealias AnalyzingCard = PapperAnalyzingCard
    typealias DragHandle = PapperDragHandle
    typealias ImportantCutout = PapperImportantCutout
    typealias PromoBanner = PapperPromoBanner
    typealias CheckerCard = PapperCheckerCard
    typealias Logo = PapperLogo
}

