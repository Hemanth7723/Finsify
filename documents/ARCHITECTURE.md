# Architecture Document - Expensify

## Architectural Style

The source uses a pragmatic MVVM architecture with a repository boundary and reactive state. It is not currently a Flutter Clean Architecture or BLoC implementation.

## Layers

| Layer | Source responsibility |
| --- | --- |
| Presentation | `MainActivity.kt` Compose screens, dialogs, charts, forms, and navigation state |
| Presentation state | `ExpenseViewModel`: StateFlow filters/theme/currency, profile state, CRUD orchestration, analytics, AI state |
| Repository | `ExpenseRepository`: delegates CRUD to DAO and generates CSV |
| Local data | `ExpenseDao`, `ExpenseDatabase`, and `Expense` Room entity |
| Device services | `CryptoManager`, `PreferencesManager`, and `VoiceRecognizerHelper` |
| Remote service | `GeminiService.kt` Retrofit contract and client |

## Dependency Direction

Compose calls the ViewModel. The ViewModel depends on the repository and device/API services. The repository depends on the DAO. Room and Android platform APIs are kept below the UI layer. The UI does not call Room or Retrofit directly for expense operations.

## Key Design Decisions

- Local-first persistence makes manual tracking available offline.
- `StateFlow` keeps filters and database changes reactive.
- One ViewModel owns dashboard, profile, voice, and AI state, which is simple for the current app but creates a broad presentation responsibility.
- AES-GCM values are stored in ordinary preferences only after encryption; the AES key remains in Android Keystore.
- AI is an optional enhancement and has explicit missing-key/error states.

## Current Risks and Evolution

- Split the large ViewModel into feature-specific state holders if the product grows.
- Add domain validation before writing expenses.
- Add Room migrations instead of destructive fallback.
- Move export formatting behind an export interface if XLSX or other formats are later required.
- Keep Firebase, authentication, cloud sync, and Flutter/BLoC decisions as future architecture work; they are not present in this source.