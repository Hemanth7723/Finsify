# Finsify feature guides

These guides describe the Flutter implementation in `lib/` as it exists today. Each guide covers the user flow, architecture, public in-app interfaces, models/data shape, persistence or platform integration, known limitations, and relevant tests. The Flutter application has no application-server API; where a feature talks to a platform plugin or Android method channel, that contract is documented explicitly.

| Guide | Feature |
|---|---|
| [Expense ledger](expense-ledger.md) | Manual entry, edit/delete, categories, filtering, sorting, in-memory lifecycle |
| [Analytics](analytics.md) | Period summaries, category analysis, chart data and rendering |
| [Voice expense entry](voice-expense-entry.md) | Device speech recognition, local parser, review and save |
| [SMS expense import](sms-expense-import.md) | Android inbox permission, candidate parsing, user review and import |
| [Investments](investments.md) | One-time/SIP records and estimated value calculations |
| [Loans and EMI](loans-and-emi.md) | Loan inputs, flat/reducing-balance calculations and end date |
| [Bills](bills.md) | Card/other bills, due dates, recurrence, payment and local storage |
| [Bill reminders](bill-reminders.md) | Local notification scheduling, permission and cancellation |
| [Expense XLSX export](expense-xlsx-export.md) | Workbook layout and Android Downloads channel |
| [App shell, navigation and theme](app-shell-navigation-theme.md) | Splash/onboarding, profile, currency, navigation, themes and motion |

## Implementation references

- UI and app orchestration: `lib/main.dart`
- Models: `lib/models/`
- Controllers: `lib/controllers/`
- Platform and domain services: `lib/services/`
- Feature widgets: `lib/widgets/`
- Android manifest and native Downloads channel: `android/app/src/main/`
- Flutter regression/unit coverage: `test/`

These are implementation guides, not promises about features that are merely described in older migration documents. Projections are estimates. The Flutter app currently has no cloud sync, account service, or Gemini API integration.
