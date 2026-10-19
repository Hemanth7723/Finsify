# Expense XLSX export

## Purpose and user flow

The dashboard's **Download XLSX** action exports the currently visible expense list (therefore respecting category filtering and sorting) into an Excel-compatible `.xlsx` workbook, then saves it to the Android public Downloads collection.

1. If no expenses match the current filter, show a message and stop.
2. Generate workbook bytes with `XlsxExportService`.
3. Generate a timestamped filename such as `finsify_expenses_2026-10-03_210000.xlsx`.
4. Call the Android `FileDownloadService` method channel.
5. Show the saved filename or report an export error.

## Architecture

```text
ExpenseDashboard._exportXlsx
  ├─ ExpenseController.visibleExpenses
  ├─ XlsxExportService.generate(expenses, currency) → Uint8List
  └─ FileDownloadService.saveToDownloads
       └─ MethodChannel: com.example.finsify/file_download
            └─ MainActivity / Android MediaStore Downloads
```

## Workbook contract

`XlsxExportService.generate(List<Expense>, String currencySymbol)` returns XLSX bytes and throws `StateError` if workbook generation produces no bytes. It creates an `Expenses` sheet with columns:

1. `S.No`
2. `Date` (Excel date value, `dd-mm-yyyy`)
3. `Time` (Excel time value, `hh:mm:ss`)
4. `Category`
5. `Message` (maps to `Expense.title`)
6. `Amount` (numeric)
7. `Currency` (symbol string)
8. `Notes`

Rows follow the supplied list order. Header row is styled; panes freeze below the header and column widths are configured.

## Android platform API

Dart channel is `com.example.finsify/file_download`; method is `saveToDownloads`; arguments are:

```text
bytes: byte[]
fileName: String
mimeType: String
```

Kotlin `MainActivity` validates non-empty bytes, filename, and MIME type, and requires Android API 29+ (`MediaStore.Downloads`). It writes asynchronously on a single-thread executor to `Environment.DIRECTORY_DOWNLOADS` with scoped storage, marks the media item pending during write, then publishes it. Success returns the filename.

Native error codes include `SAVE_FAILED` and `UNSUPPORTED_ANDROID_VERSION`. Flutter maps `PlatformException` to an exception shown via snackbar. No broad storage permission is requested.

## Platform/API constraints

`FileDownloadService` explicitly throws `UnsupportedError` outside Android. The export button currently calls direct Android Downloads saving; no share sheet or cross-platform file save is implemented.

## Data/privacy

Only filtered visible expenses are exported. No SMS message body is exported because SMS-derived expenses retain only parsed fields and a fixed note. Workbook bytes are generated in process and written locally.

## Tests and limitations

The current automated suite does not include an XLSX workbook-content or Android MediaStore integration test. Validate generated workbook in Excel/LibreOffice and verify save/collision/error behavior on Android API 29+. The filename has second-level precision, so repeated exports in the same second may collide depending on MediaStore behavior.
