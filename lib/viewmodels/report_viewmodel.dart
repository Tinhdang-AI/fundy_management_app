import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/transaction_utils.dart';

class ReportViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _isMonthly = true; // Toggle between monthly and yearly view
  bool _hasNoData = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Data
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _incomes = [];
  Map<String, double> _expenseCategoryTotals = {};
  Map<String, double> _incomeCategoryTotals = {};

  // Category details state
  String? _selectedCategory;
  bool _showingCategoryDetails = false;
  bool _isCategoryExpense = true;
  List<ExpenseModel> _categoryTransactions = [];

  // Totals
  double _expenseTotal = 0;
  double _incomeTotal = 0;
  double _netTotal = 0;

  // Tab selection
  int _tabIndex = 0; // 0 for expenses, 1 for incomes

  // Colors for charts
  final List<Color> _colors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.indigo.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
    Colors.brown.shade400,
    Colors.lime.shade400,
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isMonthly => _isMonthly;
  bool get hasNoData => _hasNoData;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get incomes => _incomes;
  Map<String, double> get expenseCategoryTotals => _expenseCategoryTotals;
  Map<String, double> get incomeCategoryTotals => _incomeCategoryTotals;
  String? get selectedCategory => _selectedCategory;
  bool get showingCategoryDetails => _showingCategoryDetails;
  bool get isCategoryExpense => _isCategoryExpense;
  List<ExpenseModel> get categoryTransactions => _categoryTransactions;
  double get expenseTotal => _expenseTotal;
  double get incomeTotal => _incomeTotal;
  double get netTotal => _netTotal;
  int get tabIndex => _tabIndex;
  List<Color> get colors => _colors;

  // Initialize
  Future<void> initialize() async {
    await checkForData();
  }

  // Check if user has any data
  Future<void> checkForData() async {
    _setLoading(true);

    try {
      bool hasData = await _databaseService.hasAnyData();

      if (!hasData) {
        _hasNoData = true;
      } else {
        await loadReportData();
      }
    } catch (e) {
      _setError("Error checking for data: ${e.toString()}");
      await loadReportData(); // Try loading data anyway
    } finally {
      _setLoading(false);
    }
  }

  // Load report data based on selected time period
  Future<void> loadReportData() async {
    _setLoading(true);

    _expenseTotal = 0;
    _incomeTotal = 0;
    _expenses = [];
    _incomes = [];
    _expenseCategoryTotals = {};
    _incomeCategoryTotals = {};
    _showingCategoryDetails = false;

    try {
      if (_isMonthly) {
        await _loadMonthlyData();
      } else {
        await _loadYearlyData();
      }
    } catch (e) {
      _setError("Không thể tải dữ liệu báo cáo. Vui lòng thử lại sau.");
    } finally {
      _setLoading(false);
    }
  }

  // Load monthly data
  Future<void> _loadMonthlyData() async {
    try {
      final List<ExpenseModel> transactions = await _databaseService.getExpensesByMonthFuture(
          _selectedDate.month,
          _selectedDate.year
      );

      _expenses = transactions.where((tx) => tx.isExpense).toList();
      _incomes = transactions.where((tx) => !tx.isExpense).toList();

      _calculateTotals();
      _generateCategoryTotals();

      _hasNoData = transactions.isEmpty;
    } catch (e) {
      _setError("Lỗi tải dữ liệu tháng: ${e.toString()}");
    }
  }

  // Load yearly data
  Future<void> _loadYearlyData() async {
    try {
      final List<ExpenseModel> yearlyTransactions = await _databaseService.getExpensesByYearFuture(
          _selectedDate.year
      );

      _expenses = yearlyTransactions.where((tx) => tx.isExpense).toList();
      _incomes = yearlyTransactions.where((tx) => !tx.isExpense).toList();

      _calculateTotals();
      _generateCategoryTotals();

      _hasNoData = yearlyTransactions.isEmpty;
    } catch (e) {
      _setError("Lỗi tải dữ liệu năm: ${e.toString()}");
    }
  }

  // Calculate totals
  void _calculateTotals() {
    _expenseTotal = _expenses.fold(0, (sum, item) => sum + item.amount);
    _incomeTotal = _incomes.fold(0, (sum, item) => sum + item.amount);
    _netTotal = _incomeTotal - _expenseTotal;
  }

  // Generate category totals
  void _generateCategoryTotals() {
    // Generate expense category totals
    Map<String, double> expenseTotals = {};
    for (var item in _expenses) {
      expenseTotals[item.category] = (expenseTotals[item.category] ?? 0) + item.amount;
    }
    _expenseCategoryTotals = expenseTotals;

    // Generate income category totals
    Map<String, double> incomeTotals = {};
    for (var item in _incomes) {
      incomeTotals[item.category] = (incomeTotals[item.category] ?? 0) + item.amount;
    }
    _incomeCategoryTotals = incomeTotals;
  }

  // Show category details
  void showCategoryDetails(String category, bool isExpense) {
    _selectedCategory = category;
    _isCategoryExpense = isExpense;

    // Filter transactions by selected category
    _categoryTransactions = isExpense
        ? _expenses.where((expense) => expense.category == category).toList()
        : _incomes.where((income) => income.category == category).toList();

    // Sort by date (newest first)
    _categoryTransactions.sort((a, b) => b.date.compareTo(a.date));

    _showingCategoryDetails = true;
    notifyListeners();
  }

  // Go back to main report
  void backToMainReport() {
    _showingCategoryDetails = false;
    notifyListeners();
  }

  // Toggle between monthly and yearly view
  void toggleTimeFrame() {
    _isMonthly = !_isMonthly;
    _showingCategoryDetails = false;
    notifyListeners();
    loadReportData();
  }

  // Update time range
  Future<void> updateTimeRange(bool isNext) async {
    if (_isMonthly) {
      // Monthly view
      _selectedDate = DateTime(
        _selectedDate.year,
        isNext ? _selectedDate.month + 1 : _selectedDate.month - 1,
      );
    } else {
      // Yearly view
      _selectedDate = DateTime(
        isNext ? _selectedDate.year + 1 : _selectedDate.year - 1,
        _selectedDate.month,
      );
    }

    _showingCategoryDetails = false;
    notifyListeners();
    await loadReportData();
  }

  // Set tab index
  void setTabIndex(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  // Edit transaction
  Future<bool> editTransaction(ExpenseModel expense) async {
    try {
      _setLoading(true);

      final result = await TransactionUtils.editTransaction(expense, _databaseService);

      if (result.success && result.updatedExpense != null) {
        ExpenseModel updatedExpense = result.updatedExpense!;

        // Update in category transactions list if showing details
        if (_showingCategoryDetails) {
          int index = _categoryTransactions.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _categoryTransactions[index] = updatedExpense;
          }

          // If category changed or transaction type changed, remove from details view
          if (updatedExpense.category != _selectedCategory ||
              updatedExpense.isExpense != _isCategoryExpense) {
            _categoryTransactions.removeWhere((item) => item.id == expense.id);
          }
        }

        // Update in main lists
        if (expense.isExpense) {
          int index = _expenses.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _expenses[index] = updatedExpense;
          }
        } else {
          int index = _incomes.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _incomes[index] = updatedExpense;
          }
        }



        // Recalculate totals and category totals
        _calculateTotals();
        _generateCategoryTotals();

        notifyListeners();
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
        // Remove from category transactions if showing details
        if (_showingCategoryDetails) {
          _categoryTransactions.removeWhere((item) => item.id == expense.id);

          // If no more transactions, go back to main report
          if (_categoryTransactions.isEmpty) {
            _showingCategoryDetails = false;
          }
        }

        // Remove from main lists
        if (expense.isExpense) {
          _expenses.removeWhere((item) => item.id == expense.id);
        } else {
          _incomes.removeWhere((item) => item.id == expense.id);
        }

        // Recalculate totals and category totals
        _calculateTotals();
        _generateCategoryTotals();

        notifyListeners();
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

  // Get color for expense category
  Color getExpenseColor(int index) {
    return _colors[index % _colors.length];
  }

  // Get color for income category
  Color getIncomeColor(int index) {
    // Use different shades of green for income
    return index % 2 == 0
        ? Colors.green.shade300.withOpacity(0.7 + (index * 0.05))
        : Colors.teal.shade300.withOpacity(0.7 + (index * 0.05));
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