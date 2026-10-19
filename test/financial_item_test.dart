import 'package:finsify/models/financial_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reducing-balance loan calculates EMI, interest, fees and end date', () {
    final loan = Loan(
      id: 1,
      name: 'Personal loan',
      principal: 12000,
      annualInterestPercent: 12,
      interestType: LoanInterestType.reducingBalance,
      tenureMonths: 12,
      fees: 500,
      startDate: DateTime(2025, 1, 15),
    );

    expect(loan.monthlyPayment, closeTo(1066.19, 0.01));
    expect(loan.totalInterest, closeTo(794.19, 0.1));
    expect(loan.totalPayable, closeTo(13294.19, 0.1));
    expect(loan.endDate, DateTime(2026, 1, 15));
  });

  test('flat-rate loan computes interest on original principal', () {
    final loan = Loan(
      id: 2,
      name: 'Flat loan',
      principal: 10000,
      annualInterestPercent: 10,
      interestType: LoanInterestType.flat,
      tenureMonths: 24,
      fees: 0,
      startDate: DateTime(2025, 1, 1),
    );

    expect(loan.totalInterest, 2000);
    expect(loan.monthlyPayment, 500);
  });
}
