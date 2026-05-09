import 'package:best_rural_events_frontend/services/ticket_service.dart';
import 'package:flutter/material.dart';
import '../../../../models/ticket.dart';
import '../../../../services/review_service.dart';
import '../../../../widgets/qr_code_dialog.dart';
import '../../../event/event_details_page.dart';

class TicketsTab extends StatefulWidget {
  final String token;
  final String userId;

  const TicketsTab({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final TicketService _ticketService = TicketService();
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();


  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _ticketService.getUserTickets(
      token: widget.token,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _tickets = result.tickets;
        _isLoading = false;
      });
    } else {
      setState(() {
        _tickets = [];
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

  Future<void> _pickDate({
    required bool isFromDate,
  }) async {
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

  List<Ticket> get _filteredTickets {
    return _tickets.where((ticket) {
      final matchesSearch = ticket.event.title
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final purchaseDate = DateTime(
        ticket.purchaseDate.year,
        ticket.purchaseDate.month,
        ticket.purchaseDate.day,
      );

      final matchesFrom = _fromDate == null ||
          !purchaseDate.isBefore(
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
          );

      final matchesTo = _toDate == null ||
          !purchaseDate.isAfter(
            DateTime(_toDate!.year, _toDate!.month, _toDate!.day),
          );

      return matchesSearch && matchesFrom && matchesTo;
    }).toList();
  }

  Future<void> _showRateDialog(Ticket ticket) async {
    int selectedRating = 5;
    final commentController = TextEditingController();
    String? commentError;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate "${ticket.event.title}"'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = value;
                            });
                          },
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) {
                        if (commentError != null) {
                          setDialogState(() {
                            commentError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Write your review',
                        errorText: commentError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final comment = commentController.text.trim();

                    if (comment.isEmpty) {
                      setDialogState(() {
                        commentError = 'Please write a review comment.';
                      });
                      return;
                    }

                    Navigator.pop(context, true);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) return;

    final comment = commentController.text.trim();

    final result = await _reviewService.createReview(
      token: widget.token,
      userId: widget.userId,
      eventId: ticket.event.id,
      rating: selectedRating,
      comment: comment,
    );

    if (!mounted) return;

    _showMessage(
      result.message,
      backgroundColor: result.success ? Colors.green : Colors.red,
    );

    if (result.success) {
      _loadTickets();
    }
  }

  Future<void> _cancelTicket(Ticket ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel ticket'),
          content: Text(
            'Are you sure you want to cancel your ticket for "${ticket.event.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await _ticketService.cancelTicket(
      token: widget.token,
      ticketId: ticket.id,
      userId: widget.userId
    );

    if (!mounted) return;

    if (success) {
      _showMessage('Ticket cancelled successfully.', backgroundColor: Colors.green);
      _loadTickets();
    } else {
      _showMessage('Could not cancel ticket.', backgroundColor: Colors.red);
    }
  }

  Future<void> _viewTicket(Ticket ticket) async {

    final result = await _ticketService.validateTicketForQr(
      token: widget.token,
      ticketId: ticket.id,
    );

    if (!mounted) return;

    if (!result.success) {
      _showMessage(result.message, backgroundColor: Colors.red);
      return;
    }

    if (!result.valid || result.qrToken == null || result.qrToken!.isEmpty) {
      _showMessage(
        result.message.isNotEmpty ? result.message : 'This ticket is not valid.',
        backgroundColor: Colors.red,
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => TicketQrDialog(
        ticket: ticket,
        qrToken: result.qrToken!,
        formattedPurchaseDate: _formatDate(ticket.purchaseDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    final tickets = _filteredTickets;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Tickets purchased',
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
                'Tickets bought between:',
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
                  'Could not load tickets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadTickets,
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_tickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'You have not purchased any tickets yet.',
                textAlign: TextAlign.center,
              ),
            )
          else if (tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'No tickets match your filters.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...tickets.map(
                    (ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TicketCard(
                    ticket: ticket,
                    token: widget.token,
                    userId: widget.userId,
                    formattedPrice: _formatPrice(ticket.price),
                    formattedPurchaseDate: _formatDate(ticket.purchaseDate),
                    onRate: ticket.canReview
                        ? () => _showRateDialog(ticket)
                        : null,
                    onViewTicket: () => _viewTicket(ticket),
                    onCancel: ticket.canCancel
                        ? () => _cancelTicket(ticket)
                        : null,
                  ),
                ),
              ),
      ],
    );
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final String token;
  final String userId;
  final String formattedPrice;
  final String formattedPurchaseDate;
  final VoidCallback? onRate;
  final VoidCallback onViewTicket;
  final VoidCallback? onCancel;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.token,
    required this.userId,
    required this.formattedPrice,
    required this.formattedPurchaseDate,
    required this.onRate,
    required this.onViewTicket,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

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
              ticket.event.imageUrls.isNotEmpty ? ticket.event.imageUrls.first : '',
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
                    ticket.event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$formattedPrice · ${ticket.refundRules}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Purchase date: $formattedPurchaseDate',
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
                _ActionButton(
                  label: 'Rate this event',
                  onPressed: onRate,
                  isPrimary: false,
                  isEnabled: onRate != null,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'View ticket',
                  onPressed: onViewTicket,
                  isPrimary: false,
                  isEnabled: true,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Event details',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsPage(
                          event: ticket.event,
                          token: token,
                          userId: userId,

                        ),
                      ),
                    );
                  },
                  isPrimary: false,
                  isEnabled: true,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Cancel',
                  onPressed: onCancel,
                  isPrimary: false,
                  isEnabled: onCancel != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isEnabled;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 34,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isEnabled ? primaryGreen : Colors.grey.shade500,
          side: BorderSide(
            color: isEnabled ? primaryGreen : Colors.grey.shade400,
          ),
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