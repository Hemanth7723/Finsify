import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import 'gmail_transaction_parser.dart';

/// Listens to Android system notifications via [NotificationListenerService]
/// and auto-saves bank/UPI transactions posted by Gmail as [Expense] records.
///
/// **Platform scope:** Android only.
/// On iOS and web this class is a no-op; all public methods return
/// immediately without calling any platform code.
///
/// **Privacy:** Only the notification title/content is read, and only when
/// the package is `com.google.android.gm`. Raw text is discarded after
/// parsing; only expense fields and an optional account suffix are persisted.
class GmailNotifImportService {
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns `true` when the user has granted Notification Access on Android.
  /// Always returns `false` on iOS/web.
  Future<bool> isPermissionGranted() async {
    if (!_isSupported) return false;
    return NotificationListenerService.isPermissionGranted();
  }

  /// Opens Android's Notification Access settings page so the user can grant
  /// permission.  No-op on iOS/web.
  Future<void> openPermissionSettings() async {
    if (!_isSupported) return;
    await NotificationListenerService.requestPermission();
  }

  /// Begins listening for Gmail bank notifications and auto-saving expenses.
  ///
  /// - Filters to `com.google.android.gm` only (inside [GmailTransactionParser]).
  /// - Uses the event's posted time and atomically saves each import once.
  /// - Calls [onImported] with a human-readable summary on success.
  /// - Calls [onError] with an error description on failure.
  void startListening({
    required ExpenseController expenseController,
    void Function(String message)? onImported,
    void Function(String error)? onError,
  }) {
    if (!_isSupported) return;
    _subscription?.cancel();
    _subscription = NotificationListenerService.notificationsStream
        .where((e) => !e.hasRemoved) // only posted events
        .listen((event) {
          unawaited(
            processNotificationEvent(
              event,
              expenseController: expenseController,
              onImported: onImported,
            ).catchError((Object e) => onError?.call(e.toString())),
          );
        }, onError: (Object e) => onError?.call(e.toString()));
  }

  @visibleForTesting
  Future<void> processNotificationEvent(
    ServiceNotificationEvent event, {
    required ExpenseController expenseController,
    void Function(String message)? onImported,
  }) async {
    if (event.hasRemoved) return;
    final parsed = GmailTransactionParser.parse(
      packageName: event.packageName,
      title: event.title,
      content: event.content,
      timestamp: event.humanTime,
    );
    if (parsed == null) return;

    final expense = Expense(
      id: parsed.fingerprint.hashCode & 0x7fffffff,
      title: parsed.title,
      amount: parsed.amount,
      category: parsed.category,
      timestamp: parsed.timestamp,
      note: 'Imported from Gmail notification',
    );
    final added = await expenseController.addImportedExpenseIfNew(
      expense: expense,
      fingerprint: parsed.fingerprint,
      transactionReference: parsed.transactionReference,
    );
    if (added) onImported?.call('Recorded: ${expense.title}');
  }

  /// Stops the notification stream subscription.
  void stopListening() => _subscription?.cancel();

  /// Stops listening and releases resources.
  void dispose() => stopListening();
}
