enum InvestmentType { stocks, mutualFunds, bonds, debt, other }

enum ContributionType { sip, oneTime }

enum LoanInterestType { reducingBalance, flat }

class Investment {
  const Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.contributionType,
    required this.amount,
    required this.annualReturnPercent,
    required this.startDate,
    this.monthlyContribution = 0,
  });

  final int id;
  final String name;
  final InvestmentType type;
  final ContributionType contributionType;
  final double amount;
  final double monthlyContribution;
  final double annualReturnPercent;
  final DateTime startDate;

  double get investedAmount {
    if (contributionType == ContributionType.oneTime) return amount;
    final months =
        ((DateTime.now().year - startDate.year) * 12 +
                DateTime.now().month -
                startDate.month)
            .clamp(0, 1200);
    return amount + monthlyContribution * months;
  }

  double get estimatedValue {
    final months =
        ((DateTime.now().year - startDate.year) * 12 +
                DateTime.now().month -
                startDate.month)
            .clamp(0, 1200);
    final monthlyRate = annualReturnPercent / 1200;
    if (contributionType == ContributionType.oneTime) {
      return amount * _compoundFactor(monthlyRate, months);
    }
    if (monthlyRate == 0) return amount + monthlyContribution * months;
    final sipValue =
        monthlyContribution *
        ((_compoundFactor(monthlyRate, months) - 1) / monthlyRate);
    return amount * _compoundFactor(monthlyRate, months) + sipValue;
  }

  static double _compoundFactor(double monthlyRate, int months) =>
      _integerPower(1 + monthlyRate, months);

  static double _integerPower(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.principal,
    required this.annualInterestPercent,
    required this.interestType,
    required this.tenureMonths,
    required this.fees,
    required this.startDate,
  });

  final int id;
  final String name;
  final double principal;
  final double annualInterestPercent;
  final LoanInterestType interestType;
  final int tenureMonths;
  final double fees;
  final DateTime startDate;

  double get monthlyPayment {
    if (tenureMonths <= 0) return 0;
    final monthlyRate = annualInterestPercent / 1200;
    if (interestType == LoanInterestType.flat) {
      return (principal +
              principal * annualInterestPercent / 100 * tenureMonths / 12) /
          tenureMonths;
    }
    if (monthlyRate == 0) return principal / tenureMonths;
    final factor = Investment._compoundFactor(monthlyRate, tenureMonths);
    return principal * monthlyRate * factor / (factor - 1);
  }

  double get totalInterest {
    if (tenureMonths <= 0) return 0;
    return interestType == LoanInterestType.flat
        ? principal * annualInterestPercent / 100 * tenureMonths / 12
        : monthlyPayment * tenureMonths - principal;
  }

  double get totalPayable => principal + totalInterest + fees;
  DateTime get endDate {
    final endMonth = DateTime(startDate.year, startDate.month + tenureMonths);
    final finalDay = DateTime(endMonth.year, endMonth.month + 1, 0).day;
    return DateTime(
      endMonth.year,
      endMonth.month,
      startDate.day > finalDay ? finalDay : startDate.day,
    );
  }
}

enum BillType { creditCard, debitCard, other }

class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.recurringMonthly = false,
    this.isPaid = false,
  });

  final int id;
  final String name;
  final BillType type;
  final double amount;
  final DateTime dueDate;
  final bool recurringMonthly;
  final bool isPaid;

  Bill copyWith({DateTime? dueDate, bool? isPaid}) {
    return Bill(
      id: id,
      name: name,
      type: type,
      amount: amount,
      dueDate: dueDate ?? this.dueDate,
      recurringMonthly: recurringMonthly,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
