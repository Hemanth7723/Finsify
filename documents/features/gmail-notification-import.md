# Gmail notification-based expense import

## Purpose and boundaries

Gmail notification import automatically captures outgoing bank and UPI transactions from notifications posted by the official Gmail app (`com.google.android.gm`) on Android. The feature operates strictly from the notification payload (title, content, and timestamp) provided by Android's `NotificationListenerService`.

### Strict privacy boundary
- **No Gmail API, IMAP, POP, or OAuth integration:** Finsify never connects to the user's Google account or Gmail mailbox.
- **Notification-payload only:** The app does not open the Gmail app, read email bodies, or access attachments.
- **Gmail package filtering:** Only notifications originating from `com.google.android.gm` are examined. Notifications from messaging apps, banking apps, or other email clients are immediately ignored without reading their contents.
- **No persistence of raw text:** Raw notification text is discarded immediately after parsing. Only extracted expense fields, a deduplication fingerprint, and the UPI transaction reference (when present) are stored.
- **Local-first:** All parsing and deduplication happen on-device in Drift SQLite. No network calls or telemetry are involved.

## Platform scope
- **Android:** Supported via Android's native `NotificationListenerService` through the `notification_listener_service` plugin. The user must manually grant notification access in Android system settings.
- **iOS:** Cross-app notification inspection is prohibited by Apple's sandboxing model. On iOS, the settings dialog displays an explanatory note, and service methods safely no-op without error.

## User flow

1. Tap the **Profile** icon in the dashboard app bar.
2. Under **Gmail Notification Import**, review the permission status and privacy description.
3. Tap **Grant Access** to open Android's **Special app access → Notification access** settings page.
4. Enable notification access for Finsify and return to the app. The app automatically detects the permission state via `WidgetsBindingObserver`.
5. Toggle the feature on. The preference is persisted in Drift (`app_settings`).
6. When a bank transaction email arrives and Gmail posts a device notification, Finsify detects the event in real-time, extracts the transaction, verifies that it is not a duplicate, and auto-records the expense into the ledger.
7. A snackbar confirms the recorded transaction with its title and amount.

## Architecture

```text
Android Notification System
  └─ NotificationListenerService (notification_listener_service plugin)
       └─ GmailNotifImportService (lib/services/gmail_notif_import_service.dart)
            ├─ packageName filter == 'com.google.android.gm'
            ├─ GmailTransactionParser.parse (lib/services/gmail_transaction_parser.dart)
            │    ├─ Filter non-debit (credits, refunds, OTPs, failed, balance alerts)
            │    ├─ Regex amount extraction (₹, Rs., INR)
            │    ├─ UPI transaction reference extraction (`UPI/P2M/<reference>/...`)
            │    ├─ Merchant and category inference
            │    └─ Stable minute-bucket fingerprint generation
            └─ ExpenseController.addImportedExpenseIfNew
                 └─ Drift transaction saves expense and import identity atomically
```

## Parsing and categorization rules

### Acceptance criteria for debit transactions
1. Originating package must equal `com.google.android.gm`.
2. Must contain an outgoing payment indicator (`debited`, `debit`, `paid`, `spent`, `purchase`, `payment of`, `transaction of`, `sent`, `transferred`).
3. Must not contain exclusion keywords (`otp`, `one time password`, `credited`, `refund`, `failed`, `declined`, `pending`, `statement`, `balance alert`, `offer`, `cashback`, etc.).
4. `credit card` mentions are allowed as payment methods, while incoming credits (`credited`, `credit to`, `credit of`) are rejected.
5. Must match a valid positive currency amount (`₹`, `Rs.`, or `INR`).
6. When the payload contains `UPI/P2M/<reference>/...`, the reference is saved for matching the corresponding SMS import.

### Category mapping
- **Transport:** fuel, petrol, diesel, uber, ola, rapido, metro, train, bus, irctc, redbus
- **Food:** grocery, restaurant, swiggy, zomato, blinkit, bigbasket, dunzo, zepto, instamart, food, cafe, hotel
- **Health:** pharmacy, hospital, clinic, medical, health, doctor, medicine, lab, diagnostic
- **Utilities:** electricity, utility, broadband, internet, mobile recharge, gas, water bill, tata power, bses, adani
- **Shopping:** amazon, flipkart, myntra, meesho, nykaa, ajio, shopping, store, mart
- **Entertainment:** netflix, hotstar, disney, spotify, prime video, youtube, zee5, sonyliv, jiocinema, gaming
- **Miscellaneous:** default for other merchants

## Deduplication

Gmail re-deliveries are identified by a fingerprint built from the amount, merchant, and notification post time. SMS re-imports use a fingerprint based on the SMS message ID/date and amount. Cross-source matches require the same UPI transaction reference and amount; transaction time and account suffix are not used as fuzzy match keys. The expense and its import identity are saved together in one local database transaction, so simultaneous imports cannot both create the same entry. If the UPI reference is missing from either source, cross-source deduplication is unavailable and only source-specific fingerprints can match.

Gmail notification content can be only a preview. Cross-source matching works only when that preview includes the UPI reference; Finsify does not open or fetch the email body to find it. The raw notification and SMS text are not persisted.

## Tests and limitations

`test/gmail_transaction_parser_test.dart` covers notification timestamp use, UPI-reference extraction from email/SMS formats, atomic concurrent deduplication, and keeping distinct references separate. It does not exercise Android's actual notification or SMS inbox delivery; those platform paths require device testing.
