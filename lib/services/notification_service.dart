import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // ✅ NEW
import 'dart:convert'; // ✅ NEW

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ ADD YOUR SERVER KEY HERE
  static const String _serverKey = 'YOUR_SERVER_KEY_HERE';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Blood Request Alerts',
    description: 'Urgent blood donation notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Permission: ${settings.authorizationStatus}');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      await _saveTokenToFirestore();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Tapped: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _fcm.getToken();
      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No authenticated user');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});

      debugPrint('✅ FCM token saved');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    try {
      _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'HopeDrop',
        message.notification?.body ?? 'New blood request nearby!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // ✅ REAL FCM sender via HTTP API
  static Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'priority': 'high',
              'default_sound': true,
            },
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent! Response: ${response.body}');
      } else {
        debugPrint('❌ FCM Error: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Send error: $e');
    }
  }
} // ← class closing bracket
