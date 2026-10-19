# UI Components, Architecture, and Dimensions Specification

## 1. Purpose and Source of Truth

This specification records the UI structure and layout measurements found in the Kotlin Android source under `Source/app/src/main/java/com/example/`. It is intended to guide a Flutter migration while preserving the existing visual hierarchy and behavior.

Primary source files:

- `MainActivity.kt`: Compose screens, reusable UI components, interactions, and explicit layout dimensions.
- `ui/ExpenseViewModel.kt`: reactive presentation state and screen actions.
- `ui/theme/Theme.kt`, `ui/theme/Color.kt`, and `ui/theme/Type.kt`: Material 3 theme, colors, and typography.

Dimensions below are source Compose `dp` values, except typography values marked `sp`. Flutter should treat `dp` as logical-pixel design values (1 dp maps to 1 Flutter logical pixel), and use scalable text styles for `sp`. Where the source uses `fillMaxWidth`, weights, scrolling, or intrinsic layout, no fixed width or total height is specified; do not invent a fixed device viewport.

## 2. UI and State Architecture

The Android implementation uses a single-activity, Jetpack Compose presentation with an MVVM/repository data path:

```text
MainActivity
  -> MyApplicationTheme
    -> MainAppHost (splash/onboarding/dashboard state and crossfade)
      -> Compose screens, cards, charts, forms, and dialogs
        -> ExpenseViewModel (StateFlow + Compose-observable profile/AI/voice state)
          -> ExpenseRepository
            -> ExpenseDao / Room database
          -> PreferencesManager / CryptoManager
          -> VoiceRecognizerHelper
          -> Gemini Retrofit service
```

| Layer | Source responsibility | Flutter migration equivalent |
| --- | --- | --- |
| App shell | `MainActivity`, edge-to-edge setup, theme host | `MaterialApp`/app shell, system insets, theme configuration |
| Screen routing | `MainAppHost`, splash delay, onboarding completion, crossfade | Router or app-level state; preserve splash-to-onboarding/dashboard decision |
| Presentation | Composables in `MainActivity.kt` | Screens and reusable Flutter widgets |
| Presentation state | `ExpenseViewModel`; expenses, filters, currency, theme, profile, insights, voice parsing | Feature controller/notifier/view model; expose observable state |
| Repository/data | `ExpenseRepository`, `ExpenseDao`, Room | Repository plus local SQLite database/DAO |
| Device services | Preferences, encryption, speech recognition, file sharing | Preferences/secure-storage, speech, and platform file/share services |
| Remote service | Retrofit Gemini client | HTTP client/service; remain optional to manual expense flows |

The existing ViewModel combines multiple feature responsibilities. Keep the UI-to-state-to-repository direction in Flutter; splitting into feature controllers is a migration choice, not a source behavior requirement. The source is local-first and does not implement authentication, cloud sync, or multi-user navigation.

## 3. Screen and Section Inventory

### App entry and routing

- `MainActivity.onCreate`: enables edge-to-edge UI, creates the ViewModel, observes the theme, and applies `MyApplicationTheme`.
- `MainAppHost`: starts on splash; waits 2.5 seconds, then routes to dashboard if onboarding is complete or onboarding otherwise. Screen transitions use a 500 ms crossfade.

### Splash screen

Centered vertical stack with animated logo, app name, subtitle, loading bar, and status text. The logo pulses and the loading fill shimmers. It occupies available screen space rather than a fixed-size page.

### Onboarding/profile setup

Scrollable full-screen form with 24 dp page padding, a welcome heading and supporting copy, display-name and email inputs, a bio/savings-target input, and a full-width primary action. The source describes profile fields as optional and persists onboarding completion when continuing.

### Dashboard

A `Scaffold` with:

- Full-width top app bar: brand mark/title, currency dropdown, theme action, profile action.
- Full-width bottom action surface with a full-width manual-add button and navigation-bar inset handling.
- Vertically scrolling `LazyColumn` body with 16 dp horizontal inset and 20 dp spacing between major sections.
- Profile greeting ribbon.
- Total-spend hero metric.
- Analytics tabs and chart card.
- Ledger title, export action, sort menu, and horizontally scrolling category filters.
- Empty state or keyed expense rows.

### Analytics

`DashboardMetricsPanel` displays the total spend hero, five tabs (Daily, Weekly, Monthly, Yearly, Categories), and a chart surface. Daily, weekly, monthly, and yearly plots use a 140 dp chart plotting row; category analytics use period filters, a date navigator, up to five category rows, and 10 dp progress bars. The empty chart state has a 120 dp minimum/fixed content area.

### Ledger and expense management

Ledger filters and category chips are horizontally scrollable. Each expense row is a full-width card with category icon, title/date/category, amount, and optional note. Tapping a row opens transaction actions; editing reuses the expense form and deletion is explicit.

### Profile and manual expense dialogs

Both forms use scrollable dialog content so smaller screens can reach all fields. Profile dialog includes profile details and theme toggle. Manual expense dialog includes title (for create), amount, category chips, notes, and date/time pickers when editing.

