import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Starting signup process for: $email'); // Debug logging
      
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully: ${userCredential.user?.uid}'); // Debug logging

      // Update user display name
      try {
        await userCredential.user?.updateDisplayName(name);
        print('Display name updated successfully'); // Debug logging
      } catch (e) {
        print('Warning: Could not update display name: $e'); // Debug logging
        // Continue with the process even if display name update fails
      }

      // Create user document in Firestore
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('User document created in Firestore'); // Debug logging
      } catch (e) {
        print('Warning: Could not create user document in Firestore: $e'); // Debug logging
        // Continue with the process even if Firestore write fails
      }

      // Return the user credential - this is the successful result
      return userCredential;
    } catch (e) {
      print('Signup error: $e'); // Debug logging
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  static Future<UserCredential> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Save authentication cookie for 30 days only if rememberMe is true
      if (rememberMe) {
        await _saveAuthCookie(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }



  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Delete user account
  static Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user from Firebase Auth
        await user.delete();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Firebase Auth errors
  static String _handleAuthError(dynamic error) {
    print('Auth Error: $error'); // Debug logging
    
    if (error is FirebaseAuthException) {
      print('Firebase Auth Error Code: ${error.code}'); // Debug logging
      print('Firebase Auth Error Message: ${error.message}'); // Debug logging
      
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          return 'Invalid credentials provided.';
        default:
          return 'Authentication failed: ${error.message} (Code: ${error.code})';
      }
    }
    
    // Handle other types of errors
    if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    
    return 'An unexpected error occurred: $error';
  }

  // Save authentication cookie for 30 days
  static Future<void> _saveAuthCookie(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create auth data to store
      final authData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'lastSignIn': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
      };
      
      // Store as JSON string
      await prefs.setString('auth_cookie', jsonEncode(authData));
      
      // Store individual values for easy access
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_display_name', user.displayName ?? '');
      await prefs.setBool('is_authenticated', true);
      
      print('Auth cookie saved successfully for user: ${user.email}');
    } catch (e) {
      print('Error saving auth cookie: $e');
    }
  }

  // Check if user has valid authentication cookie
  static Future<bool> hasValidAuthCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authCookieString = prefs.getString('auth_cookie');
      
      if (authCookieString == null) return false;
      
      final authData = jsonDecode(authCookieString) as Map<String, dynamic>;
      final expiresAt = authData['expiresAt'] as int;
      
      // Check if cookie is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _clearAuthCookie();
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking auth cookie: $e');
      return false;
    }
  }

  // Get stored user data from cookie
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authCookieString = prefs.getString('auth_cookie');
      
      if (authCookieString == null) return null;
      
      final authData = jsonDecode(authCookieString) as Map<String, dynamic>;
      final expiresAt = authData['expiresAt'] as int;
      
      // Check if cookie is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _clearAuthCookie();
        return null;
      }
      
      return authData;
    } catch (e) {
      print('Error getting stored user data: $e');
      return null;
    }
  }

  // Clear authentication cookie
  static Future<void> _clearAuthCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_cookie');
      await prefs.remove('user_uid');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
      await prefs.setBool('is_authenticated', false);
      
      print('Auth cookie cleared successfully');
    } catch (e) {
      print('Error clearing auth cookie: $e');
    }
  }

  // Sign out and clear cookie
  static Future<void> signOut() async {
    await _auth.signOut();
    await _clearAuthCookie();
  }

  // Auto-login using stored cookie
  static Future<User?> autoLogin() async {
    try {
      if (!await hasValidAuthCookie()) {
        return null;
      }
      
      final storedData = await getStoredUserData();
      if (storedData == null) return null;
      
      // Check if Firebase user is still valid
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == storedData['uid']) {
        return currentUser;
      }
      
      // If no current user, try to restore from stored data
      // Note: Firebase doesn't support direct user restoration, so we'll need to
      // handle this differently - the user will need to sign in again
      print('User needs to sign in again - cookie expired or user changed');
      return null;
      
    } catch (e) {
      print('Error during auto-login: $e');
      return null;
    }
  }

  // Refresh auth cookie (extend expiration)
  static Future<void> refreshAuthCookie() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _saveAuthCookie(currentUser);
        print('Auth cookie refreshed for user: ${currentUser.email}');
      }
    } catch (e) {
      print('Error refreshing auth cookie: $e');
    }
  }

  // Get user preferences (additional stored data)
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'theme': prefs.getString('theme') ?? 'system',
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
        'watering_reminders': prefs.getBool('watering_reminders') ?? true,
        'language': prefs.getString('language') ?? 'en',
        'timezone': prefs.getString('timezone') ?? 'UTC',
      };
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }

  // Save user preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in preferences.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        }
      }
      
      print('User preferences saved successfully');
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }
} 