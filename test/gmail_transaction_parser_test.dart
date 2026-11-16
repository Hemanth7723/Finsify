import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:finsify/controllers/expense_controller.dart';
import 'package:finsify/database/app_database.dart';
import 'package:finsify/models/expense.dart';
import 'package:finsify/services/database_service.dart';
import 'package:finsify/services/gmail_notif_import_service.dart';
import 'package:finsify/services/gmail_transaction_parser.dart';
import 'package:finsify/services/transaction_import_identity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_listener_service/notification_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('GmailTransactionParser unit tests', () {
    const gmailPkg = 'com.google.android.gm';
    final testTime = DateTime(2026, 11, 10, 14, 30, 15);

    test('parses Indian Rupee (₹) debit transaction for Food', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Bank Alert: Transaction Successful',
        content: 'Dear Customer, Rs. 450.00 debited from A/C **1234 on 10-Nov for Swiggy order. Avl Bal: Rs 12,000',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 450.0);
      expect(parsed.category, 'Food');
      expect(parsed.title.toLowerCase(), contains('swiggy'));
      expect(parsed.fingerprint, isNotEmpty);
    });

    test('parses INR symbol debit transaction for Transport', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'HDFC Bank: Debit Alert',
        content: 'INR 1,200.50 spent via card at Uber India on 10-Nov.',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1200.50);
      expect(parsed.category, 'Transport');
      expect(parsed.title.toLowerCase(), contains('uber'));
    });

    test('parses ₹ symbol debit transaction for Entertainment', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'ICICI Bank Alert',
        content: '₹ 649 paid for Netflix subscription renewal.',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 649.0);
      expect(parsed.category, 'Entertainment');
      expect(parsed.title.toLowerCase(), contains('netflix'));
    });

    test('parses Shopping category for Amazon/Flipkart transactions', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'SBI Card Transaction',
        content: 'Rs. 2,499.00 spent on your Credit Card ending in 4321 at Amazon Retail.',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 2499.0);
      expect(parsed.category, 'Shopping');
      expect(parsed.title.toLowerCase(), contains('amazon'));
    });

    test('parses Utilities category for electricity/recharge', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Axis Bank Alert',
        content: 'Payment of Rs. 1500 to Tata Power electricity bill was successful.',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1500.0);
      expect(parsed.category, 'Utilities');
    });

    test('extracts the UPI reference from a bank email', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Transaction Alert',
        content: '''
Dear Customer,
Here's the summary of your transaction:
Amount Debited:
INR 48.00
Account Number:
XXXXXX
Date & Time:
16-11-26, 19:48:01 IST
Transaction Info:
UPI/P2M/194801246719/COMPASS INDIA FOOD''',
        timestamp: testTime,
      );

      expect(parsed?.amount, 48);
      expect(parsed?.transactionReference, '194801246719');
    });

    test('extracts the UPI reference from an SMS', () {
      expect(
        extractUpiReference(
          'INR 40.00 debited A/c no. XXXXXX 15-11-26, 20:22:22 '
          'UPI/P2M/202221774779/THOTA GANGADHAR RE',
        ),
        '202221774779',
      );
    });

    test('parses Health category for medical/pharmacy', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Kotak Bank Alert',
        content: 'Rs. 750 debited for Apollo Pharmacy medical purchase.',
        timestamp: testTime,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 750.0);
      expect(parsed.category, 'Health');
    });

    test('rejects non-Gmail package notification', () {
      final parsed = GmailTransactionParser.parse(
        packageName: 'com.whatsapp',
        title: 'Alert',
        content: 'Paid Rs. 500 to Friend',
        timestamp: testTime,
      );

      expect(parsed, isNull);
    });

    test('rejects OTP messages even when amount is mentioned', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Bank OTP Alert',
        content: 'OTP is 543210 for purchase of Rs. 2,000 at Flipkart. Do not share OTP.',
        timestamp: testTime,
      );

      expect(parsed, isNull);
    });

    test('rejects credit / refund messages', () {
      final parsed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Account Credited',
        content:
            'Your A/C has been credited with Rs. 25,000 towards salary refund.',
        timestamp: testTime,
      );

      expect(parsed, isNull);
    });

    test('rejects failed / declined / pending transactions', () {
      final failed = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Transaction Failed',
        content: 'Your transaction of Rs. 1,000 has failed due to timeout.',
        timestamp: testTime,
      );
      expect(failed, isNull);

      final declined = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Card Declined',
        content: 'Card payment of Rs. 850 was declined by bank.',
        timestamp: testTime,
      );
      expect(declined, isNull);
    });

    test('rejects messages without amount or valid debit indicators', () {
      final noAmount = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Transaction update',
        content: 'Your account was debited for your order.',
        timestamp: testTime,
      );
      expect(noAmount, isNull);

      final noDebit = GmailTransactionParser.parse(
        packageName: gmailPkg,
        title: 'Monthly statement',
        content: 'Check your e-statement for Rs. 5000 due date.',
        timestamp: testTime,
      );
      expect(noDebit, isNull);
    });

    test(
      'fingerprint is identical for re-deliveries within the same minute',
      () {
        final ts1 = DateTime(2026, 11, 10, 14, 30, 5);
        final ts2 = DateTime(2026, 11, 10, 14, 30, 45);

        final fp1 = GmailTransactionParser.buildFingerprint(
          450.0,
          'Swiggy Order',
          ts1,
        );
        final fp2 = GmailTransactionParser.buildFingerprint(
          450.0,
          'Swiggy Order',
          ts2,
        );

        expect(fp1, equals(fp2));
      },
    );

    test('fingerprint changes across different minutes or amounts', () {
      final ts1 = DateTime(2026, 11, 10, 14, 30, 0);
      final ts2 = DateTime(2026, 11, 10, 14, 32, 0);

      final fp1 = GmailTransactionParser.buildFingerprint(
        450.0,
        'Swiggy Order',
        ts1,
      );
      final fp2 = GmailTransactionParser.buildFingerprint(
        450.0,
        'Swiggy Order',
        ts2,
      );
      final fp3 = GmailTransactionParser.buildFingerprint(
        500.0,
        'Swiggy Order',
        ts1,
      );

      expect(fp1, isNot(equals(fp2)));
      expect(fp1, isNot(equals(fp3)));
    });
  });

  group('Imported expense deduplication tests', () {
    late AppDatabase appDb;
    late DatabaseService dbService;
    late ExpenseController controller;

    setUp(() {
      appDb = AppDatabase(NativeDatabase.memory());
      dbService = DatabaseService(database: appDb);
      controller = ExpenseController(databaseService: dbService);
    });

    tearDown(() async {
      controller.dispose();
      await dbService.close();
    });

    test(
      'only one concurrent delivery can save the same UPI reference',
      () async {
        final expense = Expense(
          id: 1,
          title: 'Compass India Food',
          amount: 48,
          category: 'Food',
          timestamp: DateTime(2026, 11, 10, 14, 30),
        );
        final results = await Future.wait([
          controller.addImportedExpenseIfNew(
            expense: expense,
            fingerprint: 'sms-1',
            transactionReference: '194801246719',
          ),
          controller.addImportedExpenseIfNew(
            expense: expense,
            fingerprint: 'gmail-1',
            transactionReference: '194801246719',
          ),
        ]);

        expect(results.where((added) => added), hasLength(1));
        expect(await dbService.getExpenses(), hasLength(1));
        expect(controller.expenses, hasLength(1));
      },
    );

    test('keeps the provided mail and SMS transactions distinct', () async {
      for (final (id, amount, timestamp, reference) in [
        (1, 48.0, DateTime(2026, 11, 16, 19, 48), '194801246719'),
        (2, 40.0, DateTime(2026, 11, 15, 20, 22), '202221774779'),
        (3, 48.0, DateTime(2026, 11, 16, 19, 48), 'another-reference'),
      ]) {
        expect(
          await controller.addImportedExpenseIfNew(
            expense: Expense(
              id: id,
              title: 'Food',
              amount: amount,
              category: 'Food',
              timestamp: timestamp,
            ),
            fingerprint: 'source-$id',
            transactionReference: reference,
          ),
          isTrue,
        );
      }
      expect(await dbService.getExpenses(), hasLength(3));
    });
  });

  test('uses the notification post time for the imported expense', () async {
    final appDb = AppDatabase(NativeDatabase.memory());
    final dbService = DatabaseService(database: appDb);
    final controller = ExpenseController(databaseService: dbService);
    final service = GmailNotifImportService();
    final eventTime = DateTime(2026, 11, 10, 14, 30, 15);
    final event = ServiceNotificationEvent(
      id: 1,
      title: 'Bank debit alert',
      canReply: false,
      haveExtraPicture: false,
      hasRemoved: false,
      packageName: 'com.google.android.gm',
      content: 'INR 48.00 debited. UPI/P2M/194801246719/COMPASS INDIA FOOD',
      onGoing: false,
      timestamp: eventTime.millisecondsSinceEpoch,
      appIcon: null,
      extrasPicture: null,
      largeIcon: null,
    );

    await service.processNotificationEvent(
      event,
      expenseController: controller,
    );

    expect(controller.expenses.single.timestamp, eventTime);
    expect(
      await controller.addImportedExpenseIfNew(
        expense: Expense(
          id: 2,
          title: 'Swiggy order',
          amount: 48,
          category: 'Food',
          timestamp: eventTime.subtract(const Duration(days: 1)),
          note: 'Imported from SMS',
        ),
        fingerprint: 'sms-copy',
        transactionReference: '194801246719',
      ),
      isFalse,
    );
    expect(controller.expenses, hasLength(1));
    await dbService.close();
    controller.dispose();
    service.dispose();
  });

  group('GmailNotifImportService platform guards (iOS / non-Android)', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('isPermissionGranted returns false when on non-Android', () async {
      final service = GmailNotifImportService();
      final result = await service.isPermissionGranted();
      expect(result, isFalse);
    });

    test(
      'openPermissionSettings and startListening do not throw on non-Android',
      () async {
        final service = GmailNotifImportService();
        await expectLater(service.openPermissionSettings(), completes);

        final appDb = AppDatabase(NativeDatabase.memory());
        final dbService = DatabaseService(database: appDb);
        final controller = ExpenseController(databaseService: dbService);

        expect(
          () => service.startListening(expenseController: controller),
          returnsNormally,
        );

        service.stopListening();
        service.dispose();
        controller.dispose();
        await dbService.close();
      },
    );
  });
}
