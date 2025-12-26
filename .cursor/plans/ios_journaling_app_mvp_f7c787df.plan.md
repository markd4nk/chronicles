---
name: iOS Journaling App MVP
overview: Build a native iOS journaling app with Firebase backend, featuring comprehensive 14-step onboarding, authentication (Google/Apple), paywall with 3-day free trial, and subscription management (monthly/yearly). MVP includes customizable journals, multiple input methods (write/scan/speak), customizable dashboard with widgets, journal templates, list/calendar views, search functionality, password/Face ID protection, and goal-setting features.
todos:
  - id: setup-project
    content: Create Xcode project with SwiftUI, configure Firebase project and add GoogleService-Info.plist
    status: pending
  - id: auth-system
    content: Implement authentication with Google Sign-In and Apple Sign-In using Firebase Auth
    status: pending
    dependencies:
      - setup-project
  - id: onboarding
    content: Build comprehensive 14-step onboarding flow with data collection, nested slideshow, reminder setup, and paywall integration
    status: pending
    dependencies:
      - auth-system
      - subscription-service
  - id: subscription-service
    content: Implement StoreKit 2 subscription management with 3-day trial and monthly/yearly plans
    status: pending
    dependencies:
      - auth-system
  - id: paywall-ui
    content: Create paywall view with subscription plan selection and purchase flow
    status: pending
    dependencies:
      - subscription-service
  - id: firestore-models
    content: Define Firestore data models (User, JournalEntry, Goal) and security rules
    status: pending
    dependencies:
      - setup-project
  - id: journal-features
    content: Build journal entry creation with multiple input methods (write/scan/speak), list view, search functionality, and detail/edit functionality with Firestore sync
    status: pending
    dependencies:
      - firestore-models
  - id: ocr-service
    content: Implement OCR service using Vision Framework for text recognition from photos
    status: pending
    dependencies:
      - setup-project
  - id: speech-service
    content: Implement speech-to-text service using Speech Framework for voice transcription
    status: pending
    dependencies:
      - setup-project
  - id: search-feature
    content: Implement search functionality for journal entries with real-time results and highlighting
    status: pending
    dependencies:
      - journal-features
  - id: goal-features
    content: Implement goal creation, tracking, and list views with Firestore integration
    status: pending
    dependencies:
      - firestore-models
  - id: main-navigation
    content: Create main tab view with navigation between Journal and Goals sections
    status: pending
    dependencies:
      - journal-features
      - goal-features
  - id: subscription-gating
    content: Implement subscription status checking and app gating (lock features without subscription)
    status: pending
    dependencies:
      - subscription-service
      - main-navigation
  - id: notification-service
    content: Implement notification service to schedule morning and evening reminders based on user preferences
    status: pending
    dependencies:
      - onboarding
  - id: custom-journals
    content: Implement custom journals system - users create journals with custom names, manage (rename/delete/reorder), and must create at least one before creating entries
    status: pending
    dependencies:
      - firestore-models
  - id: all-entries-view
    content: Create All Entries view showing entries from all journals with filtering and search
    status: pending
    dependencies:
      - custom-journals
      - journal-features
  - id: list-calendar-views
    content: Implement separate List and Calendar view tabs showing all entries, with clickable calendar dates
    status: pending
    dependencies:
      - all-entries-view
  - id: password-faceid
    content: Implement password/Face ID protection using LocalAuthentication framework with settings toggle
    status: pending
    dependencies:
      - auth-system
  - id: dashboard-system
    content: Build customizable dashboard with personalized greeting, weekly calendar, and widget system
    status: pending
    dependencies:
      - custom-journals
  - id: journal-templates
    content: Implement journal templates system - create templates in settings with prompts and structure, journal-specific
    status: pending
    dependencies:
      - custom-journals
  - id: quick-entry-widgets
    content: Create quick entry widgets based on templates that open pre-filled entries, show completion status
    status: pending
    dependencies:
      - dashboard-system
      - journal-templates
---

# Chronicles - iOS Journaling App MVP

## Project Overview

