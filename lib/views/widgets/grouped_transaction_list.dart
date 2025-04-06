import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/transaction_utils.dart';

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
    // Group transactions by date
    Map<String, List<ExpenseModel>> groupedTransactions = {};
    for (var transaction in transactions) {
      String date = DateFormat('d/M/yyyy (EEEE)').format(transaction.date);
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
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              child: Text(
                date,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(8),
              itemCount: dayTransactions.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Category icon
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconData(int.parse(transaction.categoryIcon), fontFamily: 'MaterialIcons'),
                              color: transaction.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (hasNote)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
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
}