import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finsify/controllers/financial_controller.dart';
import 'package:finsify/database/app_database.dart';
import 'package:finsify/models/financial_item.dart';
import 'package:finsify/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    DatabaseService.instance = DatabaseService(
      database: AppDatabase(NativeDatabase.memory()),
    );
  });

  test('persists and reloads investment records locally with Drift', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FinancialController();
    await controller.load();
    await controller.addInvestment(
      Investment(
        id: 1,
        name: 'Index fund',
        type: InvestmentType.mutualFunds,
        contributionType: ContributionType.sip,
        amount: 500,
        monthlyContribution: 100,
        annualReturnPercent: 8,
        startDate: DateTime(2025, 1, 1),
      ),
    );
    await controller.addLoan(
      Loan(
        id: 2,
        name: 'Car loan',
        principal: 10000,
        annualInterestPercent: 8.5,
        interestType: LoanInterestType.reducingBalance,
        tenureMonths: 36,
        fees: 250,
        startDate: DateTime(2025, 2, 1),
      ),
    );
    await controller.addBill(
      Bill(
        id: 3,
        name: 'Travel card',
        type: BillType.creditCard,
        amount: 1250,
        dueDate: DateTime(2026, 10, 20),
        recurringMonthly: true,
      ),
    );

    final restored = FinancialController();
    await restored.load();

    expect(restored.investments, hasLength(1));
    expect(restored.investments.single.name, 'Index fund');
    expect(restored.investments.single.monthlyContribution, 100);
    expect(restored.loans.single.totalPayable, greaterThan(10000));
    expect(restored.bills.single.recurringMonthly, isTrue);
    expect(restored.bills.single.isPaid, isFalse);

    // Test updates and deletions
    await restored.updateBill(
      restored.bills.single.copyWith(isPaid: true),
    );
    final updatedCheck = FinancialController();
    await updatedCheck.load();
    expect(updatedCheck.bills.single.isPaid, isTrue);

    await updatedCheck.deleteInvestment(1);
    await updatedCheck.deleteLoan(2);
    await updatedCheck.deleteBill(3);

    final emptyCheck = FinancialController();
    await emptyCheck.load();
    expect(emptyCheck.investments, isEmpty);
    expect(emptyCheck.loans, isEmpty);
    expect(emptyCheck.bills, isEmpty);
  });
}
