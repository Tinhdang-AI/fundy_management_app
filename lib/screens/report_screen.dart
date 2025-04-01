import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '/screens/expense_screen.dart';
import '/screens/calendar_screen.dart';
import '/screens/more_screen.dart';
import '/screens/search_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';
import '../utils/currency_formatter.dart';
import '/utils/message_utils.dart';
import '/utils/transaction_utils.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  bool isMonthly = true;
  int _selectedIndex = 2; // Báo cáo là tab thứ 3 (index 2)
  TabController? _tabController;

  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  double _expenseTotal = 0;
  double _incomeTotal = 0;
  bool _isLoading = true;
  bool _hasNoData = false;
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _incomes = [];
  Map<String, double> _expenseCategoryTotals = {};
  Map<String, double> _incomeCategoryTotals = {};

  // Thêm biến để theo dõi trạng thái hiển thị chi tiết danh mục
  String? _selectedCategory;
  bool _showingCategoryDetails = false;
  bool _isCategoryExpense = true; // Là chi tiêu hay thu nhập
  List<ExpenseModel> _categoryTransactions = [];

  // Danh sách màu cho biểu đồ tròn
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

  final List<Widget> _screens = [
    ExpenseScreen(), // Nhập vào
    CalendarScreen(), // Lịch
    ReportScreen(), // Báo cáo
    MoreScreen(), // Khác
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);

    // Check if user has any data first
    _checkForData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Check if user has any data
  Future<void> _checkForData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool hasData = await _databaseService.hasAnyData();

      if (!hasData) {
        setState(() {
          _hasNoData = true;
          _isLoading = false;
        });
      } else {
        _loadReportData();
      }
    } catch (e) {
      print("Error checking for data: $e");
      _loadReportData(); // Try loading data anyway
    }
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging) {
      setState(() {
        // Reset category details view when switching tabs
        _showingCategoryDetails = false;
      });
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _expenseTotal = 0;
      _incomeTotal = 0;
      _expenses = [];
      _incomes = [];
      _expenseCategoryTotals = {};
      _incomeCategoryTotals = {};
      _showingCategoryDetails = false;
    });

    try {
      if (isMonthly) {
        await _loadMonthlyData();
      } else {
        await _loadYearlyData();
      }
    } catch (e) {
      print("Error loading report data: $e");
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage("Không thể tải dữ liệu báo cáo. Vui lòng thử lại sau.");
    }
  }

  // Mới: hàm xử lý khi nhấp vào một danh mục
  void _showCategoryDetails(String category, bool isExpense) {
    setState(() {
      _isLoading = true;
    });

    _selectedCategory = category;
    _isCategoryExpense = isExpense;

    // Lọc các giao dịch theo danh mục đã chọn
    _categoryTransactions = isExpense
        ? _expenses.where((expense) => expense.category == category).toList()
        : _incomes.where((income) => income.category == category).toList();

    // Sắp xếp theo ngày (mới nhất trước)
    _categoryTransactions.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _showingCategoryDetails = true;
      _isLoading = false;
    });
  }

  // Mới: hàm quay lại báo cáo chính
  void _backToMainReport() {
    setState(() {
      _showingCategoryDetails = false;
    });
  }

  Future<void> _loadMonthlyData() async {
    try {
      print("Loading monthly data for ${_selectedDate.month}/${_selectedDate.year}");

      // Use Future version instead of Stream to avoid timeout issues
      final List<ExpenseModel> transactions = await _databaseService.getExpensesByMonthFuture(
          _selectedDate.month,
          _selectedDate.year
      );

      print("Received ${transactions.length} transactions for month ${_selectedDate.month}/${_selectedDate.year}");

      if (mounted) {
        setState(() {
          _expenses = transactions.where((tx) => tx.isExpense).toList();
          _incomes = transactions.where((tx) => !tx.isExpense).toList();
          _calculateTotals();
          _generateCategoryTotals();
          _isLoading = false;
          _hasNoData = transactions.isEmpty;
        });
      }
    } catch (e) {
      print("Error loading monthly transactions: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage("Lỗi tải dữ liệu tháng: ${e.toString()}");
      }
    }
  }

  Future<void> _loadYearlyData() async {
    try {
      print("Loading yearly data for ${_selectedDate.year}");

      // Load all expenses for the year
      final List<ExpenseModel> yearlyTransactions = await _databaseService.getExpensesByYearFuture(
          _selectedDate.year
      );

      print("Received ${yearlyTransactions.length} transactions for year ${_selectedDate.year}");

      // Separate expenses and incomes
      final List<ExpenseModel> yearExpenses = yearlyTransactions.where((tx) => tx.isExpense).toList();
      final List<ExpenseModel> yearIncomes = yearlyTransactions.where((tx) => !tx.isExpense).toList();

      // Calculate category totals for expenses
      Map<String, double> expenseTotals = {};
      for (var expense in yearExpenses) {
        expenseTotals[expense.category] = (expenseTotals[expense.category] ?? 0) + expense.amount;
      }

      // Calculate category totals for income
      Map<String, double> incomeTotals = {};
      for (var income in yearIncomes) {
        incomeTotals[income.category] = (incomeTotals[income.category] ?? 0) + income.amount;
      }

      // Calculate totals
      final double totalExpenses = yearExpenses.fold(0, (sum, item) => sum + item.amount);
      final double totalIncomes = yearIncomes.fold(0, (sum, item) => sum + item.amount);

      if (mounted) {
        setState(() {
          _expenseTotal = totalExpenses;
          _incomeTotal = totalIncomes;
          _expenses = yearExpenses;
          _incomes = yearIncomes;
          _expenseCategoryTotals = expenseTotals;
          _incomeCategoryTotals = incomeTotals;
          _isLoading = false;
          _hasNoData = yearlyTransactions.isEmpty;
        });
      }
    } catch (e) {
      print("Error loading yearly data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage("Lỗi tải dữ liệu năm: ${e.toString()}");
      }
    }
  }
  void _showTransactionActionMenu(BuildContext context, ExpenseModel expense) {
    TransactionUtils.showActionMenu(
        context,
        expense,
            () => _editTransaction(expense),
            () async {
          final confirmed = await TransactionUtils.showDeleteConfirmation(context, expense);
          if (confirmed == true) {
            _deleteTransaction(expense);
          }
        }
    );
  }

