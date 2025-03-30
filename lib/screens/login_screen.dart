import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import '../services/database_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/expense');
        } else {
          // User was logged in according to SharedPreferences but Firebase says no
          await prefs.setBool('isLoggedIn', false);
        }
      }
    } catch (e) {
      print("Error checking login state: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAlert("Vui lòng nhập đầy đủ email và mật khẩu!");
      return;
    }

    if (!EmailValidator.validate(email)) {
      showAlert("Email không hợp lệ! Vui lòng nhập đúng định dạng.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Thử đăng nhập trực tiếp mà không kiểm tra trước
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveLoginState();
      Navigator.pushReplacementNamed(context, '/expense');

    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e.code == 'invalid-credential') {
        showAlert("Email chưa được đăng ký hoặc Mật khẩu không đúng! Vui lòng kiểm tra lại.");
      } else {
        showAlert("Lỗi đăng nhập: ${e.message}");
      }
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

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
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

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFF8B55),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFF8B55),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 125, left: 30, right: 30),
          child: Column(
            children: [
              Text(
                'Chào mừng bạn trở lại!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Nhập email và mật khẩu để tiếp tục.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0C7AD1),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons
                          .visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                      : Text('Đăng Nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                        color: Colors.black, thickness: 2), // Đường kẻ bên trái
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    // Khoảng cách giữa chữ và đường kẻ
                    child: Text("hoặc", style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Divider(
                        color: Colors.black, thickness: 2), // Đường kẻ bên phải
                  ),
                ],
              ),

              SizedBox(height: 10),
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    UserCredential? user = await signInWithGoogle();
                    if (user != null) {
                      Navigator.pushReplacementNamed(context, '/expense');
                    }
                  },
                  icon: Image.asset('assets/google_icon.png', width: 24),
                  label: Text(
                    'Đăng nhập bằng Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  text: 'Chưa có tài khoản? ',
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Đăng ký',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context,
                              '/signup'); // Điều hướng đến trang đăng ký
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}