import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/expense_screen.dart';
import '/screens/calendar_screen.dart';
import '/screens/more_screen.dart';
import '/screens/search_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';

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
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _incomes = [];
  Map<String, double> _categoryTotals = {};

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
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging) {
      setState(() {});
      _onTabChange();
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _expenseTotal = 0;
      _incomeTotal = 0;
      _expenses = [];
      _incomes = [];
      _categoryTotals = {};
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
    }
  }

  Future<void> _loadMonthlyData() async {
    _databaseService
        .getExpensesByMonth(_selectedDate.month, _selectedDate.year)
        .listen(
          (transactions) {
        if (mounted) {
          setState(() {
            _expenses = transactions.where((tx) => tx.isExpense).toList();
            _incomes = transactions.where((tx) => !tx.isExpense).toList();
            _calculateTotals();

            if (_tabController?.index == 0) {
              _generateCategoryTotals(_expenses);
            } else {
              _generateCategoryTotals(_incomes);
            }

            _isLoading = false;
          });
        }
      },
      onError: (e) {
        print("Error loading monthly transactions: $e");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onDone: () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _loadYearlyData() async {
    try {
      // Lấy tổng chi tiêu và thu nhập theo năm
      final expenseTotal = await _databaseService.getTotalExpensesByYear(_selectedDate.year);
      final incomeTotal = await _databaseService.getTotalIncomeByYear(_selectedDate.year);

      if (_tabController?.index == 0) {
        // Tab Chi tiêu được chọn
        final categoryData = await _databaseService.getExpensesByCategoryForYear(_selectedDate.year);

        if (mounted) {
          setState(() {
            _expenseTotal = expenseTotal;
            _incomeTotal = incomeTotal;
            _categoryTotals = categoryData;
            _isLoading = false;
          });
        }
      } else {
        // Tab Thu nhập được chọn
        // Có thể thực hiện truy vấn đặc biệt cho thu nhập theo danh mục nếu cần
        if (mounted) {
          setState(() {
            _expenseTotal = expenseTotal;
            _incomeTotal = incomeTotal;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading yearly data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotals() {
    _expenseTotal = _expenses.fold(0, (sum, item) => sum + item.amount);
    _incomeTotal = _incomes.fold(0, (sum, item) => sum + item.amount);
  }

  void _generateCategoryTotals(List<ExpenseModel> items) {
    Map<String, double> totals = {};
    for (var item in items) {
      if (totals.containsKey(item.category)) {
        totals[item.category] = totals[item.category]! + item.amount;
      } else {
        totals[item.category] = item.amount;
      }
    }
    _categoryTotals = totals;
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

  void _onTabChange() {
    if (isMonthly) {
      if (_tabController?.index == 0) {
        _generateCategoryTotals(_expenses);
      } else {
        _generateCategoryTotals(_incomes);
      }
    } else {
      _loadYearlyData();
    }
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
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : _buildReportContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
    // Định dạng ngày đầu tháng và cuối tháng
    DateTime firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    String monthRange = isMonthly
        ? "${DateFormat('MM/yyyy').format(_selectedDate)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})"
        : "${DateFormat('yyyy').format(_selectedDate)}";

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
            monthRange,
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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chi tiêu:', style: TextStyle(color: Colors.black)),
              Text(
                  '-${NumberFormat('#,###').format(_expenseTotal)}VND',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thu nhập:', style: TextStyle(color: Colors.black)),
              Text(
                  '+${NumberFormat('#,###').format(_incomeTotal)}VND',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thu chi:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              Text(
                _incomeTotal > _expenseTotal
                    ? '+${NumberFormat('#,###').format(_incomeTotal - _expenseTotal)}VND'
                    : '-${NumberFormat('#,###').format(_expenseTotal - _incomeTotal)}VND',
                style: TextStyle(
                    color: _incomeTotal > _expenseTotal ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
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
    // Ở chế độ xem theo năm nhưng không có dữ liệu danh mục
    if (!isMonthly && _categoryTotals.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu chi tiêu cho năm này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Ở chế độ xem theo tháng nhưng không có giao dịch chi tiêu nào
    if (isMonthly && _expenses.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu chi tiêu cho tháng này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Có dữ liệu danh mục (từ tháng hoặc năm)
    if (_categoryTotals.isNotEmpty) {
      List<MapEntry<String, double>> sortedCategories = _categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final totalAmount = _categoryTotals.values.fold(0.0, (sum, val) => sum + val);

      return ListView.builder(
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final percentage = (totalAmount > 0)
              ? (category.value / totalAmount * 100)
              : 0;

          return ListTile(
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 10,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text('${percentage.toStringAsFixed(1)}%'),
              ],
            ),
            trailing: Text(
              '${NumberFormat('#,###').format(category.value)}VND',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        },
      );
    }

    // Nếu không có dữ liệu danh mục nhưng có tổng chi tiêu
    return Center(
      child: Text(
        'Không có dữ liệu chi tiêu theo danh mục',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildIncomeTab() {
    // Ở chế độ xem theo tháng nhưng không có giao dịch thu nhập nào
    if (isMonthly && _incomes.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu thu nhập cho tháng này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Ở chế độ xem theo năm, chỉ hiển thị thông báo
    if (!isMonthly) {
      return Center(
        child: Text(
          'Không có dữ liệu thu nhập chi tiết cho năm này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Hiển thị thu nhập theo tháng nếu có dữ liệu
    Map<String, double> incomeTotals = {};
    for (var income in _incomes) {
      if (incomeTotals.containsKey(income.category)) {
        incomeTotals[income.category] = incomeTotals[income.category]! + income.amount;
      } else {
        incomeTotals[income.category] = income.amount;
      }
    }

    List<MapEntry<String, double>> sortedCategories = incomeTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu thu nhập theo danh mục',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final percentage = (_incomeTotal > 0)
            ? (category.value / _incomeTotal * 100)
            : 0;

        return ListTile(
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 10,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('${percentage.toStringAsFixed(1)}%'),
            ],
          ),
          trailing: Text(
            '${NumberFormat('#,###').format(category.value)}VND',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle), label: "Nhập vào"),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: "Lịch"),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Báo cáo"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Khác"),
      ],
    );
  }
}