**Chronicles** is a native iOS journaling and goal-setting app built with SwiftUI and Firebase. The app requires a subscription (no free tier) with a 3-day free trial. Users go through an extensive 14-step onboarding process that personalizes their experience and collects preferences.

### Key Requirements

- ✅ **No Free Tier**: Users must subscribe to use the app
- ✅ **3-Day Free Trial**: Full feature access during trial period
- ✅ **Monthly & Yearly Subscriptions**: Two subscription options
- ✅ **Google & Apple Sign-In**: Authentication options
- ✅ **Comprehensive Onboarding**: 14-step personalized onboarding flow
- ✅ **Custom Journals**: Users create custom journals with their own names, manage (rename/delete/reorder)
- ✅ **Journaling Features**: Create, view, and edit journal entries
- ✅ **Multiple Input Methods**: Write (type), Scan (OCR from photos), and Speak (voice-to-text)
- ✅ **Search Functionality**: Search through all journal entries
- ✅ **List & Calendar Views**: Separate tabs showing all entries, clickable calendar dates
- ✅ **All Entries View**: View entries from all journals in one place
- ✅ **Dark Mode & Light Mode**: Full theme support with system preference
- ✅ **Customizable Dashboard**: Personalized greeting, weekly calendar, customizable widgets
- ✅ **Journal Templates**: Create templates with prompts and structure, journal-specific
- ✅ **Quick Entry Widgets**: Widgets based on templates that open pre-filled entries
- ✅ **Password/Face ID**: App lock using system authentication, toggle in settings
- ✅ **Goal Setting**: Create and track goals
- ✅ **Reminder System**: Morning and evening journaling reminders

---

## Technology Stack

### Frontend

- **SwiftUI** (iOS 16+)
- **MVVM Architecture Pattern**
- **Native iOS Design System**

### Backend

- **Firebase Authentication** (Google & Apple Sign-In)
- **Cloud Firestore** (NoSQL database)
- **Firebase Storage** (for future image support)

### Subscriptions

- **StoreKit 2** (native iOS subscriptions)
- **RevenueCat** (optional, recommended for easier management)

### Additional Frameworks

- **UserNotifications** (for reminder notifications)
- **GoogleSignIn SDK** (for Google authentication)
- **Vision Framework** (for OCR text recognition from images)
- **Speech Framework** (for voice-to-text transcription)
- **AVFoundation** (for camera access and photo capture)
- **LocalAuthentication** (for Face ID/Touch ID/passcode protection)

---

## Project Structure

```javascript
Chronicles/
├── Chronicles/
│   ├── App/
│   │   ├── ChroniclesApp.swift
│   │   └── AppDelegate.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Journal.swift (NEW - custom journals)
│   │   ├── JournalEntry.swift
│   │   ├── JournalTemplate.swift (NEW)
│   │   ├── Goal.swift
│   │   └── Subscription.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── PaywallViewModel.swift
│   │   ├── JournalViewModel.swift
│   │   ├── JournalListViewModel.swift (NEW)
│   │   ├── DashboardViewModel.swift (NEW)
│   │   ├── TemplateViewModel.swift (NEW)
│   │   └── GoalViewModel.swift
│   ├── Views/
│   │   ├── Onboarding/ (14 steps)
│   │   ├── Auth/
│   │   ├── Paywall/
│   │   ├── Dashboard/ (NEW)
│   │   │   ├── DashboardView.swift
│   │   │   ├── WeeklyCalendarView.swift
│   │   │   └── Widgets/
│   │   │       ├── QuickEntryWidget.swift
│   │   │       ├── DailyQuoteWidget.swift
│   │   │       └── WidgetContainer.swift
│   │   ├── Journals/ (NEW)
│   │   │   ├── JournalListView.swift (list of user's journals)
│   │   │   ├── JournalDetailView.swift (entries for a journal)
│   │   │   ├── CreateJournalView.swift
│   │   │   └── ManageJournalsView.swift
│   │   ├── Entries/
│   │   │   ├── AllEntriesView.swift (NEW - all entries across journals)
│   │   │   ├── EntriesListView.swift (NEW - list view tab)
│   │   │   ├── EntriesCalendarView.swift (NEW - calendar view tab)
│   │   │   ├── JournalEntryView.swift
│   │   │   ├── CreateEntryView.swift
│   │   │   └── EntryInputMethods/
│   │   │       ├── WriteEntryView.swift
│   │   │       ├── ScanEntryView.swift
│   │   │       └── SpeakEntryView.swift
│   │   ├── Templates/ (NEW)
│   │   │   ├── TemplatesListView.swift
│   │   │   ├── CreateTemplateView.swift
│   │   │   └── EditTemplateView.swift
│   │   ├── Goals/
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── SecuritySettingsView.swift (NEW - password/Face ID)
│   │   │   └── WidgetSettingsView.swift (NEW)
│   │   └── Main/
│   │       └── MainTabView.swift
│   ├── Services/
│   │   ├── FirebaseService.swift
│   │   ├── AuthService.swift
│   │   ├── SubscriptionService.swift
│   │   ├── OnboardingService.swift
│   │   ├── NotificationService.swift
│   │   ├── OCRService.swift
│   │   ├── SpeechService.swift
│   │   ├── SecurityService.swift (NEW - password/Face ID)
│   │   └── StorageService.swift
│   └── Utilities/
│       ├── Extensions/
│       ├── Constants.swift
│       └── Design/
│           ├── ColorTokens.swift (NEW - Papper color palette)
│           ├── TypographyTokens.swift (NEW - Font styles)
│           └── ShadowTokens.swift (NEW - Shadow styles)
├── Firebase/
│   └── GoogleService-Info.plist
└── README.md
```

