import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
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
} 