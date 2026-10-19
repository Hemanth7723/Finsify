# Flutter Migration Specification - Expensify

## 1. Purpose

This specification defines the target Flutter implementation behavior for the Android Kotlin application in `Source`. It separates compatibility requirements from implementation choices so the migration can be planned without changing product behavior accidentally.

## 2. Target Product Boundary

The Flutter app must preserve the current single-user, local-first expense tracker:

- Splash, onboarding/profile, dashboard, expense editor, voice entry, analytics, and profile/settings flows.
- Manual expense CRUD available without network access.
- Optional Gemini transcript parsing and spending insights.
- CSV export with the same columns and escaping behavior.
- Currency-symbol preference without currency conversion.

Authentication, cloud sync, Firebase, receipts, budgets, recurring expenses, and XLSX export are not migration requirements because they are absent from the source implementation.

## 3. Recommended Target Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  core/
    errors/
    security/
    networking/
  features/
    onboarding/
    expenses/
    analytics/
    voice_entry/
    insights/
    export/
  shared/
    models/
    widgets/
```

The exact state-management package is a planning decision. The implementation must retain one-way flow from UI to state/application services to repositories and data sources.

## 4. Kotlin-to-Dart Mapping

| Kotlin source | Flutter responsibility |
| --- | --- |
| `MainActivity.kt` | `MaterialApp` shell, routes, Compose screen equivalents |
| `ExpenseViewModel` | Feature controller/notifier; expose immutable UI state |
| `Expense` | Immutable Dart expense model with JSON/database mapping |
| `ExpenseDao` | Local database DAO/repository interface |
| `ExpenseDatabase` | SQLite database provider |
| `ExpenseRepository` | Expense repository and CSV formatter |
| `PreferencesManager` | Preferences plus secure profile storage service |
| `CryptoManager` | Platform secure storage abstraction |
| `VoiceRecognizerHelper` | Speech recognition service abstraction |
| `GeminiService.kt` | Gemini HTTP client and DTOs |

## 5. Compatibility Rules

1. Preserve expense field names and timestamp semantics: epoch milliseconds.
2. Preserve default currency `₹`, default theme light, and onboarding default false.
3. Preserve category names exactly, including `Miscellaneous`.
4. Preserve sort semantics and case-insensitive category filtering.
5. Preserve the 30-expense limit for insight prompts.
6. Keep API keys out of logs, exports, analytics prompts beyond the request authorization query, and crash reports.
7. Treat old Android data import as a separate task; no cross-platform database file compatibility is assumed.

## 6. Migration Decisions Required Before Coding

- State-management package and lifecycle conventions.
- SQLite package and schema migration policy.
- Android/iOS support scope and minimum OS versions.
- Speech recognition package and permission UX.
- CSV file/share package.
- Gemini model/version configuration and response validation policy.
- Whether existing Android users receive an import tool or start with a new Flutter database.