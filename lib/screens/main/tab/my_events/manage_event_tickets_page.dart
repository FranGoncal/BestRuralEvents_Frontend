import 'package:flutter/material.dart';
import 'package:best_rural_events_frontend/models/event.dart';
import 'package:best_rural_events_frontend/models/event_ticket.dart';
import 'package:best_rural_events_frontend/services/ticket_service.dart';

class ManageEventTicketsPage extends StatefulWidget {
  final String token;
  final Event event;
  final String userId;

  const ManageEventTicketsPage({
    super.key,
    required this.token,
    required this.event,
    required this.userId,
  });

  @override
  State<ManageEventTicketsPage> createState() => _ManageEventTicketsPageState();
}

class _ManageEventTicketsPageState extends State<ManageEventTicketsPage> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _searchController = TextEditingController();

  int? _capacity;
  int? _ticketsSoldSummary;
  int? _ticketsAvailableSummary;
  List<EventTicket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEventTickets();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEventTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _ticketService.getEventTickets(
      token: widget.token,
      eventId: widget.event.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _tickets = result.tickets;
        _capacity = result.capacity;
        _ticketsSoldSummary = result.ticketsSold;
        _ticketsAvailableSummary = result.ticketsAvailable;
        _errorMessage = null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _tickets = [];
        _capacity = null;
        _ticketsSoldSummary = null;
        _ticketsAvailableSummary = null;
        _errorMessage = result.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _refundTicket(EventTicket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund ticket'),
        content: Text(
          'Do you want to refund ${ticket.quantity} '
              '${ticket.quantity == 1 ? 'ticket' : 'tickets'} for ${ticket.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _ticketService.cancelTicket(
      token: widget.token,
      ticketId: ticket.id,
      userId: widget.userId
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Ticket refunded successfully.' : 'Could not refund ticket.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadEventTickets();
    }
  }

  List<EventTicket> get _filteredTickets {
    if (_searchQuery.isEmpty) return _tickets;

    return _tickets.where((ticket) {
      return ticket.customerName.toLowerCase().contains(_searchQuery) ||
          ticket.customerEmail.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  bool _isRefunded(EventTicket ticket) {
    final status = ticket.status.toLowerCase();
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'refunded';
  }

  int get _ticketsSold {
    return _ticketsSoldSummary ??
        _tickets
            .where((ticket) => !_isRefunded(ticket))
            .fold(0, (sum, ticket) => sum + ticket.quantity);
  }

  int? get _totalCapacity => _capacity;

  int? get _ticketsAvailable {
    if (_ticketsAvailableSummary != null) return _ticketsAvailableSummary;
    final total = _totalCapacity;
    if (total == null) return null;
    final available = total - _ticketsSold;
    return available < 0 ? 0 : available;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    final tickets = _filteredTickets;
    final totalCapacity = _totalCapacity;
    final ticketsAvailable = _ticketsAvailable;
    final progress = totalCapacity != null && totalCapacity > 0
        ? (_ticketsSold / totalCapacity).clamp(0.0, 1.0)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Tickets · ${widget.event.title}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(widget.event.date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by buyer name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: primaryGreen),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _isLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
                : _errorMessage != null
                ? Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Could not load tickets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadEventTickets,
                  child: const Text('Try again'),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tickets sold',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 12),
                if (tickets.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No tickets sold yet.'
                          : 'No tickets match your search.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...tickets.map(
                        (ticket) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${ticket.quantity} ${ticket.quantity == 1 ? 'ticket' : 'tickets'} · '
                                    '${ticket.customerName} · '
                                    '${ticket.createdAt != null ? _formatDate(ticket.createdAt!) : 'No date'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _isRefunded(ticket)
                                      ? Colors.grey.shade500
                                      : const Color(0xFF455A64),
                                  decoration: _isRefunded(ticket)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _isRefunded(ticket)
                                  ? null
                                  : () => _refundTicket(ticket),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                                side: BorderSide(
                                  color: _isRefunded(ticket)
                                      ? Colors.grey.shade300
                                      : Colors.red.shade300,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isRefunded(ticket) ? 'Refunded' : 'Refund',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                Text(
                  totalCapacity == null ? 'Tickets summary' : 'Capacity & tickets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 16),

                if (totalCapacity != null) ...[
                  Text(
                    'Tickets',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LinearProgressIndicator(
                          value: progress ?? 0,
                          minHeight: 22,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                        ),
                        Text(
                          '$_ticketsSold sold · $ticketsAvailable available',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SummaryRow(
                    label: 'Total capacity:',
                    value: totalCapacity.toString(),
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Tickets sold:',
                    value: _ticketsSold.toString(),
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Tickets available:',
                    value: ticketsAvailable.toString(),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tickets sold: $_ticketsSold',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF37474F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Capacity is not available for this event.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
}