import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '/screens/expense_screen.dart';
import '/screens/report_screen.dart';
import '/screens/more_screen.dart';
import '/screens/search_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';

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

  // Thêm để theo dõi ngày có giao dịch
  Map<DateTime, List<ExpenseModel>> _eventsByDay = {};

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

      _databaseService.getExpensesByMonth(month, year).listen(
            (expenses) {
          if (mounted) {
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

            setState(() {
              _eventsByDay = eventsByDay;
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          print("Error loading month data: $e");
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print("Error in _loadMonthData: $e");
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
      print("Loading expenses for date: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}");

      _databaseService.getExpensesByDate(_selectedDay).listen(
            (expenses) {
          print("Received ${expenses.length} expenses for selected day");
          if (mounted) {
            setState(() {
              _selectedDayExpenses = expenses;
              _calculateTotals();
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          print("Error in getExpensesByDate stream: $e");
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onDone: () {
          print("Stream completed for selected day");
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print("Error in _loadSelectedDayData: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  // Hàm để thay đổi tháng
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _loadMonthData();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _buildMonthSelector(),
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

  Widget _buildMonthSelector() {
    // Định dạng ngày đầu tháng và cuối tháng
    DateTime firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    String monthRange = "${DateFormat('MM/yyyy').format(_focusedDay)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFA07A), // Màu cam sáng giống trong hình
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              });
              _loadMonthData();
            },
          ),
          Text(
            monthRange,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              });
              _loadMonthData();
            },
          ),
        ],
      ),
    );
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
    // Lưu ý: Thứ 2 = 1, Chủ Nhật = 7 (khác với DateTime.weekday, nơi Chủ Nhật = 0)
    int startOffset = firstDay.weekday - 1; // -1 vì muốn bắt đầu từ thứ 2
    if (startOffset < 0) startOffset = 6; // Nếu là Chủ Nhật

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

    // Tính số ngày cần thêm cho đủ 6 hàng
    int endOffset = 42 - days.length; // 42 = 6 rows * 7 days

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

        // Lưới các ngày
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
              }

              if (isSelected) {
                textColor = Colors.white;
                backgroundColor = Colors.orange.shade100;
              } else if (isToday) {
                backgroundColor = Colors.grey.shade200;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = DateTime(day.year, day.month, day.day);
                    });
                    _loadSelectedDayData();
                  },
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
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasIncome || hasExpense)
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
          _buildSummaryItem('Tiền thu', '${NumberFormat('#,###').format(_incomeTotal)}đ', Colors.green),
          _buildSummaryItem('Tiền chi', '${NumberFormat('#,###').format(_expenseTotal)}đ', Colors.red),
          _buildSummaryItem(
              'Tổng',
              '${_netTotal >= 0 ? '' : '-'}${NumberFormat('#,###').format(_netTotal.abs())}đ',
              _netTotal >= 0 ? Colors.green : Colors.red
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black87)),
        SizedBox(height: 2),
        Text(amount, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
              color: Colors.grey.shade600,
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(date, style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
            ...dayExpenses.map((expense) => ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    IconData(int.parse(expense.categoryIcon), fontFamily: 'MaterialIcons'),
                    color: Colors.orange
                ),
              ),
              title: Row(
                children: [
                  expense.isExpense ? SizedBox() : Text('🔥 ', style: TextStyle(fontSize: 16)),
                  Text(expense.category, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Text(expense.note),
              trailing: Text(
                  '${NumberFormat('#,###').format(expense.amount)}đ',
                  style: TextStyle(
                      color: expense.isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold
                  )
              ),
            )).toList(),
          ],
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
