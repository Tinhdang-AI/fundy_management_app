import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushNamed(context, '/expense'); // Chuyển đến màn hình quản lý chi tiêu
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: ${e.toString()}')),
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
                child:TextField(
                  controller: emailController,
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
                child:TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.visibility_off),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Đăng Nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
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
              ),

              SizedBox(height: 10),
              Container(
                width: 350, // Độ rộng của ô nhập
                height: 50, // Độ cao của ô nhập
                child:ElevatedButton.icon(
                  onPressed: () async {
                    UserCredential? user = await signInWithGoogle();
                    if (user != null) {
                      print("Đăng nhập thành công: ${user.user?.displayName}");
                      Navigator.pushNamed(context, '/expense'); // Chuyển hướng sau khi đăng nhập
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
                          Navigator.pushNamed(context, '/signup'); // Điều hướng đến trang đăng ký
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
