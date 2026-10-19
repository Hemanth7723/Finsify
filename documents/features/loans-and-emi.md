# Loans and EMI

## Purpose

The Loans & EMI screen records a user-described loan and calculates indicative monthly payment, total interest, total payable including fees, and estimated end date. It does not connect to a lender or reconcile actual statements.

## User flow

1. Select **Loans** in bottom navigation.
2. Tap add (screen icon or persistent plus).
3. Enter loan name, principal, annual interest rate, interest type, tenure in months, applicable fees, and first payment date.
4. Save validates values and stores the loan locally.
5. The loan card displays calculated EMI, interest, fees + total payable, and payment end date.
6. Delete removes the loan.

## Architecture

`FinancialPage(section: loans)` owns the form/card UI. `Loan` in `lib/models/financial_item.dart` owns the calculation getters. `FinancialController` serializes the record along with investments and bills into one `SharedPreferences` JSON value.

```text
Loans screen/form → Loan(principal, rate, type, tenure, fees, date)
                         ├─ monthlyPayment
                         ├─ totalInterest
                         ├─ totalPayable
                         └─ endDate
                   → FinancialController → SharedPreferences
```

## In-app API and model

Controller methods: `addLoan(Loan)`, `deleteLoan(int id)`, and `load()`. There is no server endpoint.

`Loan` fields: `id`, `name`, `principal`, `annualInterestPercent`, `interestType` (`reducingBalance` or `flat`), `tenureMonths`, `fees`, and `startDate`.

## Calculation rules

Let `P` be principal, annual percentage rate `a`, tenure months `n`, and monthly rate `r = a / 1200`.

- Flat interest: `P × a/100 × n/12`.
- Flat EMI: `(P + flatInterest) / n`.
- Reducing-balance EMI for `r > 0`: `P × r × (1+r)^n / ((1+r)^n − 1)`.
- Zero-rate reducing balance: `P / n`.
- Reducing-balance total interest: `EMI × n − P`.
- Total payable: `P + totalInterest + fees`.
- End date: start calendar month advanced by `n` months; if the original day does not exist in that month, use that month's last day.

Fees are added to total payable, not principal/EMI. The calculations are estimates and do not model payment timing changes, variable rates, lender rounding, insurance, penalties, taxes, or extra payments.

## Validation

Name is required; principal must be finite and positive; annual rate must be finite and 0–1000%; tenure must be 1–1200 months; fees must be finite and non-negative. Date selection allows 2000–2100.

## Persistence shape

The `loans` JSON array stores `id`, `name`, `principal`, `annualInterestPercent`, `interestType` enum name, `tenureMonths`, `fees`, and ISO-8601 `startDate` under preference key `finsify_financial_records_v1`.

## Tests

`test/financial_item_test.dart` covers sample reducing-balance EMI/interest/fees/end-date calculations and flat-rate interest. `test/financial_controller_test.dart` verifies loan persistence/reload through the combined finance store.

## Limitations

No loan edits, schedules, actual payment history, lender integration, or reminder scheduling are provided. Delete and re-add to correct a record.
