import 'package:flutter/material.dart';
import '../../../../models/event.dart';
import '../../../../services/event_service.dart';
import '../../../../widgets/event_card.dart';

class FavoritesTab extends StatefulWidget {
  final String token;

  const FavoritesTab({
    super.key,
    required this.token,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Event> _allFavorites = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _eventService.getFavoriteEvents(
      token: widget.token,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _allFavorites = result.events;
        _isLoading = false;
      });
    } else {
      setState(() {
        _allFavorites = [];
        _errorMessage = result.message;
        _isLoading = false;
      });

      _showMessage(
        result.message,
        backgroundColor: Colors.red,
      );
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

  void _applySearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<Event> get _filteredFavorites {
    if (_searchQuery.isEmpty) return _allFavorites;

    return _allFavorites.where((event) {
      return event.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
    final filteredFavorites = _filteredFavorites;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Favorite events',
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
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _applySearch(),
            decoration: InputDecoration(
              hintText: 'Search by event name',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _applySearch,
                icon: const Icon(Icons.arrow_forward),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
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
                borderSide: BorderSide(color: Color(0xFF2E7D32)),
              ),
            ),
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
                const Icon(
                  Icons.error_outline,
                  size: 42,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load favorite events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadFavorites,
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_allFavorites.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'You have no favorite events yet.',
                textAlign: TextAlign.center,
              ),
            )
          else if (filteredFavorites.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'No favorite events match your search.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...filteredFavorites.map(
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