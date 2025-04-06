import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/message_utils.dart';
import '../../utils/transaction_utils.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import '../widgets/grouped_transaction_list.dart';
import '../widgets/transaction_action_menu.dart';
import '../widgets/custom_date_picker.dart'; // Import widget chọn lịch chung

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize the calendar view model when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarViewModel = Provider.of<CalendarViewModel>(context, listen: false);
      calendarViewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the calendar view model
    final calendarViewModel = Provider.of<CalendarViewModel>(context);

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
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MonthPicker(
            selectedDate: calendarViewModel.selectedDay,
            focusedDate: calendarViewModel.focusedDay,
            onDateChanged: (date) {
              calendarViewModel.selectDate(date);
            },
            onMonthChanged: (change) {
              calendarViewModel.changeMonth(change);
            },
          ),
          _buildCustomCalendar(calendarViewModel),
          _buildSummary(calendarViewModel),
          Expanded(
            child: calendarViewModel.isLoading
                ? Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
                : calendarViewModel.selectedDayExpenses.isEmpty
                ? Center(
              child: Text(
                'Không có giao dịch nào vào ngày này',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _buildTransactionList(calendarViewModel),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1, // 1 for CalendarScreen
        onTabSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/expense');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/report');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/more');
              break;
          }
        },
      ),
    );
  }

  // Custom calendar widget
  Widget _buildCustomCalendar(CalendarViewModel viewModel) {
    // Get current month information
    final int year = viewModel.focusedDay.year;
    final int month = viewModel.focusedDay.month;

    // First day of month
    final DateTime firstDay = DateTime(year, month, 1);

    // Days in month
    final DateTime lastDay = DateTime(year, month + 1, 0);
    final int daysInMonth = lastDay.day;

    // Calculate start offset (first day of week containing day 1)
    // Note: Monday = 1, Sunday = 7 (whereas Sunday = 0 in DateTime.weekday)
    int startOffset = firstDay.weekday - 1; // -1 to start from Monday
    if (startOffset < 0) startOffset = 6; // If Sunday

    // Calculate total days to show and number of rows needed
    int totalDaysToShow = startOffset + daysInMonth;
    int numberOfRows = (totalDaysToShow / 7).ceil(); // Round up to have enough rows

    // List of days from previous month, current month, and next month
    List<DateTime> days = [];

    // Add days from previous month
    final DateTime prevMonth = DateTime(year, month - 1, 1);
    final int daysInPrevMonth = DateTime(year, month, 0).day;
    for (int i = 0; i < startOffset; i++) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - startOffset + i + 1));
    }

    // Add days from current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(year, month, i));
    }

    // Calculate days needed to fill the last row
    int endOffset = (numberOfRows * 7) - days.length;

    // Add days from next month
    for (int i = 1; i <= endOffset; i++) {
      days.add(DateTime(year, month + 1, i));
    }

    // Create weekly lists
    List<List<DateTime>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Column(
      children: [
        // Header with weekday names
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

        // Calendar grid - only show the necessary number of rows
        for (var week in weeks)
          Row(
            children: week.map((day) {
              bool isCurrentMonth = day.month == month;
              bool isToday = _isSameDay(day, DateTime.now());
              bool isSelected = _isSameDay(day, viewModel.selectedDay);
              bool isWeekend = day.weekday >= 6; // Saturday and Sunday

              // Check if day has transactions
              List<ExpenseModel> expenses = viewModel.getExpensesForDay(day);
              bool hasIncome = expenses.any((e) => !e.isExpense);
              bool hasExpense = expenses.any((e) => e.isExpense);

              // Determine style for the cell
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
                  onTap: isCurrentMonth ? () => viewModel.selectDay(day) : null,
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

  Widget _buildSummary(CalendarViewModel viewModel) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Tiền thu', formatCurrencyWithSymbol(viewModel.incomeTotal), Colors.green),
          _buildSummaryItem('Tiền chi', formatCurrencyWithSymbol(viewModel.expenseTotal), Colors.red),
          _buildSummaryItem(
              'Tổng',
              viewModel.netTotal >= 0
                  ? formatCurrencyWithSymbol(viewModel.netTotal)
                  : '-${formatCurrencyWithSymbol(viewModel.netTotal.abs())}',
              viewModel.netTotal >= 0 ? Colors.green : Colors.red
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
          constraints: BoxConstraints(maxWidth: 110),
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

  Widget _buildTransactionList(CalendarViewModel viewModel) {
    return GroupedTransactionList(
      transactions: viewModel.selectedDayExpenses,
      onLongPress: (context, expense) =>
          _showActionMenu(context, expense, viewModel),
    );
  }


  void _showActionMenu(BuildContext context, ExpenseModel expense, CalendarViewModel viewModel) {
    TransactionActionMenu.show(
      context: context,
      expense: expense,
      viewModel: viewModel,
      onEditSuccess: (updatedExpense) async {
      },
      onDeleteSuccess: (deletedExpense) async {
      },
    );
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}