// Hàm sửa giao dịch
  Future<void> _editTransaction(ExpenseModel expense) async {
    TransactionUtils.editTransaction(
      context,
      expense,
          (updatedExpense) {
        setState(() {
          _isLoading = true;
        });

        // Cập nhật trong danh sách hiện tại
        int index = _categoryTransactions.indexWhere((item) => item.id == expense.id);
        if (index >= 0) {
          _categoryTransactions[index] = updatedExpense;
        }

        // Cập nhật trong danh sách gốc (expenses hoặc incomes)
        if (expense.isExpense) {
          index = _expenses.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _expenses[index] = updatedExpense;
          }
        } else {
          index = _incomes.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _incomes[index] = updatedExpense;
          }
        }

        // Tính lại tổng số
        _calculateTotals();
        _generateCategoryTotals();

        // Cập nhật lại danh sách chi tiết nếu người dùng đã thay đổi danh mục
        // hoặc loại giao dịch (chuyển từ chi tiêu sang thu nhập hoặc ngược lại)
        if (updatedExpense.category != _selectedCategory ||
            updatedExpense.isExpense != _isCategoryExpense) {
          // Xóa khỏi danh sách chi tiết
          _categoryTransactions.removeWhere((item) => item.id == expense.id);
        }

        setState(() {
          _isLoading = false;
        });
      },
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
  }

