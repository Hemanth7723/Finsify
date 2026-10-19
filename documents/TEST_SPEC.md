# Test and Acceptance Specification - Expensify

## 1. Test Scope

The Flutter implementation is accepted only when core local behavior works without network access and optional AI failures do not break expense management.

## 2. Unit Tests

- Expense serialization preserves `id`, `title`, `amount`, `category`, `timestamp`, and `note`.
- CSV output contains the exact seven-column header.
- CSV fields containing commas, quotes, or newlines are escaped correctly.
- Total spend equals the sum of expense amounts.
- Category grouping and day/week/month/year grouping return correct totals.
- Newest, oldest, amount-high, and amount-low sort orders match Kotlin behavior.
- Category filtering is case-insensitive and `All` returns every record.
- Voice response extraction handles raw JSON, wrapped text, missing fields, and malformed JSON safely.
- API-key selection prefers the encrypted user key over build configuration.

## 3. Repository and Persistence Tests

- First launch defaults to onboarding, light theme, and `₹`.
- Saving profile data sets onboarding complete.
- Insert, update, delete, delete-by-ID, and clear-all persist correctly.
- Database re-open preserves expenses.
- Secure profile values are not readable as plaintext from ordinary preferences.
- Schema upgrades use explicit migrations and do not silently delete rows.

## 4. Widget and Flow Tests

- Splash routes to onboarding or dashboard after the configured delay.
- Manual expense creation updates the ledger and total.
- Editing updates the selected record without creating a duplicate.
- Deleting removes the selected record.
- Filters and sort controls update the visible ledger.
- Theme and currency settings persist after restart.
- Voice permission denial leaves manual entry usable.
- Parsed voice expense requires confirmation before insertion.
- AI loading, success, empty, and error states are visible and recoverable.
- CSV export invokes the platform share/save flow.

## 5. Non-functional Checks

- No API key appears in logs, exported files, analytics UI, or exception text.
- Core screens remain usable on small and large phone widths.
- Text and controls do not overlap in light or dark theme.
- Database and repository operations do not block the UI thread.
- Accessibility labels exist for icon-only actions and form controls.

## 6. Acceptance Scenarios

### Offline expense capture

Disable network, complete onboarding, add three expenses, filter by category, sort by amount, reopen the app, and verify the records remain available.

### Optional AI failure

Leave the API key unset, attempt voice parsing and insights, verify a clear configuration message appears, then manually add an expense successfully.

### Export integrity

Create expenses containing commas, quotes, and line breaks in title/note fields. Export and verify a standard CSV reader reconstructs the original values.