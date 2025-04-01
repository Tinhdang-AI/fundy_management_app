import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/currency_formatter.dart';
import '/utils/message_utils.dart';

class TransactionUtils {
  static final DatabaseService _databaseService = DatabaseService();

  // Edit transaction
  static Future<bool> editTransaction(
      BuildContext context,
      ExpenseModel expense,
      Function onSuccess,
      {Function? onLoading}
      ) async {
    // Show edit dialog
    final result = await showEditDialog(context, expense);

    if (result == null || !result.updated) {
      return false; // User cancelled or no changes
    }

    if (onLoading != null) {
      onLoading(true);
    }

    try {
      // Kiểm tra xem có thay đổi nào không
      if (result.amount != expense.amount ||
          result.note != expense.note ||
          !_isSameDay(result.date, expense.date)) {

        final updatedExpense = ExpenseModel(
          id: expense.id,
          userId: expense.userId,
          note: result.note,
          amount: result.amount,
          category: expense.category,
          categoryIcon: expense.categoryIcon,
          date: result.date,
          isExpense: expense.isExpense,
        );

        await _databaseService.updateExpense(updatedExpense);

        // Notify caller about successful update
        onSuccess(updatedExpense);

        // Show success message
        MessageUtils.showSuccessMessage(context, "Đã cập nhật giao dịch thành công");
        return true;
      }
    } catch (e) {
      MessageUtils.showErrorMessage(context, "Không thể cập nhật giao dịch. Vui lòng thử lại sau.");
    } finally {
      if (onLoading != null) {
        onLoading(false);
      }
    }

    return false;
  }

  // Hàm so sánh xem có phải cùng một ngày không
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Delete transaction
  static Future<bool> deleteTransaction(
      BuildContext context,
      ExpenseModel expense,
      Function onSuccess,
      {Function? onLoading}
      ) async {
    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(context, expense);

    if (confirmed != true) {
      return false; // User cancelled
    }

    if (onLoading != null) {
      onLoading(true);
    }

    try {
      await _databaseService.deleteExpense(expense.id);

      // Notify caller about successful deletion
      onSuccess();

      // Show success message
      MessageUtils.showSuccessMessage(context, "Đã xóa giao dịch thành công");
      return true;
    } catch (e) {
      MessageUtils.showErrorMessage(context, "Không thể xóa giao dịch. Vui lòng thử lại sau.");
    } finally {
      if (onLoading != null) {
        onLoading(false);
      }
    }

    return false;
  }

  // Show action menu on long press
  static void showActionMenu(
      BuildContext context,
      ExpenseModel expense,
      Function onEdit,
      Function onDelete
      ) {
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
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa giao dịch'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
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

  // Show edit dialog with current values
  static Future<EditResult?> showEditDialog(
      BuildContext context,
      ExpenseModel expense
      ) {
    final TextEditingController noteController = TextEditingController(text: expense.note);
    final TextEditingController amountController = TextEditingController(text: formatCurrency.format(expense.amount));

    // Hiển thị danh mục (không cho phép thay đổi)
    String category = expense.category;

    // Lưu lại giá trị ban đầu của ngày
    DateTime selectedDate = expense.date;

    // Hiển thị dưới dạng định dạng dd/MM/yyyy
    final dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate)
    );

    return showDialog<EditResult?>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Chỉnh sửa giao dịch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị danh mục (không cho phép thay đổi)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                IconData(int.parse(expense.categoryIcon), fontFamily: 'MaterialIcons'),
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text(expense.category, style: TextStyle(fontSize: 16))
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Ghi chú
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Số tiền
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Số tiền',
                        border: OutlineInputBorder(),
                        suffix: Text(getCurrentSymbol()),
                      ),
                      inputFormatters: [
                        CurrencyInputFormatter(),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Ngày giao dịch
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(Duration(days: 30)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.orange,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            labelText: 'Ngày',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = parseFormattedCurrency(amountController.text);
                    final note = noteController.text.trim();

                    if (amount <= 0) {
                      MessageUtils.showErrorMessage(context, "Số tiền không hợp lệ");
                      return;
                    }

                    Navigator.pop(
                        context,
                        EditResult(
                            note: note,
                            amount: amount,
                            category: expense.category,
                            categoryIcon: expense.categoryIcon,
                            date: selectedDate,
                            updated: note != expense.note ||
                                amount != expense.amount ||
                                !_isSameDay(selectedDate, expense.date)
                        )
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Lưu'),
                ),
              ],
            );
          }
      ),
    );
  }

  // Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation(BuildContext context, ExpenseModel expense) {
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
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Class to hold edit dialog results
class EditResult {
  final String note;
  final double amount;
  final String category;
  final String categoryIcon;
  final DateTime date;
  final bool updated;

  EditResult({
    required this.note,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.date,
    required this.updated
  });
}