import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/expense.dart';
import '../models/financial_item.dart';

class SmsExpenseCandidate {
  const SmsExpenseCandidate({
    required this.id,
    required this.expense,
    required this.preview,
  });

  final String id;
  final Expense expense;
  final String preview;
}

class SmsExpenseImporter {
  Future<List<SmsExpenseCandidate>> fetchRecentExpenses() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('SMS import is available on Android only.');
    }

    final permission = await Permission.sms.request();
    if (!permission.isGranted) {
      throw StateError(
        permission.isPermanentlyDenied
            ? 'SMS access is disabled. Enable it in app settings to import messages.'
            : 'SMS access was not granted.',
      );
    }

    final messages = await SmsQuery().querySms(
      kinds: const [SmsQueryKind.inbox],
      count: 100,
      sort: true,
    );
    final candidates = <SmsExpenseCandidate>[];
    for (final message in messages) {
      final body = message.body;
      if (body == null || body.trim().isEmpty) continue;
      final parsed = _parseTransaction(body);
      if (parsed == null) continue;
      final date = message.date ?? DateTime.now();
      final fingerprint =
          '${message.id ?? date.millisecondsSinceEpoch}-${parsed.amount}';
      candidates.add(
        SmsExpenseCandidate(
          id: fingerprint,
          expense: Expense(
            id: fingerprint.hashCode & 0x7fffffff,
            title: parsed.title,
            amount: parsed.amount,
            category: parsed.category,
            timestamp: date,
            note: 'Imported from SMS',
          ),
          preview: _safePreview(body),
        ),
      );
    }
    return candidates;
  }

  ({String title, double amount, String category})? _parseTransaction(
    String body,
  ) {
    final normalized = body.replaceAll(',', '');
    if (RegExp(
      r'\b(otp|one.time.password|verification code)\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return null;
    }
    if (!RegExp(
      r'\b(debit|debited|spent|purchase|paid|transaction|payment)\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return null;
    }

    final amountMatch = RegExp(
      r'(?:rs\.?|inr|₹)\s*([0-9]+(?:\.[0-9]{1,2})?)|([0-9]+(?:\.[0-9]{1,2})?)\s*(?:inr|rs\.?|₹)',
      caseSensitive: false,
    ).firstMatch(normalized);
    final rawAmount = amountMatch?.group(1) ?? amountMatch?.group(2);
    final amount = rawAmount == null ? null : double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    final lower = normalized.toLowerCase();
    final category = lower.contains('fuel') || lower.contains('petrol')
        ? 'Transport'
        : lower.contains('grocery') || lower.contains('restaurant')
        ? 'Food'
        : lower.contains('pharmacy') || lower.contains('hospital')
        ? 'Health'
        : lower.contains('electricity') || lower.contains('utility')
        ? 'Utilities'
        : 'Miscellaneous';
    final title = normalized
        .replaceFirst(amountMatch!.group(0)!, '')
        .replaceAll(
          RegExp(
            r'\b(available balance|avl bal|balance|debited|debit|spent|purchase|paid|transaction|payment|from|to|at|on|via|using|card|account|a/c|inr|rs\.?)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[*xX]{3,}\d+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (
      title: title.isEmpty ? category : title.split(' ').take(3).join(' '),
      amount: amount,
      category: category,
    );
  }

  String _safePreview(String body) {
    final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return trimmed.length <= 100 ? trimmed : '${trimmed.substring(0, 97)}...';
  }
}

class BillReminderService {
  BillReminderService() {
    tz_data.initializeTimeZones();
  }

  static const _firstNotificationId = 50000;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> schedule(Bill bill) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Bill notifications are supported on mobile only.',
      );
    }
    await _initialize();
    await cancel(bill.id);
    if (bill.isPaid) return;
    final now = DateTime.now();
    final dueEnd = DateTime(
      bill.dueDate.year,
      bill.dueDate.month,
      bill.dueDate.day,
      23,
      59,
    );
    if (!dueEnd.isAfter(now)) return;
    await _requestPermission();

    final firstReminder = now.add(const Duration(hours: 24));
    final earliestReminder = dueEnd.subtract(const Duration(days: 365));
    final pending = await _notifications.pendingNotificationRequests();
    final platformLimit = defaultTargetPlatform == TargetPlatform.iOS
        ? 64
        : 500;
    final remainingSlots = platformLimit - pending.length;
    if (remainingSlots <= 0) {
      throw StateError(
        'The device has no remaining notification slots for bill reminders.',
      );
    }
    final reminderLimit = remainingSlots < 365 ? remainingSlots : 365;
    final limitStart = dueEnd.subtract(Duration(days: reminderLimit - 1));
    final reminderStart = firstReminder.isAfter(dueEnd)
        ? now
        : firstReminder.isBefore(earliestReminder)
        ? (earliestReminder.isBefore(limitStart)
              ? limitStart
              : earliestReminder)
        : (firstReminder.isBefore(limitStart) ? limitStart : firstReminder);
    var reminder = DateTime(
      reminderStart.year,
      reminderStart.month,
      reminderStart.day,
      reminderStart.hour,
      reminderStart.minute,
    );
    var day = 0;
    try {
      while (!reminder.isAfter(dueEnd) && day < reminderLimit) {
        await _notifications.zonedSchedule(
          id: _notificationId(bill.id, day),
          title: 'Bill due: ${bill.name}',
          body:
              'Reminder to pay ${bill.name} before ${bill.dueDate.day}/${bill.dueDate.month}.',
          scheduledDate: tz.TZDateTime.from(reminder, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'bill_due_reminders',
              'Bill due reminders',
              channelDescription:
                  'Daily reminders before saved bill due dates.',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        day++;
        reminder = reminder.add(const Duration(days: 1));
      }
    } catch (_) {
      await cancel(bill.id);
      rethrow;
    }
  }

  Future<void> cancel(int billId) async {
    await _initialize();
    final pending = await _notifications.pendingNotificationRequests();
    final firstId = _firstNotificationId + (billId % 100000) * 1000;
    for (final request in pending) {
      if (request.id >= firstId && request.id < firstId + 1000) {
        await _notifications.cancel(id: request.id);
      }
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<void> _requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) {
      throw StateError('Notification permission was not granted.');
    }
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted == false) {
      throw StateError('Notification permission was not granted.');
    }
  }

  int _notificationId(int billId, int day) =>
      _firstNotificationId + (billId % 100000) * 1000 + day;
}