### Voice entry panel

`VoiceSpeechParserPanel` is defined in `MainActivity.kt` with recording control, transcript entry, parse/loading/error states, preview, and confirm-save action. In the current `MainDashboardView` composition, the dashboard holds a voice-panel visibility state but does not render a trigger or invoke this panel. Treat voice UI reachability as a source wiring issue to confirm before claiming exact feature parity; do not infer a specific entry point from the panel definition alone.

### Flutter feature additions

The Flutter dashboard now uses a rounded, theme-matched bottom dock for Expenses, Investments, Loans, and Bills. A centered 48 dp circular "+" action stays visible on every tab and opens that tab's add flow. Financial entry forms are scrollable dialogs; summary cards are content-sized with 14 dp insets, 16 dp row radii, and standard body typography to avoid oversized cards and labels on phone screens. Splash and onboarding dimensions are also reduced to the documented 130 dp logo, 24 dp page inset, 16 dp form gaps, and 56 dp primary action.

- **Voice expense entry:** reachable from the expense screen and floating action. Device speech recognition produces an editable transcript; a local rule-based parser suggests amount and category, and the user confirms before saving. This path does not call Gemini.
- **SMS expense import:** Android-only and explicitly user-started. It requests inbox permission only on import, checks up to 100 recent messages, and presents candidates for review before adding parsed expense fields. Message text is not saved or sent to a backend.
- **Investments:** locally saved entries capture name, asset type, SIP/one-time contribution, contribution amounts, start date, and assumed annual return. Future value is an estimate, not a guarantee.
- **Loans and EMI:** locally saved entries capture principal, annual rate, flat/reducing-balance calculation, tenure, fees, and first payment date. EMI, estimated interest, total payable, and projected end date are calculated locally.
- **Bills and reminders:** locally saved card/other bills include amount and due date. With notification permission, daily local reminders are scheduled no earlier than 365 days before and through the saved due date; they do not require network access.

## 4. Verified Layout Dimensions

Values are explicit Compose modifiers/padding in source. `fillMaxWidth` means the available parent width, not a fixed width. Radii, borders, and gaps are included where they shape the same component.

| Component/section | Verified source dimensions | Flutter guidance |
| --- | --- | --- |
| Splash logo container | 130 x 130 dp | Fixed square visual; center in available screen |
| Splash outer ring | 110 x 110 dp; 6 dp stroke | Keep ring inside logo container |
| Splash inner emblem | 75 x 75 dp; 1.5 dp border | Center in ring; circular |
| Splash logo/text gap | 32 dp | Vertical spacing |
| Splash progress track | 180 x 6 dp; 3 dp corner radius | Keep fixed track size; animate inner fill fraction |
| Splash final progress label gap | 12 dp top padding | Preserve spacing under track |
| Onboarding content | Full available width; 24 dp outer padding | Scroll vertically; respect safe areas and keyboard insets |
| Onboarding input gaps | 16 dp | Vertical spacing between fields |
| Onboarding bio field | Full width x 110 dp | Fixed source height; allow suitable multiline behavior |
| Onboarding primary action | Full width x 56 dp; 14 dp corner radius | Preserve minimum tap target and full-width action |
| Dashboard header brand mark | 36 x 36 dp; 10 dp corner radius | Fixed square mark |
| Dashboard header currency selector | 12 dp horizontal and 6 dp vertical inner padding; 20 dp radius | Intrinsic width based on label/currency |
| Header theme/profile icons | 24 dp / 28 dp icon size | Keep platform tap targets larger than glyph size |
| Dashboard bottom action | Full width x 50 dp; 12 dp radius; row padding 16 dp horizontal, 10 dp vertical | Include bottom system inset; constrain to available width |
| Dashboard list | 16 dp horizontal padding; 20 dp spacing between sections; 10 dp top and 30 dp bottom spacer | Scrollable, not a fixed-height page |
| Profile ribbon | Full width; 16 dp internal padding; 24 dp corner radius; 54 x 54 dp avatar; 16 dp avatar-to-copy gap | Height is content-driven |
| AI insight card | Full width; 16 dp internal padding; 24 dp radius; 40 x 40 dp icon tile; result box 12 dp padding and 16 dp radius | Result region expands with content |
| Total spend hero | Full width; 24 dp internal padding; 28 dp radius; 4 dp vertical outer padding; 36 sp total amount | Height is content-driven; allow large values to wrap/scale |
| Analytics tabs | Full width; 4 dp outer inset; 8 dp vertical tab padding; capsule radius | Five equal-weight tabs; use horizontal overflow or compact labels on narrow screens if needed |
| Analytics chart card | Full width; 16 dp internal padding; 24 dp radius; 20 dp gap before plot | Content-driven height |
| Daily/weekly/monthly/yearly plot | 140 dp plot row; bars 24/26/28/36 dp wide respectively; baseline 2 dp high | Preserve 140 logical-pixel plotting area; scale bar widths only if necessary for narrow devices |
| Analytics no-data state | 120 dp high | Keep message centered in bounded empty area |
| Category analytics controls | Filter row 4 dp inset; option vertical padding 6 dp; date arrows 32 x 32 dp; progress bars 10 dp high | Filter chips and date row should stay scrollable or fit responsively |
| Ledger toolbar | 12 dp gap before filter row; sort/filter controls use 12 dp horizontal and 8 dp vertical padding; filter gap 8 dp | Filter row scrolls horizontally |
| Expense row | Full width; 16 dp radius; 14 dp row padding; 46 x 46 dp category icon; 14 dp icon-to-text gap; optional note max width 100 dp | Row height is content-driven; use ellipsis for long title/note |
| Empty ledger state | 32 dp vertical padding; 70 x 70 dp icon; 16 dp gap below icon | Center content; allow supporting text to wrap |
| Profile/manual dialog content | Full available dialog width; vertically scrollable; fields 12 dp corner radius; manual form uses 12 dp between fields | Use platform dialog constraints/max width; never force a full-screen fixed width |
| Voice recording control | 100 x 100 dp outer circle; 60 x 60 dp inner circle; 32 dp microphone/stop icon; 16 dp vertical section spacing | Scroll dialog content; retain central record action and states |
| Voice preview | Full available width; 14 dp padding; 16 dp radius; 16 dp between main dialog content sections | Content-driven, preview amount must remain legible |

