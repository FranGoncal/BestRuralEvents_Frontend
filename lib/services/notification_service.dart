import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_notification.dart';

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
  static const String _baseUrl = 'http://192.168.1.68:8080';

  Future<NotificationStatusResult> loadNotificationStatus({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/status');
      debugPrint('NOTIFICATIONS -> sending GET to $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  Future<NotificationListResult> loadNotifications({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification');
      debugPrint('NOTIFICATIONS LIST -> sending GET to $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/$notificationId');
      debugPrint('DELETE NOTIFICATION -> sending DELETE to $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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