# App shell, navigation, theme, and profile

## Scope

This guide covers startup, onboarding, the dashboard shell, bottom navigation, profile dialog, currency display selector, light/dark theme, and motion behavior.

## Startup and onboarding

`main()` runs `FinsifyApp`. The app's `MaterialApp` uses `buildFinsifyTheme(dark: false/true)` and an in-memory `ThemeMode`. Startup shows `SplashScreen`, whose timed completion replaces the route with `ProfileScreen`. Profile name, email, and bio are optional text fields. **Get Started** replaces onboarding with `ExpenseDashboard(profile, onThemeChanged)`.

The profile is represented by the immutable `ProfileData(name, email, bio)` class, then copied into dashboard state. It is not persisted; it is not encrypted. Email and bio are presently collected but are not used in financial calculations or sent anywhere.

## Navigation flow

The dashboard bottom dock has four destinations:

| Index | Destination | Plus action |
|---:|---|---|
| 0 | Expenses | Manual expense dialog |
| 1 | Investments | Investment form |
| 2 | Loans & EMI | Loan form |
| 3 | Bills | Bill form |

The same central plus button remains in every destination. Dashboard index state chooses the visible content. Finance pages receive the currently selected `FinancialSection`, `FinancialController`, currency symbol, reminder service, and a `ValueNotifier` add request. `FinancialPage` listens for that request and opens the current section's form. The dashboard does not use a `GlobalKey` for this bridge.

## Theme behavior

`FinsifyColors` is a `ThemeExtension` in `lib/theme/finsify_theme.dart`, defining background, surfaces, text, accent, outlines, and chart colors for light and dark themes. `buildFinsifyTheme` wires it into Material 3 color scheme, dialog, input, snackbar, text-selection, and button themes. Widgets that need precise surface/chart colors read `context.finsifyColors`; shared component colors come from `Theme.of(context)`.

The profile dialog's theme switch previews its own locally selected mode without rebuilding `MaterialApp` while the dialog is mounted. On **Save Profile**, it returns profile values and the selected mode; the app-level mode changes afterward. The theme selection is session-only; it is not saved across process restarts.

## Currency

The app bar selector offers ₹, $, €, £, and ¥. The value is local dashboard state and passed to expense/finance displays and export. It is a display symbol only: no exchange-rate fetch, conversion, or currency per-record field exists.

## Motion and accessibility

Screen replacement and analytics use `AnimatedSwitcher`; chart bars, finance list height, navigation selection, and the persistent plus action use implicit animations. Route transitions use fade/slide. Most newer transitions check `MediaQuery.disableAnimationsOf(context)` and use zero duration when the user requests reduced motion. Material button theme defines a short animation duration for state changes. Splash includes a repeating logo/progress animation.

## In-app APIs and models

- `ProfileData`: immutable `name`, `email`, `bio`.
- `ExpenseDashboard.onThemeChanged`: callback to request app-level mode update.
- `FinsifyApp` owns the current theme mode and builds both themes.
- No authentication, remote profile API, account API, or persistence API exists.

## Error/behavior notes

Navigation uses `setState` on the dashboard. Financial records are loaded asynchronously by `FinancialController`; loading and load errors are shown on finance pages. The expense dashboard remains usable independently. Add request notifier and controller listeners are removed/disposed with their owner widgets.

## Tests

`test/widget_test.dart` covers onboarding, navigation across all four destinations, plus-action form routing, light/dark surface styling, and changing the profile theme preview then saving.

## Limitations

- Profile and theme choice reset after process restart.
- Currency is not an ISO currency code and does not convert values.
- Profile fields are session-only and not encrypted.
- iOS/Web/Desktop compile targets do not imply every Android-specific feature works there.
