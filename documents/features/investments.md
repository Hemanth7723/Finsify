# Investments

## Purpose

Investments are user-managed tracking records for stocks, mutual funds, bonds, debt, or other assets. Finsify tracks these offline; it does not connect to external brokerage APIs or scrape real-time asset pricing. Projected values are calculated using standard compound growth models based on user-provided return expectations.

## User Flow

1. Select **Invest** from the bottom navigation bar.
2. Tap the screen add button or persistent floating action button.
3. Enter investment name, asset type, contribution mode (SIP or one-time), starting amount, expected annual return percentage, and initial investment date.
4. For recurring SIP contributions, specify the monthly contribution amount.
5. Saving validates all fields and inserts the record into Drift SQLite via `FinancialController`. The investment card immediately renders invested capital, projected current value, and annual yield.
6. Delete removes the record from the database.

## Architecture

```text
ExpenseDashboard Navigation / Action Button
  └─ FinancialPage(section: investments)
       ├─ Add form + Field validation
       ├─ Investment calculations (model getters)
       └─ FinancialController (ChangeNotifier)
            └─ DatabaseService.instance
                 └─ AppDatabase (Drift SQLite: "investments" table)
```

Implementation files: [`lib/widgets/financial_pages.dart`](file:///e:/finsify/lib/widgets/financial_pages.dart), [`lib/models/financial_item.dart`](file:///e:/finsify/lib/models/financial_item.dart), [`lib/controllers/financial_controller.dart`](file:///e:/finsify/lib/controllers/financial_controller.dart), and [`lib/services/database_service.dart`](file:///e:/finsify/lib/services/database_service.dart).

## In-App API and Model

`FinancialController` exposes `investments`, `addInvestment(Investment)`, and `deleteInvestment(int id)`.

`Investment` fields:

| Field | Type | SQLite / Drift Column | Meaning |
|---|---|---|---|
| `id` | `int` | `id` (INTEGER PK AUTOINCREMENT) | Unique record identifier |
| `name` | `String` | `name` (TEXT NOT NULL) | Name of holding or investment goal |
| `type` | `InvestmentType` | `type` (TEXT NOT NULL) | `stocks`, `mutualFunds`, `bonds`, `debt`, `other` |
| `contributionType` | `ContributionType` | `contribution_type` (TEXT NOT NULL) | `sip` or `oneTime` |
| `amount` | `double` | `amount` (REAL NOT NULL) | Initial lump-sum or principal amount |
| `monthlyContribution` | `double` | `monthly_contribution` (REAL NOT NULL) | Recurring monthly SIP contribution |
| `annualReturnPercent` | `double` | `annual_return_percent` (REAL NOT NULL) | Expected annual growth rate (%) |
| `startDate` | `DateTime` | `start_date` (DATETIME NOT NULL) | Date tracking begins |

## Calculation Behavior

Elapsed months are computed from `startDate` to `DateTime.now()`, clamped between 0 and 1200 months.

- **One-time Estimated Value:** $\text{amount} \times (1 + \frac{\text{annualRate}}{1200})^{\text{months}}$
- **SIP Invested Amount:** $\text{amount} + (\text{monthlyContribution} \times \text{months})$
- **SIP Estimated Value:** Compounded initial amount plus $\text{monthlyContribution} \times \frac{(1 + \text{monthlyRate})^{\text{months}} - 1}{\text{monthlyRate}}$. If monthly rate is 0, sum of initial plus all monthly contributions.
- **Monthly Rate:** $\frac{\text{annualReturnPercent}}{1200}$.

All calculations execute on-device using IEEE 754 double-precision floating-point arithmetic.

## Validation

- **Name:** Required and non-empty.
- **Initial Amount:** Must parse to a positive, finite number ($> 0$).
- **Annual Return:** Must be between 0% and 1000% inclusive.
- **Monthly Contribution:** Must be non-negative ($\ge 0$).

## Persistence & Migration

- Persisted in the `investments` table of the local Drift SQLite database (`finsify.sqlite` on mobile/desktop, IndexedDB via WebAssembly on web).
- **Legacy Migration:** When initialized, `FinancialController` checks `SharedPreferences` for legacy JSON key `finsify_financial_records_v1`. If detected, records are automatically migrated into Drift SQLite tables and cleaned up from preferences.

## Tests and Limitations

- [`test/financial_controller_test.dart`](file:///e:/finsify/test/financial_controller_test.dart): Verifies CRUD operations, SQLite persistence, and state restoration across controller reloads.
- [`test/financial_item_test.dart`](file:///e:/finsify/test/financial_item_test.dart): Verifies mathematical financial projection formulas.
- Projections are illustrative estimations and do not account for expense ratios, taxation, or market volatility.
