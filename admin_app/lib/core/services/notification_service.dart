import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

/// Notification service to handle permissions, token registration, and notifications.
class NotificationService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseMessaging? fcm,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _fcm = fcm ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Requests notification permissions for Android 13+ (POST_NOTIFICATIONS) and iOS.
  Future<bool> requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        await registerDeviceToken();
      }
      return granted;
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return false;
    }
  }

  /// Retrieves the FCM device token and saves it to the admin's Firestore document.
  Future<String?> registerDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token rotations
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveTokenToFirestore(newToken);
      });

      return token;
    } catch (e) {
      debugPrint('FCM Token registration error: $e');
      return null;
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('admins').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token to Firestore: $e');
    }
  }

  /// Removes current token when logging out.
  Future<void> unregisterDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      final user = _auth.currentUser;
      if (token != null && user != null) {
        await _firestore.collection('admins').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  /// Stream of foreground messages.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  /// Stream of messages clicked while in background.
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
