import 'package:flutter/material.dart';
import '../home//profile_page.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../event/event_details_page.dart';

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
  final EventService _eventService = EventService();


  bool _isLoading = true;
  String? _errorMessage;
  String? _lastUpdated;
  List<Event> _events = [];

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
        const SizedBox(height: 8),
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
            'Backend lastUpdated: $_lastUpdated',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
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
                  (event) => _EventCard(
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

class _EventCard extends StatelessWidget {
  final Event event;
  final String formattedDate;
  final String formattedPrice;
  final String token;

  const _EventCard({
    required this.event,
    required this.formattedDate,
    required this.formattedPrice,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: lightGray),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              event.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event.location)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(formattedDate)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sell_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsPage(event: event, token: token,),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                    ),
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}