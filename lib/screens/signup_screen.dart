import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _saveLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _signUp() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showAlert("Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    if (!EmailValidator.validate(email)) {
      showAlert("Email không hợp lệ! Vui lòng nhập đúng định dạng.");
      return;
    }

    if (password != confirmPassword) {
      showAlert("Mật khẩu không khớp! Vui lòng nhập lại.");
      return;
    }

    if (password.length < 6) {
      showAlert("Mật khẩu phải có ít nhất 6 ký tự!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Tạo tài khoản
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật tên hiển thị
      await userCredential.user?.updateDisplayName(name);

      // Lưu thông tin người dùng vào Firestore
      await _databaseService.saveUserInfo(name, email);

      setState(() {
        _isLoading = false;
      });

      showAlert("Đăng ký thành công! Vui lòng đăng nhập.", onOk: () {
        Navigator.pushNamed(context, '/login');
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      showAlert("Email này đã được đăng ký! Vui lòng sử dụng email khác.");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showAlert("Lỗi không xác định: ${e.toString()}");
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;
      if (user != null) {
        // Lưu thông tin người dùng vào Firestore nếu đây là lần đầu đăng nhập
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _databaseService.saveUserInfo(
            user.displayName ?? "Người dùng Google",
            user.email ?? "",
          );
        }
      }

      await _saveLoginState();
      return userCredential;
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showAlert(String message, {VoidCallback? onOk}) {
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
                onPressed: () {
                  Navigator.pop(context);
                  if (onOk != null) {
                    onOk();
                  }
                },
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

  Widget _buildTextField(String hintText, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.orange.shade200,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.orange,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 80, left: 30, right: 30),
          child: Column(
            children: [
              Text(
                'Tạo tài khoản mới!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Điền thông tin bên dưới để tạo tài khoản!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: _buildTextField('Họ và Tên', nameController),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: _buildTextField('Email', emailController),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: _buildTextField('Mật khẩu', passwordController, isPassword: true),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: _buildTextField('Xác nhận lại mật khẩu', confirmPasswordController, isPassword: true),
              ),
              SizedBox(height: 20),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Đăng Ký',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2), // Đường kẻ bên trái
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2), // Khoảng cách giữa chữ và đường kẻ
                    child: Text("hoặc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2), // Đường kẻ bên phải
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: ElevatedButton.icon(
                  onPressed: () async {
                    UserCredential? user = await signInWithGoogle();
                    if (user != null) {
                      Navigator.pushReplacementNamed(context, '/expense'); // Chuyển hướng sau khi đăng ký thành công
                    }
                  },
                  icon: Image.asset('assets/google_icon.png', width: 24),
                  label: Text('Đăng ký bằng Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: 'Đã có tài khoản? ',
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Đăng nhập',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, '/login');
                        },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
