import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/currency_formatter.dart';

class ExpenseViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  // Default categories
  final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {"icon": Icons.restaurant, "label": "Ăn uống"},
    {"icon": Icons.shopping_bag, "label": "Chi tiêu hàng ngày"},
    {"icon": Icons.checkroom, "label": "Quần áo"},
    {"icon": Icons.spa, "label": "Mỹ phẩm"},
    {"icon": Icons.wine_bar, "label": "Phí giao lưu"},
    {"icon": Icons.local_hospital, "label": "Y tế"},
    {"icon": Icons.school, "label": "Giáo dục"},
    {"icon": Icons.electrical_services, "label": "Tiền điện"},
    {"icon": Icons.directions_bus, "label": "Đi lại"},
    {"icon": Icons.phone, "label": "Phí liên lạc"},
    {"icon": Icons.home, "label": "Tiền nhà"},
    {"icon": Icons.water_drop, "label": "Tiền nước"},
    {"icon": Icons.local_gas_station, "label": "Xăng dầu"},
    {"icon": Icons.computer, "label": "Công nghệ"},
    {"icon": Icons.car_repair, "label": "Sửa chữa"},
    {"icon": Icons.coffee, "label": "Cafe"},
    {"icon": Icons.pets, "label": "Thú cưng"},
    {"icon": Icons.cleaning_services, "label": "Dịch vụ"},
    {"icon": Icons.build, "label": "Chỉnh sửa"},
  ];

  final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {"icon": Icons.attach_money, "label": "Tiền lương"},
    {"icon": Icons.savings, "label": "Tiền phụ cấp"},
    {"icon": Icons.card_giftcard, "label": "Tiền thưởng"},
    {"icon": Icons.trending_up, "label": "Đầu tư"},
    {"icon": Icons.account_balance_wallet, "label": "Thu nhập phụ"},
    {"icon": Icons.work, "label": "Việc làm thêm"},
    {"icon": Icons.corporate_fare, "label": "Hoa hồng"},
    {"icon": Icons.real_estate_agent, "label": "Bất động sản"},
    {"icon": Icons.currency_exchange, "label": "Chênh lệch tỷ giá"},
    {"icon": Icons.dynamic_feed, "label": "Khác"},
    {"icon": Icons.build, "label": "Chỉnh sửa"},
  ];

  // List of all available icons for category creation
  final List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.checkroom,
    Icons.spa,
    Icons.wine_bar,
    Icons.local_hospital,
    Icons.school,
    Icons.electrical_services,
    Icons.directions_bus,
    Icons.phone,
    Icons.home,
    Icons.attach_money,
    Icons.pets,
    Icons.theater_comedy,
    Icons.sports_basketball,
    Icons.music_note,
    Icons.movie,
    Icons.flight,
    Icons.fitness_center,
    Icons.shopping_cart,
    Icons.child_care,
    Icons.toys,
    Icons.water_drop,
    Icons.coffee,
    Icons.fastfood,
    Icons.emoji_transportation,
    Icons.park,
    Icons.book,
    Icons.weekend,
    Icons.computer,
    Icons.car_repair,
    Icons.smartphone,
    Icons.local_gas_station,
    Icons.credit_card,
    Icons.subscriptions,
    Icons.sports_esports,
    Icons.cleaning_services,
    Icons.cake,
    Icons.create,
    Icons.style,
    Icons.work,
    Icons.monetization_on,
    Icons.analytics,
    Icons.payments,
    Icons.corporate_fare,
    Icons.dynamic_feed,
    Icons.inventory,
    Icons.savings,
    Icons.card_giftcard,
    Icons.auto_graph,
    Icons.currency_exchange,
    Icons.real_estate_agent,
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get expenseCategories => _expenseCategories;
  List<Map<String, dynamic>> get incomeCategories => _incomeCategories;
  List<IconData> get icons => availableIcons;

  // Load categories from Firebase
  Future<void> loadCategories() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setDefaultCategories();
        _isInitialized = true;
        _setLoading(false);
        return;
      }

      String userId = currentUser.uid;

      // Query data from Firestore
      DocumentSnapshot doc = await _firestore.collection('users')
          .doc(userId)
          .get();

      bool hasCategories = false;

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Load expense categories
        if (userData.containsKey('expenseCategories') &&
            userData['expenseCategories'] is List &&
            (userData['expenseCategories'] as List).isNotEmpty) {
          List<dynamic> loadedExpenseCategories = userData['expenseCategories'];
          List<Map<String, dynamic>> parsedExpenseCategories = loadedExpenseCategories.map((item) {
            return {
              "label": item["label"],
              "icon": IconData(item["iconCode"], fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Chỉnh sửa" category exists
          if (!parsedExpenseCategories.any((element) => element["label"] == "Chỉnh sửa")) {
            parsedExpenseCategories.add({"icon": Icons.build, "label": "Chỉnh sửa"});
          }

          _expenseCategories = parsedExpenseCategories;
          hasCategories = true;
        }

        // Load income categories
        if (userData.containsKey('incomeCategories') &&
            userData['incomeCategories'] is List &&
            (userData['incomeCategories'] as List).isNotEmpty) {
          List<dynamic> loadedIncomeCategories = userData['incomeCategories'];
          List<Map<String, dynamic>> parsedIncomeCategories = loadedIncomeCategories.map((item) {
            return {
              "label": item["label"],
              "icon": IconData(item["iconCode"], fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Chỉnh sửa" category exists
          if (!parsedIncomeCategories.any((element) => element["label"] == "Chỉnh sửa")) {
            parsedIncomeCategories.add({"icon": Icons.build, "label": "Chỉnh sửa"});
          }

          _incomeCategories = parsedIncomeCategories;
          hasCategories = true;
        }
      }

      // If user has no categories, use default ones and save to Firebase
      if (!hasCategories) {
        _setDefaultCategories();
        await _saveDefaultCategoriesToFirebase();
      }

      _isInitialized = true;
    } catch (e) {
      _setDefaultCategories();
      _setError("Error loading categories: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Set default categories
  void _setDefaultCategories() {
    _expenseCategories = List.from(_defaultExpenseCategories);
    _incomeCategories = List.from(_defaultIncomeCategories);
  }

  // Save default categories to Firebase
  Future<void> _saveDefaultCategoriesToFirebase() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      String userId = currentUser.uid;

      // Convert expense categories to serializable format
      List<Map<String, dynamic>> serializableExpenseCategories = _defaultExpenseCategories.map((category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert income categories to serializable format
      List<Map<String, dynamic>> serializableIncomeCategories = _defaultIncomeCategories.map((category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set({
        'expenseCategories': serializableExpenseCategories,
        'incomeCategories': serializableIncomeCategories,
        'isDefaultCategoriesSaved': true,
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } catch (e) {
      _setError("Lỗi khi tạo danh mục mặc định: ${e.toString()}");
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  // Add a new category
  Future<bool> addCategory(String name, IconData icon, bool isExpense) async {
    // Loại bỏ khoảng trắng thừa và chuyển về chữ thường để so sánh
    name = name.trim().toLowerCase();

    // Chọn danh sách danh mục phù hợp
    List<Map<String, dynamic>> targetList = isExpense
        ? _expenseCategories
        : _incomeCategories;

    // Kiểm tra tên danh mục đã tồn tại (không phân biệt hoa thường)
    bool categoryExists = targetList.any(
            (category) => category["label"].toString().toLowerCase() == name
    );

    if (categoryExists) {
      _setError("Danh mục đã tồn tại!");
      return false;
    }

    if (name.isEmpty) {
      _setError("Vui lòng nhập tên danh mục!");
      return false;
    }

    try {
      // Remove "Chỉnh sửa" entry to add it last
      targetList.removeWhere((element) => element["label"] == "Chỉnh sửa");

      // Add new category
      targetList.add({
        "icon": icon,
        "label": name,
      });

      // Add "Chỉnh sửa" entry back
      targetList.add({"icon": Icons.build, "label": "Chỉnh sửa"});

      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Save changes to Firebase
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Lỗi khi thêm danh mục: ${e.toString()}");
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int index, bool isExpense) async {
    _setLoading(false);

    try {
      List<Map<String, dynamic>> targetList = isExpense ? _expenseCategories : _incomeCategories;

      // Don't allow deleting "Chỉnh sửa" category
      if (targetList[index]["label"] == "Chỉnh sửa") {
        return false;
      }

      targetList.removeAt(index);

      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Save changes to Firebase
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Lỗi khi xóa danh mục: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reorder category method
  Future<bool> reorderCategory(int oldIndex, int newIndex, bool isExpense) async {
    try {
      // Choose the correct list based on transaction type
      List<Map<String, dynamic>> targetList = isExpense ? _expenseCategories : _incomeCategories;

      // Prevent reordering the "Chỉnh sửa" category
      if (oldIndex == targetList.length - 1 || newIndex == targetList.length - 1) {
        return false;
      }

      // Remove the item from the old index
      final Map<String, dynamic> movedCategory = targetList.removeAt(oldIndex);

      // Insert the item at the new index
      // Adjust newIndex if it's after the removed item
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      targetList.insert(newIndex, movedCategory);

      // Update the respective list
      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Save changes to Firebase
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Lỗi khi sắp xếp danh mục: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Save categories to Firebase
  Future<void> _saveCategoriesToFirebase() async {
    _setLoading(false);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setLoading(false);
        return;
      }

      String userId = currentUser.uid;

      // Convert expense categories to serializable format
      List<Map<String, dynamic>> serializableExpenseCategories = _expenseCategories.map((category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert income categories to serializable format
      List<Map<String, dynamic>> serializableIncomeCategories = _incomeCategories.map((category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set({
        'expenseCategories': serializableExpenseCategories,
        'incomeCategories': serializableIncomeCategories,
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } catch (e) {
      _setError("Lỗi khi lưu danh mục: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Add a new transaction
  Future<bool> addTransaction({
    required String note,
    required double amount,
    required String category,
    required String categoryIcon,
    required DateTime date,
    required bool isExpense,
  }) async {
    _setLoading(false);

    try {
      await _databaseService.addExpense(
        note: note,
        amount: amount,
        category: category,
        categoryIcon: categoryIcon,
        date: date,
        isExpense: isExpense,
      );

      return true;
    } catch (e) {
      _setError("Lỗi khi lưu giao dịch: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}