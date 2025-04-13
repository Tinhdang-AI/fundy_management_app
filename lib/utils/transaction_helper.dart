import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../utils/message_utils.dart';
import '../utils/transaction_utils.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '/localization/app_localizations_extension.dart';

/// Helper class for transaction operations across different screens
class TransactionHelper {
  /// Handle transaction action menu with proper view model handling
  static void showActionMenu<T>(
      BuildContext context,
      ExpenseModel expense,
      T viewModel,
      Future<void> Function(ExpenseModel)? onEditSuccess,
      Future<void> Function(ExpenseModel)? onDeleteSuccess,
      ) {
    TransactionUtils.showActionMenu(
      context,
      expense,
          () => _editTransaction(context, expense, viewModel, onEditSuccess),
          () => _deleteTransaction(context, expense, viewModel, onDeleteSuccess),
    );
  }

  /// Internal method to handle transaction editing
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

        final success = await _updateTransactionInViewModel(viewModel, updatedExpense);

        if (success) {
          // Wait a bit for animations to complete and data to update
          await Future.delayed(Duration(milliseconds: 300));

          if (context.mounted) {
            // Get the current ScaffoldMessenger and make sure it's valid
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Clear all displayed SnackBars
            scaffoldMessenger.clearSnackBars();

            // Display success message with longer duration
            String type = updatedExpense.isExpense
                ? context.tr('expense')
                : context.tr('income');

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(context.tr('transaction_updated', [type])),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Call optional success callback
          if (onEditSuccess != null) {
            await onEditSuccess(updatedExpense);
          }
        } else {
          // Display error message if update fails
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('update_error')),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Error editing transaction: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${context.tr('error')}: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          // Wait a bit for animations to complete and data to update
          await Future.delayed(Duration(milliseconds: 300));

          // Display success message
          if (context.mounted) {
            // Get current ScaffoldMessenger and ensure it's valid
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Clear all displayed SnackBars
            scaffoldMessenger.clearSnackBars();

            String type = expense.isExpense
                ? context.tr('expense')
                : context.tr('income');

            // Display success message with longer duration
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(context.tr('transaction_deleted', [type])),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Call optional success callback
          if (onDeleteSuccess != null) {
            await onDeleteSuccess(expense);
          }
        } else {
          // Display error message if deletion fails
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('delete_error')),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print("Error deleting transaction: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${context.tr('error')}: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Helper method to get categories from different view model types
  static Future<List<Map<String, dynamic>>> _getCategoriesFromViewModel<T>(T viewModel) async {
    if (viewModel is SearchViewModel) {
      return await viewModel.getAllCategories();
    } else if (viewModel is CalendarViewModel) {
      return await viewModel.getAllCategories();
    } else if (viewModel is ReportViewModel) {
      return await viewModel.getAllCategories();
    } else {
      // Default empty categories list for unsupported view models
      print("Warning: Getting categories from unsupported view model type: ${viewModel.runtimeType}");
      return [];
    }
  }

  /// Helper method to update transaction in different view model types
  static Future<bool> _updateTransactionInViewModel<T>(T viewModel, ExpenseModel expense) async {
    if (viewModel is SearchViewModel) {
      return await viewModel.editTransaction(expense);
    } else if (viewModel is CalendarViewModel) {
      return await viewModel.editTransaction(expense, (e) {});
    } else if (viewModel is ReportViewModel) {
      return await viewModel.editTransaction(expense);
    } else {
      // Default failure for unsupported view models
      print("Warning: Updating transaction in unsupported view model type: ${viewModel.runtimeType}");
      return false;
    }
  }

  /// Helper method to delete transaction in different view model types
  static Future<bool> _deleteTransactionInViewModel<T>(T viewModel, ExpenseModel expense) async {
    if (viewModel is SearchViewModel) {
      return await viewModel.deleteTransaction(expense);
    } else if (viewModel is CalendarViewModel) {
      return await viewModel.deleteTransaction(expense);
    } else if (viewModel is ReportViewModel) {
      return await viewModel.deleteTransaction(expense);
    } else {
      // Default failure for unsupported view models
      print("Warning: Deleting transaction in unsupported view model type: ${viewModel.runtimeType}");
      return false;
    }
  }
}