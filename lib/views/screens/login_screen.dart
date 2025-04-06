import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/message_utils.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the AuthViewModel using Provider
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Show loading indicator if authentication is in progress
    if (authViewModel.isLoading) {
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
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 20),

              // Email input field
              Container(
                width: 350,
                height: 50,
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

              // Password input field
              Container(
                width: 350,
                height: 50,
                child: TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Login button
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _login(context, authViewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Đăng Nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text("hoặc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Google Sign-In button
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context, authViewModel),
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

              // Sign up link
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
                          Navigator.pushNamed(context, '/signup');
                        },
                    ),
                  ],
                ),
              ),

              // Show error message if any
              if (authViewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authViewModel.errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Email and password login
  Future<void> _login(BuildContext context, AuthViewModel authViewModel) async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      MessageUtils.showErrorMessage(context, "Vui lòng nhập đầy đủ email và mật khẩu!");
      return;
    }

    bool success = await authViewModel.signInWithEmail(email, password);

    if (success) {
      Navigator.pushReplacementNamed(context, '/expense');
    }
  }

  // Google sign in
  Future<void> _signInWithGoogle(BuildContext context, AuthViewModel authViewModel) async {
    bool success = await authViewModel.signInWithGoogle();

    if (success) {
      Navigator.pushReplacementNamed(context, '/expense');
    }
  }
}