---

## Core Features

### 1. Custom Journals System

**Journal Model**:

```swift
struct Journal {
    let id: String
    let userId: String
    let name: String
    let createdAt: Date
    let order: Int // For reordering
    let color: String? // Optional color coding
}
```

**Features**:

- **Create Custom Journals**: Users create journals with custom names
- **No Default Journal**: Users must create at least one journal before creating entries
- **Journal Management**:
- Rename journals
- Delete journals (with handling of entries - move to another journal or delete)
- Reorder journals (drag and drop)
- **Journal Selection**: When creating entries, users select which journal to add to
- **Journal-Specific Templates**: Templates are tied to specific journals

**UI Components**:

- `JournalListView`: List of all user's journals
- `JournalDetailView`: Shows entries for a specific journal
- `CreateJournalView`: Form to create new journal
- `ManageJournalsView`: Screen to rename/delete/reorder journals

---

### 2. All Entries View

**Features**:

- Shows entries from **all journals** in one chronological list
- Filter by journal type
- Search across all journals
- Same entry creation/editing capabilities
- Date-based organization

**UI**:

- `AllEntriesView`: Main view showing all entries
- Filter bar to filter by journal
- Search integration

---

### 3. List & Calendar Views

**Features**:

- **Separate Tabs**: List view and Calendar view as separate tabs
- **Show All Entries**: Both views show entries from all journals
- **List View**: Chronological list of all entries
- **Calendar View**:
- Monthly calendar display
- Indicators (dots) on dates with entries
- Clickable dates to view entries for that day
- Navigate between months

**UI Components**:

- `EntriesListView`: List view tab
- `EntriesCalendarView`: Calendar view tab
- Date selection and navigation

---

### 4. Customizable Dashboard

**Dashboard Design** (based on reference image):

- **Top Section**:
- Personalized greeting: "Good [Morning/Afternoon/Evening], [Name]!"
- Current date display: "FRIDAY 26 DECEMBER 2025"
- User profile icon (top right)
- **Weekly Calendar Selector**:
- Horizontal row showing week (Mo-Su with dates)
- Current day highlighted
- Clickable dates to view entries for that day
- **Widget Cards**:
- Customizable widget system
- Long press to drag and reorder
- Tap to configure widget settings
- Widgets show completion status (e.g., "Completed" if entry done today)

**Widget Types**:

- **Quick Entry Widgets**: Based on templates, open pre-filled entries when tapped
- **Daily Quote Widget**: Shows inspirational quotes
- **Future Widgets**: Expandable system for more widgets

