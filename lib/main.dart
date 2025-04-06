import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'utils/currency_formatter.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/expense_viewmodel.dart';
import 'viewmodels/calendar_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/more_viewmodel.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/signup_screen.dart';
import 'views/screens/expense_screen.dart';
import 'views/screens/calendar_screen.dart';
import 'views/screens/report_screen.dart';
import 'views/screens/more_screen.dart';
import 'views/screens/search_screen.dart';
import 'views/screens/forgot_password_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize currency settings
  await initCurrency();

  // Run the application
  runApp(FundyApp());
}

class FundyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Register all our ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => MoreViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fundy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/expense': (context) => ExpenseScreen(),
          '/calendar': (context) => CalendarScreen(),
          '/report': (context) => ReportScreen(),
          '/more': (context) => MoreScreen(),
          '/search': (context) => SearchScreen(),
          '/forgot_password': (context) => ForgotPasswordScreen(),
        },
      ),
    );
  }
}