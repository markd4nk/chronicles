---
name: iOS Journaling App MVP
overview: Build a native iOS journaling app with Firebase backend, featuring comprehensive 14-step onboarding, authentication (Google/Apple), paywall with 3-day free trial, and subscription management (monthly/yearly). MVP includes customizable journals, multiple input methods (write/scan/speak), customizable dashboard with widgets, TikTok-style prompts feed, AI reflect/analyze feature with conversational interface, journal templates, list/calendar views, search functionality, and password/Face ID protection.
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
    content: Define Firestore data models (User, JournalEntry, Journal, JournalTemplate, JournalPrompt, AIConversation, AIMessage) and security rules
    status: pending
    dependencies:
      - setup-project
  - id: journal-features
    content: Build journal entry creation with multiple input methods (write/scan/speak), list view, search functionality, and detail/edit functionality with Firestore sync
    status: pending
    dependencies:
      - firestore-models
  - id: ocr-service
    content: Create OCR input UI placeholder (button/structure ready for GPT integration - not using Vision Framework)
    status: pending
    dependencies:
      - setup-project
  - id: speech-service
    content: Create Speech input UI placeholder (button/structure ready for GPT integration - not using Speech Framework)
    status: pending
    dependencies:
      - setup-project
  - id: search-feature
    content: Implement search functionality for journal entries with real-time results and highlighting
    status: pending
    dependencies:
      - journal-features
  - id: main-navigation
    content: Create main tab view with 5-button navigation (Dashboard, AI Reflect, +, All Entries, Prompts)
    status: pending
    dependencies:
      - journal-features
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
  - id: streak-tracking
    content: Implement streak tracking system - calculate and store current journaling streak based on consecutive days with entries
    status: pending
    dependencies:
      - journal-features
  - id: dashboard-system
    content: Build dashboard/home page with streak counter (top left), profile/settings button (top right), welcome message, and clickable widgets for quick journal entry creation
    status: pending
    dependencies:
      - custom-journals
      - streak-tracking
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
  - id: prompts-feature
    content: Build TikTok-style prompts feature - swipeable feed of journal prompts (questions, reflections, quotes) with "Write it Out" button to create entries, like/share functionality, and "For You" personalized curation
    status: pending
    dependencies:
      - journal-features
      - custom-journals
  - id: ai-reflect-feature
    content: Build AI reflect/analyze UI - conversational interface ready for GPT API integration (chat UI, journal selection, insights display)
    status: pending
    dependencies:
      - journal-features
      - custom-journals
---

# Chronicles - iOS Journaling App MVP

## Project Overview

**Chronicles** is a native iOS journaling app built with SwiftUI and Firebase. The app requires a subscription (no free tier) with a 3-day free trial. Users go through an extensive 14-step onboarding process that personalizes their experience and collects preferences.

### Key Requirements

- ✅ **No Free Tier**: Users must subscribe to use the app
- ✅ **3-Day Free Trial**: Full feature access during trial period
- ✅ **Monthly & Yearly Subscriptions**: Two subscription options
- ✅ **Google & Apple Sign-In**: Authentication options
- ✅ **Comprehensive Onboarding**: 14-step personalized onboarding flow
- ✅ **Custom Journals**: Users create custom journals with their own names, manage (rename/delete/reorder)
- ✅ **5-Button Tab Bar Navigation**: Dashboard, AI Reflect, + button (center), All Entries, Prompts
- ✅ **Central + Button**: Prominent + button in center of tab bar opens journal selection for entry creation
- ✅ **Journal Selection Flow**: When creating entry, user selects existing journal or creates new one from selection screen
- ✅ **Settings Access**: Settings accessed via profile button on Dashboard (not a separate tab)
- ✅ **Journaling Features**: Create, view, and edit journal entries
- ✅ **Multiple Input Methods**: Write (type), Scan (UI placeholder ready for GPT OCR), and Speak (UI placeholder ready for GPT speech-to-text)
- ✅ **Search Functionality**: Search through all journal entries
- ✅ **List & Calendar Views**: Separate tabs showing all entries, clickable calendar dates
- ✅ **All Entries View**: View entries from all journals in one place
- ✅ **Dark Mode & Light Mode**: Full theme support with system preference
- ✅ **Dashboard/Home Page**: Streak counter, welcome message, and clickable widgets for quick entry creation
- ✅ **Journal Templates**: Create templates with prompts and structure, journal-specific
- ✅ **Quick Entry Widgets**: Widgets based on templates that open pre-filled entries
- ✅ **Password/Face ID**: App lock using system authentication, toggle in settings
- ✅ **Reminder System**: Morning and evening journaling reminders
- ✅ **Journal Management**: View, rename, delete, and reorder journals from All Entries view
- ✅ **Templates Management**: Create and manage journal templates in Settings
- ✅ **Widget Configuration**: Configure dashboard widgets from Dashboard (long press or edit mode)
- ✅ **TikTok-Style Prompts Feed**: Swipeable feed of journal prompts (questions, reflections, quotes) with "Write it Out" button, like/share functionality, and personalized "For You" curation
- ✅ **AI Reflect/Analyze**: AI agent analyzes user's journals and provides conversational interface for reflection, analysis, and thinking support

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
- **AI API Integration** (OpenAI API or similar for journal analysis and conversational AI)

