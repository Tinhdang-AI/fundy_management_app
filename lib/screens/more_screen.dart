import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/screens/expense_screen.dart';
import '/screens/calendar_screen.dart';
import '/screens/report_screen.dart';
import '/screens/search_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';
import '../utils/currency_formatter.dart';

class MoreScreen extends StatefulWidget {
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _selectedIndex = 3;
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _appVersion = '1.0.0';
  String _userJoinDate = '';
  String _profileImageUrl = '';

  // Thống kê người dùng
  int _totalTransactions = 0;
  int _monthTransactions = 0;
  double _totalBalance = 0;

  final List<Widget> _screens = [
    ExpenseScreen(),
    CalendarScreen(),
    ReportScreen(),
    MoreScreen(),
  ];

  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAppInfo();
    _loadUserStats();
  }

  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      print("Error loading app info: $e");
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user metadata from Firestore if available
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            DateTime? createdAt;

            if (userData.containsKey('createdAt')) {
              if (userData['createdAt'] is Timestamp) {
                createdAt = (userData['createdAt'] as Timestamp).toDate();
              }
            }

            setState(() {
              _userName = userData['name'] ?? user.displayName ?? 'Người dùng';
              _userJoinDate = createdAt != null
                  ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                  : '';
              _profileImageUrl = userData['profileImageUrl'] ?? '';
            });
          }
        } catch (e) {
          print("Error loading Firestore user data: $e");
        }

        // Use Firebase Auth data as fallback
        setState(() {
          if (_userName.isEmpty) {
            _userName = user.displayName ?? 'Người dùng';
          }
          _userEmail = user.email ?? '';
          if (_userJoinDate.isEmpty && user.metadata.creationTime != null) {
            DateTime creationTime = user.metadata.creationTime!;
            _userJoinDate = '${creationTime.day}/${creationTime.month}/${creationTime.year}';
          }
          if (_profileImageUrl.isEmpty) {
            _profileImageUrl = user.photoURL ?? '';
          }
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

  Future<void> _loadUserStats() async {
    try {
      // Get current month/year
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Get all transactions
      final allTransactions = await _databaseService.getUserExpenses().first;

      // Get this month's transactions
      final monthTransactions = await _databaseService.getExpensesByMonthFuture(currentMonth, currentYear);

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;

      for (var tx in allTransactions) {
        if (tx.isExpense) {
          totalExpense += tx.amount;
        } else {
          totalIncome += tx.amount;
        }
      }

      setState(() {
        _totalTransactions = allTransactions.length;
        _monthTransactions = monthTransactions.length;
        _totalBalance = totalIncome - totalExpense;
      });
    } catch (e) {
      print("Error loading user stats: $e");
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

  Future<void> _resetApp() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đặt lại ứng dụng?"),
        content: Text("Thao tác này sẽ xóa tất cả dữ liệu của bạn và không thể khôi phục. Bạn có chắc chắn muốn tiếp tục?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Đặt lại", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete all expenses for the user
          QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
              .collection('expenses')
              .where('userId', isEqualTo: user.uid)
              .get();

          // Use a batch to delete all expenses
          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var doc in expensesSnapshot.docs) {
            batch.delete(doc.reference);
          }

          // Commit the batch
          await batch.commit();

          setState(() {
            _isLoading = false;
            _totalTransactions = 0;
            _monthTransactions = 0;
            _totalBalance = 0;
          });

          // Reload stats
          _loadUserStats();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tất cả dữ liệu đã được xóa thành công")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Không tìm thấy người dùng")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đặt lại ứng dụng: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Read the image file
        File imageFile = File(image.path);
        List<int> imageBytes = await imageFile.readAsBytes();

        // Convert the image to base64 string
        String base64Image = base64Encode(imageBytes);

        // Upload image to Firestore
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Create a unique ID for the image
          String imageId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

          // Create image document in Firestore
          await FirebaseFirestore.instance
              .collection('user_images')
              .doc(imageId)
              .set({
            'userId': user.uid,
            'imageData': base64Image,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Update in Firestore user document - store just the image ID
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': imageId});

          // Update local state
          setState(() {
            _profileImageUrl = imageId;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cập nhật ảnh đại diện thành công")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi cập nhật ảnh đại diện: ${e.toString()}")),
      );
    }
  }

  Future<void> _updateUserProfile() async {
    String newName = _userName;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cập nhật thông tin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await _pickImage();
                // Re-open dialog after image picker
                _updateUserProfile();
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildProfileAvatar(radius: 40),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Tên hiển thị",
                hintText: "Nhập tên của bạn",
              ),
              onChanged: (value) {
                newName = value;
              },
              controller: TextEditingController(text: _userName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (newName.trim().isNotEmpty && newName != _userName) {
                setState(() {
                  _isLoading = true;
                });

                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Update display name in Firebase Auth
                    await user.updateDisplayName(newName);

                    // Update in Firestore if available
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': newName});

                    setState(() {
                      _userName = newName;
                      _isLoading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Cập nhật thông tin thành công")),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi cập nhật thông tin: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text("Cập nhật"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({required double radius}) {
    // This will track if we have an image from Firestore
    bool hasImageFromFirestore = _profileImageUrl.isNotEmpty &&
        !_profileImageUrl.startsWith('http'); // Assume non-http URLs are our image IDs

    // Handle regular network images (for backward compatibility)
    bool hasNetworkImage = _profileImageUrl.isNotEmpty &&
        _profileImageUrl.startsWith('http');

    if (hasImageFromFirestore) {
      // If we have a Firestore image ID
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('user_images')
            .doc(_profileImageUrl)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.orange.shade200,
              child: SizedBox(
                width: radius * 0.7,
                height: radius * 0.7,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.exists) {
            // Get the base64 image data
            Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
            String? base64Image = data?['imageData'] as String?;

            if (base64Image != null) {
              // Convert base64 to image
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.orange.shade200,
                backgroundImage: MemoryImage(
                  base64Decode(base64Image),
                ),
              );
            }
          }

          // Fallback for errors or missing data
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.orange.shade200,
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else if (hasNetworkImage) {
      // Regular network image - likely from Firebase Storage in older versions
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade200,
        backgroundImage: NetworkImage(_profileImageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle network image loading errors
          print("Error loading network image: $exception");
        },
        child: null,
      );
    } else {
      // No image, display the first letter of the name
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade200,
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Cài đặt', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SafeArea(
        child: Column(
          children: [
            _buildUserHeader(),
            SizedBox(height: 10),
            _buildStats(),
            SizedBox(height: 10),
            Expanded(
              child: _buildMenuList(),
            ),
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
          _buildProfileAvatar(radius: 30),
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
                if (_userJoinDate.isNotEmpty) SizedBox(height: 5),
                if (_userJoinDate.isNotEmpty)
                  Text(
                    "Đã tham gia từ: $_userJoinDate",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.orange),
            onPressed: _updateUserProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Giao dịch',
            '$_totalTransactions',
            Icons.receipt_long,
          ),
          _buildStatItem(
            'Tháng này',
            '$_monthTransactions',
            Icons.date_range,
          ),
          _buildStatItem(
            'Tổng số dư',
            formatCurrencyWithSymbol(_totalBalance),
            Icons.account_balance_wallet,
            valueColor: _totalBalance >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? valueColor}) {
    // Nếu là tổng số dư, định dạng lại giá trị
    if (label == 'Tổng số dư' && value.contains('đ')) {
      // Chỉ định dạng nếu giá trị chứa đơn vị tiền tệ
      try {
        // Xử lý dấu cộng/trừ ở đầu
        bool isNegative = value.contains('-');
        String numericPart = value.replaceAll('+', '').replaceAll('-', '').replaceAll('đ', '');
        double amount = double.parse(numericPart);

        String formattedValue = isNegative
            ? '-${formatCurrencyWithSymbol(amount)}'
            : '+${formatCurrencyWithSymbol(amount)}';

        return Column(
          children: [
            Icon(icon, color: Colors.orange, size: 20),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              formattedValue,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        );
      } catch (e) {
        // Nếu có lỗi khi định dạng, giữ nguyên giá trị gốc
        print("Error formatting balance: $e");
      }
    }

    // Giá trị mặc định cho các mục không phải số dư
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }


  Widget _buildMenuList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildExpansionTile("Tài khoản", Icons.person, [
          _buildSubMenuItem("Đổi mật khẩu", Icons.lock_open, () {
            _showChangePasswordDialog();
          }),
          _buildSubMenuItem("Đăng xuất", Icons.logout, _logout),
        ]),
        _buildMenuItem("Đặt lại ứng dụng", Icons.restore, _resetApp),
        _buildMenuItem("Giới thiệu", Icons.info_outline, () {
          _showAboutDialog();
        }),
        _buildMenuItem("Phản hồi", Icons.feedback, () {
          _showFeedbackDialog();
        }),
      ],
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Gửi phản hồi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Phản hồi của bạn giúp chúng tôi cải thiện ứng dụng"),
            SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Nhập phản hồi của bạn",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                try {
                  setState(() {
                    _isLoading = true;
                  });

                  User? user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('feedback').add({
                    'userId': user?.uid ?? 'anonymous',
                    'userName': _userName,
                    'userEmail': _userEmail,
                    'feedback': controller.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'appVersion': _appVersion
                  });

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Đã gửi phản hồi thành công")),
                  );
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi gửi phản hồi: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text("Gửi"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscureText1 = true;
    bool _obscureText2 = true;
    bool _obscureText3 = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Đổi mật khẩu"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: _obscureText1,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu hiện tại",
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText1 = !_obscureText1),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      obscureText: _obscureText2,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu mới",
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText2 = !_obscureText2),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureText3,
                      decoration: InputDecoration(
                        labelText: "Xác nhận mật khẩu",
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText3 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText3 = !_obscureText3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Hủy"),
                ),
                TextButton(
                  onPressed: () async {
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
                      );
                      return;
                    }

                    if (newPasswordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Mật khẩu mới không khớp")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.email != null) {
                        // Reauthenticate user
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPasswordController.text,
                        );

                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPasswordController.text);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đổi mật khẩu thành công")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi: ${e.toString()}")),
                      );
                    }
                  },
                  child: Text("Cập nhật"),
                ),
              ],
            );
          },
        );
      },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text("Fundy - Quản lý tài chính cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Phiên bản: $_appVersion"),
            SizedBox(height: 10),
            Text("Ứng dụng giúp bạn quản lý thu chi hàng ngày một cách dễ dàng và hiệu quả."),
            SizedBox(height: 15),
            Text("Tính năng:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("• Theo dõi thu chi hàng ngày"),
            Text("• Xem báo cáo tổng quan, biểu đồ"),
            Text("• Lịch chi tiêu"),
            Text("• Tìm kiếm giao dịch"),
            Text("• Quản lý danh mục"),
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