# Chronicles - Dashboard Preview

This is a preview of the Chronicles iOS app dashboard using the Papper Design Library styling.

## Files Created

```
Chronicles/
├── App/
│   ├── ChroniclesApp.swift      # Main app entry
│   └── ContentView.swift        # Content wrapper
├── Design/
│   ├── ColorTokens.swift        # Papper color palette
│   ├── TypographyTokens.swift   # Font styles
│   └── ShadowTokens.swift       # Shadow styles
├── Views/
│   └── Dashboard/
│       ├── DashboardView.swift       # Main dashboard
│       ├── WeeklyCalendarView.swift  # Weekly calendar
│       └── Widgets/
│           ├── QuickEntryWidget.swift    # Quick entry cards
│           └── DailyQuoteWidget.swift    # Quote widget
└── README.md
```

## How to View in Xcode

### Option 1: Create New Xcode Project (Recommended)

1. Open Xcode on a Mac
2. Create new project: File → New → Project
3. Select "iOS" → "App"
4. Settings:
   - Product Name: Chronicles
   - Interface: SwiftUI
   - Language: Swift
5. Delete the default ContentView.swift
6. Copy all files from this `Chronicles/` folder into the Xcode project
7. Build and run (⌘R) to see the dashboard

### Option 2: Swift Playground

1. Open Swift Playgrounds on Mac or iPad
2. Create new playground
3. Copy the code from the Swift files
4. Run to see previews

## Design Features

- **Papper Design Library** color palette
- **Dark mode** optimized (with light mode support)
- **Personalized greeting** based on time of day
- **Weekly calendar** with selectable dates
- **Widget cards** for Morning/Evening reflections
- **Completion status** indicators

## Color Palette

- Primary: `#FF6B6B` (Coral)
- Dark Background: `#1C1C1E`
- Cards: `#2C2C2E` / `#3A3A3C`
- Morning Widget: `#FFB347` (Orange)
- Evening Widget: `#7B68EE` (Purple)
- Completed: `#34C759` (Green)

## Typography

- Large greeting: Serif, bold
- Body: SF Pro, regular
- Small text: SF Pro, 11px
- Calendar: SF Pro, medium