// Hàm xóa giao dịch
  Future<void> _deleteTransaction(ExpenseModel expense) async {
    TransactionUtils.deleteTransaction(
      context,
      expense,
          () {
        setState(() {
          // Xóa khỏi danh sách chi tiết
          _categoryTransactions.removeWhere((item) => item.id == expense.id);

          // Xóa khỏi danh sách gốc
          if (expense.isExpense) {
            _expenses.removeWhere((item) => item.id == expense.id);
          } else {
            _incomes.removeWhere((item) => item.id == expense.id);
          }

          // Tính lại tổng số
          _calculateTotals();
          _generateCategoryTotals();

          // Nếu không còn giao dịch nào, quay về màn hình chính
          if (_categoryTransactions.isEmpty) {
            _showingCategoryDetails = false;
          }
        });
      },
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
  }

  void _calculateTotals() {
    _expenseTotal = _expenses.fold(0, (sum, item) => sum + item.amount);
    _incomeTotal = _incomes.fold(0, (sum, item) => sum + item.amount);
  }

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

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  void _updateTimeRange(bool isNext) {
    setState(() {
      if (isMonthly) {
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
      _showingCategoryDetails = false; // Reset when changing time range
    });

    _loadReportData();
  }

  void _showSuccessMessage(String message) {
    MessageUtils.showSuccessMessage(context, message);
  }

  void _showErrorMessage(String message) {
    MessageUtils.showErrorMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildSummaryBox(),
          if (!_hasNoData && !_showingCategoryDetails) _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : _hasNoData
                ? _buildNoDataView()
                : _showingCategoryDetails
                ? _buildCategoryDetailsView()
                : _buildReportContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoryDetailsView() {
    final totalAmount = _categoryTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final color = _isCategoryExpense ? Colors.red : Colors.green;

    // Nhóm các giao dịch theo ngày
    Map<String, List<ExpenseModel>> groupedTransactions = {};
    for (var transaction in _categoryTransactions) {
      String date = DateFormat('d/M/yyyy (EEEE)').format(transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    String timeRangeDisplay = isMonthly
        ? 'Tháng ${_selectedDate.month}/${_selectedDate.year}'
        : 'Năm ${_selectedDate.year}';

    return Column(
      children: [
        // Thanh tiêu đề với nút quay lại
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _backToMainReport,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  '$_selectedCategory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                formatCurrencyWithSymbol(totalAmount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          child: Center(
            child: Text(
              timeRangeDisplay,
              style: TextStyle(
                fontWeight: FontWeight.bold,  // In đậm
                fontSize: 15,
              ),
            ),
          ),
        ),

        // Danh sách giao dịch theo ngày
        Expanded(
          child: _categoryTransactions.isEmpty
              ? Center(
            child: Text(
              'Không có giao dịch nào',
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              String date = groupedTransactions.keys.elementAt(index);
              List<ExpenseModel> dayTransactions = groupedTransactions[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề ngày - sửa giống tiêu đề tháng
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    width: double.infinity,
                    child: Text(
                        date,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,  // In đậm
                          fontSize: 13,
                        )
                    ),
                  ),

                  // Danh sách giao dịch của ngày đó
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(8),
                    itemCount: dayTransactions.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final transaction = dayTransactions[index];
                      final bool hasNote = transaction.note.trim().isNotEmpty;

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
                        child: InkWell(
                          onLongPress: () => _showTransactionActionMenu(context, transaction),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icon danh mục
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    IconData(int.parse(transaction.categoryIcon), fontFamily: 'MaterialIcons'),
                                    color: transaction.isExpense ? Colors.red : Colors.green,
                                  ),
                                ),
                                SizedBox(width: 12),

                                // Nội dung chính
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (hasNote)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            transaction.note,
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Số tiền
                                Text(
                                  formatCurrencyWithSymbol(transaction.amount),
                                  style: TextStyle(
                                    color: transaction.isExpense ? Colors.red : Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Không có dữ liệu trong khoảng thời gian này',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ExpenseScreen()),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Thêm giao dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: _buildTimeToggle(),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeToggle() {
    return Container(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isMonthly) {
                  setState(() {
                    isMonthly = true;
                    _showingCategoryDetails = false;
                  });
                  _loadReportData();
                }
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isMonthly ? Color(0xFFFF8B55) : Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                child: Text(
                  'Hàng Tháng',
                  style: TextStyle(
                    color: isMonthly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isMonthly) {
                  setState(() {
                    isMonthly = false;
                    _showingCategoryDetails = false;
                  });
                  _loadReportData();
                }
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isMonthly ? Color(0xFFFF8B55) : Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Text(
                  'Hàng Năm',
                  style: TextStyle(
                    color: !isMonthly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    String timeDisplay;

    if (isMonthly) {
      // Định dạng ngày đầu tháng và cuối tháng
      DateTime firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      DateTime lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      timeDisplay = "${DateFormat('MM/yyyy').format(_selectedDate)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";
    } else {
      timeDisplay = "${DateFormat('yyyy').format(_selectedDate)}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFA07A), // Màu cam sáng giống trong hình
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _updateTimeRange(false),
          ),
          Text(
            timeDisplay,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => _updateTimeRange(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    final netAmount = _incomeTotal - _expenseTotal;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row: Expense and Income boxes
          Row(
            children: [
              // Expense box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiêu:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formatCurrencyWithSymbol(_expenseTotal),
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Income box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thu nhập:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formatCurrencyWithSymbol(_incomeTotal),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Second row: Balance box
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Thu chi:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),

                Flexible(
                  child: Text(
                    netAmount >= 0
                        ? '+${formatCurrencyWithSymbol(netAmount)}'
                        : '-${formatCurrencyWithSymbol(netAmount.abs())}',
                    style: TextStyle(
                      color: netAmount >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: "Chi tiêu"),
        Tab(text: "Thu nhập"),
      ],
      labelColor: Colors.orange,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.orange,
    );
  }

  Widget _buildReportContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExpenseTab(),
        _buildIncomeTab(),
      ],
    );
  }

  Widget _buildExpenseTab() {
    // Get the appropriate category data based on the selected tab
    Map<String, double> categoryData = _expenseCategoryTotals;

    // If no data available
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu chi tiêu cho ${isMonthly ? "tháng" : "năm"} này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort categories by amount
    List<MapEntry<String, double>> sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        // Phần biểu đồ tròn
        Container(
          height: MediaQuery.of(context).size.height * 0.25, // 25% chiều cao màn hình
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _buildPieChart(sortedCategories, Colors.red),
        ),
        // Đường phân cách
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        // Phần danh sách
        Expanded(
          child: ListView.separated(
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final percentage = (totalAmount > 0)
                  ? (category.value / totalAmount * 100)
                  : 0;

              // Hiển thị danh sách với màu sắc tương ứng từ biểu đồ tròn
              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getExpenseColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  category.key,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(_getExpenseColor(index)),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(category.value),
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () => _showCategoryDetails(category.key, true),
              );
            },
          ),
        )
      ],
    );
  }


  Widget _buildIncomeTab() {
    // Get the appropriate category data based on the selected tab
    Map<String, double> categoryData = _incomeCategoryTotals;

    // If no data available
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu thu nhập cho ${isMonthly ? "tháng" : "năm"} này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort categories by amount
    List<MapEntry<String, double>> sortedCategories = categoryData.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        // Phần biểu đồ tròn
        Container(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.25, // 25% chiều cao màn hình
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _buildPieChart(sortedCategories, Colors.green, isIncome: true),
        ),
        // Đường phân cách
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        // Phần danh sách
        Expanded(
          child: ListView.separated(
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final percentage = (totalAmount > 0)
                  ? (category.value / totalAmount * 100)
                  : 0;

              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getIncomeColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  category.key,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getIncomeColor(index)),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(category.value),
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                onTap: () =>
                    _showCategoryDetails(
                        category.key, false), // Thêm sự kiện khi nhấp
              );
            },
          ),
        )
      ],
    );
  }


  // Hàm tạo biểu đồ tròn
  Widget _buildPieChart(List<MapEntry<String, double>> categories, Color baseColor, {bool isIncome = false}) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: _generatePieChartSections(categories, isIncome: isIncome),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Có thể thêm xử lý khi người dùng chạm vào biểu đồ
            if (event is FlTapUpEvent && pieTouchResponse != null &&
                pieTouchResponse.touchedSection != null) {
              final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              if (touchedIndex >= 0 && touchedIndex < categories.length) {
                // Khi người dùng chạm vào phần biểu đồ, cũng hiển thị chi tiết
                _showCategoryDetails(categories[touchedIndex].key, !isIncome);
              }
            }
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      List<MapEntry<String, double>> categories, {bool isIncome = false}) {
    final totalAmount = categories.fold(0.0, (sum, entry) => sum + entry.value);

    return List.generate(
      categories.length,
          (index) {
        final category = categories[index];
        final percentage = (category.value / totalAmount) * 100;
        final color = isIncome
            ? _getIncomeColor(index)
            : _getExpenseColor(index);

        return PieChartSectionData(
          value: category.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: color,
        );
      },
    );
  }

  Color _getExpenseColor(int index) {
    return _colors[index % _colors.length];
  }

  Color _getIncomeColor(int index) {
    // Dùng màu khác cho thu nhập, dùng các màu xanh lá
    return index % 2 == 0
        ? Colors.green.shade300.withOpacity(0.7 + (index * 0.05))
        : Colors.teal.shade300.withOpacity(0.7 + (index * 0.05));
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.orangeAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.grey[200],
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Nhập vào",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Lịch",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart),
          label: "Báo cáo",
          activeIcon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.pie_chart, color: Colors.orangeAccent),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "Khác",
        ),
      ],
    );
  }
}