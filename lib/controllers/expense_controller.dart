import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController({DatabaseService? databaseService})
      : _dbService = databaseService ?? DatabaseService.instance;

  final DatabaseService _dbService;
  final List<Expense> _expenses = [];
  List<Expense> _cachedVisibleExpenses = [];
  bool _visibleDirty = true;
  String _categoryFilter = 'All';
  String _sortOrder = 'Newest';
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  String get categoryFilter => _categoryFilter;
  String get sortOrder => _sortOrder;
  double get totalSpend =>
      _expenses.fold(0, (total, item) => total + item.amount);

  List<Expense> get visibleExpenses {
    if (_visibleDirty) {
      _recomputeVisibleExpenses();
      _visibleDirty = false;
    }
    return _cachedVisibleExpenses;
  }

  void _recomputeVisibleExpenses() {
    final visible = _categoryFilter == 'All'
        ? [..._expenses]
        : _expenses
            .where(
              (item) =>
                  item.category.toLowerCase() == _categoryFilter.toLowerCase(),
            )
            .toList();
    switch (_sortOrder) {
      case 'Oldest':
        visible.sort(
          (left, right) => left.timestamp.compareTo(right.timestamp),
        );
      case 'Amount High':
        visible.sort((left, right) => right.amount.compareTo(left.amount));
      case 'Amount Low':
        visible.sort((left, right) => left.amount.compareTo(right.amount));
      default:
        visible.sort(
          (left, right) => right.timestamp.compareTo(left.timestamp),
        );
    }
    _cachedVisibleExpenses = visible;
  }

  Future<void> load() async {
    try {
      final loaded = await _dbService.getExpenses();
      _expenses
        ..clear()
        ..addAll(loaded);
      _visibleDirty = true;
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
      rethrow;
    }
  }

  void setCategoryFilter(String category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    _visibleDirty = true;
    notifyListeners();
  }

  void setSortOrder(String order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    _visibleDirty = true;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _visibleDirty = true;
    notifyListeners();
    try {
      await _dbService.insertExpense(expense);
    } catch (_) {
      // In-memory state remains intact
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    _visibleDirty = true;
    notifyListeners();
    try {
      await _dbService.updateExpense(expense);
    } catch (_) {
      // In-memory state remains intact
    }
  }

  Future<void> deleteExpense(int id) async {
    _expenses.removeWhere((item) => item.id == id);
    _visibleDirty = true;
    notifyListeners();
    try {
      await _dbService.deleteExpense(id);
    } catch (_) {
      // In-memory state remains intact
    }
  }

  Future<void> clearAll() async {
    _expenses.clear();
    _visibleDirty = true;
    notifyListeners();
    try {
      await _dbService.clearAllExpenses();
    } catch (_) {
      // In-memory state remains intact
    }
  }
}
