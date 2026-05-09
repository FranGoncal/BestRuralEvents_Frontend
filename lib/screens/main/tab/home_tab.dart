import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/event_card.dart';
import 'profile_tab.dart';
import '../../../models/event.dart';
import '../../../services/event_service.dart';
import '../../event/event_details_page.dart';

// page responsible only for the TAB home in the main page
class HomeTab extends StatefulWidget {
  final String token;
  final String userId;
  final String email;
  final ValueChanged<bool> onNotificationsChanged;

  const HomeTab({
    super.key,
    required this.token,
    required this.userId,
    required this.email,
    required this.onNotificationsChanged,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  //service to call the backend
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _lastUpdated;
  List<Event> _events = [];

  // run once the page is loaded
  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    await Future.wait([
      _loadEvents(),
      _loadNotifications(),
    ]);
  }

  String _formatDateRange(DateTime startDate, DateTime endDate) {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    if (start == end) return start;

    return '$start - $end';
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
    final result = await _notificationService.loadNotificationStatus(
      token: widget.token,
    );

    if (!mounted) return;

    if (result.success) {
      widget.onNotificationsChanged(result.hasUnreadNotifications);
    } else {
      widget.onNotificationsChanged(false);
    }
  }

  // Get the main page events through the event service
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _eventService.loadMainPageEventsSmart(
      token: widget.token,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _events = result.events;
        _lastUpdated = result.lastUpdated;
        _isLoading = false;
      });

      _showMessage(
        result.message,
        backgroundColor: result.loadedFromCache ? Colors.orange : Colors.green,
      );
    } else {
      setState(() {
        _events = [];
        _errorMessage = result.message;
        _isLoading = false;
      });

      _showMessage(
        'DEBUG: ${result.message}',
        backgroundColor: Colors.red,
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Free';
    return '€${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    //make page scrollable
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Discover Rural Experiences',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 20),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
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
                  size: 42,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load main page events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        else if (_events.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: lightGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No featured events available right now.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._events.map(
                  (event) => EventCard(
                event: event,
                formattedDate: _formatDateRange(event.startDate, event.endDate),
                formattedPrice: _formatPrice(event.price),
                token: widget.token,
                userId: widget.userId,
              ),
            ),
      ],
    );
  }
}