# Bill due reminders

## Purpose and behavior

`BillReminderService` schedules local reminders for saved bills. It uses operating-system notifications through `flutter_local_notifications`; no push server or Finsify backend is involved. Reminders are intended to occur approximately every 24 hours before a bill's due date. Schedule precision is platform-controlled, especially for inexact Android scheduling.

## Lifecycle flow

### Create or reschedule

1. The bill is saved first.
2. `schedule(bill)` verifies Android/iOS support, initializes the plugin, cancels existing pending reminder IDs for the bill, exits if paid or past due, and requests notifications permission.
3. It checks pending notification count, applies the implementation's platform limit budget (64 for iOS, 500 for other supported mobile platform), and caps one bill's scheduled notifications at 365/available slots.
4. Individual daily notifications are scheduled with timezone-aware `TZDateTime` values through the due date.
5. If scheduling fails part-way through, it attempts to cancel the bill's scheduled IDs and rethrows the original scheduling error.

### Mark paid/delete

- One-time bill marked paid: persist paid state, then cancel pending notifications for that bill.
- Recurring bill marked paid: advance its due date to next month and schedule the next cycle; the record remains unpaid for that new cycle.
- Delete: remove bill, then cancel all pending reminders belonging to that bill.

## Architecture and API

`BillReminderService` is in `lib/services/financial_services.dart`. Its public in-app methods are:

```dart
Future<void> schedule(Bill bill);
Future<void> cancel(int billId);
```

The service uses:

- `FlutterLocalNotificationsPlugin.initialize(settings: ...)`
- `pendingNotificationRequests()`
- `zonedSchedule(id:, title:, body:, scheduledDate:, notificationDetails:, androidScheduleMode:)`
- `cancel(id:)`
- Android `requestNotificationsPermission()`
- iOS `requestPermissions(alert: true, badge: true, sound: true)`

These are plugin/platform APIs, not HTTP routes.

## Notification IDs and payload

IDs start at 50000 and reserve 1000 IDs per bill:

```text
firstId = 50000 + (billId % 100000) * 1000
notificationId = firstId + dayIndex
```

Title is `Bill due: <name>`. Body reminds the user to pay before the saved due date. Notification channel is `bill_due_reminders`, displayed as “Bill due reminders.” Android uses `inexactAllowWhileIdle`; iOS uses `DarwinNotificationDetails`.

## Platform configuration

Android manifest (`android/app/src/main/AndroidManifest.xml`) declares `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`, and registers scheduled-notification and boot receivers. The app requests notification permission when it schedules a bill. iOS permission is requested through the plugin. Scheduling is rejected on web and non-mobile desktop platforms.

Timezone data is initialized with `timezone/data/latest.dart`; scheduled local `DateTime` values are converted to the service's `tz.local`.

## Errors and edge cases

- Unsupported target: `UnsupportedError`.
- Explicitly denied notification permission: `StateError`.
- No available pending-notification slots: `StateError`.
- Past-due bill: no new notifications are scheduled.
- Bill already paid: any old schedule is canceled, then no new one is added.
- If system permission is restricted or the OS changes delivery timing, notifications may not appear exactly 24 hours apart.

## Limitations and tests

No test currently exercises OS scheduling, reboot restoration, or notification taps. Verify permission prompts, schedule delivery, app update/reboot behavior, and cancellation on physical Android/iOS devices. The service schedules a finite sequence rather than an unbounded repeating notification; if an eligible due date exceeds the cap, only the capped set is scheduled.
