import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/financial_item.dart';

class FinancialController extends ChangeNotifier {
  List<Investment> _investments = [];
  List<Loan> _loans = [];
  List<Bill> _bills = [];
  static const _storageKey = 'finsify_financial_records_v1';
  bool _loaded = false;
  String? _loadError;

  List<Investment> get investments => List.unmodifiable(_investments);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<Bill> get bills => List.unmodifiable(_bills);
  bool get isLoaded => _loaded;
  String? get loadError => _loadError;

  Future<void> load() async {
    _loadError = null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey);
      if (encoded != null) {
        final data = jsonDecode(encoded) as Map<String, dynamic>;
        _investments = (data['investments'] as List<dynamic>)
            .map((item) => _investmentFromJson(item as Map<String, dynamic>))
            .toList();
        _loans = (data['loans'] as List<dynamic>)
            .map((item) => _loanFromJson(item as Map<String, dynamic>))
            .toList();
        _bills = (data['bills'] as List<dynamic>)
            .map((item) => _billFromJson(item as Map<String, dynamic>))
            .toList();
      }
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error.toString();
      _loaded = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addInvestment(Investment investment) async {
    _investments.add(investment);
    notifyListeners();
    await _save();
  }

  Future<void> addLoan(Loan loan) async {
    _loans.add(loan);
    notifyListeners();
    await _save();
  }

  Future<void> addBill(Bill bill) async {
    _bills.add(bill);
    notifyListeners();
    await _save();
  }

  Future<void> updateBill(Bill bill) async {
    final index = _bills.indexWhere((item) => item.id == bill.id);
    if (index == -1) {
      throw StateError('Bill was not found.');
    }
    _bills[index] = bill;
    notifyListeners();
    await _save();
  }

  Future<void> deleteInvestment(int id) async {
    _investments.removeWhere((item) => item.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> deleteLoan(int id) async {
    _loans.removeWhere((item) => item.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> deleteBill(int id) async {
    _bills.removeWhere((item) => item.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode({
        'investments': _investments.map(_investmentToJson).toList(),
        'loans': _loans.map(_loanToJson).toList(),
        'bills': _bills.map(_billToJson).toList(),
      }),
    );
    if (!saved) {
      throw StateError('Could not save financial records on this device.');
    }
  }

  Map<String, Object> _investmentToJson(Investment item) => {
    'id': item.id,
    'name': item.name,
    'type': item.type.name,
    'contributionType': item.contributionType.name,
    'amount': item.amount,
    'monthlyContribution': item.monthlyContribution,
    'annualReturnPercent': item.annualReturnPercent,
    'startDate': item.startDate.toIso8601String(),
  };

  Investment _investmentFromJson(Map<String, dynamic> data) => Investment(
    id: data['id'] as int,
    name: data['name'] as String,
    type: InvestmentType.values.byName(data['type'] as String),
    contributionType: ContributionType.values.byName(
      data['contributionType'] as String,
    ),
    amount: (data['amount'] as num).toDouble(),
    monthlyContribution: (data['monthlyContribution'] as num).toDouble(),
    annualReturnPercent: (data['annualReturnPercent'] as num).toDouble(),
    startDate: DateTime.parse(data['startDate'] as String),
  );

  Map<String, Object> _loanToJson(Loan item) => {
    'id': item.id,
    'name': item.name,
    'principal': item.principal,
    'annualInterestPercent': item.annualInterestPercent,
    'interestType': item.interestType.name,
    'tenureMonths': item.tenureMonths,
    'fees': item.fees,
    'startDate': item.startDate.toIso8601String(),
  };

  Loan _loanFromJson(Map<String, dynamic> data) => Loan(
    id: data['id'] as int,
    name: data['name'] as String,
    principal: (data['principal'] as num).toDouble(),
    annualInterestPercent: (data['annualInterestPercent'] as num).toDouble(),
    interestType: LoanInterestType.values.byName(
      data['interestType'] as String,
    ),
    tenureMonths: data['tenureMonths'] as int,
    fees: (data['fees'] as num).toDouble(),
    startDate: DateTime.parse(data['startDate'] as String),
  );

  Map<String, Object> _billToJson(Bill item) => {
    'id': item.id,
    'name': item.name,
    'type': item.type.name,
    'amount': item.amount,
    'dueDate': item.dueDate.toIso8601String(),
    'recurringMonthly': item.recurringMonthly,
    'isPaid': item.isPaid,
  };

  Bill _billFromJson(Map<String, dynamic> data) => Bill(
    id: data['id'] as int,
    name: data['name'] as String,
    type: BillType.values.byName(data['type'] as String),
    amount: (data['amount'] as num).toDouble(),
    dueDate: DateTime.parse(data['dueDate'] as String),
    recurringMonthly: data['recurringMonthly'] as bool? ?? false,
    isPaid: data['isPaid'] as bool? ?? false,
  );
}