**Features**:

- Widget layout saved per user
- Add/remove widgets
- Reorder widgets (long press drag)
- Configure widget settings (tap widget)
- Dashboard appears as main tab AND first screen after unlock

**UI Components**:

- `DashboardView`: Main dashboard screen
- `WeeklyCalendarView`: Weekly calendar selector
- `QuickEntryWidget`: Widget for quick entry from templates
- `DailyQuoteWidget`: Daily quote display widget
- `WidgetContainer`: Container for managing widgets

---

### 5. Journal Templates

**Template Model**:

```swift
struct JournalTemplate {
    let id: String
    let userId: String
    let journalId: String // Journal-specific
    let name: String
    let prompts: [String] // Questions/prompts
    let structure: String // Format/structure
    let createdAt: Date
}
```

**Features**:

- **Create Templates**: In dedicated settings screen
- **Template Content**:
- Prompts/questions (e.g., "What are your goals today?")
- Structure/format (sections, headings)
- **Journal-Specific**: Templates tied to specific journals
- **Used by Quick Entry Widgets**: Widgets can be created from templates

**UI Components**:

- `TemplatesListView`: List of templates for a journal
- `CreateTemplateView`: Form to create template
- `EditTemplateView`: Edit existing template

---

### 6. Quick Entry Widgets

**Features**:

- Widgets based on journal templates
- Display template name (e.g., "Morning reflection", "Goals for the day")
- Show completion status (e.g., "Completed" if entry created today)
- Tap widget to open pre-filled entry with template
- Users can add multiple widgets based on different templates
- Widgets appear on customizable dashboard

**Widget Behavior**:

- Shows template name and icon
- Displays status (Completed/Pending)
- Tapping opens `CreateEntryView` with template pre-filled
- Completion status updates based on entries created today

---

### 7. Password/Face ID Protection

**Features**:

- **Setup**: When user chooses to enable in settings (not during onboarding)
- **Toggle**: Settings toggle to enable/disable
- **Authentication**: Uses Apple's system passcode/biometrics
- Face ID / Touch ID (primary)
- Device passcode (automatic fallback)
- No custom password needed
- **Required on Launch**: If enabled, required every time app launches
- **Auto Fallback**: Automatically shows passcode option if biometric fails

**Implementation**:

- Uses `LocalAuthentication` framework
- Checks device biometric/passcode availability
- Prompts on app launch if enabled
- Stores preference in UserDefaults or Firestore

**UI Components**:

- `SecuritySettingsView`: Settings screen for security options
- `LockScreenView`: Lock screen with biometric/passcode prompt

---

### 8. Journaling Features (Enhanced)

**Journal Entry Model**:

```swift
struct JournalEntry {
    let id: String
    let userId: String
    let journalId: String // NEW - which journal it belongs to
    let templateId: String? // NEW - if created from template
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let inputMethod: String? // "write", "scan", "speak"
    let mood: String? // Optional
}
```

**Features**:

- **Create Entry**: Must select journal first (or create one)
- **Multiple Input Methods**:
- **Write**: Text input
- **Scan**: OCR from photos (Vision Framework)
- **Speak**: Voice-to-text (Speech Framework)
- **Template Support**: Create entry from template (pre-filled)
- **Entry List**: Chronological list per journal
- **All Entries View**: View entries from all journals
- **Search**: Full-text search across all entries
- **Edit/Delete**: Modify or remove entries
- **Firestore Sync**: Real-time sync

---

## Firebase Setup

### Firestore Collections

#### Users Collection

```javascript
users/
  {userId}/
  - email: String
  - displayName: String
  - preferredName: String
  - createdAt: Timestamp
  - onboardingCompleted: Bool
  - onboardingData: {...}
  - subscriptionStatus: String
  - securityEnabled: Bool (NEW - password/Face ID toggle)
  - dashboardLayout: Array (NEW - widget configuration)
```

#### Journals Collection (NEW)

```javascript
journals/
  {journalId}/
  - userId: String
  - name: String
  - createdAt: Timestamp
  - order: Int
  - color: String?
```

