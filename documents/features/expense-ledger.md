# Expense ledger

## Purpose and scope

The expense ledger lets a user manually create, inspect, edit, delete, sort, and filter expenses for the current app process. Expense records are **not persisted**: restarting the process clears them. Voice and SMS flows eventually add records to the same controller and ledger.

## User flow

1. The Expenses destination shows the total-spend card, analytics, ledger controls, and rows (or an empty state).
2. The persistent plus action opens the manual-entry dialog. The user provides title, amount, category, and optional note. Date/time are set to the current time in this flow.
3. Selecting a row opens a detail dialog. The user can dismiss, edit amount/date/time/category/note, or delete the item.
4. Category chips and the sort dropdown update the visible row list. The total-spend card sums every expense in memory, independent of the current row filters.
5. The filtered list is also the source for XLSX export.

## Architecture

```text
ExpenseDashboard (lib/main.dart)
  ├─ manual entry / edit / delete dialogs
  ├─ ledger row + filter/sort controls
  ├─ VoiceExpenseDialog ───────────────┐
  └─ SMS import review ────────────────┤
                                       v
                         ExpenseController (ChangeNotifier)
                                       |
                                       v
                                List<Expense>
```

`ExpenseDashboard` owns one `ExpenseController`, listens to it, and rebuilds dashboard state when it notifies listeners. `visibleExpenses` returns a fresh filtered and sorted list. There is no repository/database behind the expense controller.

## In-app API

`ExpenseController` (`lib/controllers/expense_controller.dart`):

| API | Behavior |
|---|---|
| `expenses` | Unmodifiable view of all current-process records |
| `visibleExpenses` | New list, filtered by category and sorted by selected order |
| `totalSpend` | Sum of all expense amounts, not just visible rows |
| `setCategoryFilter(String)` | Set category (`All` is the all-records option), notify listeners |
| `setSortOrder(String)` | Set `Newest`, `Oldest`, `Amount High`, or `Amount Low`; notify |
| `addExpense(Expense)` | Append, then notify |
| `updateExpense(Expense)` | Replace matching `id`; no-op if not found |
| `deleteExpense(int id)` | Remove matching IDs, then notify |
| `clearAll()` | Clear all current-process records, then notify |

These are Dart in-process calls, not HTTP endpoints.

## Model

`Expense` (`lib/models/expense.dart`):

| Field | Type | Meaning |
|---|---|---|
| `id` | `int` | In-process identifier; dialogs/import flows generate it from time/hash |
| `title` | `String` | User-facing description |
| `amount` | `double` | Numeric value in the currently displayed currency |
| `category` | `String` | Category label |
| `timestamp` | `DateTime` | Expense date and time |
| `note` | `String` | Optional note; defaults to empty |

Built-in categories are Food, Transport, Entertainment, Shopping, Health, Utilities, and Miscellaneous. The currency selector changes only the symbol shown; it does not convert values.

## Validation and errors

The manual form parses the amount as a number and does not add the record if parsing fails. The UI does not apply a centralized model-level validation policy for title/amount sign. The voice parser requires a positive amount. SMS candidates are rule-matched and reviewed before import. Edits with an unparsable amount are not saved.

## Persistence and privacy

Records and filter/sort state are held in memory. There is no expense API, remote endpoint, database, or background sync. SMS message text is not added to the record; imported records use a fixed note, `Imported from SMS`.

## Tests

- `test/widget_test.dart`: dashboard navigation, plus-action add dialog, dark theme.
- `test/voice_expense_parser_test.dart`: voice-derived expense parsing.
- Add controller tests when changing expense CRUD, sorting, filtering, or total behavior.

## Known limitations

- Expenses are lost when the app process ends.
- No multi-currency conversion or currency metadata is stored per record.
- `totalSpend` is global to all in-memory records while the ledger row count/list can be filtered.
