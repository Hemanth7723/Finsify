import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/financial_item.dart';
import '../services/database_service.dart';

class FinancialController extends ChangeNotifier {
  FinancialController({DatabaseService? databaseService})
      : _dbService = databaseService ?? DatabaseService.instance;

  final DatabaseService _dbService;
  List<Investment> _investments = [];
  List<Loan> _loans = [];
  List<Bill> _bills = [];
  static const _legacyStorageKey = 'finsify_financial_records_v1';
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
      _investments = await _dbService.getInvestments();
      _loans = await _dbService.getLoans();
      _bills = await _dbService.getBills();

      // Migrate legacy SharedPreferences records into Drift if present
      if (_investments.isEmpty && _loans.isEmpty && _bills.isEmpty) {
        await _migrateLegacyRecordsIfPresent();
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
    await _dbService.insertInvestment(investment);
  }

  Future<void> addLoan(Loan loan) async {
    _loans.add(loan);
    notifyListeners();
    await _dbService.insertLoan(loan);
  }

  Future<void> addBill(Bill bill) async {
    _bills.add(bill);
    notifyListeners();
    await _dbService.insertBill(bill);
  }

  Future<void> updateBill(Bill bill) async {
    final index = _bills.indexWhere((item) => item.id == bill.id);
    if (index == -1) {
      throw StateError('Bill was not found.');
    }
    _bills[index] = bill;
    notifyListeners();
    await _dbService.updateBill(bill);
  }

  Future<void> deleteInvestment(int id) async {
    _investments.removeWhere((item) => item.id == id);
    notifyListeners();
    await _dbService.deleteInvestment(id);
  }

  Future<void> deleteLoan(int id) async {
    _loans.removeWhere((item) => item.id == id);
    notifyListeners();
    await _dbService.deleteLoan(id);
  }

  Future<void> deleteBill(int id) async {
    _bills.removeWhere((item) => item.id == id);
    notifyListeners();
    await _dbService.deleteBill(id);
  }

  Future<void> _migrateLegacyRecordsIfPresent() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_legacyStorageKey);
      if (encoded != null) {
        final data = jsonDecode(encoded) as Map<String, dynamic>;
        final legacyInvestments = (data['investments'] as List<dynamic>?)
                ?.map((item) => _investmentFromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
        final legacyLoans = (data['loans'] as List<dynamic>?)
                ?.map((item) => _loanFromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
        final legacyBills = (data['bills'] as List<dynamic>?)
                ?.map((item) => _billFromJson(item as Map<String, dynamic>))
                .toList() ??
            [];

        for (final inv in legacyInvestments) {
          await _dbService.insertInvestment(inv);
        }
        for (final loan in legacyLoans) {
          await _dbService.insertLoan(loan);
        }
        for (final bill in legacyBills) {
          await _dbService.insertBill(bill);
        }

        if (legacyInvestments.isNotEmpty ||
            legacyLoans.isNotEmpty ||
            legacyBills.isNotEmpty) {
          _investments = await _dbService.getInvestments();
          _loans = await _dbService.getLoans();
          _bills = await _dbService.getBills();
        }
      }
    } catch (_) {
      // Legacy migration is best-effort
    }
  }

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
