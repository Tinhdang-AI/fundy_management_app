import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import thêm thư viện hỗ trợ ngôn ngữ
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';

class GroupedTransactionList extends StatelessWidget {
  final List<ExpenseModel> transactions;
  final Function(BuildContext, ExpenseModel) onLongPress;
  final bool enableLongPress;

  const GroupedTransactionList({
    Key? key,
    required this.transactions,
    required this.onLongPress,
    this.enableLongPress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Đảm bảo đã khởi tạo locale tiếng Việt
    initializeDateFormatting('vi_VN', null);

    // Group transactions by date
    Map<String, List<ExpenseModel>> groupedTransactions = {};
    for (var transaction in transactions) {
      // Sử dụng locale 'vi_VN' để hiển thị ngày tiếng Việt
      String date = _formatDateToVietnamese(transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    return ListView.builder(
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        String date = groupedTransactions.keys.elementAt(index);
        List<ExpenseModel> dayTransactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: dayTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final transaction = dayTransactions[index];
                final bool hasNote = transaction.note.trim().isNotEmpty;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    onLongPress: enableLongPress
                        ? () => onLongPress(context, transaction)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Category icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconData(int.parse(transaction.categoryIcon), fontFamily: 'MaterialIcons'),
                              color: transaction.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (hasNote)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      transaction.note,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Amount
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
    );
  }

  // Hàm chuyển đổi định dạng ngày tháng sang tiếng Việt
  String _formatDateToVietnamese(DateTime date) {
    // Pattern trực tiếp với thứ tiếng Việt
    final formatter = DateFormat('d/M/yyyy', 'vi_VN');

    // Lấy tên thứ trong tuần
    String weekday = _getVietnameseWeekday(date.weekday);

    // Kết hợp ngày tháng với tên thứ
    return '${formatter.format(date)} ($weekday)';
  }

  // Hàm trả về tên thứ tiếng Việt dựa trên weekday (1-7)
  String _getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ hai';
      case 2:
        return 'Thứ ba';
      case 3:
        return 'Thứ tư';
      case 4:
        return 'Thứ năm';
      case 5:
        return 'Thứ sáu';
      case 6:
        return 'Thứ bảy';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }
}