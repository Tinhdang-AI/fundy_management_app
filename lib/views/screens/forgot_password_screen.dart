import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showAlert("Vui lòng nhập email!");
      return;
    }

    if (!EmailValidator.validate(email)) {
      showAlert("Email không hợp lệ!");
      return;
    }

    try {
      // Kiểm tra xem email đã được đăng ký chưa
      List<String> signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isEmpty) {
        showAlert("Email chưa được đăng ký!");
        return;
      }

      // Nếu email hợp lệ, gửi mã đặt lại mật khẩu
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showAlert("Email đặt lại mật khẩu đã được gửi!");
    } catch (e) {
      showAlert("Lỗi: ${e.toString()}");
    }
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 15),
            Divider(color: Colors.grey.shade300),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                ),
                child: Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quên Mật Khẩu")),
      body: Padding(
        padding: EdgeInsets.only(top: 100, left: 30, right: 30),
        child: Column(
          children: [
            Text(
              "Nhập email của bạn để nhận liên kết đặt lại mật khẩu",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 350,
              height: 50,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Gửi Email",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
