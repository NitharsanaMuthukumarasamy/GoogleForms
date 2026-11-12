import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/admin_model.dart';

/// Custom exception thrown when a user successfully authenticates in Firebase Auth
/// but is NOT registered in the Firestore "admins" collection.
class UnauthorizedAdminException implements Exception {
  final String message;
  const UnauthorizedAdminException([
    this.message = 'Access Denied: Your account is not authorized as an administrator. Please contact your system administrator.',
  ]);

  @override
  String toString() => message;
}

/// Custom exception for friendly auth errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Repository handling Firebase Authentication and Admin RBAC verification.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of Firebase Auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently logged-in Firebase User.
  User? get currentUser => _auth.currentUser;

  /// Authenticates with Email and Password, and verifies admin eligibility.
  /// Throws [UnauthorizedAdminException] if user is not in the "admins" collection.
  Future<Admin> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user returned.');
      }

      // Check the "admins" collection in Firestore
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        // Immediate sign out to reject unauthorized users
        await _auth.signOut();
        throw const UnauthorizedAdminException();
      }

      return Admin.fromFirestore(adminDoc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } on UnauthorizedAdminException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sends a password reset email to the specified admin email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Signs out the currently authenticated admin.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Verifies if the current logged-in user is an authorized admin and returns their profile.
  Future<Admin?> getCurrentAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        return null;
      }
      return Admin.fromFirestore(adminDoc);
    } catch (_) {
      return null;
    }
  }

  /// Helper to convert Firebase Auth codes into human-readable messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No administrator account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This administrator account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please wait a few minutes before trying again.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connectivity.';
      default:
        return e.message ?? 'Authentication error occurred. Please try again.';
    }
  }
}
