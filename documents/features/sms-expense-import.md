# SMS expense import (Android)

## Purpose and boundaries

SMS import scans up to 100 recent inbox messages on Android, identifies likely debit/payment alerts with local regular expressions, and asks the user to review matches before import. Message bodies are processed in memory on-device; they are not uploaded and are not stored as SMS text.

## User flow

1. Tap **Import from SMS** in the Expenses section.
2. Confirm that the app may inspect up to 100 recent inbox messages.
3. Android SMS permission is requested. If denied or permanently denied, the flow reports an actionable error.
4. The app queries inbox messages and locally filters/parses likely transactions.
5. Candidate records already represented by an expense ID are filtered out.
6. A review dialog lists candidate transaction summaries and previews. All candidates are initially selected; the user can deselect rows.
7. Confirming imports the selected candidates into `ExpenseController`. Cancel imports none.

## Architecture

```text
ExpenseDashboard._importSmsExpenses
  ├─ confirmation/review dialogs
  ├─ SmsExpenseImporter.fetchRecentExpenses
  │    ├─ permission_handler: SMS permission
  │    ├─ flutter_sms_inbox: inbox query (max 100)
  │    └─ local regex parser + candidate builder
  └─ ExpenseController.addExpense
```

Main implementation: `lib/services/financial_services.dart` (`SmsExpenseImporter`) and `lib/main.dart` (confirmation, selection and import orchestration).

## In-app API

`Future<List<SmsExpenseCandidate>> fetchRecentExpenses()` returns candidate entries or throws:

- `UnsupportedError` outside Android or on web.
- `StateError` if permission is not granted (with different text for permanently denied).
- Plugin/platform errors if inbox query fails.

`SmsExpenseCandidate` contains:

| Field | Type | Meaning |
|---|---|---|
| `id` | `String` | Candidate selection/dedup key based on message ID/date and parsed amount |
| `expense` | `Expense` | Proposed ledger record |
| `preview` | `String` | Whitespace-normalized, maximum 100-character SMS preview |

There is no HTTP API or bank integration.

## Matching and model mapping

Messages are considered only if text contains one of `debit`, `debited`, `spent`, `purchase`, `paid`, `transaction`, or `payment`. Messages containing OTP/verification phrases are rejected. The amount must include `Rs`, `INR`, or `₹` before or after a positive numeric amount with up to two decimal places.

Heuristic categories are:

- Fuel/petrol → Transport
- Grocery/restaurant → Food
- Pharmacy/hospital → Health
- Electricity/utility → Utilities
- Otherwise → Miscellaneous

Title is derived by stripping the amount, transaction keywords, account/card terms, masking, and punctuation, then keeping at most the first three words. Candidate `Expense.note` is the fixed text `Imported from SMS`; the message content is not saved. The message date is used if available, otherwise the current time.

## Platform configuration and permission

- Manifest: `android/app/src/main/AndroidManifest.xml` declares `android.permission.READ_SMS`.
- Runtime permission: `permission_handler` requests SMS access only when import is initiated.
- Query: `flutter_sms_inbox` queries inbox messages (`SmsQueryKind.inbox`), sorted, count 100.
- This feature is unavailable on iOS/Web and must not be described as automatic bank/SMS synchronization.

## Errors and duplicate behavior

The dashboard shows a loading state while querying and surfaces errors in a snackbar. If no new candidate exists, it shows a no-new-messages message. Candidates are filtered against current expense IDs; this is not durable deduplication because expenses are in memory and IDs depend on source message/date plus amount hashing.

## Tests and limitations

No automated test currently exercises Android inbox access or parser examples. Permission and inbox behavior require Android device testing. Heuristics can miss bank alerts with unsupported formatting or match non-expense messages with qualifying words; the human review step is required before adding.
