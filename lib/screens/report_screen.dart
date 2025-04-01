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
      setState(() {});
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
          if (!_hasNoData) _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : _hasNoData
                ? _buildNoDataView()
                : _buildReportContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
                          '-${formatCurrencyWithSymbol(_expenseTotal)}',
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
                          '-${formatCurrencyWithSymbol(_incomeTotal)}',
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
          child: ListView.builder(
            itemCount: sortedCategories.length,
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
    List<MapEntry<String, double>> sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        // Phần biểu đồ tròn
        Container(
          height: MediaQuery.of(context).size.height * 0.25, // 25% chiều cao màn hình
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _buildPieChart(sortedCategories, Colors.green, isIncome: true),
        ),
        // Đường phân cách
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        // Phần danh sách
        Expanded(
          child: ListView.builder(
            itemCount: sortedCategories.length,
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
                          valueColor: AlwaysStoppedAnimation<Color>(_getIncomeColor(index)),
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
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
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