#### Journal Templates Collection (NEW)

```javascript
journalTemplates/
  {templateId}/
  - userId: String
  - journalId: String
  - name: String
  - prompts: [String]
  - structure: String
  - createdAt: Timestamp
```

#### Journal Entries Collection

```javascript
journalEntries/
  {entryId}/
  - userId: String
  - journalId: String (NEW)
  - templateId: String? (NEW)
  - title: String
  - content: String
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - inputMethod: String?
  - mood: String?
```

#### Goals Collection

```javascript
goals/
  {goalId}/
  - userId: String
  - title: String
  - description: String
  - targetDate: Timestamp
  - status: String
  - progress: Int
  - createdAt: Timestamp
```

---

## Implementation Phases

### Phase 1: Foundation

1. Create Xcode project
2. Set up Firebase project
3. Configure authentication providers
4. Set up Firestore database
5. Create basic app structure

### Phase 2: Authentication

1. Implement Google Sign-In
2. Implement Apple Sign-In
3. Create AuthService
4. Set up user profile creation
5. Test authentication flow

### Phase 3: Onboarding

1. Create onboarding view structure
2. Implement 14-step navigation
3. Build each onboarding screen
4. Create OnboardingService
5. Implement data collection

### Phase 4: Subscription System

1. Set up StoreKit 2
2. Create subscription products
3. Implement SubscriptionService
4. Build paywall UI
5. Integrate purchase flow
6. Implement subscription gating

### Phase 5: Custom Journals System

1. Create Journal model
2. Build FirebaseService for journals
3. Create JournalListView
4. Create CreateJournalView
5. Implement journal management (rename/delete/reorder)
6. Update entry creation to require journal selection

### Phase 6: Journaling Features

1. Update JournalEntry model (add journalId)
2. Build FirebaseService for entries
3. Create entry creation with journal selection
4. Implement multiple input methods (write/scan/speak)
5. Create entry list view per journal
6. Implement real-time sync

### Phase 7: All Entries & Views

1. Create AllEntriesView
2. Implement filtering by journal
3. Create List view tab
4. Create Calendar view tab
5. Implement clickable calendar dates
6. Add search functionality

### Phase 8: Journal Templates

1. Create JournalTemplate model
2. Build template creation in settings
3. Implement template storage in Firestore
4. Create template selection when creating entry
5. Pre-fill entry from template

### Phase 9: Dashboard System

1. Create DashboardView
2. Implement personalized greeting
3. Build WeeklyCalendarView
4. Create widget system architecture
5. Implement widget drag and drop
6. Create DailyQuoteWidget

### Phase 10: Quick Entry Widgets

1. Create QuickEntryWidget component
2. Link widgets to templates
3. Implement completion status tracking
4. Connect widget tap to entry creation
5. Add widget configuration

### Phase 11: Password/Face ID

1. Implement SecurityService using LocalAuthentication
2. Create SecuritySettingsView
3. Add toggle for security feature
4. Create LockScreenView
5. Implement app launch protection
6. Test biometric and passcode flows

### Phase 12: Goal Features

1. Create Goal model
2. Build FirebaseService for goals
3. Create goals list view
4. Create goal detail/edit view
5. Implement progress tracking

### Phase 13: Main Navigation

1. Create MainTabView with tabs:

- Dashboard
- All Entries (with List/Calendar sub-tabs)
- Journals
- Goals
- Settings

2. Integrate all features
3. Implement navigation flow

### Phase 14: Design System Implementation

1. Create ColorTokens.swift with Papper color palette
2. Create TypographyTokens.swift with font styles
3. Create ShadowTokens.swift with shadow styles
4. Implement gradient backgrounds for light/dark modes
5. Apply design tokens throughout app
6. Test color contrast and accessibility
7. Verify design consistency across all screens

### Phase 15: Polish & Testing

1. Add loading states
2. Implement error handling
3. Add empty states
4. Test complete user flow
5. Test dark mode and light mode
6. Test all input methods
7. Test search functionality
8. Test permissions
9. Optimize performance
10. Test offline functionality
11. Verify design token implementation

