import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/login_screen.dart';
import '/screens/expense_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a minimum delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user is logged in via shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Also verify with Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Navigate to appropriate screen
      if (isLoggedIn && currentUser != null) {
        // User is logged in, navigate to expense screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ExpenseScreen()),
        );
      } else {
        // User is not logged in, clear any stale login state
        if (isLoggedIn && currentUser == null) {
          await prefs.setBool('isLoggedIn', false);
        }

        // Navigate to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      // In case of error, default to login screen
      print("Error checking login state: $e");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
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
            Image.asset('assets/logo_e.png', width: 278, height: 278),
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
          ],
        ),
      ),
    );
  }
}
