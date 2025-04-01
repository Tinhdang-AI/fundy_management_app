import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/calendar_screen.dart';
import '/screens/report_screen.dart';
import '/screens/more_screen.dart';
import '../services/database_service.dart';
import '/screens/search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/currency_formatter.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Controllers & Services
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();

  // State variables
  int selectedTab = 0; // 0: Expense, 1: Income
  int _selectedIndex = 0; // Current tab (Input)
  DateTime selectedDate = DateTime.now();
  String selectedCategory = "";
  String selectedCategoryIcon = "";
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isInitialized = false;
  IconData? selectedIconForNewCategory;

  // Navigation screens
  final List<Widget> _screens = [
    ExpenseScreen(),
    CalendarScreen(),
    ReportScreen(),
    MoreScreen(),
  ];

  // Available icons for categories
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

  // Category lists
  List<Map<String, dynamic>> expenseCategories = [];
  List<Map<String, dynamic>> incomeCategories = [];

  // Default categories
  final List<Map<String, dynamic>> defaultExpenseCategories = [
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

  final List<Map<String, dynamic>> defaultIncomeCategories = [
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

  @override
  void initState() {
    super.initState();
    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesFromFirebase();
    });

    // Make sure currency is initialized
    initCurrency();
  }

  // Navigation
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Category selection
  void _selectCategory(String category, IconData icon) {
    if (category == "Chỉnh sửa") {
      setState(() {
        _isEditMode = true;
      });
      return;
    }

    setState(() {
      selectedCategory = category;
      selectedCategoryIcon = icon.codePoint.toString();
    });
  }

  Future<void> _saveExpense() async {
    if (amountController.text.isEmpty || selectedCategory.isEmpty) {
      _showMessage("Vui lòng nhập số tiền và chọn danh mục!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double amount = parseFormattedCurrency(amountController.text);
      if (amount <= 0) {
        _showMessage("Số tiền phải lớn hơn 0!");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Chuyển đổi từ đơn vị tiền tệ hiện tại sang VND để lưu vào database
      double amountInVND = convertToVND(amount);

      await _databaseService.addExpense(
        note: noteController.text,
        amount: amountInVND, // Lưu giá trị theo VND
        category: selectedCategory,
        categoryIcon: selectedCategoryIcon,
        date: selectedDate,
        isExpense: selectedTab == 0,
      );

      // Reset form
      setState(() {
        noteController.clear();
        amountController.clear();
        selectedCategory = "";
        selectedCategoryIcon = "";
        _isLoading = false;
      });

      // Show success message
      _showSuccessMessage(selectedTab == 0
          ? "Đã lưu khoản chi thành công!"
          : "Đã lưu khoản thu thành công!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Lỗi: ${e.toString()}");
    }
  }

// Add a new method for success messages with a different style
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addNewCategory() {
    if (categoryNameController.text.isEmpty ||
        selectedIconForNewCategory == null) {
      _showMessage("Vui lòng nhập tên danh mục và chọn biểu tượng!");
      return;
    }

    setState(() {
      List<Map<String, dynamic>> targetList = selectedTab == 0
          ? expenseCategories
          : incomeCategories;

      // Remove "Chỉnh sửa" entry to add it last
      targetList.removeWhere((element) => element["label"] == "Chỉnh sửa");

      // Add new category
      targetList.add({
        "icon": selectedIconForNewCategory,
        "label": categoryNameController.text,
      });

      // Add "Chỉnh sửa" entry back
      targetList.add({"icon": Icons.build, "label": "Chỉnh sửa"});

      // Reset values
      categoryNameController.clear();
      selectedIconForNewCategory = null;
    });

    // Save changes to Firebase
    _saveCategoriesToFirebase();
  }

  // Delete category
  void _deleteCategory(int index) {
    List<Map<String, dynamic>> targetList = selectedTab == 0
        ? expenseCategories
        : incomeCategories;

    // Don't allow deleting "Chỉnh sửa" category
    if (targetList[index]["label"] != "Chỉnh sửa") {
      setState(() {
        targetList.removeAt(index);
      });
      _saveCategoriesToFirebase();
    }
  }

  // Save categories to Firebase
  Future<void> _saveCategoriesToFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String userId = currentUser.uid;

      // Convert expense categories to serializable format
      List<Map<String,
          dynamic>> serializableExpenseCategories = expenseCategories.map((
          category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert income categories to serializable format
      List<Map<String, dynamic>> serializableIncomeCategories = incomeCategories
          .map((category) {
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
      _showMessage("Lỗi khi lưu danh mục: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save default categories for new users
  Future<void> _saveDefaultCategoriesToFirebase() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      String userId = currentUser.uid;

      // Convert default expense categories to serializable format
      List<Map<String,
          dynamic>> serializableExpenseCategories = defaultExpenseCategories
          .map((category) {
        return {
          "label": category["label"],
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert default income categories to serializable format
      List<Map<String,
          dynamic>> serializableIncomeCategories = defaultIncomeCategories.map((
          category) {
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
      _showMessage("Lỗi khi tạo danh mục mặc định: ${e.toString()}");
    }
  }

  // Load categories from Firebase
  Future<void> _loadCategoriesFromFirebase() async {
    if (_isInitialized) return; // Avoid loading multiple times

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          // Use default categories if not logged in
          expenseCategories = List.from(defaultExpenseCategories);
          incomeCategories = List.from(defaultIncomeCategories);
          _isLoading = false;
          _isInitialized = true;
        });
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
          List<Map<String,
              dynamic>> parsedExpenseCategories = loadedExpenseCategories.map((
              item) {
            return {
              "label": item["label"],
              "icon": IconData(item["iconCode"],
                  fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Chỉnh sửa" category exists
          if (!parsedExpenseCategories.any((element) =>
          element["label"] == "Chỉnh sửa")) {
            parsedExpenseCategories.add(
                {"icon": Icons.build, "label": "Chỉnh sửa"});
          }

          setState(() {
            expenseCategories = parsedExpenseCategories;
          });

          hasCategories = true;
        }

        // Load income categories
        if (userData.containsKey('incomeCategories') &&
            userData['incomeCategories'] is List &&
            (userData['incomeCategories'] as List).isNotEmpty) {
          List<dynamic> loadedIncomeCategories = userData['incomeCategories'];
          List<Map<String,
              dynamic>> parsedIncomeCategories = loadedIncomeCategories.map((
              item) {
            return {
              "label": item["label"],
              "icon": IconData(item["iconCode"],
                  fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Chỉnh sửa" category exists
          if (!parsedIncomeCategories.any((element) =>
          element["label"] == "Chỉnh sửa")) {
            parsedIncomeCategories.add(
                {"icon": Icons.build, "label": "Chỉnh sửa"});
          }

          setState(() {
            incomeCategories = parsedIncomeCategories;
          });

          hasCategories = true;
        }
      }

      // If user has no categories, use default ones and save to Firebase
      if (!hasCategories) {
        setState(() {
          expenseCategories = List.from(defaultExpenseCategories);
          incomeCategories = List.from(defaultIncomeCategories);
        });

        await _saveDefaultCategoriesToFirebase();
      }

      _isInitialized = true;
    } catch (e) {
      // Use default categories in case of error
      setState(() {
        expenseCategories = List.from(defaultExpenseCategories);
        incomeCategories = List.from(defaultIncomeCategories);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show icon selector dialog
  void _showIconSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Chọn icon"),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIconForNewCategory = availableIcons[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(availableIcons[index], size: 30),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _isEditMode ? FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.check, color: Colors.white),
        onPressed: () {
          _saveCategoriesToFirebase();
          setState(() {
            _isEditMode = false;
          });
        },
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditMode) _buildToggleTab(),
              SizedBox(height: 10),
              if (!_isEditMode) _buildDateSelector(),
              SizedBox(height: 10),
              if (!_isEditMode) _buildExpenseFields(),
              if (!_isEditMode) SizedBox(height: 10),
              if (_isEditMode)
                _buildCategoryEditor()
              else
                expenseCategories.isEmpty || incomeCategories.isEmpty
                    ? Center(child: Text("Đang tải danh mục..."))
                    : Expanded(child: _buildCategoryGrid()),
              SizedBox(height: 20),
              if (!_isEditMode) _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // UI Components
  Widget _buildToggleTab() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.white,
      child: Row(
        children: [
          _buildTabButton("Tiền chi", 0),
          SizedBox(width: 8),
          _buildTabButton("Tiền thu", 1),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
            _isEditMode = false; // Turn off edit mode when switching tabs
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFF8B55) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            "Ngày",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_left, color: Color(0xFFFFAE88)),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(Duration(days: 1));
              });
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 20,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFAE88),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    DateFormat('dd/MM/yyyy (E)').format(selectedDate),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Color(0xFFFFAE88)),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(Duration(days: 1));
              });
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ghi chú
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  "Ghi chú",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Tiền chi/thu with dynamic currency symbol
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  "Tiền ${selectedTab == 0 ? 'chi' : 'thu'}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          ),
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                      Text(getCurrentSymbol(), style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildCategoryEditor() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chỉnh sửa danh mục ${selectedTab == 0 ? 'Chi tiêu' : 'Thu nhập'}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Form to add new category
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Thêm danh mục mới",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Tên danh mục",
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showIconSelector,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: selectedIconForNewCategory != null
                            ? Icon(selectedIconForNewCategory, size: 30)
                            : Icon(Icons.add, size: 30),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addNewCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                          "Thêm", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text("Danh sách danh mục hiện tại:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          // Current category list
          Expanded(
            child: ListView.builder(
              itemCount: selectedTab == 0
                  ? expenseCategories.length
                  : incomeCategories.length,
              itemBuilder: (context, index) {
                final category = selectedTab == 0
                    ? expenseCategories[index]
                    : incomeCategories[index];
                bool isEditCategory = category["label"] == "Chỉnh sửa";

                return ListTile(
                  leading: Icon(category["icon"], size: 30),
                  title: Text(category["label"]),
                  trailing: isEditCategory
                      ? null
                      : IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    List<Map<String, dynamic>> categories = selectedTab == 0
        ? expenseCategories
        : incomeCategories;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        bool isSelected = selectedCategory == categories[index]["label"];
        bool isEditButton = categories[index]["label"] == "Chỉnh sửa";

        return GestureDetector(
          onTap: () =>
              _selectCategory(
                categories[index]["label"],
                categories[index]["icon"],
              ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categories[index]["icon"],
                  size: 40,
                  color: isSelected || isEditButton ? Colors.orange : Colors
                      .grey,
                ),
                SizedBox(height: 5),
                Text(
                  categories[index]["label"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected || isEditButton ? Colors.orange : Colors
                        .black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        ),
        child: _isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          "Nhập khoản tiền ${selectedTab == 0 ? 'chi' : 'thu'}",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.orangeAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.grey[200],
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Nhập vào",
          activeIcon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.edit, color: Colors.orangeAccent),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Lịch",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart),
          label: "Báo cáo",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "Khác",
        ),
      ],
    );
  }
}