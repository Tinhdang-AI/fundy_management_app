import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/message_utils.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
    // Access the AuthViewModel
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

              // Name field
              Container(
                width: 350,
                height: 50,
                child: _buildTextField('Họ và Tên', nameController),
              ),
              SizedBox(height: 10),

              // Email field
              Container(
                width: 350,
                height: 50,
                child: _buildTextField('Email', emailController),
              ),
              SizedBox(height: 10),

              // Password field
              Container(
                width: 350,
                height: 50,
                child: _buildTextField('Mật khẩu', passwordController, isPassword: true),
              ),
              SizedBox(height: 10),

              // Confirm password field
              Container(
                width: 350,
                height: 50,
                child: _buildTextField('Xác nhận lại mật khẩu', confirmPasswordController, isPassword: true),
              ),
              SizedBox(height: 20),

              // Signup button
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _signUp(context, authViewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                      'Đăng Ký',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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

              // Google signup button
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context, authViewModel),
                  icon: Image.asset('assets/google_icon.png', width: 24),
                  label: Text(
                      'Đăng ký bằng Google',
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

              // Login link
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

  // Email and password signup
  Future<void> _signUp(BuildContext context, AuthViewModel authViewModel) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Validate inputs
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      MessageUtils.showErrorMessage(context, "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    if (!EmailValidator.validate(email)) {
      MessageUtils.showErrorMessage(context, "Email không hợp lệ! Vui lòng nhập đúng định dạng.");
      return;
    }

    if (password != confirmPassword) {
      MessageUtils.showErrorMessage(context, "Mật khẩu không khớp! Vui lòng nhập lại.");
      return;
    }

    if (password.length < 6) {
      MessageUtils.showErrorMessage(context, "Mật khẩu phải có ít nhất 6 ký tự!");
      return;
    }

    // Register with the auth view model
    bool success = await authViewModel.signUpWithEmail(name, email, password);

    if (success) {
      MessageUtils.showAlertDialog(
          context: context,
          title: "Đăng ký thành công",
          message: "Tài khoản đã được tạo. Vui lòng đăng nhập để tiếp tục.",
          onOk: () {
            Navigator.pushReplacementNamed(context, '/login');
          }
      );
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