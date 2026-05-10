import 'package:flutter/material.dart';
import '../../../models/app_notification.dart';
import '../../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final String token;
  final String userId;

  const NotificationsPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _notificationService.loadNotifications(
      token: widget.token,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _notifications = result.notifications;
        _isLoading = false;
      });
    } else {
      setState(() {
        _notifications = [];
        _errorMessage = result.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final result = await _notificationService.deleteNotification(
      token: widget.token,
      notificationId: notificationId,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });

      _showMessage(
        result.message,
        backgroundColor: Colors.green,
      );
    } else {
      _showMessage(
        result.message,
        backgroundColor: Colors.red,
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: lightGray),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_notifications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: lightGray),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'You have no notifications right now.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._notifications.map(
                      (notification) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.notifications,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(notification.text),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDateTime(notification.time),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteNotification(notification.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}