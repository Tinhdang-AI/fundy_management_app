import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/viewmodels/more_viewmodel.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/views/widgets/app_bottom_navigation_bar.dart';
import '/views/screens/search_screen.dart';
import '/utils/message_utils.dart';
import '/utils/currency_formatter.dart';

class MoreScreen extends StatefulWidget {
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize the view model when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moreViewModel = Provider.of<MoreViewModel>(context, listen: false);
      moreViewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access view models
    final moreViewModel = Provider.of<MoreViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

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
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 3,
        onTabSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/expense');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/report');
              break;
            case 3:
            // Already on this screen, do nothing
              break;
          }
        },
      ),
      body: moreViewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SafeArea(
        child: Column(
          children: [
            _buildUserHeader(moreViewModel),
            SizedBox(height: 10),
            _buildStats(moreViewModel),
            Expanded(
              child: _buildMenuList(context, moreViewModel, authViewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(MoreViewModel viewModel) {
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
          _buildProfileAvatar(viewModel, radius: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  viewModel.userEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (viewModel.userJoinDate.isNotEmpty) SizedBox(height: 5),
                if (viewModel.userJoinDate.isNotEmpty)
                  Text(
                    "Đã tham gia từ: ${viewModel.userJoinDate}",
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
            onPressed: () => _updateUserProfile(viewModel),
          ),
        ],
      ),
    );
  }

  // Show feedback dialog
  void _showFeedbackDialog(BuildContext context, MoreViewModel viewModel) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Gửi phản hồi"),
            backgroundColor: Colors.white,
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
                  if (controller.text
                      .trim()
                      .isNotEmpty) {
                    final success = await viewModel.submitFeedback(
                        controller.text.trim());

                    if (success) {
                      MessageUtils.showSuccessMessage(
                          context, "Đã gửi phản hồi thành công");
                    }
                  }
                },
                child: Text("Gửi"),
              ),
            ],
          ),
    );
  }

  // Show about dialog
  void _showAboutDialog(BuildContext context, MoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Về ứng dụng"),
            backgroundColor: Colors.white,
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
                Text("Fundy - Quản lý tài chính cá nhân",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Phiên bản: ${viewModel.appVersion}"),
                SizedBox(height: 10),
                Text(
                    "Ứng dụng giúp bạn quản lý thu chi hàng ngày một cách dễ dàng và hiệu quả."),
                SizedBox(height: 15),
                Text("Tính năng:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
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

  // Show change password dialog
  void _showChangePasswordDialog(BuildContext context,
      AuthViewModel authViewModel) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChangingPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool obscureText1 = true;
            bool obscureText2 = true;
            bool obscureText3 = true;

            return AlertDialog(
              title: Text("Đổi mật khẩu"),
              backgroundColor: Colors.white,
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
                              Text("Đang xử lý...",
                                  style: TextStyle(color: Colors.grey)),
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
                                icon: Icon(
                                    obscureText1 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText1 = !obscureText1),
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
                                icon: Icon(
                                    obscureText2 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText2 = !obscureText2),
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
                                icon: Icon(
                                    obscureText3 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText3 = !obscureText3),
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
                    // Validate inputs
                    if (currentPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context, "Vui lòng nhập mật khẩu hiện tại");
                      return;
                    }

                    if (newPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context, "Vui lòng nhập mật khẩu mới");
                      return;
                    }

                    if (confirmPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context, "Vui lòng xác nhận mật khẩu mới");
                      return;
                    }

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      MessageUtils.showErrorMessage(
                          context, "Mật khẩu mới không khớp");
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      MessageUtils.showErrorMessage(
                          context, "Mật khẩu mới phải có ít nhất 6 ký tự");
                      return;
                    }

                    if (currentPasswordController.text ==
                        newPasswordController.text) {
                      MessageUtils.showErrorMessage(context,
                          "Mật khẩu mới không được giống mật khẩu hiện tại");
                      return;
                    }

                    // Update state to show loading
                    setDialogState(() {
                      isChangingPassword = true;
                    });

                    // Update password using view model
                    final success = await authViewModel.updatePassword(
                        currentPasswordController.text,
                        newPasswordController.text
                    );

                    if (success) {
                      Navigator.pop(dialogContext);
                      MessageUtils.showSuccessMessage(
                          context, "Đổi mật khẩu thành công");
                    } else {
                      // Error message is already shown by the view model
                      setDialogState(() {
                        isChangingPassword = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                  child: Text("Cập nhật"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Confirm reset app
  Future<void> _confirmResetApp(BuildContext context,
      MoreViewModel viewModel) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: "Đặt lại ứng dụng?",
      message: "Thao tác này sẽ xóa tất cả dữ liệu của bạn và không thể khôi phục. Bạn có chắc chắn muốn tiếp tục?",
      confirmLabel: "Đặt lại",
      cancelLabel: "Hủy",
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      final success = await viewModel.resetApp();

      if (success) {
        MessageUtils.showSuccessMessage(
            context, "Tất cả dữ liệu đã được xóa thành công");
      }
    }
  }

  // Logout
  Future<void> _logout(BuildContext context, MoreViewModel viewModel) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: "Đăng xuất",
      message: "Bạn có chắc chắn muốn đăng xuất không?",
      confirmLabel: "Đăng xuất",
      cancelLabel: "Hủy",
    );

    if (confirmed == true) {
      final success = await viewModel.signOut();

      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Widget _buildProfileAvatar(MoreViewModel viewModel,
      {required double radius}) {
    if (viewModel.profileImageUrl.isEmpty) {
      return _buildDefaultAvatar(viewModel.userName, radius);
    }

    // Check if it's a Firebase URL (base64 encoded) or a network image
    bool isFirebaseImage = !viewModel.profileImageUrl.startsWith('http');

    if (isFirebaseImage) {
      return FutureBuilder<String?>(
        future: viewModel.getProfileImage(viewModel.profileImageUrl),
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
          } else if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.orange.shade200,
              backgroundImage: MemoryImage(
                  viewModel.base64ToImage(snapshot.data!)),
            );
          }

          return _buildDefaultAvatar(viewModel.userName, radius);
        },
      );
    } else {
      // Network image
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade200,
        backgroundImage: NetworkImage(viewModel.profileImageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
  }

  Widget _buildDefaultAvatar(String name, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.orange.shade200,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay() {
    String code = getCurrentCode();
    String symbol = getCurrentSymbol();
    String currencyName = _getCurrencyName(code);

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

  String _getCurrencyName(String code) {
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
        return currency['name']!;
      }
    }

    return 'Việt Nam Đồng';
  }

  Widget _buildStats(MoreViewModel viewModel) {
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
            '${viewModel.totalTransactions}',
            Icons.receipt_long,
          ),
          _buildStatItem(
            'Tháng này',
            '${viewModel.monthTransactions}',
            Icons.date_range,
          ),
          _buildStatItem(
            'Tổng số dư',
            formatCurrencyWithSymbol(viewModel.totalBalance),
            Icons.account_balance_wallet,
            valueColor: viewModel.totalBalance >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? valueColor}) {
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

  Widget _buildMenuList(BuildContext context, MoreViewModel moreViewModel,
      AuthViewModel authViewModel) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildExpansionTile("Tài khoản", Icons.person, [
          _buildSubMenuItem("Đổi mật khẩu", Icons.lock_open, () {
            _showChangePasswordDialog(context, authViewModel);
          }),
          _buildSubMenuItem(
              "Đăng xuất", Icons.logout, () => _logout(context, moreViewModel)),
        ]),
        _buildMenuItem("Đơn vị tiền tệ", Icons.currency_exchange, () {
          _showCurrencySelector(context, moreViewModel);
        }),
        _buildMenuItem("Đặt lại ứng dụng", Icons.restore, () {
          _confirmResetApp(context, moreViewModel);
        }),
        _buildMenuItem("Giới thiệu", Icons.info_outline, () {
          _showAboutDialog(context, moreViewModel);
        }),
        _buildMenuItem("Phản hồi", Icons.feedback, () {
          _showFeedbackDialog(context, moreViewModel);
        }),
      ],
    );
  }

  Widget _buildExpansionTile(String title, IconData icon,
      List<Widget> children) {
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

  // Update user profile
  Future<void> _updateUserProfile(MoreViewModel viewModel) async {
    String newName = viewModel.userName;

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Cập nhật thông tin"),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.updateProfileImage();
                    _updateUserProfile(viewModel);
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildProfileAvatar(viewModel, radius: 40),
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
                  controller: TextEditingController(text: viewModel.userName),
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

                  if (newName
                      .trim()
                      .isNotEmpty && newName != viewModel.userName) {
                    bool success = await viewModel.updateUserProfile(newName);

                    if (success) {
                      MessageUtils.showSuccessMessage(
                          context, "Cập nhật thông tin thành công");
                    }
                  }
                },
                child: Text("Cập nhật"),
              ),
            ],
          ),
    );
  }

  // Show currency selector dialog
  void _showCurrencySelector(BuildContext context, MoreViewModel viewModel) {
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
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Chọn đơn vị tiền tệ'),
                backgroundColor: Colors.white,
                content: Container(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currencies.length,
                    itemBuilder: (context, index) {
                      final currency = currencies[index];
                      final bool isSelected = currency['code'] ==
                          selectedCurrencyCode;

                      return ListTile(
                        leading: Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            currency['symbol']!,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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

                      Navigator.pop(context);

                      final success = await viewModel.updateCurrency(
                          selectedCurrency['code']!,
                          selectedCurrency['symbol']!,
                          selectedCurrency['name']!
                      );

                      if (success) {
                        MessageUtils.showSuccessMessage(
                            context,
                            'Đã cập nhật đơn vị tiền tệ thành ${selectedCurrency['name']}'
                        );
                      }
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
}