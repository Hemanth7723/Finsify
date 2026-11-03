# Loans and EMI

## Purpose

The Loans & EMI module allows users to track debt instruments, auto loans, personal loans, and home mortgages. The app calculates indicative equated monthly installments (EMI), total interest payable, total financial cost including processing fees, and projected loan payoff dates.

## User Flow

1. Select **Loans** in the bottom navigation.
2. Tap the screen add button or floating action button.
3. Input loan title, principal balance, annual interest rate, interest calculation model (reducing balance vs. flat rate), tenure in months, any one-time processing fees, and the first payment start date.
4. Save validates the values and inserts the loan record into Drift SQLite.
5. The loan card displays calculated monthly EMI, cumulative interest, total payable, and final payoff date.
6. Delete removes the loan record from the database.

## Architecture

```text
FinancialPage(section: loans)
  └─ Loan form / card UI
       ├─ Loan model calculations (lib/models/financial_item.dart)
       └─ FinancialController (ChangeNotifier)
            └─ DatabaseService.instance
                 └─ AppDatabase (Drift SQLite: "loans" table)
```

## In-App API and Model

`FinancialController` methods:
- `addLoan(Loan)`: Inserts record into SQLite and updates reactive state.
- `deleteLoan(int id)`: Deletes record from SQLite and updates state.
- `load()`: Queries Drift SQLite and populates in-memory loan list.

`Loan` fields:

| Field | Type | SQLite / Drift Column | Meaning |
|---|---|---|---|
| `id` | `int` | `id` (INTEGER PK AUTOINCREMENT) | Unique identifier |
| `name` | `String` | `name` (TEXT NOT NULL) | Description or bank/institution name |
| `principal` | `double` | `principal` (REAL NOT NULL) | Initial borrowed amount |
| `annualInterestPercent` | `double` | `annual_interest_percent` (REAL NOT NULL) | Nominal annual interest rate (%) |
| `interestType` | `InterestType` | `interest_type` (TEXT NOT NULL) | `reducingBalance` or `flat` |
| `tenureMonths` | `int` | `tenure_months` (INTEGER NOT NULL) | Total repayment period in months |
| `fees` | `double` | `fees` (REAL NOT NULL) | Upfront administrative/processing fees |
| `startDate` | `DateTime` | `start_date` (DATETIME NOT NULL) | First repayment date |

## Calculation Rules

Let $P$ be principal, $a$ be annual interest rate (%), $n$ be tenure in months, and $r = \frac{a}{1200}$ be monthly interest rate:

- **Flat Interest:** $P \times \frac{a}{100} \times \frac{n}{12}$
- **Flat EMI:** $\frac{P + \text{flatInterest}}{n}$
- **Reducing-Balance EMI ($r > 0$):** $\frac{P \times r \times (1 + r)^n}{(1 + r)^n - 1}$
- **Zero-rate Reducing Balance ($r = 0$):** $\frac{P}{n}$
- **Reducing-Balance Total Interest:** $(\text{EMI} \times n) - P$
- **Total Payable:** $P + \text{totalInterest} + \text{fees}$
- **End Date:** Start calendar month advanced by $n$ months (clamped to target month's maximum day).

## Validation

- Name must be non-empty.
- Principal must be finite and positive ($> 0$).
- Annual interest rate must be between 0% and 1000%.
- Tenure must be an integer between 1 and 1200 months.
- Fees must be non-negative ($\ge 0$).

## Persistence & Migration

- Persisted in the `loans` table of the Drift SQLite database (`finsify.sqlite`).
- Existing legacy loans saved in `SharedPreferences` JSON are automatically migrated to SQLite on startup.

## Tests

- [`test/financial_item_test.dart`](file:///e:/finsify/test/financial_item_test.dart): Validates reducing-balance and flat-rate EMI, interest totals, fee additions, and maturity date calculations.
- [`test/financial_controller_test.dart`](file:///e:/finsify/test/financial_controller_test.dart): Verifies loan persistence in Drift SQLite and state reloads.
