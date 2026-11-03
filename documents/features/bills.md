# Bills and Card Balances

## Purpose

The Bills screen tracks recurring and one-time payables for credit cards, debit cards, utilities, and general bills. It provides due date tracking, payment status management, monthly recurrence roll-over, and local notification reminders.

## User Flow

1. Select **Bills** from the bottom navigation.
2. Tap the screen add button or floating action button.
3. Enter bill/card name, instrument type, amount, due date, and whether the bill recurs monthly.
4. On save, the bill is inserted into Drift SQLite and reminders are scheduled via `BillReminderService`.
5. The card renders amount, type, due date status (`Paid`, `Overdue`, `Due today`, or `Due in N days`), recurrence, and reminder state.
6. **Marking a one-time bill paid:** Updates `isPaid = true` in SQLite and cancels active notification reminders.
7. **Marking a recurring bill paid:** Advances the due date by one calendar month (clamping month-end dates such as the 31st to the target month's last day), resets `isPaid = false`, updates the record in SQLite, and reschedules notification reminders.
8. **Delete:** Removes the bill from SQLite and cancels scheduled reminders.

## Architecture

```text
FinancialPage(section: bills)
  ├─ Bill Card / Form Dialog
  ├─ FinancialController (ChangeNotifier)
  │    └─ DatabaseService.instance
  │         └─ AppDatabase (Drift SQLite: "bills" table)
  └─ BillReminderService (Local notifications)
```

Implementation files: [`lib/widgets/financial_pages.dart`](file:///e:/finsify/lib/widgets/financial_pages.dart), [`lib/models/financial_item.dart`](file:///e:/finsify/lib/models/financial_item.dart), [`lib/controllers/financial_controller.dart`](file:///e:/finsify/lib/controllers/financial_controller.dart), and [`lib/services/financial_services.dart`](file:///e:/finsify/lib/services/financial_services.dart).

## In-App API and Model

`FinancialController` methods:
- `addBill(Bill)`: Persists bill into SQLite and updates state.
- `updateBill(Bill)`: Updates SQLite record (e.g., status/due date) and updates state.
- `deleteBill(int id)`: Deletes SQLite record and updates state.
- `load()`: Loads all bills from Drift SQLite.

`Bill` fields:

| Field | Type | SQLite / Drift Column | Meaning |
|---|---|---|---|
| `id` | `int` | `id` (INTEGER PK AUTOINCREMENT) | Unique bill identifier |
| `name` | `String` | `name` (TEXT NOT NULL) | Bill or credit card name |
| `type` | `BillType` | `type` (TEXT NOT NULL) | `creditCard`, `debitCard`, `other` |
| `amount` | `double` | `amount` (REAL NOT NULL) | Amount due |
| `dueDate` | `DateTime` | `due_date` (DATETIME NOT NULL) | Due date and time |
| `recurringMonthly` | `bool` | `recurring_monthly` (BOOLEAN NOT NULL DEFAULT FALSE) | Whether bill repeats monthly |
| `isPaid` | `bool` | `is_paid` (BOOLEAN NOT NULL DEFAULT FALSE) | Settlement status |

## Validation and Persistence

- Name is required and non-empty.
- Amount must parse to a finite number greater than zero.
- Due date defaults to 7 days from creation.
- Stored in the `bills` table of the Drift SQLite database (`finsify.sqlite`).
- Automatically migrates existing JSON records from `SharedPreferences` upon app initialization.

## Tests and Limitations

- [`test/financial_controller_test.dart`](file:///e:/finsify/test/financial_controller_test.dart): Tests bill SQLite persistence, recurrence handling, and state loading.
- Notification reminders rely on platform channels and device permissions (`flutter_local_notifications`).
