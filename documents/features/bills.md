# Bills and card balances

## Purpose

The Bills screen tracks user-entered amounts due for credit cards, debit cards, or other bills. It displays due status and supports optional monthly recurrence. Bills are not fetched from a bank or card issuer.

## User flow

1. Select **Bills** in navigation.
2. Add a bill using the screen add button or persistent plus action.
3. Enter a bill/card name, type, amount, due date, and whether it repeats monthly.
4. On save, the app stores the bill and then attempts to schedule reminders.
5. The bill card shows amount, type, due date/status, recurrence, and reminder status.
6. Mark a one-time bill paid to persist `isPaid = true` and cancel its reminders.
7. Mark a recurring bill paid to advance due date by one calendar month, clamp dates such as the 31st to the next month's last day, keep it unpaid for the next cycle, and reschedule reminders.
8. Delete removes the bill and its reminders.

## Architecture

```text
FinancialPage(section: bills)
  ├─ form / paid / delete actions
  ├─ FinancialController ───── bill JSON in SharedPreferences
  └─ BillReminderService ────── local notifications
```

Main code: `lib/widgets/financial_pages.dart`, `lib/models/financial_item.dart`, `lib/controllers/financial_controller.dart`, `lib/services/financial_services.dart`.

## In-app API and model

`FinancialController` provides `bills`, `addBill(Bill)`, `updateBill(Bill)`, and `deleteBill(int id)`. `BillReminderService` provides `schedule(Bill)` and `cancel(int billId)`. These are local Dart service APIs, not HTTP endpoints.

`Bill` fields: `id`, `name`, `type` (`creditCard`, `debitCard`, `other`), `amount`, `dueDate`, `recurringMonthly` (default false), and `isPaid` (default false). `copyWith` supports due date and paid status updates.

Displayed due status is `Paid`, `Overdue`, `Due today`, or `Due in N days`. The implementation calculates days from normalized due date against `DateTime.now()` and renders the status when the widget rebuilds.

## Validation and persistence

Name is required; amount must parse as finite and positive. Default due date is seven days from the form's opening. Bill records are stored in the shared finance JSON at key `finsify_financial_records_v1`; the stored bill object includes type enum name, amount, ISO-8601 due date, recurrence, and paid status.

This storage is local `SharedPreferences`, not secure encrypted storage or a database. Records persist across process restarts on the device but are not synchronized.

## Failure behavior

Bill save failure is reported and prevents reminder scheduling. If saving succeeds but reminder setup fails, the bill remains stored and the UI reports that reminder setup failed. Delete/mark-paid persistence and reminder operations may also show a snackbar error.

## Tests and limitations

`test/financial_controller_test.dart` verifies bill persistence and recurrence flag. Notification integration is device/platform behavior and has no automated platform-channel test here. Bills are not imported automatically. Editing a bill is not exposed; delete and recreate to correct it.
