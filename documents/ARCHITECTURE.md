# Architecture Document - Finsify

## 1. Architectural Overview

Finsify is built on a clean, layered Flutter architecture prioritizing local-first data privacy, high rendering performance (60/120 FPS), and cross-platform flexibility across Mobile, Desktop, and Web.

```text
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  - ExpenseDashboard, ProfileScreen, SplashScreen            │
│  - FinancialPage (Investments, Loans, Bills)                │
│  - Lazy Rendering: CustomScrollView + SliverList.builder    │
│  - Dialogs with safe transition lifecycle management        │
└──────────────────────────────┬──────────────────────────────┘
                               │ State Binding & Events
                               v
┌─────────────────────────────────────────────────────────────┐
│                    CONTROLLER LAYER                         │
│  - ExpenseController (ChangeNotifier)                       │
│      └─ Query/Filter Memoization (_visibleDirty cache)      │
│  - FinancialController (ChangeNotifier)                     │
│      └─ Legacy SharedPreferences auto-migrator              │
└──────────────────────────────┬──────────────────────────────┘
                               │ Method Calls
                               v
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                          │
│  - DatabaseService (Singleton SQLite abstraction)           │
│  - VoiceRecognitionService (Offline speech-to-text parsing)  │
│  - SmsExpenseImporter (Regex rule-based SMS extraction)     │
│  - BillReminderService (Local OS notification scheduling)   │
│  - XlsxExportService (Spreadsheet generation)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ Type-Safe Queries
                               v
┌─────────────────────────────────────────────────────────────┐
│                 STORAGE LAYER (DRIFT ORM)                   │
│  - AppDatabase (Type-safe Drift SQLite)                     │
│  - Tables: Profiles, Expenses, Investments, Loans, Bills,    │
│            AppSettings                                      │
│  - Native: finsify.sqlite (via sqlite3_flutter_libs)        │
│  - Web: sqlite3.wasm + drift_worker.js (via IndexedDB)      │
│  - Tests: NativeDatabase.memory()                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Layers and Responsibilities

| Layer | Primary Components | Key Responsibilities |
|---|---|---|
| **Presentation** | [`lib/main.dart`](file:///e:/finsify/lib/main.dart), [`lib/widgets/financial_pages.dart`](file:///e:/finsify/lib/widgets/financial_pages.dart), [`lib/screens/profile_screen.dart`](file:///e:/finsify/lib/screens/profile_screen.dart) | Material 3 UI rendering, user interaction, input forms, responsive layout, chart visualization, and lazy list virtualisation via slivers. |
| **Controllers** | [`lib/controllers/expense_controller.dart`](file:///e:/finsify/lib/controllers/expense_controller.dart), [`lib/controllers/financial_controller.dart`](file:///e:/finsify/lib/controllers/financial_controller.dart) | State management (`ChangeNotifier`), presentation logic, in-memory filtering/sorting cache, CRUD coordination, and legacy data migration. |
| **Services** | [`lib/services/database_service.dart`](file:///e:/finsify/lib/services/database_service.dart), [`lib/services/voice_recognition_service.dart`](file:///e:/finsify/lib/services/voice_recognition_service.dart), [`lib/services/sms_expense_importer.dart`](file:///e:/finsify/lib/services/sms_expense_importer.dart), [`lib/services/financial_services.dart`](file:///e:/finsify/lib/services/financial_services.dart) | Peripheral hardware interfaces (Microphone, SMS, Notifications), file serialization (Excel XLSX), and persistent database operations. |
| **Storage** | [`lib/database/app_database.dart`](file:///e:/finsify/lib/database/app_database.dart) | Drift SQLite relational tables, schema migrations, and cross-platform database connection initialization (Native SQLite & Web WASM). |

---

## 3. Key Design Decisions

### 3.1 Type-Safe Persistence with Drift
- Replaced previous in-memory and `sqflite` persistence with **Drift**.
- Provides compile-time query verification, typed data classes (`DbProfile`, `DbExpense`, etc.), and automatic schema management.
- Works consistently across mobile devices, desktop OSes, and web browsers via WASM + IndexedDB.

### 3.2 High-Performance Rendering & Caching
- **Lazy Slivers:** Viewports use `CustomScrollView` and `SliverList.builder` instead of non-virtualized `ListView(children: ...)`. Rows are instantiated on-demand and recycled during scrolling, preventing garbage-collection pauses and stuttering on budget hardware.
- **Memoized Filtering:** `ExpenseController` caches visible filtered and sorted items with a dirty flag (`_visibleDirty`). The $O(N \log N)$ sorting and filtering logic only runs when expenses or filter criteria actually change, not during routine widget rebuilds.

### 3.3 Safe Controller Lifecycle
- Text controllers used in modal dialogs defer disposal by 500ms following `Navigator.pop`. This allows route exit animations to fully unmount before controller disposal, preventing `RawGestureDetector` assertion crashes.

### 3.4 Local-First Privacy
- All financial information (profile, budget, expenses, investments, loans, bills) resides strictly on the local device in SQLite.
- No network analytics, cloud sync, or remote server endpoints are utilized.

---

## 4. Testing & Testability

- `DatabaseService` allows injecting custom `AppDatabase` instances (e.g. `NativeDatabase.memory()`).
- Controller and widget tests execute against fast, isolated in-memory SQLite instances without writing to disk or interfering with user data.
- Standard test suite:
  - `test/database_service_test.dart`: Validates Drift SQLite CRUD and restart state restoration.
  - `test/financial_controller_test.dart`: Validates financial modules and persistence.
  - `test/financial_item_test.dart`: Unit tests EMI, interest, and investment math.
  - `test/voice_expense_parser_test.dart`: Validates offline voice-to-expense parsing.
  - `test/widget_test.dart`: Validates UI flow, navigation, theme toggle, and startup routing.
