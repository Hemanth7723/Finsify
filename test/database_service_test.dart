import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finsify/database/app_database.dart';
import 'package:finsify/models/expense.dart';
import 'package:finsify/models/profile_data.dart';
import 'package:finsify/services/database_service.dart';
import 'package:finsify/controllers/expense_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('DatabaseService Drift SQLite tests', () {
    late AppDatabase appDb;
    late DatabaseService dbService;

    setUp(() {
      appDb = AppDatabase(NativeDatabase.memory());
      dbService = DatabaseService(database: appDb);
      DatabaseService.instance = dbService;
    });

    tearDown(() async {
      await dbService.close();
    });

    test('saves and retrieves profile data with Drift', () async {
      final initial = await dbService.getProfile();
      expect(initial, isNull);

      const profile = ProfileData(
        name: 'Alice',
        email: 'alice@example.com',
        bio: 'Save 20% every month',
      );

      await dbService.saveProfile(profile);

      final retrieved = await dbService.getProfile();
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'Alice');
      expect(retrieved?.email, 'alice@example.com');
      expect(retrieved?.bio, 'Save 20% every month');

      // Update profile
      const updated = ProfileData(
        name: 'Alice Cooper',
        email: 'alice.c@example.com',
        bio: 'Updated bio',
      );
      await dbService.saveProfile(updated);

      final secondRetrieved = await dbService.getProfile();
      expect(secondRetrieved?.name, 'Alice Cooper');
      expect(secondRetrieved?.email, 'alice.c@example.com');
      expect(secondRetrieved?.bio, 'Updated bio');
    });

    test('inserts, updates, queries and deletes expenses with Drift', () async {
      final now = DateTime.now();
      final expense1 = Expense(
        id: 101,
        title: 'Grocery Store',
        amount: 54.50,
        category: 'Food',
        timestamp: now.subtract(const Duration(hours: 2)),
        note: 'Weekly essentials',
      );
      final expense2 = Expense(
        id: 102,
        title: 'Bus Ticket',
        amount: 3.25,
        category: 'Transport',
        timestamp: now,
      );

      await dbService.insertExpense(expense1);
      await dbService.insertExpense(expense2);

      final expenses = await dbService.getExpenses();
      expect(expenses.length, 2);
      expect(expenses.first.title, 'Bus Ticket'); // sorted by timestamp DESC

      // Update expense
      final updatedExpense1 = expense1.copyWith(
        amount: 60.0,
        note: 'Weekly essentials with snacks',
      );
      await dbService.updateExpense(updatedExpense1);

      final refreshed = await dbService.getExpenses();
      final found = refreshed.firstWhere((e) => e.id == 101);
      expect(found.amount, 60.0);
      expect(found.note, 'Weekly essentials with snacks');

      // Delete expense
      await dbService.deleteExpense(102);
      final afterDelete = await dbService.getExpenses();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.id, 101);

      // Clear all
      await dbService.clearAllExpenses();
      final empty = await dbService.getExpenses();
      expect(empty, isEmpty);
    });

    test('ExpenseController persists and reloads expenses across restart', () async {
      final controller = ExpenseController(databaseService: dbService);
      await controller.load();
      expect(controller.expenses, isEmpty);

      final exp = Expense(
        id: 201,
        title: 'Dinner with friends',
        amount: 45.00,
        category: 'Food',
        timestamp: DateTime(2026, 11, 2, 19, 0),
      );

      await controller.addExpense(exp);
      expect(controller.expenses.length, 1);
      expect(controller.totalSpend, 45.00);

      // Simulate app restart by creating a new controller with the same database
      final restartedController = ExpenseController(databaseService: dbService);
      await restartedController.load();

      expect(restartedController.expenses.length, 1);
      expect(restartedController.expenses.first.title, 'Dinner with friends');
      expect(restartedController.expenses.first.amount, 45.00);
      expect(restartedController.totalSpend, 45.00);

      // Delete in restarted controller and verify persistence
      await restartedController.deleteExpense(201);
      expect(restartedController.expenses, isEmpty);

      final thirdController = ExpenseController(databaseService: dbService);
      await thirdController.load();
      expect(thirdController.expenses, isEmpty);
    });
  });
}
