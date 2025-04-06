import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/currency_formatter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Add a minimum delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Initialize currency settings
    await initCurrency();

    // Use the AuthViewModel to check the login state
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.checkAuthState();

    if (authViewModel.isLoggedIn) {
      // User is logged in, navigate to expense screen
      Navigator.of(context).pushReplacementNamed('/expense');
    } else {
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_icon.png', width: 278, height: 278),
            const SizedBox(height: 20),
            const Text(
              'FUNDY',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black26,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}