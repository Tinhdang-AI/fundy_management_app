import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/expense_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';
import '../utils/currency_formatter.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editNoteController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();
  List<ExpenseModel> _searchResults = [];
  List<ExpenseModel> _allExpenses = []; // Store all expenses for filtering
  bool _isSearching = false;
  bool _showExpenses = true; // Toggle between expenses and income
  final DatabaseService _databaseService = DatabaseService();

  // Filter states
  String _selectedCategory = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterActive = false;

  double _expenseTotal = 0;
  double _incomeTotal = 0;
  double _netTotal = 0;

  // List of unique categories for the filter dropdown
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    // Load all expenses initially
    _loadAllExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editNoteController.dispose();
    _editAmountController.dispose();
    super.dispose();
  }

  // Load all expenses to provide immediate data
  Future<void> _loadAllExpenses() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final expenses = await _databaseService.getUserExpenses().first;

      Set<String> categories = {};
      expenses.forEach((expense) {
        if (expense.category.isNotEmpty) {
          categories.add(expense.category);
        }
      });

      setState(() {
        _allExpenses = expenses;
        _searchResults = expenses;
        _availableCategories = categories.toList()..sort();
        _isSearching = false;
        _calculateTotals();
      });
    } catch (e) {
      print("Error loading expenses: $e");
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _allExpenses = [];
      });
      _showMessage("Không thể tải danh sách giao dịch. Vui lòng thử lại sau.", isError: true);
    }
  }

  // Apply all filters (search text, category, and date range)
  void _applyFilters() {
    setState(() {
      _isSearching = true;
    });

    try {
      List<ExpenseModel> filteredResults = List.from(_allExpenses);

      // Apply text search filter
      if (_searchController.text.isNotEmpty) {
        String query = _searchController.text.toLowerCase().trim();
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
          return expense.date.isAfter(start) ||
              expense.date.isAtSameMomentAs(start);
        }).toList();
      }

      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        filteredResults = filteredResults.where((expense) {
          return expense.date.isBefore(end) ||
              expense.date.isAtSameMomentAs(end);
        }).toList();
      }

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
        _calculateTotals();
        _isFilterActive = _selectedCategory.isNotEmpty || _startDate != null || _endDate != null;
      });
    } catch (e) {
      print("Error applying filters: $e");
      setState(() {
        _isSearching = false;
      });
      _showMessage("Lỗi khi lọc dữ liệu. Vui lòng thử lại.", isError: true);
    }
  }

  // Handle search text changes
  void _onSearchChanged(String query) {
    _applyFilters();
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = '';
      _startDate = null;
      _endDate = null;
      _isFilterActive = false;
      _searchResults = _allExpenses;
    });
    _calculateTotals();
  }

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

    setState(() {
      _expenseTotal = expenses;
      _incomeTotal = income;
      _netTotal = income - expenses;
    });
  }

  // Delete expense
  Future<void> _deleteExpense(ExpenseModel expense) async {
    setState(() {
      _isSearching = true;
    });

    try {
      await _databaseService.deleteExpense(expense.id);

      setState(() {
        _allExpenses.removeWhere((item) => item.id == expense.id);
        _searchResults.removeWhere((item) => item.id == expense.id);
        _isSearching = false;
      });

      _calculateTotals();
      _showMessage("Đã xóa giao dịch thành công");
    } catch (e) {
      print("Error deleting expense: $e");
      setState(() {
        _isSearching = false;
      });
      _showMessage("Không thể xóa giao dịch. Vui lòng thử lại sau.", isError: true);
    }
  }

  Future<void> _editExpense(ExpenseModel expense) async {
    // Hiển thị dialog chỉnh sửa
    final bool? result = await _showEditDialog(expense);

    if (result != true) {
      return; // Người dùng đã hủy
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Lấy giá trị đã cập nhật từ dialog
      final double amount = parseFormattedCurrency(_editAmountController.text);
      final String note = _editNoteController.text.trim();

      // Chỉ cập nhật nếu có sự thay đổi
      if (amount != expense.amount || note != expense.note) {
        await _databaseService.updateExpense(
            ExpenseModel(
              id: expense.id,
              userId: expense.userId,
              note: note,
              amount: amount,
              category: expense.category,
              categoryIcon: expense.categoryIcon,
              date: expense.date,
              isExpense: expense.isExpense,
            )
        );

        // Cập nhật danh sách local
        final updatedExpense = ExpenseModel(
          id: expense.id,
          userId: expense.userId,
          note: note,
          amount: amount,
          category: expense.category,
          categoryIcon: expense.categoryIcon,
          date: expense.date,
          isExpense: expense.isExpense,
        );

        setState(() {
          // Find and update in both lists
          final allIndex = _allExpenses.indexWhere((item) => item.id == expense.id);
          if (allIndex >= 0) {
            _allExpenses[allIndex] = updatedExpense;
          }

          final searchIndex = _searchResults.indexWhere((item) => item.id == expense.id);
          if (searchIndex >= 0) {
            _searchResults[searchIndex] = updatedExpense;
          }
        });

        _calculateTotals();
        _showMessage("Đã cập nhật giao dịch thành công", isError: false);
      }
    } catch (e) {
      _showMessage("Không thể cập nhật giao dịch. Vui lòng thử lại sau.", isError: true);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<bool?> _showEditDialog(ExpenseModel expense) {
    // Initialize controllers with current values
    _editNoteController.text = expense.note;
    _editAmountController.text = formatCurrency.format(expense.amount);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa giao dịch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Danh mục: ${expense.category}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _editNoteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _editAmountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  border: OutlineInputBorder(),
                  suffix: Text('đ'),
                ),
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Ngày: ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate input
              if (_editNoteController.text.trim().isEmpty) {
                _showMessage("Ghi chú không được để trống", isError: true);
                return;
              }

              final amount = parseFormattedCurrency(_editAmountController.text);

              if (amount <= 0) {
                _showMessage("Số tiền không hợp lệ", isError: true);
                return;
              }

              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(ExpenseModel expense) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa khoản ${expense.isExpense ? "chi" : "thu"} "${expense.note}" với số tiền ${formatCurrencyWithSymbol(expense.amount)} không?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Show action menu on long press
  void _showActionMenu(BuildContext context, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text('Chỉnh sửa giao dịch'),
                onTap: () {
                  Navigator.pop(context);
                  _editExpense(expense);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa giao dịch'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showDeleteConfirmation(expense);
                  if (confirm == true) {
                    _deleteExpense(expense);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Hủy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Select date range
  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tìm kiếm',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (_isFilterActive)
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: Colors.orange),
              onPressed: _resetFilters,
              tooltip: 'Xóa tất cả bộ lọc',
            ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilterSection(),
          _buildSummarySection(),
          _buildToggleButtons(),
          _isSearching
              ? Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          )
              : Expanded(
            child: _searchResults.isEmpty
                ? Center(
              child: Text(
                'Không tìm thấy kết quả',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm ghi chú...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _applyFilters();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _selectDateRange(context),
                icon: Icon(Icons.date_range, size: 18),
                label: Text('Chọn ngày'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      label: Text(
                        'Từ: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - Đến: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _applyFilters();
                      },
                      backgroundColor: Colors.orange.shade100,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
          hint: Text('Chọn danh mục'),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
          style: TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue ?? '';
            });
            _applyFilters();
          },
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text('Tất cả danh mục'),
            ),
            ..._availableCategories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem('Chi tiêu', formatCurrencyWithSymbol(_expenseTotal), Colors.blue.shade100),
          _buildSummaryItem('Thu nhập', formatCurrencyWithSymbol(_incomeTotal), Colors.pink.shade100),
          _buildSummaryItem(
              'Chênh lệch',
              _netTotal >= 0
                  ? formatCurrencyWithSymbol(_netTotal)
                  : '-${formatCurrencyWithSymbol(_netTotal.abs())}',
              _netTotal >= 0 ? Colors.green.shade100 : Colors.red.shade100
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color backgroundColor) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              amount,
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showExpenses = true;
              });
            },
            child: Container(
              height: 40,
              color: _showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                'Tiền chi',
                style: TextStyle(
                  color: _showExpenses ? Colors.white : Colors.black,
                  fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showExpenses = false;
              });
            },
            child: Container(
              height: 40,
              color: !_showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                'Tiền thu',
                style: TextStyle(
                  color: !_showExpenses ? Colors.white : Colors.black,
                  fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    // Filter by expense or income based on toggle
    List<ExpenseModel> filteredResults = _searchResults
        .where((item) => item.isExpense == _showExpenses)
        .toList();

    // Sort by date (newest first)
    filteredResults.sort((a, b) => b.date.compareTo(a.date));

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          'Không có ${_showExpenses ? 'khoản chi' : 'khoản thu'} nào phù hợp',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SafeArea(
      bottom: true,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          final item = filteredResults[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onLongPress: () => _showActionMenu(context, item),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildCategoryIcon(item),
                ),
                title: Text(
                  item.category,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.note),
                    Text(DateFormat('dd/MM/yyyy').format(item.date)),
                  ],
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(item.amount),
                  style: TextStyle(
                    color: item.isExpense ? Colors.red : Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryIcon(ExpenseModel item) {
    try {
      // Handle potential parsing errors with the category icon
      if (item.categoryIcon.isEmpty) {
        return Icon(
          item.isExpense ? Icons.trending_down : Icons.trending_up,
          color: item.isExpense ? Colors.red : Colors.green,
        );
      }

      return Icon(
        IconData(int.parse(item.categoryIcon), fontFamily: 'MaterialIcons'),
        color: item.isExpense ? Colors.red : Colors.green,
      );
    } catch (e) {
      // Fallback icon if there's an error
      return Icon(
        item.isExpense ? Icons.trending_down : Icons.trending_up,
        color: item.isExpense ? Colors.red : Colors.green,
      );
    }
  }
}