import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import 'currency_formatter.dart';
import 'message_utils.dart';

class TransactionUtils {
  // Edit a transaction
  static Future<TransactionResult> editTransaction(
      ExpenseModel expense,
      DatabaseService databaseService) async {
    try {
      // Get the updated expense from the database after update
      await databaseService.updateExpense(expense);

      return TransactionResult(
        success: true,
        updatedExpense: expense,
      );
    } catch (e) {
      print("Error updating transaction: $e");
      return TransactionResult(
        success: false,
        errorMessage: "Lỗi cập nhật giao dịch: ${e.toString()}",
      );
    }
  }

  // Delete a transaction
  static Future<bool> deleteTransaction(
      String expenseId,
      DatabaseService databaseService) async {
    try {
      await databaseService.deleteExpense(expenseId);
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }

  // Show action menu for a transaction
  static void showActionMenu(
      BuildContext context,
      ExpenseModel expense,
      Function onEdit,
      Function onDelete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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

  // Show edit dialog
  static Future<EditResult?> showEditDialog(
      BuildContext context,
      ExpenseModel expense,
      List<Map<String, dynamic>> categoryList) {
    final TextEditingController noteController = TextEditingController(text: expense.note);

    // Convert the amount from VND to current currency
    final double convertedAmount = convertFromVND(expense.amount);
    final TextEditingController amountController = TextEditingController(
        text: formatCurrency.format(convertedAmount));

    // Keep original date value
    DateTime selectedDate = expense.date;

    // Khởi tạo danh mục đã chọn và biểu tượng danh mục
    String selectedCategory = expense.category;
    String selectedCategoryIcon = expense.categoryIcon;

    // Format date as dd/MM/yyyy
    final dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));


    return showDialog<EditResult?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            // Áp dụng theme riêng cho dialog này
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Colors.orange,
                selectionColor: Colors.orange.withOpacity(0.3),
                selectionHandleColor: Colors.orange,
              ),
            ),
            child: AlertDialog(
              title: Text('Chỉnh sửa giao dịch'),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần danh mục có thể chọn
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        // Container có thể nhấn để mở dialog chọn danh mục
                        GestureDetector(
                          onTap: () {
                            // Hiển thị dialog chọn danh mục
                            _showCategorySelectionDialog(
                                context,
                                categoryList,
                                expense.isExpense,
                                selectedCategory,
                                    (category, icon) {
                                  setState(() {
                                    selectedCategory = category;
                                    selectedCategoryIcon = icon;
                                  });
                                }
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Phần hiển thị danh mục đã chọn
                                Row(
                                  children: [
                                    Icon(
                                      IconData(int.parse(selectedCategoryIcon), fontFamily: 'MaterialIcons'),
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(selectedCategory,
                                        style: TextStyle(fontSize: 16, color: Colors.black)
                                    ),
                                  ],
                                ),
                                // Thêm icon để cho biết có thể nhấn vào
                                Icon(Icons.arrow_drop_down, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Note field
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                      ),
                    ),

                    SizedBox(height: 16),

                    // Amount field
                    TextField(
                      controller: amountController,
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Số tiền',
                        suffix: Text(getCurrentSymbol(), style: TextStyle(color: Colors.black)),
                      ),
                      inputFormatters: [
                        CurrencyInputFormatter(),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Date picker
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
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Ngày',
                            suffixIcon: Icon(Icons.calendar_today, color: Colors.black),
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
                    // Parse the amount in current currency and convert back to VND
                    final amount = convertToVND(parseFormattedCurrency(amountController.text));
                    final note = noteController.text.trim();

                    if (amount <= 0) {
                      // Show error
                      MessageUtils.showErrorMessage(context, "Số tiền không hợp lệ");
                      return;
                    }

                    // Check if there are any changes
                    bool hasChanges = note != expense.note ||
                        amount != expense.amount ||
                        !isSameDay(selectedDate, expense.date) ||
                        selectedCategory != expense.category ||
                        selectedCategoryIcon != expense.categoryIcon;

                    // Return updated expense if there are changes
                    if (hasChanges) {
                      Navigator.pop(
                        context,
                        EditResult(
                          note: note,
                          amount: amount,
                          date: selectedDate,
                          category: selectedCategory,
                          categoryIcon: selectedCategoryIcon,
                          updated: true,
                        ),
                      );
                    } else {
                      Navigator.pop(
                        context,
                        EditResult(
                          note: note,
                          amount: amount,
                          date: selectedDate,
                          category: selectedCategory,
                          categoryIcon: selectedCategoryIcon,
                          updated: false,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Lưu'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _showCategorySelectionDialog(
      BuildContext context,
      List<Map<String, dynamic>> categoryList,
      bool isExpense,
      String currentCategory,
      Function(String, String) onCategorySelected) {

    // Lọc danh sách danh mục theo loại (thu/chi) VÀ loại bỏ mục "Chỉnh sửa"
    final filteredCategories = categoryList.where((category) =>
    category['isExpense'] == isExpense &&
        category['name'] != "Chỉnh sửa" // Loại bỏ mục "Chỉnh sửa"
    ).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isExpense ? 'Chọn danh mục chi' : 'Chọn danh mục thu'),
          backgroundColor: Colors.white,
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: filteredCategories.isEmpty
                ? Center(child: Text('Không có danh mục nào.'))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                final isSelected = category['name'] == currentCategory;

                return ListTile(
                  leading: Icon(
                    IconData(int.parse(category['icon']), fontFamily: 'MaterialIcons'),
                    color: Colors.orange,
                  ),
                  title: Text(category['name'], style: TextStyle(color: Colors.black)),
                  selected: isSelected,
                  selectedTileColor: Colors.orange.shade50,
                  trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    onCategorySelected(category['name'], category['icon']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  // Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation(
      BuildContext context,
      ExpenseModel expense) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        backgroundColor: Colors.white,
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

  // Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Result classes
class TransactionResult {
  final bool success;
  final String? errorMessage;
  final ExpenseModel? updatedExpense;

  TransactionResult({
    required this.success,
    this.errorMessage,
    this.updatedExpense,
  });
}

class EditResult {
  final String note;
  final double amount;
  final DateTime date;
  final String category;       // Thêm trường category
  final String categoryIcon;   // Thêm trường categoryIcon
  final bool updated;

  EditResult({
    required this.note,
    required this.amount,
    required this.date,
    required this.category,
    required this.categoryIcon,
    required this.updated,
  });
}