import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/transaction_utils.dart';

class SearchViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _showExpenses = true; // Toggle between expenses and income
  String? _errorMessage;

  // Search parameters
  String _searchText = '';
  String _selectedCategory = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterActive = false;

  // Data
  List<ExpenseModel> _allExpenses = [];
  List<ExpenseModel> _searchResults = [];
  List<String> _availableCategories = [];

  // Totals
  double _expenseTotal = 0;
  double _incomeTotal = 0;
  double _netTotal = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get showExpenses => _showExpenses;
  String? get errorMessage => _errorMessage;
  String get searchText => _searchText;
  String get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isFilterActive => _isFilterActive;
  List<ExpenseModel> get allExpenses => _allExpenses;
  List<ExpenseModel> get searchResults => _searchResults;
  List<String> get availableCategories => _availableCategories;
  double get expenseTotal => _expenseTotal;
  double get incomeTotal => _incomeTotal;
  double get netTotal => _netTotal;

  // Initialize
  Future<void> initialize() async {
    await loadAllExpenses();
  }

  // Load all expenses for searching
  Future<void> loadAllExpenses() async {
    _setLoading(true);

    try {
      final expenses = await _databaseService.getUserExpenses().first;

      // Extract unique categories
      Set<String> categories = {};
      expenses.forEach((expense) {
        if (expense.category.isNotEmpty) {
          categories.add(expense.category);
        }
      });

      _allExpenses = expenses;
      _searchResults = expenses;
      _availableCategories = categories.toList()..sort();

      _calculateTotals();
    } catch (e) {
      _setError("Không thể tải danh sách giao dịch. Vui lòng thử lại sau.");
    } finally {
      _setLoading(false);
    }
  }

  // Apply search filters
  void applyFilters() {
    _setLoading(true);

    try {
      List<ExpenseModel> filteredResults = List.from(_allExpenses);

      // Apply text search filter
      if (_searchText.isNotEmpty) {
        String query = _searchText.toLowerCase().trim();
        filteredResults = filteredResults.where((expense) {
          return expense.note.toLowerCase().contains(query) ||
              expense.category.toLowerCase().contains(query) ||
              expense.amount.toString().contains(query);
        }).toList();
      }

      // Apply category filter
      if (_selectedCategory.isNotEmpty) {
        filteredResults = filteredResults.where((expense) {
          return expense.category == _selectedCategory;
        }).toList();
      }

      // Apply date range filter
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        filteredResults = filteredResults.where((expense) {
          return expense.date.isAfter(start.subtract(Duration(seconds: 1))) ||
              isSameDay(expense.date, start);
        }).toList();
      }

      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        filteredResults = filteredResults.where((expense) {
          return expense.date.isBefore(end.add(Duration(seconds: 1))) ||
              isSameDay(expense.date, end);
        }).toList();
      }

      _searchResults = filteredResults;
      _isFilterActive = _selectedCategory.isNotEmpty || _startDate != null || _endDate != null;

      _calculateTotals();
    } catch (e) {
      _setError("Lỗi khi lọc dữ liệu. Vui lòng thử lại.");
    } finally {
      _setLoading(false);
    }
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calculate totals based on search results
  void _calculateTotals() {
    double expenses = 0;
    double income = 0;

    for (var item in _searchResults) {
      if (item.isExpense) {
        expenses += item.amount;
      } else {
        income += item.amount;
      }
    }

    _expenseTotal = expenses;
    _incomeTotal = income;
    _netTotal = income - expenses;

    notifyListeners();
  }

  // Set search text
  void setSearchText(String text) {
    _searchText = text;
    applyFilters();
  }

  // Set selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    applyFilters();
  }

  // Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    applyFilters();
  }

  // Reset all filters
  void resetFilters() {
    _searchText = '';
    _selectedCategory = '';
    _startDate = null;
    _endDate = null;
    _isFilterActive = false;
    _searchResults = _allExpenses;

    _calculateTotals();
  }

  // Toggle between expenses and income view
  void toggleExpensesIncomeView(bool showExpenses) {
    _showExpenses = showExpenses;
    notifyListeners();
  }

  // Edit transaction
  Future<bool> editTransaction(ExpenseModel expense) async {
    try {
      _setLoading(true);

      final result = await TransactionUtils.editTransaction(expense, _databaseService);

      if (result.success && result.updatedExpense != null) {
        ExpenseModel updatedExpense = result.updatedExpense!;

        // Update in all expenses list
        int allIndex = _allExpenses.indexWhere((item) => item.id == expense.id);
        if (allIndex >= 0) {
          _allExpenses[allIndex] = updatedExpense;
        }

        // Update in search results list
        int searchIndex = _searchResults.indexWhere((item) => item.id == expense.id);
        if (searchIndex >= 0) {
          _searchResults[searchIndex] = updatedExpense;
        }

        // Reapply filters in case the update affects search results
        applyFilters();

        return true;
      }
      return false;
    } catch (e) {
      _setError("Lỗi cập nhật giao dịch: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(ExpenseModel expense) async {
    try {
      _setLoading(true);

      final result = await TransactionUtils.deleteTransaction(expense.id, _databaseService);

      if (result) {
        // Remove from all expenses list
        _allExpenses.removeWhere((item) => item.id == expense.id);

        // Remove from search results list
        _searchResults.removeWhere((item) => item.id == expense.id);

        // Recalculate totals
        _calculateTotals();

        return true;
      }
      return false;
    } catch (e) {
      _setError("Lỗi xóa giao dịch: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      return await _databaseService.getCategories();
    } catch (e) {
      print("Error getting categories in viewmodel: $e");
      return [];
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}