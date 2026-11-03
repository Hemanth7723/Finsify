import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/expense.dart';
import '../models/financial_item.dart';
import '../models/profile_data.dart';

class DatabaseService {
  DatabaseService({AppDatabase? database})
      : _database = database ?? AppDatabase();

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService();
  static set instance(DatabaseService service) => _instance = service;

  final AppDatabase _database;

  AppDatabase get db => _database;

  // --- Profile Operations ---

  Future<ProfileData?> getProfile() async {
    final query = _database.select(_database.profiles)
      ..where((tbl) => tbl.id.equals(1))
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ProfileData(
      name: row.name,
      email: row.email,
      bio: row.bio,
    );
  }

  Future<void> saveProfile(ProfileData profile) async {
    await _database.into(_database.profiles).insertOnConflictUpdate(
      ProfilesCompanion(
        id: const Value(1),
        name: Value(profile.name),
        email: Value(profile.email),
        bio: Value(profile.bio),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProfile() async {
    await (_database.delete(_database.profiles)
          ..where((tbl) => tbl.id.equals(1)))
        .go();
  }

  // --- Expense Operations ---

  Future<List<Expense>> getExpenses() async {
    final query = _database.select(_database.expenses)
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => Expense(
            id: row.id,
            title: row.title,
            amount: row.amount,
            category: row.category,
            timestamp: row.timestamp,
            note: row.note,
          ),
        )
        .toList();
  }

  Future<void> insertExpense(Expense expense) async {
    await _database.into(_database.expenses).insertOnConflictUpdate(
      ExpensesCompanion(
        id: Value(expense.id),
        title: Value(expense.title),
        amount: Value(expense.amount),
        category: Value(expense.category),
        timestamp: Value(expense.timestamp),
        note: Value(expense.note),
      ),
    );
  }

  Future<void> updateExpense(Expense expense) async {
    await (_database.update(_database.expenses)
          ..where((t) => t.id.equals(expense.id)))
        .write(
      ExpensesCompanion(
        title: Value(expense.title),
        amount: Value(expense.amount),
        category: Value(expense.category),
        timestamp: Value(expense.timestamp),
        note: Value(expense.note),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await (_database.delete(_database.expenses)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> clearAllExpenses() async {
    await _database.delete(_database.expenses).go();
  }

  // --- Investment Operations ---

  Future<List<Investment>> getInvestments() async {
    final query = _database.select(_database.investments)
      ..orderBy([
        (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => Investment(
            id: row.id,
            name: row.name,
            type: InvestmentType.values.byName(row.type),
            contributionType:
                ContributionType.values.byName(row.contributionType),
            amount: row.amount,
            monthlyContribution: row.monthlyContribution,
            annualReturnPercent: row.annualReturnPercent,
            startDate: row.startDate,
          ),
        )
        .toList();
  }

  Future<void> insertInvestment(Investment item) async {
    await _database.into(_database.investments).insertOnConflictUpdate(
      InvestmentsCompanion(
        id: Value(item.id),
        name: Value(item.name),
        type: Value(item.type.name),
        contributionType: Value(item.contributionType.name),
        amount: Value(item.amount),
        monthlyContribution: Value(item.monthlyContribution),
        annualReturnPercent: Value(item.annualReturnPercent),
        startDate: Value(item.startDate),
      ),
    );
  }

  Future<void> deleteInvestment(int id) async {
    await (_database.delete(_database.investments)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // --- Loan Operations ---

  Future<List<Loan>> getLoans() async {
    final query = _database.select(_database.loans)
      ..orderBy([
        (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => Loan(
            id: row.id,
            name: row.name,
            principal: row.principal,
            annualInterestPercent: row.annualInterestPercent,
            interestType: LoanInterestType.values.byName(row.interestType),
            tenureMonths: row.tenureMonths,
            fees: row.fees,
            startDate: row.startDate,
          ),
        )
        .toList();
  }

  Future<void> insertLoan(Loan item) async {
    await _database.into(_database.loans).insertOnConflictUpdate(
      LoansCompanion(
        id: Value(item.id),
        name: Value(item.name),
        principal: Value(item.principal),
        annualInterestPercent: Value(item.annualInterestPercent),
        interestType: Value(item.interestType.name),
        tenureMonths: Value(item.tenureMonths),
        fees: Value(item.fees),
        startDate: Value(item.startDate),
      ),
    );
  }

  Future<void> deleteLoan(int id) async {
    await (_database.delete(_database.loans)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // --- Bill Operations ---

  Future<List<Bill>> getBills() async {
    final query = _database.select(_database.bills)
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => Bill(
            id: row.id,
            name: row.name,
            type: BillType.values.byName(row.type),
            amount: row.amount,
            dueDate: row.dueDate,
            recurringMonthly: row.recurringMonthly,
            isPaid: row.isPaid,
          ),
        )
        .toList();
  }

  Future<void> insertBill(Bill item) async {
    await _database.into(_database.bills).insertOnConflictUpdate(
      BillsCompanion(
        id: Value(item.id),
        name: Value(item.name),
        type: Value(item.type.name),
        amount: Value(item.amount),
        dueDate: Value(item.dueDate),
        recurringMonthly: Value(item.recurringMonthly),
        isPaid: Value(item.isPaid),
      ),
    );
  }

  Future<void> updateBill(Bill item) async {
    await (_database.update(_database.bills)
          ..where((t) => t.id.equals(item.id)))
        .write(
      BillsCompanion(
        name: Value(item.name),
        type: Value(item.type.name),
        amount: Value(item.amount),
        dueDate: Value(item.dueDate),
        recurringMonthly: Value(item.recurringMonthly),
        isPaid: Value(item.isPaid),
      ),
    );
  }

  Future<void> deleteBill(int id) async {
    await (_database.delete(_database.bills)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // --- Settings Operations ---

  Future<String?> getSetting(String key) async {
    final query = _database.select(_database.appSettings)
      ..where((tbl) => tbl.key.equals(key))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await _database.into(_database.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<void> close() async {
    await _database.close();
  }
}
