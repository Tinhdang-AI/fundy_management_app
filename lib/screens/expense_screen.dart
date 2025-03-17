import 'package:flutter/material.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  int selectedTab = 0; // 0: Tiền chi, 1: Tiền thu

  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.restaurant, "label": "Ăn uống"},
    {"icon": Icons.shopping_bag, "label": "Chi tiêu hàng ngày"},
    {"icon": Icons.checkroom, "label": "Quần áo"},
    {"icon": Icons.spa, "label": "Mỹ phẩm"},
    {"icon": Icons.wine_bar, "label": "Phí giao lưu"},
    {"icon": Icons.local_hospital, "label": "Y tế"},
    {"icon": Icons.school, "label": "Giáo dục"},
    {"icon": Icons.electrical_services, "label": "Tiền điện"},
    {"icon": Icons.directions_bus, "label": "Đi lại"},
    {"icon": Icons.mail, "label": "Phí liên lạc"},
    {"icon": Icons.home, "label": "Tiền nhà"},
    {"icon": Icons.build, "label": "Chỉnh sửa"},
  ];

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
              _buildTextField("Ghi chú"),
              SizedBox(height: 10),
              _buildTextField("Tiền chi", isNumber: true),
              SizedBox(height: 10),
              Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              _buildCategoryGrid(),
              SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle giữa Tiền chi & Tiền thu
  Widget _buildToggleTab() {
    return Row(
      children: [
        _buildTabButton("Tiền chi", 0),
        _buildTabButton("Tiền thu", 1),
        Spacer(),
        Icon(Icons.edit, color: Colors.orange), // Icon chỉnh sửa
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selectedTab == index ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange),
        ),
        child: Text(
          text,
          style: TextStyle(color: selectedTab == index ? Colors.white : Colors.orange),
        ),
      ),
    );
  }

  // Ô nhập ngày
  Widget _buildDateField() {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.orange),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "10/3/2025 (Thứ 2)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }

  // Ô nhập text
  Widget _buildTextField(String hint, {bool isNumber = false}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }

  // Lưới danh mục
  Widget _buildCategoryGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 cột
          childAspectRatio: 1, // Ô vuông
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(categories[index]["icon"], categories[index]["label"]);
        },
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Colors.orange),
        SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // Nút nhập khoản tiền chi
  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        ),
        child: Text("Nhập khoản tiền chi", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  // Thanh điều hướng
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.add_circle, color: Colors.orange), label: "Nhập vào"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today, color: Colors.grey), label: "Lịch"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart, color: Colors.grey), label: "Báo cáo"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz, color: Colors.grey), label: "Khác"),
      ],
    );
  }
}
