import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy ID của người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get expensesCollection => _firestore.collection('expenses');

  // Lưu thông tin người dùng khi đăng ký
  Future<void> saveUserInfo(String name, String email) async {
    if (currentUserId == null) return;

    UserModel user = UserModel(
      id: currentUserId!,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await usersCollection.doc(currentUserId).set(user.toMap());
  }

  // Thêm một khoản chi tiêu/thu nhập
  Future<String> addExpense({
    required String note,
    required double amount,
    required String category,
    required String categoryIcon,
    required DateTime date,
    required bool isExpense,
  }) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');

    ExpenseModel expense = ExpenseModel(
      id: '',
      userId: currentUserId!,
      note: note,
      amount: amount,
      category: category,
      categoryIcon: categoryIcon,
      date: date,
      isExpense: isExpense,
    );

    DocumentReference docRef = await expensesCollection.add(expense.toMap());

    // Cập nhật ID sau khi thêm vào Firestore
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  // Cập nhật một khoản chi tiêu/thu nhập
  Future<void> updateExpense(ExpenseModel expense) async {
    await expensesCollection.doc(expense.id).update(expense.toMap());
  }

  // Xóa một khoản chi tiêu/thu nhập
  Future<void> deleteExpense(String expenseId) async {
    await expensesCollection.doc(expenseId).delete();
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng
  Stream<List<ExpenseModel>> getUserExpenses() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        List<ExpenseModel> expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        print("Retrieved ${expenses.length} total expenses");
        return expenses;
      });
    } catch (e) {
      print("Error in getUserExpenses: $e");
      return Stream.value([]);
    }
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng trong một ngày cụ thể (Future)
  Future<List<ExpenseModel>> getExpensesByDateFuture(DateTime date) async {
    if (currentUserId == null) {
      print("getExpensesByDateFuture: currentUserId is null");
      return [];
    }

    try {
      // Tạo ngày bắt đầu (00:00:00) và ngày kết thúc (23:59:59)
      DateTime startDate = DateTime(date.year, date.month, date.day);
      DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      print("Future: Fetching expenses from ${startDate.toString()} to ${endDate.toString()} for user $currentUserId");

      // Kiểm tra xem người dùng có dữ liệu không
      QuerySnapshot countSnapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      print("User has data: ${countSnapshot.docs.isNotEmpty}");

      // Thực hiện truy vấn với bộ lọc ngày
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      List<ExpenseModel> expenses = [];
      for (var doc in snapshot.docs) {
        try {
          ExpenseModel expense = ExpenseModel.fromFirestore(doc);
          expenses.add(expense);
        } catch (parseError) {
          print("Error parsing document ${doc.id}: $parseError");
        }
      }

      print("Future: Found ${expenses.length} expenses for date ${date.toString()}");
      return expenses;
    } catch (e) {
      print("Error in getExpensesByDateFuture: $e");

      // Fallback - try to get all expenses and filter manually
      try {
        print("Attempting fallback query for date ${date.toString()}");
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> allExpenses = [];
        for (var doc in snapshot.docs) {
          try {
            ExpenseModel expense = ExpenseModel.fromFirestore(doc);
            allExpenses.add(expense);
          } catch (parseError) {
            print("Error parsing document in fallback: $parseError");
          }
        }

        // Filter on the client side
        DateTime startDate = DateTime(date.year, date.month, date.day);
        DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

        List<ExpenseModel> filteredExpenses = allExpenses.where((expense) {
          DateTime expDate = expense.date;
          return (expDate.isAfter(startDate) || isSameDateTime(expDate, startDate)) &&
              (expDate.isBefore(endDate) || isSameDateTime(expDate, endDate));
        }).toList();

        print("Fallback found ${filteredExpenses.length} expenses for date ${date.toString()}");
        return filteredExpenses;
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng trong một tháng cụ thể (Future)
  Future<List<ExpenseModel>> getExpensesByMonthFuture(int month, int year) async {
    if (currentUserId == null) {
      print("getExpensesByMonthFuture: currentUserId is null");
      return [];
    }

    try {
      // Fix date range calculation
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = month < 12
          ? DateTime(year, month + 1, 1).subtract(Duration(milliseconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

      print("Future: Fetching monthly expenses from ${startDate.toString()} to ${endDate.toString()} for user $currentUserId");

      // First, check if the query would execute successfully
      QuerySnapshot countSnapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      print("User has data: ${countSnapshot.docs.isNotEmpty}");

      // Execute the actual query with date filters
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      // Process results
      List<ExpenseModel> expenses = [];
      for (var doc in snapshot.docs) {
        try {
          ExpenseModel expense = ExpenseModel.fromFirestore(doc);
          expenses.add(expense);
        } catch (parseError) {
          print("Error parsing document ${doc.id}: $parseError");
        }
      }

      print("Future: Found ${expenses.length} expenses for month $month/$year");
      return expenses;
    } catch (e) {
      print("Error in getExpensesByMonthFuture: $e");

      // Try a simpler query as fallback
      try {
        print("Attempting fallback query for month $month/$year");
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> allExpenses = [];
        for (var doc in snapshot.docs) {
          try {
            ExpenseModel expense = ExpenseModel.fromFirestore(doc);
            allExpenses.add(expense);
          } catch (parseError) {
            print("Error parsing document in fallback: $parseError");
          }
        }

        // Filter on the client side
        DateTime startDate = DateTime(year, month, 1);
        DateTime endDate = month < 12
            ? DateTime(year, month + 1, 1).subtract(Duration(milliseconds: 1))
            : DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

        List<ExpenseModel> filteredExpenses = allExpenses.where((expense) {
          DateTime expDate = expense.date;
          return (expDate.isAfter(startDate) || isSameDateTime(expDate, startDate)) &&
              (expDate.isBefore(endDate) || isSameDateTime(expDate, endDate));
        }).toList();

        print("Fallback found ${filteredExpenses.length} expenses for month $month/$year");
        return filteredExpenses;
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Lấy thông tin chi tiêu theo năm (Future)
  Future<List<ExpenseModel>> getExpensesByYearFuture(int year) async {
    if (currentUserId == null) {
      print("getExpensesByYearFuture: currentUserId is null");
      return [];
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

      print("Future: Fetching yearly expenses from ${startDate.toString()} to ${endDate.toString()} for user $currentUserId");

      // First, check if the query would execute successfully
      QuerySnapshot countSnapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      print("User has data: ${countSnapshot.docs.isNotEmpty}");

      // Execute the actual query with date filters
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      // Process results
      List<ExpenseModel> expenses = [];
      for (var doc in snapshot.docs) {
        try {
          ExpenseModel expense = ExpenseModel.fromFirestore(doc);
          expenses.add(expense);
        } catch (parseError) {
          print("Error parsing document ${doc.id}: $parseError");
        }
      }

      print("Future: Found ${expenses.length} expenses for year $year");
      return expenses;
    } catch (e) {
      print("Error in getExpensesByYearFuture: $e");

      // Try a simpler query as fallback
      try {
        print("Attempting fallback query for year $year");
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> allExpenses = [];
        for (var doc in snapshot.docs) {
          try {
            ExpenseModel expense = ExpenseModel.fromFirestore(doc);
            allExpenses.add(expense);
          } catch (parseError) {
            print("Error parsing document in fallback: $parseError");
          }
        }

        // Filter on the client side
        DateTime startDate = DateTime(year, 1, 1);
        DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

        List<ExpenseModel> filteredExpenses = allExpenses.where((expense) {
          DateTime expDate = expense.date;
          return (expDate.isAfter(startDate) || isSameDateTime(expDate, startDate)) &&
              (expDate.isBefore(endDate) || isSameDateTime(expDate, endDate));
        }).toList();

        print("Fallback found ${filteredExpenses.length} expenses for year $year");
        return filteredExpenses;
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Lấy tổng chi tiêu theo tháng
  Future<double> getTotalExpensesByMonth(int month, int year) async {
    try {
      List<ExpenseModel> monthlyExpenses = await getExpensesByMonthFuture(month, year);
      double total = 0;
      for (var expense in monthlyExpenses) {
        if (expense.isExpense) {
          total += expense.amount;
        }
      }
      return total;
    } catch (e) {
      print("Error getting total expenses by month: $e");
      return 0;
    }
  }

  // Lấy tổng thu nhập theo tháng
  Future<double> getTotalIncomeByMonth(int month, int year) async {
    try {
      List<ExpenseModel> monthlyExpenses = await getExpensesByMonthFuture(month, year);
      double total = 0;
      for (var expense in monthlyExpenses) {
        if (!expense.isExpense) {
          total += expense.amount;
        }
      }
      return total;
    } catch (e) {
      print("Error getting total income by month: $e");
      return 0;
    }
  }

  // Lấy tổng chi tiêu theo năm
  Future<double> getTotalExpensesByYear(int year) async {
    try {
      List<ExpenseModel> yearlyExpenses = await getExpensesByYearFuture(year);
      double total = 0;
      for (var expense in yearlyExpenses) {
        if (expense.isExpense) {
          total += expense.amount;
        }
      }
      return total;
    } catch (e) {
      print("Error getting total expenses by year: $e");
      return 0;
    }
  }

  // Lấy tổng thu nhập theo năm
  Future<double> getTotalIncomeByYear(int year) async {
    try {
      List<ExpenseModel> yearlyExpenses = await getExpensesByYearFuture(year);
      double total = 0;
      for (var expense in yearlyExpenses) {
        if (!expense.isExpense) {
          total += expense.amount;
        }
      }
      return total;
    } catch (e) {
      print("Error getting total income by year: $e");
      return 0;
    }
  }

  // Lấy thông tin chi tiêu theo danh mục cho báo cáo tháng
  Future<Map<String, double>> getExpensesByCategory(int month, int year) async {
    try {
      List<ExpenseModel> monthlyExpenses = await getExpensesByMonthFuture(month, year);
      Map<String, double> categoryTotals = {};

      for (var expense in monthlyExpenses) {
        if (expense.isExpense) {
          String category = expense.category;
          categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
        }
      }

      return categoryTotals;
    } catch (e) {
      print("Error getting expenses by category: $e");
      return {};
    }
  }

  // Lấy thông tin chi tiêu theo danh mục cho báo cáo năm
  Future<Map<String, double>> getExpensesByCategoryForYear(int year) async {
    try {
      List<ExpenseModel> yearlyExpenses = await getExpensesByYearFuture(year);
      Map<String, double> categoryTotals = {};

      for (var expense in yearlyExpenses) {
        if (expense.isExpense) {
          String category = expense.category;
          categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
        }
      }

      return categoryTotals;
    } catch (e) {
      print("Error getting expenses by category for year: $e");
      return {};
    }
  }

  // Kiểm tra xem người dùng có dữ liệu nào không
  Future<bool> hasAnyData() async {
    if (currentUserId == null) return false;

    try {
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for data: $e");
      return false;
    }
  }

  // Hàm trợ giúp để so sánh hai DateTime đến giây
  bool isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute &&
        a.second == b.second;
  }
}