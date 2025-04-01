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
import '../utils/currency_formatter.dart';
import '/utils/message_utils.dart';

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

  // User statistics
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // Silent error handling
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
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
          // Silent error handling
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final allTransactions = await _databaseService.getUserExpenses().first;
      final monthTransactions = await _databaseService.getExpensesByMonthFuture(currentMonth, currentYear);

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
      // Silent error handling
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
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage("Lỗi đăng xuất");
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
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
              .collection('expenses')
              .where('userId', isEqualTo: user.uid)
              .get();

          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var doc in expensesSnapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();

          setState(() {
            _isLoading = false;
            _totalTransactions = 0;
            _monthTransactions = 0;
            _totalBalance = 0;
          });

          _loadUserStats();

          _showErrorMessage("Tất cả dữ liệu đã được xóa thành công");
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage("Lỗi khi đặt lại ứng dụng");
      }
    }
  }

  // Currency Selector Dialog
  void _showCurrencySelector() {
    // Common currencies
    final List<Map<String, String>> currencies = [
      {'code': 'VND', 'symbol': 'đ', 'name': 'Việt Nam Đồng'},
      {'code': 'USD', 'symbol': '\$', 'name': 'Đô la Mỹ'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'Bảng Anh'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Yên Nhật'},
      {'code': 'CNY', 'symbol': '¥', 'name': 'Nhân dân tệ'},
      {'code': 'KRW', 'symbol': '₩', 'name': 'Won Hàn Quốc'},
      {'code': 'SGD', 'symbol': 'S\$', 'name': 'Đô la Singapore'},
      {'code': 'THB', 'symbol': '฿', 'name': 'Baht Thái'},
      {'code': 'MYR', 'symbol': 'RM', 'name': 'Ringgit Malaysia'},
    ];

    // Get current currency code
    String selectedCurrencyCode = getCurrentCode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Chọn đơn vị tiền tệ'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final bool isSelected = currency['code'] == selectedCurrencyCode;

                  return ListTile(
                    leading: Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        currency['symbol']!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(currency['name']!),
                    subtitle: Text(currency['code']!),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedCurrencyCode = currency['code']!;
                      });
                    },
                    selected: isSelected,
                    selectedTileColor: Colors.orange.shade50,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Find the selected currency
                  final selectedCurrency = currencies.firstWhere(
                        (c) => c['code'] == selectedCurrencyCode,
                    orElse: () => currencies.first,
                  );

                  // Show loading
                  this.setState(() {
                    _isLoading = true;
                  });

                  // Update the currency
                  await updateCurrency(
                      selectedCurrency['code']!,
                      selectedCurrency['symbol']!
                  );

                  // Save to Firestore
                  User? currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    await _firestore.collection('users').doc(currentUser.uid).update({
                      'currency': {
                        'code': selectedCurrency['code'],
                        'symbol': selectedCurrency['symbol'],
                        'name': selectedCurrency['name'],
                      }
                    });
                  }

                  Navigator.pop(context);

                  _showSuccessMessage('Đã cập nhật đơn vị tiền tệ thành ${selectedCurrency['name']}');

                  // Hide loading and refresh
                  this.setState(() {
                    _isLoading = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    MessageUtils.showSuccessMessage(context, message);
  }

  void _showErrorMessage(String message) {
    MessageUtils.showErrorMessage(context, message);
  }

  // Current Currency Display
  Widget _buildCurrencyDisplay() {
    String code = getCurrentCode();
    String symbol = getCurrentSymbol();

    String currencyName = "Việt Nam Đồng";

    // Find currency name from code
    const List<Map<String, String>> currencies = [
      {'code': 'VND', 'symbol': 'đ', 'name': 'Việt Nam Đồng'},
      {'code': 'USD', 'symbol': '\$', 'name': 'Đô la Mỹ'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'Bảng Anh'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Yên Nhật'},
      {'code': 'CNY', 'symbol': '¥', 'name': 'Nhân dân tệ'},
      {'code': 'KRW', 'symbol': '₩', 'name': 'Won Hàn Quốc'},
      {'code': 'SGD', 'symbol': 'S\$', 'name': 'Đô la Singapore'},
      {'code': 'THB', 'symbol': '฿', 'name': 'Baht Thái'},
      {'code': 'MYR', 'symbol': 'RM', 'name': 'Ringgit Malaysia'},
    ];

    for (var currency in currencies) {
      if (currency['code'] == code) {
        currencyName = currency['name']!;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            size: 14,
            color: Colors.grey.shade700,
          ),
          SizedBox(width: 4),
          Text(
            'Đơn vị tiền tệ: $currencyName ($symbol)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
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

        File imageFile = File(image.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String imageId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

          await FirebaseFirestore.instance
              .collection('user_images')
              .doc(imageId)
              .set({
            'userId': user.uid,
            'imageData': base64Image,
            'timestamp': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': imageId});

          setState(() {
            _profileImageUrl = imageId;
            _isLoading = false;
          });

          _showSuccessMessage("Cập nhật ảnh đại diện thành công");
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _showErrorMessage("Lỗi khi tải ảnh");
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
                    await user.updateDisplayName(newName);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': newName});

                    setState(() {
                      _userName = newName;
                      _isLoading = false;
                    });

                    _showSuccessMessage("Cập nhật thông tin thành công");

                  }
                } catch (e) {
                  _showErrorMessage("Lỗi khi cập nhật thông tin");
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
    bool hasImageFromFirestore = _profileImageUrl.isNotEmpty &&
        !_profileImageUrl.startsWith('http');

    bool hasNetworkImage = _profileImageUrl.isNotEmpty &&
        _profileImageUrl.startsWith('http');

    if (hasImageFromFirestore) {
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
            Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
            String? base64Image = data?['imageData'] as String?;

            if (base64Image != null) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.orange.shade200,
                backgroundImage: MemoryImage(
                  base64Decode(base64Image),
                ),
              );
            }
          }

          return _buildDefaultAvatar(radius);
        },
      );
    } else if (hasNetworkImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade200,
        backgroundImage: NetworkImage(_profileImageUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    } else {
      return _buildDefaultAvatar(radius);
    }
  }

  Widget _buildDefaultAvatar(double radius) {
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
        title: Text('Khác', style: TextStyle(color: Colors.black)),
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
                _buildCurrencyDisplay(),
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
        _buildMenuItem("Đơn vị tiền tệ", Icons.currency_exchange, _showCurrencySelector),
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

                  _showSuccessMessage("Đã gửi phản hồi thành công");

                } catch (e) {
                  _showErrorMessage("Lỗi khi gửi phản hồi");

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
    bool isChangingPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool obscureText1 = true;
        bool obscureText2 = true;
        bool obscureText3 = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Đổi mật khẩu"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChangingPassword)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.orange),
                              SizedBox(height: 16),
                              Text("Đang xử lý...", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: currentPasswordController,
                            obscureText: obscureText1,
                            decoration: InputDecoration(
                              labelText: "Mật khẩu hiện tại",
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(obscureText1 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setDialogState(() => obscureText1 = !obscureText1),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: newPasswordController,
                            obscureText: obscureText2,
                            decoration: InputDecoration(
                              labelText: "Mật khẩu mới",
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(obscureText2 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setDialogState(() => obscureText2 = !obscureText2),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureText3,
                            decoration: InputDecoration(
                              labelText: "Xác nhận mật khẩu",
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(obscureText3 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setDialogState(() => obscureText3 = !obscureText3),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: isChangingPassword ? [] : [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (currentPasswordController.text.isEmpty) {
                      _showErrorMessage("Vui lòng nhập mật khẩu hiện tại");
                      return;
                    }

                    if (newPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Vui lòng nhập mật khẩu mới")),
                      );
                      return;
                    }

                    if (confirmPasswordController.text.isEmpty) {
                      _showErrorMessage("Vui lòng xác nhận mật khẩu mới");
                      return;
                    }

                    if (newPasswordController.text != confirmPasswordController.text) {
                      _showErrorMessage("Mật khẩu mới không khớp");
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      _showErrorMessage("Mật khẩu mới phải có ít nhất 6 ký tự");
                      return;
                    }

                    if (currentPasswordController.text == newPasswordController.text) {
                      _showErrorMessage("Mật khẩu mới không được giống mật khẩu hiện tại");
                      return;
                    }

                    setDialogState(() {
                      isChangingPassword = true;
                    });

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.email != null) {
                        String email = user.email!;
                        String currentPassword = currentPasswordController.text;
                        String newPassword = newPasswordController.text;

                        try {
                          AuthCredential credential = EmailAuthProvider.credential(
                              email: email,
                              password: currentPassword
                          );

                          UserCredential result = await user.reauthenticateWithCredential(credential);

                          if (result.user != null) {
                            try {
                              await user.updatePassword(newPassword);
                               _showSuccessMessage("Đổi mật khẩu thành công");
                            } catch (passwordUpdateError) {
                              _showErrorMessage("Lỗi đổi mật khẩu");
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          _showErrorMessage("Mật khẩu hiện tại không đúng");
                        } catch (e) {
                          Navigator.pop(dialogContext);
                        }
                      } else {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
      color: Colors.white,
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
      color: Colors.white,
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
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 32, right: 16),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(icon, size: 18, color: Colors.grey.shade700),
        onTap: onTap,
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
          activeIcon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.more_horiz, color: Colors.orangeAccent),
          ),
        ),
      ],
    );
  }
}