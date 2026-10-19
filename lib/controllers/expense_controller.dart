import 'package:flutter/foundation.dart';

import '../models/expense.dart';

class ExpenseController extends ChangeNotifier {
  final List<Expense> _expenses = [];
  String _categoryFilter = 'All';
  String _sortOrder = 'Newest';

  List<Expense> get expenses => List.unmodifiable(_expenses);
  String get categoryFilter => _categoryFilter;
  String get sortOrder => _sortOrder;
  double get totalSpend =>
      _expenses.fold(0, (total, item) => total + item.amount);

  List<Expense> get visibleExpenses {
    final visible = _categoryFilter == 'All'
        ? [..._expenses]
        : _expenses
              .where(
                (item) =>
                    item.category.toLowerCase() ==
                    _categoryFilter.toLowerCase(),
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
    return visible;
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    notifyListeners();
  }

  void deleteExpense(int id) {
    _expenses.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearAll() {
    _expenses.clear();
    notifyListeners();
  }
}
