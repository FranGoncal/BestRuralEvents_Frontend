import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/app_notification.dart';


class RegisterDeviceTokenResult {
  final bool success;
  final String message;

  RegisterDeviceTokenResult({
    required this.success,
    required this.message,
  });
}

class NotificationStatusResult {
  final bool success;
  final bool hasUnreadNotifications;
  final String message;

  NotificationStatusResult({
    required this.success,
    required this.hasUnreadNotifications,
    required this.message,
  });
}

class NotificationListResult {
  final bool success;
  final List<AppNotification> notifications;
  final String message;

  NotificationListResult({
    required this.success,
    required this.notifications,
    required this.message,
  });
}

class DeleteNotificationResult {
  final bool success;
  final String message;

  DeleteNotificationResult({
    required this.success,
    required this.message,
  });
}

class NotificationService {
  static String get _baseUrl => AppConfig.baseUrl;

  Future<NotificationStatusResult> loadNotificationStatus({
    required String token,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/status');
      debugPrint('NOTIFICATIONS -> sending GET to $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      debugPrint('NOTIFICATIONS -> status code: ${response.statusCode}');
      debugPrint('NOTIFICATIONS -> body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hasUnread = data['hasUnreadNotifications'] == true;

        return NotificationStatusResult(
          success: true,
          hasUnreadNotifications: hasUnread,
          message: 'Notification status loaded successfully.',
        );
      }

      return NotificationStatusResult(
        success: false,
        hasUnreadNotifications: false,
        message: 'Failed to load notifications. Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('NOTIFICATIONS -> exception: $e');

      return NotificationStatusResult(
        success: false,
        hasUnreadNotifications: false,
        message: 'Error loading notifications: $e',
      );
    }
  }

  Future<DeleteNotificationResult> deleteAllNotifications({
    required String token,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification');
      debugPrint('DELETE ALL NOTIFICATIONS -> sending DELETE to $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      debugPrint('DELETE ALL NOTIFICATIONS -> status code: ${response.statusCode}');
      debugPrint('DELETE ALL NOTIFICATIONS -> body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return DeleteNotificationResult(
          success: true,
          message: 'All notifications deleted successfully.',
        );
      }

      return DeleteNotificationResult(
        success: false,
        message: 'Failed to delete all notifications. Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('DELETE ALL NOTIFICATIONS -> exception: $e');

      return DeleteNotificationResult(
        success: false,
        message: 'Error deleting all notifications: $e',
      );
    }
  }

  Future<RegisterDeviceTokenResult> registerDeviceToken({
    required String token,
    required String userId,
    required String fcmToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/device-token');
      debugPrint('REGISTER FCM TOKEN -> sending POST to $url');
      debugPrint('REGISTER FCM TOKEN -> token: $fcmToken');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': 'ANDROID',
        }),
      );

      debugPrint('REGISTER FCM TOKEN -> status code: ${response.statusCode}');
      debugPrint('REGISTER FCM TOKEN -> body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterDeviceTokenResult(
          success: true,
          message: 'Device token registered successfully.',
        );
      }

      return RegisterDeviceTokenResult(
        success: false,
        message: 'Failed to register device token. Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('REGISTER FCM TOKEN -> exception: $e');

      return RegisterDeviceTokenResult(
        success: false,
        message: 'Error registering device token: $e',
      );
    }
  }

  Future<NotificationListResult> loadNotifications({
    required String token,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification');
      debugPrint('NOTIFICATIONS LIST -> sending GET to $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      debugPrint('NOTIFICATIONS LIST -> status code: ${response.statusCode}');
      debugPrint('NOTIFICATIONS LIST -> body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final notifications = data
            .map((item) => AppNotification.fromJson(item))
            .toList();

        return NotificationListResult(
          success: true,
          notifications: notifications,
          message: 'Notifications loaded successfully.',
        );
      }

      return NotificationListResult(
        success: false,
        notifications: [],
        message: 'Failed to load notifications. Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('NOTIFICATIONS LIST -> exception: $e');

      return NotificationListResult(
        success: false,
        notifications: [],
        message: 'Error loading notifications: $e',
      );
    }
  }

  Future<DeleteNotificationResult> deleteNotification({
    required String token,
    required String notificationId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/$notificationId');
      debugPrint('DELETE NOTIFICATION -> sending DELETE to $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      debugPrint('DELETE NOTIFICATION -> status code: ${response.statusCode}');
      debugPrint('DELETE NOTIFICATION -> body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return DeleteNotificationResult(
          success: true,
          message: 'Notification deleted successfully.',
        );
      }

      return DeleteNotificationResult(
        success: false,
        message: 'Failed to delete notification. Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('DELETE NOTIFICATION -> exception: $e');

      return DeleteNotificationResult(
        success: false,
        message: 'Error deleting notification: $e',
      );
    }
  }
}