# Voice expense entry

## Purpose and privacy boundary

Voice entry transcribes speech through the device's speech-recognition service, then applies deterministic local Dart rules to the transcript. It does **not** send text to Gemini or any Finsify server. Speech recognition itself is provided by the operating system/service; whether that service uses network resources depends on the device and its configuration.

## User flow

1. From the expense dashboard, tap **Voice entry**.
2. Tap the microphone button. The app requests speech recognition through `speech_to_text`, listening for up to 20 seconds.
3. The recognized words populate an editable transcript field.
4. The local parser looks for a positive amount and infers a category from keywords. A preview displays parsed title, category, and amount.
5. If parsing succeeds, tap **Add expense**. The dialog constructs an `Expense` with the current timestamp and note `Added by voice`, then passes it to the expense controller.
6. The user can edit the transcript manually before saving. Cancel closes without adding.

## Architecture

```text
ExpenseDashboard
  └─ VoiceExpenseDialog
      ├─ VoiceRecognitionService ── speech_to_text plugin / OS recognizer
      ├─ VoiceExpenseParser ──────── local pure-Dart rules
      └─ onSave(Expense) ─────────── ExpenseController.addExpense
```

Files: `lib/widgets/voice_expense_dialog.dart`, `lib/services/voice_recognition_service.dart`, `lib/services/voice_expense_parser.dart`, and `lib/models/expense.dart`.

## In-app API

`VoiceRecognitionService.listen` accepts callbacks for transcript, listening state, and error text, and returns whether recognition is available. `stop()` stops listening. The service retains callbacks for the active listening session.

`VoiceExpenseParser.parse(String transcript)` returns `ParsedVoiceExpense?`; `null` means no valid positive amount was found. Parsed fields are `title`, `amount`, and `category`. The caller, not the parser, creates and persists/adds the `Expense`.

No HTTP endpoint or backend contract exists for voice input.

## Parsing behavior

- Commas are removed before extracting the first number.
- The first amount matching an optional `₹`, `Rs`, or `rupees` prefix and up to two decimal places is considered.
- Amount must parse as a positive `double`.
- Keywords map to Food, Transport, Entertainment, Shopping, Health, or Utilities. Otherwise the last category (`Miscellaneous`) is used.
- The matched amount and the tokens `I`, `spent`, `spend`, `paid`, `pay`, `for`, `on`, and currency words are removed from the transcript to create the title. Remaining whitespace is normalized. If that is empty, category is used as the title.

This is a deliberately simple heuristic: it is not natural-language understanding and can misinterpret complex statements, multiple amounts, or ambiguous wording. Always review the preview.

## Permissions and platform

Android declares `RECORD_AUDIO` and a speech recognition service query in `android/app/src/main/AndroidManifest.xml`. Platform/plugin behavior and required permissions may differ on iOS and other Flutter targets. Recognition availability is checked at runtime; errors are shown in the dialog.

## Model and lifecycle

The resulting `Expense` has a generated microsecond timestamp ID, parsed title/amount/category, `DateTime.now()`, and the fixed note `Added by voice`. The expense controller keeps it in memory only.

## Tests

`test/voice_expense_parser_test.dart` verifies common amount/category parsing and rejects missing/non-positive amounts. Recognition is device-service behavior and is not covered by an automated integration test.
