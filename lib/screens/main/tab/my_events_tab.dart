import 'package:flutter/material.dart';
import 'package:best_rural_events_frontend/models/event.dart';
import 'package:best_rural_events_frontend/services/event_service.dart';

import '../../event/event_details_page.dart';
import 'my_events/create_event_page.dart';
import 'my_events/edit_event_page.dart';
import 'my_events/manage_event_tickets_page.dart';
import 'my_events/promote_event_page.dart';

class MyEventsTab extends StatefulWidget {
  final String token;
  final String userId;

  const MyEventsTab({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<MyEventsTab> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadMyEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _loadMyEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _eventService.getUserCreatedEvents(
      token: widget.token,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _events = result.events;
        _isLoading = false;
      });
    } else {
      setState(() {
        _events = [];
        _errorMessage = result.message;
        _isLoading = false;
      });

      _showMessage(result.message, backgroundColor: Colors.red);
    }
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Free';
    return '${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)} €';
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final initialDate = isFromDate
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
        _fromDateController.text = _formatDate(picked);
      } else {
        _toDate = picked;
        _toDateController.text = _formatDate(picked);
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<Event> get _filteredEvents {
    return _events.where((event) {
      final matchesSearch = event.title
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      final matchesFrom = _fromDate == null ||
          !eventDate.isBefore(
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
          );

      final matchesTo = _toDate == null ||
          !eventDate.isAfter(
            DateTime(_toDate!.year, _toDate!.month, _toDate!.day),
          );

      return matchesSearch && matchesFrom && matchesTo;
    }).toList();
  }

  Future<void> _promoteEvent(Event event) async {
    final promoted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromoteEventPage(
          event: event,
          token: widget.token,
          userId: widget.userId,
        ),
      ),
    );

    if (!mounted) return;

    if (promoted == true) {
      _showMessage(
        'Event promoted successfully',
        backgroundColor: Colors.green,
      );

      // Optional: reload if backend returns updated event promotion state
      await _loadMyEvents();
    }
  }

  Future<void> _viewDetails(Event event) async {

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          token: widget.token,
        ),
      ),
    );
  }

  Future<void> _editEvent(Event event) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventPage(
          token: widget.token,
          event: event,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      _showMessage(
        'Event updated successfully',
        backgroundColor: Colors.green,
      );
      await _loadMyEvents();
    }
  }

  Future<void> _manageTickets(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageEventTicketsPage(
          token: widget.token,
          event: event,
        ),
      ),
    );
  }

  Future<void> _createEvent() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventPage(token: widget.token),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _showMessage(
        'Event created successfully',
        backgroundColor: Colors.green,
      );
      await _loadMyEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    final events = _filteredEvents;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createEvent,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'My events',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by event name',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: primaryGreen),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Events between:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isFromDate: true),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _fromDateController,
                            decoration: InputDecoration(
                              hintText: 'From date',
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isFromDate: false),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _toDateController,
                            decoration: InputDecoration(
                              hintText: 'To date',
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 42, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadMyEvents,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            )
          else if (_events.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'You have not created any events yet.',
                  textAlign: TextAlign.center,
                ),
              )
            else if (events.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'No events match your filters.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...events.map(
                      (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: MyEventCard(
                      event: event,
                      formattedPrice: _formatPrice(event.price),
                      formattedDate: _formatDate(event.date),
                      onPromote: () => _promoteEvent(event),
                      onViewDetails: () => _viewDetails(event),
                      onEditEvent: () => _editEvent(event),
                      onManageTickets: () => _manageTickets(event),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class MyEventCard extends StatelessWidget {
  final Event event;
  final String formattedPrice;
  final String formattedDate;
  final VoidCallback onPromote;
  final VoidCallback onViewDetails;
  final VoidCallback onEditEvent;
  final VoidCallback onManageTickets;

  const MyEventCard({
    super.key,
    required this.event,
    required this.formattedPrice,
    required this.formattedDate,
    required this.onPromote,
    required this.onViewDetails,
    required this.onEditEvent,
    required this.onManageTickets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              event.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 88,
                  height: 88,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedPrice,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Date: $formattedDate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 136,
            child: Column(
              children: [
                _MyEventActionButton(
                  label: 'Promote',
                  onPressed: onPromote,
                ),
                const SizedBox(height: 8),
                _MyEventActionButton(
                  label: 'View details',
                  onPressed: onViewDetails,
                ),
                const SizedBox(height: 8),
                _MyEventActionButton(
                  label: 'Edit event',
                  onPressed: onEditEvent,
                ),
                const SizedBox(height: 8),
                _MyEventActionButton(
                  label: 'Manage tickets',
                  onPressed: onManageTickets,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyEventActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MyEventActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}