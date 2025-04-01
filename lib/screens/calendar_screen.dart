import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '/screens/expense_screen.dart';
import '/screens/report_screen.dart';
import '/screens/more_screen.dart';
import '/screens/search_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';
import '../utils/currency_formatter.dart';
import '/utils/message_utils.dart';
import '/utils/transaction_utils.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _selectedIndex = 1;
  final DatabaseService _databaseService = DatabaseService();
  List<ExpenseModel> _selectedDayExpenses = [];
  double _incomeTotal = 0;
  double _expenseTotal = 0;
  double _netTotal = 0;
  bool _isLoading = true;
  bool _showDateSelector = false;

  // Thêm để theo dõi ngày có giao dịch
  Map<DateTime, List<ExpenseModel>> _eventsByDay = {};

  final TextEditingController _editNoteController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();

  final List<Widget> _screens = [
    ExpenseScreen(), // Nhập vào
    CalendarScreen(), // Lịch
    ReportScreen(), // Báo cáo
    MoreScreen(), // Khác
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthData();
    _loadSelectedDayData();
  }

  Future<void> _loadMonthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final int month = _focusedDay.month;
      final int year = _focusedDay.year;

      final expenses = await _databaseService.getExpensesByMonthFuture(month, year);

      // Nhóm các giao dịch theo ngày
      Map<DateTime, List<ExpenseModel>> eventsByDay = {};

      for (var expense in expenses) {
        // Chỉ lấy ngày tháng năm, không lấy giờ phút giây
        final date = DateTime(expense.date.year, expense.date.month, expense.date.day);

        if (eventsByDay[date] == null) {
          eventsByDay[date] = [];
        }
        eventsByDay[date]!.add(expense);
      }

      if (mounted) {
        setState(() {
          _eventsByDay = eventsByDay;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSelectedDayData() async {
    setState(() {
      _isLoading = true;
      // Quan trọng: Làm trống danh sách giao dịch và đặt lại tổng số trước khi tải dữ liệu mới
      _selectedDayExpenses = [];
      _incomeTotal = 0;
      _expenseTotal = 0;
      _netTotal = 0;
    });

    // Đặt timeout để đảm bảo không hiển thị loading vô thời hạn
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    try {
      final expenses = await _databaseService.getExpensesByDateFuture(_selectedDay);

      if (mounted) {
        setState(() {
          _selectedDayExpenses = expenses;
          _calculateTotals();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showActionMenu(BuildContext context, ExpenseModel expense) {
    TransactionUtils.showActionMenu(
        context,
        expense,
            () => _editExpense(expense),
            () async {
          final confirmed = await TransactionUtils.showDeleteConfirmation(context, expense);
          if (confirmed == true) {
            _deleteExpense(expense);
          }
        }
    );
  }

  Future<void> _editExpense(ExpenseModel expense) async {
    TransactionUtils.editTransaction(
        context,
        expense,
            (updatedExpense) {
          setState(() {
            // Cập nhật trong danh sách ngày hiện tại
            final index = _selectedDayExpenses.indexWhere((item) => item.id == expense.id);
            if (index >= 0) {
              _selectedDayExpenses[index] = updatedExpense;
            }

            // Cập nhật trong events
            final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
            if (_eventsByDay.containsKey(date)) {
              final eventIndex = _eventsByDay[date]?.indexWhere((item) => item.id == expense.id) ?? -1;
              if (eventIndex >= 0 && _eventsByDay[date] != null) {
                _eventsByDay[date]![eventIndex] = updatedExpense;
              }
            }
          });
          _calculateTotals();
        },
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    await TransactionUtils.deleteTransaction(
      context,
      expense,
          () {
        setState(() {
          _selectedDayExpenses.removeWhere((item) => item.id == expense.id);

          // Cập nhật events
          final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
          if (_eventsByDay.containsKey(date)) {
            _eventsByDay[date]?.removeWhere((item) => item.id == expense.id);
            if (_eventsByDay[date]?.isEmpty ?? true) {
              _eventsByDay.remove(date);
            }
          }
        });

        _calculateTotals();
      },
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
  }

  void _showSuccessMessage(String message) {
    MessageUtils.showSuccessMessage(context, message);
  }

  void _showErrorMessage(String message) {
    MessageUtils.showErrorMessage(context, message);
  }

  void _calculateTotals() {
    double income = 0;
    double expense = 0;

    for (var item in _selectedDayExpenses) {
      if (item.isExpense) {
        expense += item.amount;
      } else {
        income += item.amount;
      }
    }

    setState(() {
      _incomeTotal = income;
      _expenseTotal = expense;
      _netTotal = income - expense;
    });
  }

  // Hàm để kiểm tra xem ngày nào có giao dịch
  List<ExpenseModel> _getExpensesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _eventsByDay[date] ?? [];
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  // Add this method for date selection like in ExpenseScreen
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;

        // Also update focused day if the month changes
        if (picked.month != _focusedDay.month || picked.year != _focusedDay.year) {
          _focusedDay = DateTime(picked.year, picked.month, 1);
          _loadMonthData();
        }
      });
      _loadSelectedDayData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Lịch', style: TextStyle(color: Colors.black)),
        centerTitle: true,
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
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildCustomCalendar(),
          _buildSummary(),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
                : _selectedDayExpenses.isEmpty
                ? Center(
              child: Text(
                'Không có giao dịch nào vào ngày này',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _buildTransactionList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Updated date selector widget that replaces the month selector
  Widget _buildDateSelector() {
    // Calculate month range info for display
    DateTime firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    String monthRange = "${DateFormat('MM/yyyy').format(_focusedDay)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFA07A), // Same color as previous month selector
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _changeMonth(-1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy (E)').format(_selectedDay),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    monthRange,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => _changeMonth(1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Add these methods to handle month changes
  void _changeMonth(int months) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + months);

      // Update selected day to be within the new month
      if (_selectedDay.month != _focusedDay.month || _selectedDay.year != _focusedDay.year) {
        _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, min(_selectedDay.day, DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day));
      }
    });
    _loadMonthData();
    _loadSelectedDayData();
  }

  // Helper function to get min value
  int min(int a, int b) {
    return a < b ? a : b;
  }

  Widget _buildCustomCalendar() {
    // Lấy các thông tin về tháng hiện tại
    final int year = _focusedDay.year;
    final int month = _focusedDay.month;

    // Ngày đầu tiên của tháng
    final DateTime firstDay = DateTime(year, month, 1);

    // Số ngày trong tháng
    final DateTime lastDay = DateTime(year, month + 1, 0);
    final int daysInMonth = lastDay.day;

    // Tính toán ngày bắt đầu hiển thị (ngày đầu tiên của tuần chứa ngày 1)
    // Lưu ý: Thứ 2 = 1, Chủ Nhật = 7 (trong đó Chủ Nhật = 0 trong DateTime.weekday)
    int startOffset = firstDay.weekday - 1; // -1 vì muốn bắt đầu từ thứ 2
    if (startOffset < 0) startOffset = 6; // Nếu là Chủ Nhật

    // Tính toán tổng số ngày cần hiển thị và số hàng cần thiết
    int totalDaysToShow = startOffset + daysInMonth;
    int numberOfRows = (totalDaysToShow / 7).ceil(); // Làm tròn lên để có đủ hàng

    // Danh sách các ngày của tháng trước, tháng hiện tại và tháng sau
    List<DateTime> days = [];

    // Thêm ngày của tháng trước
    final DateTime prevMonth = DateTime(year, month - 1, 1);
    final int daysInPrevMonth = DateTime(year, month, 0).day;
    for (int i = 0; i < startOffset; i++) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - startOffset + i + 1));
    }

    // Thêm ngày của tháng hiện tại
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(year, month, i));
    }

    // Tính số ngày cần thêm để điền đủ hàng cuối cùng
    int endOffset = (numberOfRows * 7) - days.length;

    // Thêm ngày của tháng sau
    for (int i = 1; i <= endOffset; i++) {
      days.add(DateTime(year, month + 1, i));
    }

    // Tạo danh sách các ngày theo tuần
    List<List<DateTime>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Column(
      children: [
        // Header với tên các ngày trong tuần
        Container(
          color: Colors.grey.shade600,
          child: Row(
            children: [
              _buildWeekdayHeader("T2"),
              _buildWeekdayHeader("T3"),
              _buildWeekdayHeader("T4"),
              _buildWeekdayHeader("T5"),
              _buildWeekdayHeader("T6"),
              _buildWeekdayHeader("T7", isWeekend: true),
              _buildWeekdayHeader("CN", isWeekend: true),
            ],
          ),
        ),

        // Lưới các ngày - chỉ hiển thị đúng số hàng cần thiết
        for (var week in weeks)
          Row(
            children: week.map((day) {
              bool isCurrentMonth = day.month == month;
              bool isToday = isSameDay(day, DateTime.now());
              bool isSelected = isSameDay(day, _selectedDay);
              bool isWeekend = day.weekday >= 6; // Thứ 7 và Chủ Nhật

              // Kiểm tra xem ngày có giao dịch không
              List<ExpenseModel> expenses = _getExpensesForDay(day);
              bool hasIncome = expenses.any((e) => !e.isExpense);
              bool hasExpense = expenses.any((e) => e.isExpense);

              // Xác định màu và style cho ô
              Color textColor = Colors.black;
              Color backgroundColor = Colors.white;

              if (isWeekend) {
                textColor = Colors.red;
              }

              if (!isCurrentMonth) {
                textColor = textColor.withOpacity(0.5);
                backgroundColor = Colors.grey.shade100;
              }

              if (isSelected && isCurrentMonth) {
                textColor = Colors.white;
                backgroundColor = Colors.orange.shade100;
              } else if (isToday) {
                backgroundColor = Colors.grey.shade200;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth ? () {
                    setState(() {
                      _selectedDay = DateTime(day.year, day.month, day.day);
                    });
                    _loadSelectedDayData();
                  } : null,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: (isToday || isSelected) && isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if ((hasIncome || hasExpense) && isCurrentMonth)
                          Positioned(
                            bottom: 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasIncome)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasExpense)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWeekdayHeader(String text, {bool isWeekend = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isWeekend ? Colors.red : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Tiền thu', formatCurrencyWithSymbol(_incomeTotal), Colors.green),
          _buildSummaryItem('Tiền chi', formatCurrencyWithSymbol(_expenseTotal), Colors.red),
          _buildSummaryItem(
              'Tổng',
              _netTotal >= 0
                  ? formatCurrencyWithSymbol(_netTotal)
                  : '-${formatCurrencyWithSymbol(_netTotal.abs())}',
              _netTotal >= 0 ? Colors.green : Colors.red
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 110), // Sesuaikan lebar maksimum
          child: Text(
            amount,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    // Group by day
    Map<String, List<ExpenseModel>> groupedExpenses = {};
    for (var expense in _selectedDayExpenses) {
      String date = DateFormat('d/M/yyyy (EEEE)').format(expense.date);
      if (!groupedExpenses.containsKey(date)) {
        groupedExpenses[date] = [];
      }
      groupedExpenses[date]!.add(expense);
    }

    return ListView.builder(
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        String date = groupedExpenses.keys.elementAt(index);
        List<ExpenseModel> dayExpenses = groupedExpenses[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              child: Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  )
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(8),
              itemCount: dayExpenses.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final expense = dayExpenses[index];
                final bool hasNote = expense.note.trim().isNotEmpty;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    onLongPress: () => _showActionMenu(context, expense),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon danh mục với màu khác nhau cho thu/chi
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconData(int.parse(expense.categoryIcon), fontFamily: 'MaterialIcons'),
                              color: expense.isExpense ? Colors.red : Colors.green, // Đổi màu icon theo loại giao dịch
                            ),
                          ),
                          SizedBox(width: 12),

                          // Nội dung chính
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                      Text(
                                        expense.category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                if (hasNote)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      expense.note,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Số tiền
                          Text(
                            formatCurrencyWithSymbol(expense.amount),
                            style: TextStyle(
                              color: expense.isExpense ? Colors.red : Colors.green,
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
    );
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
          activeIcon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.calendar_today, color: Colors.orangeAccent),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart),
          label: "Báo cáo",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "Khác",
        ),
      ],
    );
  }
}
