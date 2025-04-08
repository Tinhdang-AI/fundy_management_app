import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
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
  const CustomDatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    this.showMonthInfo = false,
    this.backgroundColor,
    this.textColor,
    this.arrowColor = Colors.orange,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthRange = _getMonthRangeText(selectedDate);

    return Padding(
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
          const SizedBox(width: 8),
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: showBorder ? Border.all(color: arrowColor) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: TextStyle(
                        color: textColor ?? Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showMonthInfo) ...[
                      const SizedBox(height: 2),
                      Text(
                        monthRange,
                        style: TextStyle(
                          color: textColor ?? Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onPressed: () => onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: arrowColor),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 20,
    );
  }

  String _getMonthRangeText(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return "${DateFormat('MM/yyyy').format(date)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";
  }

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

class MonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onMonthChanged;

  const MonthPicker({
    Key? key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthRange = _getMonthRangeText(focusedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFA07A),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => onMonthChanged(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                monthRange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => onMonthChanged(1),
          ),
        ],
      ),
    );
  }

  String _getMonthRangeText(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return "${DateFormat('MM/yyyy').format(date)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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