### Subscriptions

- **StoreKit 2** (native iOS subscriptions)
- **RevenueCat** (optional, recommended for easier management)

### Additional Frameworks

- **UserNotifications** (for reminder notifications)
- **GoogleSignIn SDK** (for Google authentication)
- **AVFoundation** (for camera access and photo capture - for OCR UI)
- **LocalAuthentication** (for Face ID/Touch ID/passcode protection)
- **GPT API** (to be integrated later for OCR, speech-to-text, and AI analysis)

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
│   │   ├── JournalPrompt.swift (NEW - prompts for feed)
│   │   ├── AIConversation.swift (NEW - AI chat conversation)
│   │   ├── AIMessage.swift (NEW - individual AI chat messages)
│   │   └── Subscription.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── PaywallViewModel.swift
│   │   ├── JournalViewModel.swift
│   │   ├── JournalListViewModel.swift (NEW)
│   │   ├── DashboardViewModel.swift (NEW)
│   │   ├── TemplateViewModel.swift (NEW)
│   │   ├── PromptsViewModel.swift (NEW - prompts feed)
│   │   └── AIReflectViewModel.swift (NEW - AI reflect/analyze)
│   ├── Views/
│   │   ├── Onboarding/ (14 steps)
│   │   ├── Auth/
│   │   ├── Paywall/
│   │   ├── Dashboard/ (NEW)
│   │   │   ├── DashboardView.swift
│   │   │   ├── StreakCounterView.swift
│   │   │   └── Widgets/
│   │   │       └── QuickEntryWidget.swift
│   │   ├── Journals/ (NEW)
│   │   │   ├── JournalListView.swift (list of user's journals)
│   │   │   ├── JournalDetailView.swift (entries for a journal)
│   │   │   ├── CreateJournalView.swift
│   │   │   ├── JournalSelectionView.swift (NEW - journal selection for entry creation)
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
│   │   ├── Prompts/ (NEW)
│   │   │   ├── PromptsFeedView.swift
│   │   │   ├── PromptCardView.swift
│   │   │   └── ForYouView.swift
│   │   ├── AIReflect/ (NEW)
│   │   │   ├── AIReflectView.swift
│   │   │   ├── AIChatView.swift
│   │   │   └── JournalInsightsView.swift
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
│   │   ├── AIService.swift (NEW - AI journal analysis and chat)
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
- **Journal Management**: Access to manage journals (rename, delete, reorder) from this view

**UI**:

- `AllEntriesView`: Main view showing all entries
- Filter bar to filter by journal
- Search integration
- Journal management interface (rename, delete, reorder)

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

### 4. Dashboard/Home Page

**Dashboard Layout**:

- **Top Bar**:
- **Top Left**: Streak counter (displays current journaling streak)
- **Top Right**: Profile/Settings button (navigates to settings)
- **Welcome Message**: Simple welcome message displayed at the top
- **Widgets Section**: 
- Widgets displayed below welcome message
- Each widget represents a quick entry option (e.g., "Morning Goal", "Reflection")
- Clicking a widget opens journal entry creation directly
- Widgets are based on templates (e.g., morning reflection template creates a morning reflection widget)

**Widget Behavior**:

- Widgets are clickable and open `CreateEntryView` with template pre-filled
- Widgets can be created from journal templates
- Example: Creating a "Morning Goal" template allows user to add a "Morning Goal" widget to dashboard
- Tapping widget creates a new journal entry using that template

**UI Components**:

- `DashboardView`: Main dashboard/home page screen
- `StreakCounterView`: Displays current journaling streak
- `QuickEntryWidget`: Widget component for quick entry creation from templates

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

- **Create Templates**: In Settings screen
- **Template Content**:
- Prompts/questions (e.g., "What are your goals today?")
- Structure/format (sections, headings)
- **Journal-Specific**: Templates tied to specific journals
- **Used by Quick Entry Widgets**: Widgets can be created from templates

**UI Components**:

- `TemplatesListView`: List of templates for a journal (accessible from Settings)
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
- **Widget Configuration**: Configure widgets from Dashboard (long press or edit mode)

**Widget Behavior**:

- Shows template name and icon
- Displays status (Completed/Pending)
- Tapping opens `CreateEntryView` with template pre-filled
- Completion status updates based on entries created today
- Long press or edit mode on Dashboard to add/remove/reorder widgets

---

### 7. TikTok-Style Prompts Feed

**Prompt Model**:

```swift
struct JournalPrompt {
    let id: String
    let question: String // Main prompt question
    let hint: String // Descriptive hint/guidance
    let category: String // "question", "reflection", "quote", etc.
    let createdAt: Date
    let likes: Int // Number of likes
    let shares: Int // Number of shares
}
```

**Features**:

- **TikTok-Style Swipeable Feed**: Vertical swipeable feed of journal prompts
- **Prompt Types**: Questions, reflections, deep quotes, and other inspirational prompts
- **Top Navigation**:
- "For You" button (centered) - personalized curated prompts
- Paintbrush icon (right) - customization options
- Play button icon (right) - audio playback of prompt (optional)
- **Prompt Display**:
- Lightbulb icon at top
- Large, bold prompt question
- Descriptive hint below question
- Action bar at bottom with:
                - Share icon (left)
                - "Write it Out" button (center) - opens entry creation with prompt pre-filled
                - Heart icon (right) - like/save prompt
- **Interaction**:
- Swipe up/down to navigate between prompts
- Tap "Write it Out" to create journal entry with prompt as starting point
- Like prompts to save them
- Share prompts
- **Personalization**: "For You" section shows curated prompts based on user preferences

**UI Components**:

- `PromptsFeedView`: Main swipeable feed view
- `PromptCardView`: Individual prompt card component
- `ForYouView`: Personalized prompts view

---

### 8. AI Reflect/Analyze Feature

**AI Conversation Model**:

```swift
struct AIConversation {
    let id: String
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let messages: [AIMessage]
}

struct AIMessage {
    let id: String
    let role: String // "user" or "assistant"
    let content: String
    let createdAt: Date
}
```

**Features**:

- **Journal Selection**: User selects which journals to analyze (not all automatically)
- **Manual Analysis Trigger**: User taps a button to start AI analysis (not automatic on page open)
- **AI Journal Analysis**: AI agent analyzes selected journal entries
- **Conversational Interface**: Chat-based interface for talking with AI about journal insights
- **Reflection Support**: AI helps users think through patterns, themes, and insights from their journals
- **Journal Insights**: AI provides analysis of:
- Patterns and themes across entries
- Emotional trends
- Recurring topics
- Growth and progress over time
- **Interactive Chat**: Users can ask questions and have conversations with AI about their journaling
- **Conversation History**: Previous conversations are saved and can be reviewed
- **Context Awareness**: AI has access to selected journal entries for context-aware responses

**UI Components**:

- `AIReflectView`: Main reflect/analyze page
- `AIChatView`: Chat interface for conversing with AI
- `JournalInsightsView`: Display of AI-generated insights and analysis
- Journal selection interface for choosing which journals to analyze

**Navigation**:

- Accessible via "AI Reflect" tab in main tab bar (5-button navigation)
- Opens full-screen reflect/analyze interface

---

### 12. Password/Face ID Protection

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

### 10. Journal Selection & Entry Creation Flow

**Journal Selection View**:

- **Trigger**: Central + button in tab bar
- **Layout**: 
- List of existing journals (e.g., "Reflection", "Dream Journal", etc.)
- Each journal shows name and can be tapped to select
- "Add New Journal" button/card at bottom or top of list
- **Flow**:

1. User taps + button in tab bar
2. JournalSelectionView appears (modal or navigation)
3. User can:

                - **Select existing journal**: Tap on journal → opens CreateEntryView for that journal
                - **Create new journal**: Tap "Add New Journal" → opens CreateJournalView → after creation, opens CreateEntryView for new journal
- **Empty State**: If user has no journals, show "Create Your First Journal" prompt

**UI Components**:

- `JournalSelectionView`: Modal/sheet showing journal list with "Add New Journal" option
- `JournalSelectionCard`: Individual journal card in selection view

---

### 11. Journaling Features (Enhanced)

**Journal Entry Model**:

```swift
struct JournalEntry {
    let id: String
    let userId: String
    let journalId: String // NEW - which journal it belongs to
    let templateId: String? // NEW - if created from template
    let promptId: String? // NEW - if created from prompt feed
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let inputMethod: String? // "write", "scan", "speak"
    let mood: String? // Optional
}
```

**Features**:

- **Create Entry**: Entry creation always starts with journal selection (via + button or other entry points)
- **Multiple Input Methods**:
- **Write**: Text input (fully implemented)
- **Scan**: OCR input UI placeholder (button/structure ready for GPT OCR integration)
- **Speak**: Speech input UI placeholder (button/structure ready for GPT speech-to-text integration)
- **Template Support**: Create entry from template (pre-filled)
- **Prompt Support**: Create entry from prompt feed (pre-filled with prompt question)
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
 - currentStreak: Int (NEW - current journaling streak count)
 - lastEntryDate: Timestamp (NEW - date of last journal entry for streak calculation)
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
 - promptId: String? (NEW - if created from prompt feed)
 - title: String
 - content: String
 - createdAt: Timestamp
 - updatedAt: Timestamp
 - inputMethod: String?
 - mood: String?
```

#### Journal Prompts Collection (NEW)

```javascript
journalPrompts/
  {promptId}/
 - question: String
 - hint: String
 - category: String ("question", "reflection", "quote", etc.)
 - createdAt: Timestamp
 - likes: Int
 - shares: Int
```

#### User Liked Prompts Collection (NEW)

```javascript
userLikedPrompts/
  {userId}/
 - likedPromptIds: [String] // Array of prompt IDs user has liked
```

#### AI Conversations Collection (NEW)

```javascript
aiConversations/
  {conversationId}/
 - userId: String
 - createdAt: Timestamp
 - updatedAt: Timestamp
```

#### AI Messages Collection (NEW)

```javascript
aiMessages/
  {messageId}/
 - conversationId: String
 - userId: String
 - role: String ("user" or "assistant")
 - content: String
 - createdAt: Timestamp
```

---**Note**: Prompts can be either:

- **Global Prompts**: Pre-populated prompts available to all users (stored in `journalPrompts` collection)
- **User-Specific**: Users can like prompts, tracked in `userLikedPrompts` collection

**Note**: AI Conversations:

- Each conversation contains multiple messages
- AI has access to user's journal entries for context
- Conversations are stored per user for privacy

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
3. Create JournalSelectionView (journal selection screen with "Add New Journal" option)
4. Create entry creation flow (journal selection → CreateEntryView)
5. Implement multiple input methods:

            - **Write**: Full text input implementation
            - **Scan**: UI placeholder (button/structure ready for GPT OCR integration)
            - **Speak**: UI placeholder (button/structure ready for GPT speech-to-text integration)

6. Create entry list view per journal
7. Implement real-time sync

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
2. Implement streak counter (top left)
3. Add profile/settings button (top right)
4. Add welcome message
5. Create widget system for quick entry widgets
6. Implement widget click to open entry creation

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

### Phase 12: Prompts Feed

1. Create JournalPrompt model
2. Build PromptsFeedView with swipeable interface
3. Implement PromptCardView component
4. Add "For You" personalized curation
5. Implement like/share functionality
6. Connect "Write it Out" button to entry creation
7. Store prompts in Firestore
8. Track user liked prompts

### Phase 13: AI Reflect/Analyze Feature

**Note**: UI will be fully built and ready. GPT API integration will be added later.

1. Create AIConversation and AIMessage models
2. Build AIService structure (placeholder methods ready for GPT API integration)
3. Create journal selection interface (user selects which journals to analyze)
4. Implement manual analysis trigger button (user taps to start analysis)
5. Create AIReflectView (main reflect/analyze page)
6. Build AIChatView (conversational interface - fully functional UI)
7. Create JournalInsightsView (display AI insights - UI ready)
8. Implement conversation history storage in Firestore
9. Add placeholder for GPT API integration (methods ready, API calls to be added)
10. Test UI and navigation flow

### Phase 14: Main Navigation

1. Create MainTabView with 5-button tab bar:

- **Dashboard** (left) - Home page with streak counter, welcome message, widgets
- **AI Reflect** - Reflect/analyze page with AI conversational interface
- **+ button** (center, prominent) - Opens journal selection for entry creation
- **All Entries** - View all entries with List/Calendar sub-tabs
- **Prompts** (right) - TikTok-style swipeable prompts feed

2. Create JournalSelectionView - shows list of existing journals with "Add New Journal" option
3. Implement + button tap flow:

- Tap + button → JournalSelectionView
- User selects existing journal OR taps "Add New Journal"
- If existing journal selected → CreateEntryView for that journal
- If "Add New Journal" → CreateJournalView → then CreateEntryView for new journal

4. Settings access: Profile button on Dashboard → SettingsView
5. Integrate all features
6. Implement navigation flow

**Note**: Journals are accessible via + button flow (journal selection) and can be managed (rename, delete, reorder) from All Entries view.

### Phase 15: Design System Implementation

**Design Reference**: Match `chronicles-preview.html` design exactly

1. Use existing PapperDesignSystem.swift and PapperUIComponents.swift (already created)
2. Apply design tokens throughout app:

            - Neutral colors (#414141 accent, warm paper backgrounds #faf8f3 light / #2a2823 dark)
            - Dashboard layout: streak badge (top left), settings gear (top right), welcome message, 2x2 widget grid
            - Tab bar: Home, Reflect, + button (center), Entries, Prompts
            - SF Symbols only (no emojis)
            - Clean, minimal spacing and typography

3. Implement light/dark mode support
4. Test color contrast and accessibility
5. Verify design matches preview HTML exactly

### Phase 16: Polish & Testing

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
- **Journaling Focus**: Calming, reflective design with neutral black and white palette
- **Modern iOS Design**: Follows iOS Human Interface Guidelines
- **Accessibility**: VoiceOver support, dynamic type
- **Dark Mode & Light Mode**: Full theme support with warm paper backgrounds
- Automatic system preference detection
- Smooth theme transitions
- **No Emojis**: Use SF Symbols for all icons

### Color Palette

**Primary Colors**:

- **Neutral Accent**: `#414141` (neutral700) - Primary accent color for CTAs, buttons, and interactive elements
- **Pure Black**: `#000000` (neutral1000) - For text and strong accents
- **White**: `#ffffff` (neutral000) - For surfaces and backgrounds

**Backgrounds**:

- **Light Mode**: Warm paper background `#faf8f3` with white surfaces `#ffffff`
- **Dark Mode**: Neutral dark background `#272727` (neutral-900) with elevated surfaces `#333333` (neutral-800)

**Shadows**:

- **Slight Shadow**: Subtle drop shadow for depth
                                                                - Color: `rgba(0, 0, 0, 0.08)` (transparent black)
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

- Primary neutral gray (`#414141`) for buttons, links, and interactive elements
- Warm paper backgrounds create calming atmosphere
- High contrast text for readability
- Adaptive colors for light/dark modes

**Component Styling**:

- Rounded corners for cards and buttons
- Subtle shadows for depth and elevation
- Clean, neutral color palette throughout (black, white, grays)
- Clean spacing and padding

**Dashboard Design**:

- Streak counter in top left corner
- Profile/settings button in top right corner
- Simple welcome message at the top
- Widget cards below welcome message
- Click widgets to create journal entries directly
- Gradient backgrounds for visual interest

**Paywall Design**:

- New York Medium serif font for titles (elegant, premium feel)
- SF Pro for subtitles and body text
- Neutral gray accent color for CTAs
- Warm paper backgrounds

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
- GPT API (to be integrated later) for OCR, speech-to-text, and journal analysis/conversational AI

---

## Configuration Files Needed

- `GoogleService-Info.plist` (from Firebase Console)
- App Store Connect configuration for subscriptions
- Info.plist permissions:
- Camera usage description (for OCR photo capture UI)
- Microphone usage description (for speech input UI)