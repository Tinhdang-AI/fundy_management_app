// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_service.dart';
// import '../services/storage_service.dart';
// import '../services/database_service.dart';
//
// class AuthViewModel extends ChangeNotifier {
//   final AuthService _authService = AuthService();
//   final StorageService _storageService = StorageService();
//   final DatabaseService _databaseService = DatabaseService();
//
//   bool _isLoading = false;
//   String? _errorMessage;
//   User? _currentUser;
//   bool _isLoggedIn = false;
//
//   // Getters
//   bool get isLoading => _isLoading;
//
//   String? get errorMessage => _errorMessage;
//
//   User? get currentUser => _currentUser;
//
//   bool get isLoggedIn => _isLoggedIn;
//
//   // Constructor with initialization
//   AuthViewModel() {
//     _init();
//   }
//
//   Future<void> _init() async {
//     await checkAuthState();
//
//     // Listen for auth state changes
//     _authService.authStateChanges.listen((User? user) {
//       _currentUser = user;
//       _isLoggedIn = user != null;
//       notifyListeners();
//     });
//   }
//
//   // Check authentication state
//   Future<void> checkAuthState() async {
//     _setLoading(true);
//
//     try {
//       // Check saved login state first
//       _isLoggedIn = await _storageService.getLoginState();
//       _currentUser = _authService.currentUser;
//
//       // If saved state says logged in but Firebase doesn't have a user
//       if (_isLoggedIn && _currentUser == null) {
//         await _storageService.saveLoginState(false);
//         _isLoggedIn = false;
//       }
//     } catch (e) {
//       _setError("Error checking authentication state: ${e.toString()}");
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Login with email and password
//   Future<bool> signInWithEmail(String email, String password) async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       UserCredential userCredential = await _authService.signInWithEmail(
//           email, password);
//       _currentUser = userCredential.user;
//       await _storageService.saveLoginState(true);
//       _isLoggedIn = true;
//       notifyListeners();
//       return true;
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'invalid-credential') {
//         _setError(
//             "Email chưa được đăng ký hoặc Mật khẩu không đúng! Vui lòng kiểm tra lại.");
//       } else {
//         _setError("Lỗi đăng nhập: ${e.message}");
//       }
//       return false;
//     } catch (e) {
//       _setError("Lỗi không xác định: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Register with email and password
//   Future<bool> signUpWithEmail(String name, String email,
//       String password) async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       UserCredential userCredential = await _authService.signUpWithEmail(
//           email, password);
//
//       // Update user display name
//       if (userCredential.user != null) {
//         await userCredential.user!.updateDisplayName(name);
//
//         // Save user info to Firestore
//         await _databaseService.saveUserInfo(name, email);
//       }
//
//       return true;
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'email-already-in-use') {
//         _setError("Email này đã được đăng ký! Vui lòng sử dụng email khác.");
//       } else {
//         _setError("Lỗi đăng ký: ${e.message}");
//       }
//       return false;
//     } catch (e) {
//       _setError("Lỗi không xác định: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Sign in with Google
//   Future<bool> signInWithGoogle() async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       UserCredential? userCredential = await _authService.signInWithGoogle();
//
//       if (userCredential == null) {
//         return false;
//       }
//
//       User? user = userCredential.user;
//       if (user != null) {
//         // Save user info to Firestore if this is a new user
//         if (userCredential.additionalUserInfo?.isNewUser ?? false) {
//           await _databaseService.saveUserInfo(
//               user.displayName ?? "Người dùng Google",
//               user.email ?? "",
//               profileImageUrl: user.photoURL
//           );
//         }
//
//         _currentUser = user;
//         await _storageService.saveLoginState(true);
//         _isLoggedIn = true;
//         notifyListeners();
//       }
//
//       return true;
//     } catch (e) {
//       _setError("Lỗi đăng nhập Google: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Reset password
//   Future<bool> resetPassword(String email) async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       List<String> signInMethods = await _authService
//           .fetchSignInMethodsForEmail(email);
//
//       if (signInMethods.isEmpty) {
//         _setError("Email chưa được đăng ký!");
//         return false;
//       }
//
//       await _authService.sendPasswordResetEmail(email);
//       return true;
//     } catch (e) {
//       _setError("Lỗi gửi email đặt lại mật khẩu: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Logout
//   Future<bool> signOut() async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       await _authService.signOut();
//       await _storageService.saveLoginState(false);
//       _isLoggedIn = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _setError("Lỗi đăng xuất: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Update password
//   Future<bool> updatePassword(String currentPassword,
//       String newPassword) async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       await _authService.updatePassword(currentPassword, newPassword);
//       return true;
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'wrong-password') {
//         _setError("Mật khẩu hiện tại không đúng");
//       } else {
//         _setError("Lỗi đổi mật khẩu: ${e.message}");
//       }
//       return false;
//     } catch (e) {
//       _setError("Lỗi không xác định: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Update user display name
//   Future<bool> updateDisplayName(String name) async {
//     _clearError();
//     _setLoading(true);
//
//     try {
//       await _authService.updateUserDisplayName(name);
//       if (_currentUser != null) {
//         _currentUser = _authService.currentUser; // Refresh current user
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       _setError("Lỗi cập nhật tên hiển thị: ${e.toString()}");
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Helper methods for state management
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
//
//   void _setError(String message) {
//     _errorMessage = message;
//     notifyListeners();
//   }
//
//   void _clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      _isLoggedIn = user != null;
      notifyListeners();
    });

    // Set initial state
    _currentUser = _authService.currentUser;
    _isLoggedIn = _currentUser != null;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      UserCredential userCredential =
      await _authService.signInWithEmail(email, password);
      _currentUser = userCredential.user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        _setError(
            "Email chưa được đăng ký hoặc Mật khẩu không đúng! Vui lòng kiểm tra lại.");
      } else {
        _setError("Lỗi đăng nhập: ${e.message}");
      }
      return false;
    } catch (e) {
      _setError("Lỗi không xác định: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      UserCredential userCredential =
      await _authService.signUpWithEmail(email, password);
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await _databaseService.saveUserInfo(name, email);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _setError("Email này đã được đăng ký! Vui lòng sử dụng email khác.");
      } else {
        _setError("Lỗi đăng ký: ${e.message}");
      }
      return false;
    } catch (e) {
      _setError("Lỗi không xác định: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);
    try {
      UserCredential? userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) return false;
      User? user = userCredential.user;
      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _databaseService.saveUserInfo(
            user.displayName ?? "Người dùng Google",
            user.email ?? "",
            profileImageUrl: user.photoURL,
          );
        }
        _currentUser = user;
        _isLoggedIn = true;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError("Lỗi đăng nhập Google: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError("Lỗi gửi email đặt lại mật khẩu: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signOut() async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.signOut();
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Lỗi đăng xuất: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.updatePassword(currentPassword, newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _setError("Mật khẩu hiện tại không đúng");
      } else {
        _setError("Lỗi đổi mật khẩu: ${e.message}");
      }
      return false;
    } catch (e) {
      _setError("Lỗi không xác định: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDisplayName(String name) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.updateUserDisplayName(name);
      if (_currentUser != null) {
        _currentUser = _authService.currentUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError("Lỗi cập nhật tên hiển thị: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
