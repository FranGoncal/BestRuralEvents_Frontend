import 'package:flutter/material.dart';
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

  const HomeTab({
    super.key,
    required this.token,
    required this.userId,
    required this.email,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  //service to call the backend
  final EventService _eventService = EventService();


  bool _isLoading = true;
  String? _errorMessage;
  String? _lastUpdated;
  List<Event> _events = [];

  // run once the page is loaded
  @override
  void initState() {
    super.initState();
    _loadEvents();
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
        /*const SizedBox(height: 8),
        Text(
          'Featured events selected for the main page',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Text(
          'Logged in as: ${widget.email}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        if (_lastUpdated != null) ...[
          const SizedBox(height: 4),
          Text(
            'Backend last Updated: $_lastUpdated',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],*/
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
                formattedDate: _formatDate(event.date),
                formattedPrice: _formatPrice(event.price),
                token: widget.token,
              ),
            ),
      ],
    );
  }
}
