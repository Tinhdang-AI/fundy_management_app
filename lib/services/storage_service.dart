import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save login status to shared preferences
  Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Get login status from shared preferences
  Future<bool> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Save profile image to Firestore as base64
  Future<String?> saveProfileImage(File imageFile) async {
    if (currentUserId == null) return null;

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      String imageId = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore
          .collection('user_images')
          .doc(imageId)
          .set({
        'userId': currentUserId,
        'imageData': base64Image,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({'profileImageUrl': imageId});

      return imageId;
    } catch (e) {
      print("Error saving profile image: $e");
      return null;
    }
  }

  // Get profile image from Firestore
  Future<String?> getProfileImage(String imageId) async {
    if (imageId.startsWith('http')) {
      // It's already a URL
      return imageId;
    }

    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('user_images')
          .doc(imageId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data['imageData'] as String?;
      }
    } catch (e) {
      print("Error getting profile image: $e");
    }
    return null;
  }

  // Clear all app data - for testing and "Reset app" functionality
  Future<void> clearAllUserData() async {
    if (currentUserId == null) return;

    try {
      // Delete all user expenses
      QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: currentUserId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in expensesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print("Error clearing user data: $e");
      throw e;
    }
  }
}