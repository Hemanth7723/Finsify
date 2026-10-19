# Technical Requirements Document - Expensify

## 1. Implemented Stack

| Area | Current implementation |
| --- | --- |
| Platform | Android, min SDK 24, target/compile SDK 36 |
| Language | Kotlin, JVM target 11 |
| UI | Jetpack Compose and Material 3 |
| Architecture | Activity + Compose UI, `ExpenseViewModel`, repository, data sources |
| State | Kotlin Coroutines, `StateFlow`, Compose state |
| Database | Room over SQLite, database name `expense_tracker_db` |
| HTTP | Retrofit with OkHttp |
| JSON | Moshi code generation |
| AI | Google Gemini REST endpoint `gemini-3.5-flash:generateContent` |
| Preferences | Android `SharedPreferences` |
| Secret protection | Android Keystore AES/GCM/NoPadding |
| Export | Manually generated CSV, shared through Android intents |

## 2. Build and Configuration

- Module: `app`.
- Application ID: `com.aistudio.dailyexpensetracker.kxmpzq`.
- Gemini build fallback is injected through the Secrets Gradle Plugin from `.env`; `.env.example` documents the expected key.
- A user-provided API key is stored encrypted and takes precedence over the build-configured key.
- Required manifest permissions are `INTERNET` and `RECORD_AUDIO`; speech recognition service discovery is declared in `<queries>`.

## 3. Persistence Requirements

Room exposes an observable `Flow<List<Expense>>` through `ExpenseDao`. DAO operations are insert, update, delete, delete by ID, clear all, and timestamp-descending query. `ExpenseDatabase` is a singleton and currently uses `fallbackToDestructiveMigration()`; production releases require versioned migrations and schema export.

`PreferencesManager` stores the currency, onboarding flag, theme flag, and encrypted profile/API-key strings under the `expense_tracker_prefs` preference file.

## 4. Security Requirements

`CryptoManager` obtains or creates the Keystore alias `ExpenseTrackerSecretKey`. It encrypts UTF-8 values with AES/GCM/NoPadding, prepends the 12-byte IV to the ciphertext, and Base64-encodes the result. Decryption failures return an empty string. API keys must not be logged or included in exported CSV data.

## 5. Network and AI Requirements

Gemini calls use a 60-second connect/read/write timeout. Transcript parsing requests `application/json` with low temperature and validates the returned JSON boundary before reading fields. Insight generation sends at most 30 expenses and requests markdown sections. Network and configuration errors are represented as UI state and do not affect local CRUD operations.

## 6. Migration Guidance

For a future Flutter port, map Room to Drift, StateFlow/ViewModel to the selected reactive state solution, SharedPreferences/Keystore to platform secure storage, Android speech recognition to a speech-to-text plugin, and CSV export to a platform share flow. These are target choices, not current dependencies.