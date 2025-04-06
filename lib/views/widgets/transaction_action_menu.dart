import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../utils/transaction_utils.dart';
import '../../utils/message_utils.dart';
import '../../viewmodels/calendar_viewmodel.dart';

class TransactionActionMenu {

  static void show<T>({
    required BuildContext context,
    required ExpenseModel expense,
    required T viewModel,
    Future<void> Function(ExpenseModel)? onEditSuccess,
    Future<void> Function(ExpenseModel)? onDeleteSuccess,
  }) {
    TransactionUtils.showActionMenu(
      context,
      expense,
          () => _editTransaction(context, expense, viewModel, onEditSuccess),
          () => _deleteTransaction(context, expense, viewModel, onDeleteSuccess),
    );
  }

  static Future<void> _editTransaction<T>(
      BuildContext context,
      ExpenseModel expense,
      T viewModel,
      Future<void> Function(ExpenseModel)? onEditSuccess,
      ) async {
    try {
      // Get categories from view model
      final categoryList = await _getCategoriesFromViewModel(viewModel);

      // Show edit dialog
      final result = await TransactionUtils.showEditDialog(
        context,
        expense,
        categoryList,
      );

      if (result != null && result.updated) {
        // Create updated expense
        final updatedExpense = expense.copyWith(
          note: result.note,
          amount: result.amount,
          date: result.date,
          category: result.category,
          categoryIcon: result.categoryIcon,
        );

        // Update transaction in view model
        bool success;
        if (viewModel is CalendarViewModel) {
          // Special handling for CalendarViewModel
          success = await (viewModel as CalendarViewModel).editTransaction(
              updatedExpense,
                  (editedExpense) {} // Empty callback since we're already handling success
          );
        } else {
          // Other view models
          success = await _updateTransactionInViewModel(viewModel, updatedExpense);
        }

        if (success) {
          // Thêm một delay ngắn để đảm bảo giao diện đã cập nhật
          await Future.delayed(Duration(milliseconds: 500));

          // Hiển thị thông báo thành công với NavigatorState.mounted check
          if (context.mounted) {
            // Đảm bảo hiển thị thông báo trên màn hình hiện tại
            ScaffoldMessenger.of(context).clearSnackBars();
            MessageUtils.showSuccessMessage(context, "Đã cập nhật giao dịch thành công");
          }

          // Gọi callback thành công tùy chọn
          if (onEditSuccess != null) {
            await onEditSuccess(updatedExpense);
          }
        } else {
          // Hiển thị thông báo lỗi nếu cập nhật không thành công
          if (context.mounted) {
            MessageUtils.showErrorMessage(context, "Không thể cập nhật giao dịch");
          }
        }
      }
    } catch (e) {
      print("Error editing transaction: $e");
      if (context.mounted) {
        MessageUtils.showErrorMessage(context, "Lỗi khi chỉnh sửa giao dịch: ${e.toString()}");
      }
    }
  }

  /// Internal method to handle transaction deletion
  static Future<void> _deleteTransaction<T>(
      BuildContext context,
      ExpenseModel expense,
      T viewModel,
      Future<void> Function(ExpenseModel)? onDeleteSuccess,
      ) async {
    // Show delete confirmation
    final confirmed = await TransactionUtils.showDeleteConfirmation(context, expense);

    if (confirmed == true) {
      try {
        final success = await _deleteTransactionInViewModel(viewModel, expense);

        if (success) {
          // Thêm một delay dài hơn để đảm bảo giao diện đã cập nhật
          await Future.delayed(Duration(milliseconds: 500));

          // Hiển thị thông báo thành công
          if (context.mounted) {
            // Đảm bảo hiển thị thông báo trên màn hình hiện tại
            ScaffoldMessenger.of(context).clearSnackBars();
            MessageUtils.showSuccessMessage(context, "Đã xóa giao dịch thành công");
          }

          // Gọi callback thành công tùy chọn
          if (onDeleteSuccess != null) {
            await onDeleteSuccess(expense);
          }
        } else {
          // Hiển thị thông báo lỗi nếu xóa không thành công
          if (context.mounted) {
            MessageUtils.showErrorMessage(context, "Không thể xóa giao dịch");
          }
        }
      } catch (e) {
        print("Error deleting transaction: $e");
        if (context.mounted) {
          MessageUtils.showErrorMessage(context, "Lỗi khi xóa giao dịch: ${e.toString()}");
        }
      }
    }
  }

  /// Dynamically get categories from view model
  static Future<List<Map<String, dynamic>>> _getCategoriesFromViewModel<T>(T viewModel) async {
    // Use reflection to call getAllCategories method
    return await (viewModel as dynamic).getAllCategories();
  }

  /// Dynamically update transaction in view model
  static Future<bool> _updateTransactionInViewModel<T>(T viewModel, ExpenseModel updatedExpense) async {
    // Use reflection to call editTransaction method
    return await (viewModel as dynamic).editTransaction(updatedExpense);
  }

  /// Dynamically delete transaction in view model
  static Future<bool> _deleteTransactionInViewModel<T>(T viewModel, ExpenseModel expense) async {
    // Use reflection to call deleteTransaction method
    return await (viewModel as dynamic).deleteTransaction(expense);
  }
}