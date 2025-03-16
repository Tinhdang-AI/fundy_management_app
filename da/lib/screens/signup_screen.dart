import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mật khẩu không khớp')));
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký: ${e.toString()}')),
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return null;
    }
  }

  Widget _buildTextField(String hintText, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        suffixIcon: isPassword ? Icon(Icons.visibility_off) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF8B55),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(top: 150, left: 30, right: 30),
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
                  color: Color(0xFF0C7AD1),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:_buildTextField('Họ và Tên', nameController),

              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:_buildTextField('Email', emailController),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:_buildTextField('Mật khẩu', passwordController, isPassword: true),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:_buildTextField('Xác nhận lại mật khẩu', confirmPasswordController, isPassword: true),
              ),
              SizedBox(height: 20),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:ElevatedButton(
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
              SizedBox(height: 20),
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
              ),              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:ElevatedButton.icon(
                  onPressed: () async {
                    UserCredential? user = await signInWithGoogle();
                    if (user != null) {
                      print("Đăng ký thành công: ${user.user?.displayName}");
                      Navigator.pushNamed(context, '/expense'); // Chuyển hướng sau khi đăng ký thành công
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
                          Navigator.pushNamed(context, '/login'); // Điều hướng đến trang đăng ký
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
