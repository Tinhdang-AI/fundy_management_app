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

    return expensesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    });
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng trong một ngày cụ thể
  Stream<List<ExpenseModel>> getExpensesByDate(DateTime date) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Sử dụng UTC để tránh vấn đề múi giờ
    DateTime startDate = DateTime(date.year, date.month, date.day);
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    print("Fetching expenses from ${startDate.toString()} to ${endDate.toString()}");

    return expensesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      print("Found ${expenses.length} expenses for date ${date.toString()}");
      return expenses;
    })
        .timeout(Duration(seconds: 10), onTimeout: (sink) {
      // Trả về danh sách rỗng nếu timeout
      print("Timeout getting expenses for date ${date.toString()}");
      sink.add([]);
    });
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng trong một tháng cụ thể
  Stream<List<ExpenseModel>> getExpensesByMonth(int month, int year) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Sử dụng UTC để tránh vấn đề múi giờ
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = (month < 12)
        ? DateTime(year, month + 1, 1).subtract(Duration(seconds: 1))
        : DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

    print("Fetching monthly expenses from ${startDate.toString()} to ${endDate.toString()}");

    return expensesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      print("Found ${expenses.length} expenses for month $month/$year");
      return expenses;
    })
        .timeout(Duration(seconds: 15), onTimeout: (sink) {
      // Trả về danh sách rỗng nếu timeout
      print("Timeout getting expenses for month $month/$year");
      sink.add([]);
    });
  }

  // Lấy tất cả các khoản chi tiêu/thu nhập của người dùng trong một năm cụ thể
  Stream<List<ExpenseModel>> getExpensesByYear(int year) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

    print("Fetching yearly expenses from ${startDate.toString()} to ${endDate.toString()}");

    return expensesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      print("Found ${expenses.length} expenses for year $year");
      return expenses;
    })
        .timeout(Duration(seconds: 20), onTimeout: (sink) {
      // Trả về danh sách rỗng nếu timeout
      print("Timeout getting expenses for year $year");
      sink.add([]);
    });
  }

  // Tìm kiếm các khoản chi tiêu/thu nhập theo ghi chú
  Future<List<ExpenseModel>> searchExpensesByNote(String query) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      List<ExpenseModel> results = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .where((expense) =>
          expense.note.toLowerCase().contains(query.toLowerCase()))
          .toList();

      print("Search found ${results.length} results for query: $query");
      return results;
    } catch (e) {
      print("Error searching expenses: $e");
      return [];
    }
  }

  // Thêm vào DatabaseService
  Future<List<ExpenseModel>> getExpensesByMonthFuture(int month, int year) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = (month < 12)
          ? DateTime(year, month + 1, 1).subtract(Duration(seconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      print("Fetching monthly expenses (Future) from ${startDate.toString()} to ${endDate.toString()}");

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      print("Found ${expenses.length} expenses for month $month/$year (Future)");
      return expenses;
    } catch (e) {
      print("Error getting expenses by month future: $e");
      return [];
    }
  }

  // Lấy thông tin chi tiêu theo năm (Future)
  Future<List<ExpenseModel>> getExpensesByYearFuture(int year) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      print("Fetching yearly expenses (Future) from ${startDate.toString()} to ${endDate.toString()}");

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      print("Found ${expenses.length} expenses for year $year (Future)");
      return expenses;
    } catch (e) {
      print("Error getting expenses by year future: $e");
      return [];
    }
  }

  // Lấy tổng chi tiêu theo tháng
  Future<double> getTotalExpensesByMonth(int month, int year) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = (month < 12)
          ? DateTime(year, month + 1, 1).subtract(Duration(seconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      print("Total expenses for month $month/$year: $total");
      return total;
    } catch (e) {
      print("Error getting total expenses by month: $e");
      return 0;
    }
  }

  // Lấy tổng thu nhập theo tháng
  Future<double> getTotalIncomeByMonth(int month, int year) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = (month < 12)
          ? DateTime(year, month + 1, 1).subtract(Duration(seconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      print("Total income for month $month/$year: $total");
      return total;
    } catch (e) {
      print("Error getting total income by month: $e");
      return 0;
    }
  }

  // Lấy tổng chi tiêu theo năm
  Future<double> getTotalExpensesByYear(int year) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      print("Total expenses for year $year: $total");
      return total;
    } catch (e) {
      print("Error getting total expenses by year: $e");
      return 0;
    }
  }

  // Lấy tổng thu nhập theo năm
  Future<double> getTotalIncomeByYear(int year) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      print("Total income for year $year: $total");
      return total;
    } catch (e) {
      print("Error getting total income by year: $e");
      return 0;
    }
  }

  // Lấy thông tin chi tiêu theo danh mục cho báo cáo tháng
  Future<Map<String, double>> getExpensesByCategory(int month, int year) async {
    if (currentUserId == null) {
      return {};
    }

    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = (month < 12)
          ? DateTime(year, month + 1, 1).subtract(Duration(seconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'Không xác định';
        double amount = (data['amount'] ?? 0).toDouble();

        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }

      print("Category breakdown for month $month/$year: $categoryTotals");
      return categoryTotals;
    } catch (e) {
      print("Error getting expenses by category: $e");
      return {};
    }
  }

  // Lấy thông tin chi tiêu theo danh mục cho báo cáo năm
  Future<Map<String, double>> getExpensesByCategoryForYear(int year) async {
    if (currentUserId == null) {
      return {};
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(seconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isExpense', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'Không xác định';
        double amount = (data['amount'] ?? 0).toDouble();

        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }

      print("Category breakdown for year $year: $categoryTotals");
      return categoryTotals;
    } catch (e) {
      print("Error getting expenses by category for year: $e");
      return {};
    }
  }
}