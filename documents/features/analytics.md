# Expense analytics

## Purpose

Analytics summarize in-memory expense records by time and category. They are descriptive displays, not forecasts, budgets, or financial advice.

## User flow

The dashboard displays four time-series tabs—Daily, Weekly, Monthly, Yearly—and a Categories tab. The time-series chart groups expenses into recent fixed windows. Category analytics has its own day/week/month/year selector and previous/next period navigation.

## Architecture and data flow

```text
ExpenseController.expenses
  ├─ _timeAnalyticsData(expenses, period)
  │    └─ AnalyticsDatum(label, value) list
  │          └─ AnalyticsBarChart
  └─ _categoryTotalsForPeriod(expenses, period, anchor)
       └─ category rows + proportional progress bars
```

All aggregation is local in `ExpenseDashboard` (`lib/main.dart`). `AnalyticsBarChart` (`lib/widgets/analytics_bar_chart.dart`) is a presentation widget. It uses layout constraints to size bars and labels to avoid a vertical overflow and takes chart colors from `FinsifyColors`.

## Time ranges and bucket rules

The time-series chart is anchored to `DateTime.now()`:

- Daily: today and the previous six calendar days, maximum seven buckets.
- Weekly: current Monday–Sunday week and the previous three weeks.
- Monthly: current calendar month and the previous three calendar months.
- Yearly: current year and the previous four calendar years.

Only buckets that contain at least one expense are emitted to the chart. A zero-amount expense still marks the bucket as present. Time-series category indexes are selected by tab order: 0 daily, 1 weekly, 2 monthly, 3 yearly.

Category analytics filters an explicit anchor date to a day, Monday-based week, calendar month, or calendar year. Previous/next changes the anchor by one selected period.

## In-app data/API

There is no network/API call. The chart input is:

```dart
class AnalyticsDatum {
  const AnalyticsDatum({required this.label, required this.value});
  final String label;
  final double value;
}
```

`AnalyticsBarChart` takes `data` and `currency`. Values are rendered with zero decimal places above the bars; the dashboard's currency symbol is a display-only prefix.

## Model and storage

Analytics use `Expense` records directly. They do not introduce a separate persistence model and do not store computed aggregates. Since expense data is in memory, analytics are session-only.

## Empty/error states

When a time range has no expenses, the dashboard shows a no-data message. Category analysis shows a no-records message. There is no API/network error path.

## Tests

- `test/analytics_bar_chart_test.dart` covers a seven-bar chart in a short/narrow constraint, dark palette colors, and absence of layout exceptions.
- `test/widget_test.dart` covers dashboard access and dark mode.

## Limitations

- Time-series chart dates are relative to the current system date; category analysis uses a separately navigable anchor.
- Chart labels can be scaled down for narrow screens.
- Summaries include the session's expenses only and cannot report across app restarts.
