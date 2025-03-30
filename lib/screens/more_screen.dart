import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/expense_screen.dart';
import '/screens/calendar_screen.dart';
import '/screens/report_screen.dart';

class MoreScreen extends StatefulWidget {
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _selectedIndex = 3;
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';

  final List<Widget> _screens = [
    ExpenseScreen(),
    CalendarScreen(),
    ReportScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? 'Người dùng';
          _userEmail = user.email ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user info: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await FirebaseAuth.instance.signOut();

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print("Error logging out: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng xuất: ${e.toString()}")),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _screens[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SafeArea(
        child: Column(
          children: [
            _buildUserHeader(),
            SizedBox(height: 20),
            _buildMenuList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange.shade200,
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildExpansionTile("Tài khoản", Icons.person, [
            _buildSubMenuItem("Thông tin cá nhân", Icons.info, () {
              // Navigate to profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Chức năng đang phát triển")),
              );
            }),
            _buildSubMenuItem("Đăng xuất", Icons.logout, _logout),
          ]),
          _buildMenuItem("Đổi Mật Khẩu", Icons.lock, () {
            // Navigate to change password screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chức năng đang phát triển")),
            );
          }),
          _buildMenuItem("Cài đặt", Icons.settings, () {
            // Navigate to settings screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chức năng đang phát triển")),
            );
          }),
          _buildMenuItem("Giới thiệu", Icons.info_outline, () {
            _showAboutDialog();
          }),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Về ứng dụng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Fundy - Quản lý tài chính cá nhân"),
            SizedBox(height: 10),
            Text("Phiên bản: 1.0.0"),
            SizedBox(height: 10),
            Text("Ứng dụng giúp bạn quản lý thu chi hàng ngày một cách dễ dàng và hiệu quả."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: TextStyle(fontSize: 16)),
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 32, right: 16),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(icon, size: 18, color: Colors.grey.shade700),
      onTap: onTap,
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
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle), label: "Nhập vào"),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: "Lịch"),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Báo cáo"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Khác"),
      ],
    );
  }
}