# Functional Requirements Document - Expensify

## 1. Scope

Expensify is an Android, local-first personal expense tracker. The current implementation is a Jetpack Compose application with an optional Gemini AI integration. Core expense recording, storage, filtering, analytics, and export work without a network connection.

## 2. User Flows

### 2.1 Startup and onboarding

1. Show an animated splash screen for approximately 2.5 seconds.
2. Read the local `onboarding_completed` preference.
3. Open the dashboard when setup is complete; otherwise open the profile setup screen.
4. Profile setup accepts display name, email, bio/savings goal, and an optional Gemini API key. Saving marks onboarding complete.

### 2.2 Expense management

- Add an expense manually with title, amount, category, timestamp, and optional note.
- Update amount, category, timestamp, and note/title through the edit flow.
- Delete one expense or clear all expenses.
- Persist every change in the local Room database.
- Display expenses ordered by newest timestamp by default.

### 2.3 Dashboard and discovery

- Show total spend calculated from the current expense list.
- Allow currency-symbol selection. This changes display/export formatting only; it does not perform currency conversion.
- Filter by `All`, `Food`, `Transport`, `Entertainment`, `Shopping`, `Health`, `Utilities`, or `Miscellaneous`.
- Sort by newest, oldest, amount high, or amount low.
- Display category totals and time-grouped totals by day, week, month, and year.
- Support light/dark theme selection.

### 2.4 Export

- Export the current expense data as comma-separated values.
- Include the columns `ID, Date, Category, Title, Amount, Currency, Notes`.
- Escape commas, quotes, and line breaks according to CSV rules.
- Share/save the generated file using Android file and share mechanisms.

### 2.5 Voice entry and AI

- Request microphone access and capture partial/final speech results using Android `SpeechRecognizer`.
- Send a transcript to Gemini when a valid custom or build-configured API key exists.
- Request a JSON object containing title, amount, category, and note.
- Preview the parsed values before saving them as an expense.
- Show errors for missing permission, unavailable recognition, missing API key, network failure, and invalid AI output.
- Generate optional spending insights from up to the latest 30 expenses in three sections: financial persona, expenditure critique, and behavioral upgrades.

## 3. Categories

The fixed categories are Food, Transport, Entertainment, Shopping, Health, Utilities, and Miscellaneous. Unknown categories use the miscellaneous presentation style.

## 4. Non-functional Requirements

- Core data must remain available offline.
- Sensitive profile values and the custom API key must be encrypted before persistence.
- AI features must be optional and must not prevent manual expense tracking.
- Destructive database migration behavior must be replaced with explicit migrations before production data is considered durable.

## 5. Out of Scope in the Current Source

There is no account login, Firebase authentication, cloud synchronization, receipt capture, budgets, recurring expenses, multi-user support, or true XLSX generation.