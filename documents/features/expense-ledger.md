# Expense Ledger

## Purpose and Scope

The expense ledger enables users to create, inspect, edit, delete, sort, and filter personal expenses. All expense records are **persistently saved** in a local SQLite database powered by [Drift](https://drift.simonbinder.eu/) (`finsify.sqlite` on native platforms and IndexedDB via WebAssembly on web). Voice input and SMS import flows seamlessly integrate into the same controller and database ledger.

## User Flow

1. **Dashboard & Overview:** The Expenses destination displays the monthly budget progress, total spend, analytics breakdown, ledger controls, and transaction rows (or an empty state).
2. **Manual Entry:** Tapping the floating action button or screen add button opens the entry dialog. The user enters title, amount, category, and an optional note. Date and time default to the current timestamp.
3. **Detail & Editing:** Selecting an expense row opens the detail dialog, allowing the user to update amount, date, time, category, or note, or delete the record.
4. **Filtering & Sorting:** Category chips and the sort selector update the visible transaction list without reloading from disk.
5. **Data Export:** The filtered list serves as the data source for spreadsheet export via XLSX.

## Architecture

```text
ExpenseDashboard (lib/main.dart)
  ├─ CustomScrollView + SliverList.builder (Lazy 60 FPS rendering)
  ├─ Manual entry / Edit / Delete dialogs
  ├─ VoiceExpenseDialog ───────────────┐
  └─ SMS import review ────────────────┤
                                       v
                         ExpenseController (ChangeNotifier)
                                       │
                         [Cached visibleExpenses]
                                       │
                                       v
                         DatabaseService (Singleton)
                                       │
                                       v
                            AppDatabase (Drift SQLite)
                        (finsify.sqlite / IndexedDB WASM)
```

`ExpenseDashboard` listens to `ExpenseController`. When modifications occur:
1. `ExpenseController` executes typed SQL queries through `DatabaseService`.
2. Controller state updates in-memory and sets `_visibleDirty = true`.
3. Calls `notifyListeners()`, triggering efficient UI updates.
4. `visibleExpenses` recomputes sorting and filtering only when dirty, guaranteeing optimal performance on frame updates.

## In-App API

`ExpenseController` ([`lib/controllers/expense_controller.dart`](file:///e:/finsify/lib/controllers/expense_controller.dart)):

| API | Behavior |
|---|---|
| `load()` | Asynchronously populates in-memory expenses from Drift SQLite |
| `expenses` | Unmodifiable view of all persisted expense records |
| `visibleExpenses` | Cached list filtered by active category and sorted by active sort order |
| `totalSpend` | Total amount summed across all expenses |
| `setCategoryFilter(String)` | Filters visible rows by category (`All` shows all records); marks cache dirty |
| `setSortOrder(String)` | Sorts by `Newest`, `Oldest`, `Amount High`, or `Amount Low`; marks cache dirty |
| `addExpense(Expense)` | Inserts into Drift SQLite and appends to in-memory list; notifies listeners |
| `updateExpense(Expense)` | Updates Drift SQLite record and updates in-memory item; notifies listeners |
| `deleteExpense(int id)` | Deletes row from Drift SQLite and removes from in-memory list; notifies listeners |
| `clearAll()` | Clears all rows in the `Expenses` table; notifies listeners |

## Model

`Expense` ([`lib/models/expense.dart`](file:///e:/finsify/lib/models/expense.dart)):

| Field | Type | SQLite / Drift Column | Meaning |
|---|---|---|---|
| `id` | `int` | `id` (INTEGER PK AUTOINCREMENT) | Unique record identifier |
| `title` | `String` | `title` (TEXT NOT NULL) | Description of the purchase |
| `amount` | `double` | `amount` (REAL NOT NULL) | Numerical expense amount |
| `category` | `String` | `category` (TEXT NOT NULL) | Category classification |
| `timestamp` | `DateTime` | `timestamp` (DATETIME NOT NULL) | Date and time of expense |
| `note` | `String` | `note` (TEXT NOT NULL DEFAULT '') | Optional context or source metadata |

Built-in categories: `Food`, `Transport`, `Entertainment`, `Shopping`, `Health`, `Utilities`, and `Miscellaneous`.

## Performance & Rendering

- **Lazy List Rendering:** The ledger list uses `CustomScrollView` with `SliverList.builder` instead of eager `ListView(children: ...)`. Rows outside the viewport are not built or retained in the element tree, ensuring smooth 60/120 FPS scrolling even with thousands of entries.
- **Query & Sorting Caching:** `visibleExpenses` employs dirty-flag memoization (`_visibleDirty`). Re-evaluating sort/filter operations occurs only when records, sort order, or category filters change—never during passive widget rebuilds.
- **Safe Dialog Cleanup:** Text controllers defer disposal by 500ms following dialog dismissal to allow route pop transitions to unmount cleanly without throwing disposed controller assertions.

## Persistence & Privacy

- All transactions are stored locally on-device in `finsify.sqlite` using Drift ORM.
- On Flutter Web, Drift utilizes WebAssembly (`sqlite3.wasm` and `drift_worker.js`) persisting to browser IndexedDB.
- No transaction data is sent to external servers or cloud databases.
- When importing expenses from SMS, raw message body text is never stored in the database.

## Tests

- [`test/database_service_test.dart`](file:///e:/finsify/test/database_service_test.dart): Verifies Drift SQLite CRUD operations, in-memory test database injection, and persistence survival across controller instances.
- [`test/widget_test.dart`](file:///e:/finsify/test/widget_test.dart): Verifies dashboard navigation, ledger rendering, manual entry dialogs, and profile routing.
- [`test/voice_expense_parser_test.dart`](file:///e:/finsify/test/voice_expense_parser_test.dart): Tests voice transaction parsing.
