import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('DbProfile')
class Profiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get bio => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbExpense')
class Expenses extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbAppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('DbInvestment')
class Investments extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get contributionType => text()();
  RealColumn get amount => real()();
  RealColumn get monthlyContribution =>
      real().withDefault(const Constant(0.0))();
  RealColumn get annualReturnPercent => real()();
  DateTimeColumn get startDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbLoan')
class Loans extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  RealColumn get principal => real()();
  RealColumn get annualInterestPercent => real()();
  TextColumn get interestType => text()();
  IntColumn get tenureMonths => integer()();
  RealColumn get fees => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbBill')
class Bills extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get recurringMonthly =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Profiles,
    Expenses,
    AppSettings,
    Investments,
    Loans,
    Bills,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'finsify',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
