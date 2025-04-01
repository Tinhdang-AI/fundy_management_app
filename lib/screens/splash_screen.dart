import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/login_screen.dart';
import '/screens/expense_screen.dart';
import '../utils/currency_formatter.dart'; // Import the currency formatter

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
      // Initialize currency settings
      await initCurrency();

      // Check if user is logged in via shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Also verify with Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;

      // If user is logged in and we have their data in Firestore, we can also load currency preference
      if (currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;

            // Check if user has currency preference saved
            if (userData.containsKey('currency')) {
              final currencyData = userData['currency'];
              if (currencyData != null &&
                  currencyData['code'] != null &&
                  currencyData['symbol'] != null) {
                // Update currency with user's preference
                await updateCurrency(
                    currencyData['code'],
                    currencyData['symbol']
                );
              }
            }
          }
        } catch (e) {
          // If there's an error, we'll just use the default currency
          print("Error loading user currency: $e");
        }
      }

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
          ],
        ),
      ),
    );
  }
}