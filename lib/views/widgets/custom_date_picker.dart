import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final bool showMonthInfo;
  final Color? backgroundColor;
  final Color? textColor;
  final Color arrowColor;
  final bool showBorder;

  /// Widget chọn lịch tùy chỉnh cho ứng dụng
  ///
  /// [selectedDate]: Ngày đang được chọn
  /// [onDateChanged]: Callback khi người dùng thay đổi ngày
  /// [showMonthInfo]: Hiển thị thông tin tháng bên dưới ngày (mặc định: false)
  /// [backgroundColor]: Màu nền của widget (mặc định: Colors.white)
  /// [textColor]: Màu chữ (mặc định: Colors.black)
  /// [arrowColor]: Màu của các mũi tên điều hướng (mặc định: Colors.orange)
  /// [showBorder]: Hiển thị viền (mặc định: true)
  CustomDatePicker({
    required this.selectedDate,
    required this.onDateChanged,
    this.showMonthInfo = false,
    this.backgroundColor,
    this.textColor,
    this.arrowColor = Colors.orange,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán thông tin phạm vi tháng để hiển thị
    DateTime firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    DateTime lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    String monthRange = "${DateFormat('MM/yyyy').format(selectedDate)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            "Ngày",
            style: TextStyle(
              color: textColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_left, color: arrowColor),
            onPressed: () {
              onDateChanged(selectedDate.subtract(Duration(days: 1)));
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 20,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: showBorder ? Border.all(color: arrowColor) : null,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        DateFormat('dd/MM/yyyy (E)').format(selectedDate),
                        style: TextStyle(
                          color: textColor ?? Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (showMonthInfo) SizedBox(height: 2),
                    if (showMonthInfo)
                      Text(
                        monthRange,
                        style: TextStyle(
                          color: textColor ?? Colors.black,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: arrowColor),
            onPressed: () {
              onDateChanged(selectedDate.add(Duration(days: 1)));
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // Hiển thị date picker để chọn ngày
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}

// Widget chọn tháng để sử dụng trong CalendarScreen
class MonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final Function(DateTime) onDateChanged;
  final Function(int) onMonthChanged;

  MonthPicker({
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime(focusedDate.year, focusedDate.month, 1);
    DateTime lastDay = DateTime(focusedDate.year, focusedDate.month + 1, 0);
    String monthRange = "${DateFormat('MM/yyyy').format(focusedDate)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFA07A),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => onMonthChanged(-1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy (E)').format(selectedDate),
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
            onPressed: () => onMonthChanged(1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Hiển thị date picker để chọn ngày
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }
}

