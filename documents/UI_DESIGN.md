# UI/UX Design - Expensify

## 1. Visual Direction

The application uses Jetpack Compose and Material 3 with a modern finance-dashboard treatment. Light mode uses a pale slate background and indigo accent surfaces. Dark mode uses deep navy surfaces with cyan/blue accents. Theme changes animate over approximately 400 ms.

## 2. Screen Map

### Splash

Animated diamond logo, rotating ring, pulsing scale, gradient background, and loading text. After 2.5 seconds it routes to onboarding or the dashboard.

### Onboarding/Profile

Scrollable form for display name, email, bio/savings goal, and optional Gemini API key. Supporting copy explains local encryption. Saving writes the profile and completes onboarding.

### Dashboard

- App title and profile access in the top area.
- Theme switch and currency selector.
- Compact, theme-matched bottom navigation for Expenses, Investments, Loans, and Bills.
- A persistent center "+" action that adds an expense, investment, loan, or bill according to the selected screen.
- Total-spend hero metric.
- Manual add, local voice-entry, and on-demand SMS import actions.
- Export/share action.
- Sort selector and category filter chips.
- Scrollable expense ledger.
- Analytics area for totals grouped by category, day, week, month, and year.
- Optional AI insights area with loading and error states.

### Expense form and management dialogs

Forms collect title, amount, category, date/time, and note. A selected ledger item can be edited or deleted. Destructive actions require an explicit user action.

### Voice entry

The recorder presents listening state, editable transcript, errors, and a locally parsed expense preview before insertion. Expense parsing is rule-based and does not call AI; speech recognition is provided by the device's speech service.

### Investments, loans, and bills

- Investments capture asset class, SIP/one-time contributions, start date, and assumed return.
- Loans capture principal, flat/reducing interest type, rate, tenure, fees, and payment start date; the screen estimates EMI, interest, total payable, and end date.
- Bills capture card/bill type, amount, and due date. Daily local notifications remind the user before the saved due date.
- These user-entered records are stored locally. SMS inbox access is Android-only and is requested only after the user explicitly starts import; detected transactions require confirmation.

## 3. Interaction Rules

- Filter and sort changes update the visible list immediately.
- The central add action remains visible on every primary screen and opens the relevant add flow for that screen.
- Currency changes update displayed symbols and CSV output, not stored numeric amounts.
- Category presentation uses emoji and colors: Food orange, Transport blue, Entertainment pink, Shopping violet, Health red, Utilities cyan, and Miscellaneous slate.
- Empty states explain that an expense must be added before analytics or insights are useful.
- Network-dependent features expose errors without blocking manual CRUD.

## 4. Accessibility and Platform Behavior

Use Material controls, readable contrast in both theme modes, content descriptions for icon actions, and scrolling for smaller screens. Voice entry must request `RECORD_AUDIO` at runtime and degrade to manual entry when permission or recognition is unavailable. File sharing uses Android's provider and intent model.

## 5. Product Boundaries

The current UI has no authentication screen, cloud account, receipt camera, budget-limit configuration, or multi-user navigation. Those should not be represented as implemented screens until their behavior exists in the application.