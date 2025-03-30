import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/calendar_screen.dart';
import '/screens/report_screen.dart';
import '/screens/more_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  int selectedTab = 0; // 0: Tiền chi, 1: Tiền thu
  int _selectedIndex = 0; // Tab hiện tại (Nhập vào)
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String selectedCategory = "";
  String selectedCategoryIcon = "";
  bool _isLoading = false;

  final List<Widget> _screens = [
    ExpenseScreen(), // Nhập vào
    CalendarScreen(), // Lịch
    ReportScreen(), // Báo cáo
    MoreScreen(), // Khác
  ];

  final List<Map<String, dynamic>> expenseCategories = [
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
    {"icon": Icons.build, "label": "Chỉnh sửa"},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {"icon": Icons.attach_money, "label": "Tiền lương"},
    {"icon": Icons.savings, "label": "Tiền phụ cấp"},
    {"icon": Icons.card_giftcard, "label": "Tiền thưởng"},
    {"icon": Icons.trending_up, "label": "Đầu tư"},
    {"icon": Icons.account_balance_wallet, "label": "Thu nhập phụ"},
    {"icon": Icons.build, "label": "Chỉnh sửa"},
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

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

  void _selectCategory(String category, IconData icon) {
    setState(() {
      selectedCategory = category;
      selectedCategoryIcon = icon.codePoint.toString();
    });
  }

  Future<void> _saveExpense() async {
    if (noteController.text.isEmpty || amountController.text.isEmpty || selectedCategory.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
      if (amount <= 0) {
        _showMessage("Số tiền phải lớn hơn 0!");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _databaseService.addExpense(
        note: noteController.text,
        amount: amount,
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

      _showMessage("Đã lưu thành công!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Lỗi: ${e.toString()}");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleTab(),
              SizedBox(height: 10),
              _buildDateField(),
              SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: "Ghi chú",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Tiền ${selectedTab == 0 ? 'chi' : 'thu'}",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  selectedCategory.isNotEmpty
                      ? Text(selectedCategory, style: TextStyle(color: Colors.orange))
                      : SizedBox(),
                ],
              ),
              SizedBox(height: 10),
              Expanded(child: _buildCategoryGrid()),
              SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

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
          Icon(Icons.edit, color: Colors.orange),
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
          });
          // Tải lại dữ liệu nếu cần
          // _loadReportData();
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy (E)').format(selectedDate),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    List<Map<String, dynamic>> categories = selectedTab == 0 ? expenseCategories : incomeCategories;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _selectCategory(
            categories[index]["label"],
            categories[index]["icon"],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedCategory == categories[index]["label"]
                    ? Colors.orange
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categories[index]["icon"],
                  size: 40,
                  color: selectedCategory == categories[index]["label"]
                      ? Colors.orange
                      : Colors.grey,
                ),
                SizedBox(height: 5),
                Text(
                  categories[index]["label"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedCategory == categories[index]["label"]
                        ? Colors.orange
                        : Colors.black,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Nhập vào"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Lịch"),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Báo cáo"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Khác"),
      ],
    );
  }
}