---

## UI/UX Design Considerations

### Design System: Papper Design Library

The app follows the **Papper Design Library** style guide with soft, calming aesthetics perfect for a journaling app.

### Design Principles

- **Minimalist Aesthetic**: Clean, uncluttered interface
- **Journaling Focus**: Calming, reflective design with soft pastel colors
- **Modern iOS Design**: Follows iOS Human Interface Guidelines
- **Accessibility**: VoiceOver support, dynamic type
- **Dark Mode & Light Mode**: Full theme support with adaptive gradients
- Automatic system preference detection
- Smooth theme transitions

### Color Palette

**Primary Color**:

- **Coral/Red Accent**: `#FF6B6B` - Primary accent color for CTAs, highlights, and interactive elements

**Gradients** (Background):

- **Light Mode**: Conic gradient with soft pastels
        - `#f7d9d9` (6.5%) - Soft pink
        - `#efe1e8` (3.5%) - Lavender
        - `#e1e5ef` (87.5%) - Soft blue-gray
- **Dark Mode**: Conic gradient with warmer tones
        - `#f7baba` (6.5%) - Warm pink
        - `#d9c8ea` (3.5%) - Purple
        - `#ffccb3` (87.5%) - Peach

**Shadows**:

- **Slight Shadow**: Subtle drop shadow for depth
        - Color: `#e0000033` (transparent black)
        - Offset: (0, 1)
        - Blur: 4px
        - Spread: 0

### Typography

**Font Families**:

- **SF Pro** (Primary): Native iOS font for body text, headers, and UI elements
- **New York Medium**: Serif font for paywall titles and special headings
- **IBM Plex Mono**: Monospace font for code or technical content
- **Hacky**: Custom font (if available)

**Font Sizes**:

- **Header 2**: 24px (semibold, 600 weight)
- **Body Title**: 16px (medium, 500 weight)
- **Body**: 14px (regular, 400 weight)
- **Body Discovery**: 13px (regular, 400 weight)
- **Body Small**: 11px (regular, 400 weight)
- **Paywall Title**: 18px (bold, 700 weight) - New York Medium
- **Paywall Subtitle**: 12px (regular, 400 weight)
- **Code Mono**: 12px (regular, 400 weight) - IBM Plex Mono

**Text Styles**:

- Headers use SF Pro, 600 weight
- Body text uses SF Pro, 400 weight
- Titles use SF Pro, 500 weight
- Paywall uses New York Medium for titles (700 weight) and SF Pro for subtitles

### Visual Design Guidelines

**Color Usage**:

- Primary coral (`#FF6B6B`) for buttons, links, and interactive elements
- Soft gradient backgrounds create calming atmosphere
- High contrast text for readability
- Adaptive colors for light/dark modes

**Component Styling**:

- Rounded corners for cards and buttons
- Subtle shadows for depth and elevation
- Soft, pastel color palette throughout
- Clean spacing and padding

**Dashboard Design**:

- Personalized greeting with time-based message
- Weekly calendar with highlighted current day (using primary color)
- Widget cards with icons and status indicators
- Long press to reorder widgets
- Tap widgets to configure or use
- Gradient backgrounds for visual interest

**Paywall Design**:

- New York Medium serif font for titles (elegant, premium feel)
- SF Pro for subtitles and body text
- Coral accent color for CTAs
- Soft gradient backgrounds

---

## Dependencies

- Firebase iOS SDK
- GoogleSignIn SDK
- StoreKit 2 (or RevenueCat SDK)
- SwiftUI (native)
- UserNotifications framework
- Vision Framework
- Speech Framework
- AVFoundation
- LocalAuthentication framework

---

## Configuration Files Needed

- `GoogleService-Info.plist` (from Firebase Console)
- App Store Connect configuration for subscriptions
- Info.plist permissions:
- Camera usage description
- Microphone usage description
- Speech recognition usage description
- Xcode Capabilities:
- Sign in with Apple
- In-App Purchase
- Camera
- Microphone
- Speech Recognition

---