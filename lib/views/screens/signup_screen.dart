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
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Custom text field with consistent styling
  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : (isConfirmPassword ? _obscureConfirmPassword : false),
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.deepOrange, width: 2),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : (isConfirmPassword
            ? IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        )
            : null),
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
        backgroundColor: Colors.orange.shade100,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    // Check for error message from view model and display it
    if (authViewModel.errorMessage != null) {
      // Use post-frame callback to show the error message after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MessageUtils.showErrorMessage(context, authViewModel.errorMessage!);
        // The error will be cleared on the next frame
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header section
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      // App logo/icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: 45,
                          color: Colors.deepOrange,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tạo tài khoản mới!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Điền thông tin bên dưới để tạo tài khoản!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Form fields section
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Name field
                        _buildTextField(
                          hintText: 'Họ và Tên',
                          controller: nameController,
                          prefixIcon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),
                        // Email field
                        _buildTextField(
                          hintText: 'Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                        SizedBox(height: 16),
                        // Password field
                        _buildTextField(
                          hintText: 'Mật khẩu',
                          controller: passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                        SizedBox(height: 16),
                        // Confirm password field
                        _buildTextField(
                          hintText: 'Xác nhận lại mật khẩu',
                          controller: confirmPasswordController,
                          isConfirmPassword: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                        SizedBox(height: 25),
                        // Signup button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () => _signUp(context, authViewModel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepOrange,
                              elevation: 5,
                              shadowColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Đăng Ký',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer section
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.white70, thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              "hoặc",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.white70, thickness: 1),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      // Google signup button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () => _signInWithGoogle(context, authViewModel),
                          icon: Image.asset('assets/google_icon.png', width: 24, height: 24),
                          label: Text(
                            'Đăng ký bằng Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            elevation: 5,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Login link
                      Text.rich(
                        TextSpan(
                          text: 'Đã có tài khoản? ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'Đăng nhập',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/login');
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      MessageUtils.showSuccessMessage(context, "Đăng nhập thành công!");

      // Slight delay to allow the message to be seen
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/expense');
      }
    }
  }
}