### Typography values used by UI components

The theme defines Material `bodyLarge` as 16 sp with 24 sp line height and 0.5 sp letter spacing. Notable explicit screen/component values include splash title 28 sp, splash subtitle 14 sp, onboarding title 26 sp, dashboard title 18 sp, hero amount 36 sp, ledger title 11 sp, expense title 15 sp, and row amount 16 sp. Preserve hierarchy while honoring Flutter text scaling/accessibility; the source does not define a complete custom typography scale.

## 5. Flutter Layout and Adaptation Requirements

1. Translate source `dp` measurements to Flutter logical pixels; use `sp` values as the initial text-style sizes, while respecting system text scaling.
2. Preserve content-driven sizing for cards, list rows, dialogs, and analytics sections. Do not assign a fixed overall screen height.
3. Use `SafeArea`/system insets and keyboard-aware scrolling for onboarding and dialogs; the Android source uses edge-to-edge mode and explicit navigation-bar padding for the bottom action.
4. Keep dashboard content scrollable. Keep ledger filters and category selectors horizontally scrollable as in Compose.
5. Keep percentage/weight layouts proportional: full-width sections, equal-width analytics tabs, and chart bars scaled to their maximum value.
6. On narrow widths, protect text and actions from overlap. Prefer wrapping or horizontal scrolling where the source already scrolls; do not reduce tap targets to preserve a screenshot.
7. Use reusable widgets that map to source ownership: `AppHeader`, `ProfileRibbon`, `ExpenseSummaryCard`, `AnalyticsPanel`, `LedgerToolbar`, `ExpenseListTile`, `ProfileDialog`, `ExpenseFormDialog`, and `VoiceEntryDialog`.
8. Keep colors/theme reactive. Source light/dark theme colors animate over 400 ms; preserve animation if matching the original experience is required.
9. Keep data and formatting logic out of visual widgets. Widgets dispatch actions to feature state/controllers; repositories and data sources own persistence/export/API responsibilities.

## 6. Migration Parity Checklist

- [ ] Splash routes after 2.5 seconds based on persisted onboarding completion.
- [ ] Onboarding and profile forms scroll on small screens and preserve field/action hierarchy.
- [ ] Dashboard app bar, currency selector, theme action, profile action, analytics, ledger, and bottom manual-add action are represented.
- [ ] Expense rows retain edit/delete interaction and amount/note layout.
- [ ] Analytics tabs and graph dimensions preserve source proportions and empty state.
- [ ] Voice entry is reachable from an explicit control if intended; verify this against product requirements because the source panel is currently not wired into the shown dashboard composition.
- [ ] Flutter navigation exposes expense, investment, loan/EMI, and bill screens with locally saved financial records.
- [ ] Investment estimates, flat/reducing EMI calculations, and bill due reminders are verified with representative values and dates.
- [ ] SMS import requests Android inbox access only after user action and requires review before inserting an expense candidate.
- [ ] Voice entry confirms the transcript and parsed amount/category before insertion; parsing is local and non-AI.
- [ ] Dark/light theme, accessibility text scaling, status/navigation bars, and keyboard insets are validated on target screen sizes.

## 7. Known Limits of the Source Measurements

The source does not declare a canonical device width/height, breakpoint table, or fixed dashboard/dialog dimensions. Most sections are full-width or content-sized. Flutter migration should validate on representative small and large phone widths and use responsive constraints rather than inventing source screen dimensions. Android `dp`/`sp` values are design-unit references, not screenshots in physical pixels.
