# Requirements Traceability Matrix - Expensify Migration

| Requirement | Kotlin source evidence | Flutter verification |
| --- | --- | --- |
| Local expense persistence | `Expense.kt`, `ExpenseDao.kt`, `ExpenseDatabase.kt` | Database/repository tests |
| Reactive expense list | `ExpenseRepository.allExpenses`, `ExpenseViewModel.filteredExpenses` | Controller and widget tests |
| Manual CRUD | `ExpenseViewModel.addExpense`, `updateExpense`, `deleteExpense`, `clearAllData` | CRUD acceptance scenario |
| Onboarding routing | `MainActivity.kt` `MainAppHost`, `PreferencesManager` | Startup flow test |
| Theme preference | `PreferencesManager`, `ExpenseViewModel.toggleDarkTheme` | Restart persistence test |
| Currency preference | `PreferencesManager`, `ExpenseViewModel.changeCurrency` | Formatting test |
| Filtering/sorting | `ExpenseViewModel.filteredExpenses` | Unit tests for every sort/filter |
| Analytics | `calculateTotalSpend`, `groupByCategory`, `groupByDay/Week/Month/Year` | Aggregate unit tests |
| Secure profile data | `CryptoManager`, `PreferencesManager` | Secure-storage test and inspection |
| Voice capture | `VoiceRecognizerHelper` | Permission and voice-state tests |
| Gemini parsing | `GeminiService.kt`, `parseTranscriptToExpense` | HTTP contract and parser tests |
| Gemini insights | `genAiInsights` | Prompt limit and UI-state tests |
| CSV export | `ExpenseRepository.generateCsvData`, `formatCsv` | CSV escaping tests |
| Android share | `MainActivity.kt`, FileProvider manifest entry | Platform integration test |
| Migration safety | Current `fallbackToDestructiveMigration()` | Explicit Flutter schema migration test |

## Excluded Features

Authentication, Firebase, cloud sync, receipt images, budgets, recurring expenses, multi-user data, and XLSX are intentionally absent from the source traceability baseline and must not be added as implicit migration requirements.