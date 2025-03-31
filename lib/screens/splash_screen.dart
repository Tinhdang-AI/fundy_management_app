import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundy/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    });
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
                fontSize: 40, // Kích thước lớn hơn
                fontWeight: FontWeight.bold, // Chữ đậm
                color: Colors.white, // Màu trắng
                letterSpacing: 2.0, // Giãn chữ để trông hiện đại hơn
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black26,
                    offset: Offset(2, 2), // Hiệu ứng bóng nhẹ
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
