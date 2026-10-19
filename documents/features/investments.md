# Investments

## Purpose

Investments are user-entered tracking records for stocks, mutual funds, bonds, debt, or other assets. The app does not fetch brokerage data, prices, balances, or live returns. Estimated values use the user's assumed annual return and are projections only.

## User flow

1. Select **Invest** in the bottom navigation.
2. Tap the screen add icon or persistent plus button.
3. Enter a name, investment type, contribution mode (SIP or one-time), starting amount, expected annual return, and start date.
4. For SIP, enter a monthly contribution as well.
5. Save validates the fields and writes the record to local preferences. The card shows invested amount, estimated value, and expected return/year.
6. Delete removes the investment record.

## Architecture

```text
ExpenseDashboard navigation / plus action
  └─ FinancialPage(section: investments)
       ├─ add form + validation
       ├─ Investment calculations (model getters)
       └─ FinancialController ── SharedPreferences JSON
```

Code: `lib/widgets/financial_pages.dart`, `lib/models/financial_item.dart`, and `lib/controllers/financial_controller.dart`.

## In-app API and model

`FinancialController` exposes `investments`, `addInvestment(Investment)`, and `deleteInvestment(int id)`. It uses the same finance store as loans and bills. There is no web API.

`Investment` fields:

| Field | Type | Meaning |
|---|---|---|
| `id` | `int` | Local record identifier |
| `name` | `String` | User-chosen holding/goal name |
| `type` | `InvestmentType` | `stocks`, `mutualFunds`, `bonds`, `debt`, `other` |
| `contributionType` | `ContributionType` | `sip` or `oneTime` |
| `amount` | `double` | Initial/contributed amount |
| `monthlyContribution` | `double` | Monthly SIP contribution; defaults to zero |
| `annualReturnPercent` | `double` | User assumption, percent per year |
| `startDate` | `DateTime` | Date from which months elapsed are counted |

## Calculation behavior

Elapsed months are calendar-month difference from start date to current date, clamped to 0–1200. Day-of-month is not used to decide whether the current month has elapsed.

- One-time estimated value: `amount × (1 + annualRate / 1200)^months`.
- SIP invested amount: `amount + monthlyContribution × months`.
- SIP estimated value: compounded initial amount plus `monthlyContribution × ((1 + monthlyRate)^months − 1) / monthlyRate`. At a zero rate, it is initial amount plus monthly contributions.
- Expected annual percent is converted to monthly rate by division by 1200.

The model performs calculations in Dart using `double`; there is no live-price source, tax, inflation, fee, or market-volatility model.

## Validation

Name is required. Initial amount must be positive and finite. Annual return must be finite and between 0 and 1000 inclusive. Monthly contribution must be finite and non-negative. The form initializes monthly contribution to `0` and also falls back to `0` if it cannot parse that field.

## Persistence shape

Stored under the shared preference key `finsify_financial_records_v1` in the `investments` array:

```json
{
  "id": 1,
  "name": "Index fund",
  "type": "mutualFunds",
  "contributionType": "sip",
  "amount": 500,
  "monthlyContribution": 100,
  "annualReturnPercent": 8,
  "startDate": "2025-01-01T00:00:00.000"
}
```

Values are serialized manually by `FinancialController`; this preference storage is not an encrypted database or cloud backup.

## Tests and limitations

`test/financial_controller_test.dart` verifies investment storage and reload. `test/financial_item_test.dart` focuses loan calculations; investment return formula test coverage should be expanded when changing these calculations. Records are editable only by delete/re-add in the current UI. Projections must not be interpreted as guaranteed returns.
