import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/event.dart';
import '../../../services/event_service.dart';
import '../../../widgets/event_card.dart';

class SearchTab extends StatefulWidget {
  final String token;
  final String userId;

  const SearchTab({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final EventService _eventService = EventService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<Event> _events = [];

  bool _hasSearched = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  int _currentPage = 0;
  final int _pageSize = 10;

  String? _errorMessage;

  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String? _activityType;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _activityTypes = const [
    'Rural',
    'Cultural',
    'Food',
    'Music',
    'Workshop',
    'Market',
    'Tradition',
    'Nature',
    'Family',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isSearching || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _hasSearched = true;
      _isSearching = true;
      _isLoadingMore = false;
      _currentPage = 0;
      _events = [];
      _hasMore = false;
      _errorMessage = null;
    });

    final result = await _eventService.searchEvents(
      token: widget.token,
      query: _searchController.text.trim(),
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      activityType: _activityType,
      startDate: _startDate,
      endDate: _endDate,
      page: 0,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _isSearching = false;

      if (result.success) {
        _events = result.events;
        _currentPage = result.page;
        _hasMore = result.hasMore;
      } else {
        _errorMessage = result.message;
      }
    });
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    final result = await _eventService.searchEvents(
      token: widget.token,
      query: _searchController.text.trim(),
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      activityType: _activityType,
      startDate: _startDate,
      endDate: _endDate,
      page: _currentPage + 1,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;

      if (result.success) {
        _events.addAll(result.events);
        _currentPage = result.page;
        _hasMore = result.hasMore;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _activityType = null;
      _startDate = null;
      _endDate = null;
      _events = [];
      _hasSearched = false;
      _hasMore = false;
      _errorMessage = null;
      _currentPage = 0;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatEventDate(Event event) {
    return DateFormat('dd MMM yyyy').format(event.date);
  }

  String _formatEventPrice(Event event) {
    if (event.price <= 0) {
      return 'Free';
    }
    return '€${event.price.toStringAsFixed(2)}';
  }

  Widget _buildSearchHeader() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search events',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _openFiltersSheet,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildActiveFilterChips(),
      ],
    );
  }

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_minPrice != null || _maxPrice != null) {
      chips.add(_filterChip(
        label: '€ ${_minPrice?.toStringAsFixed(0) ?? '0'} - ${_maxPrice?.toStringAsFixed(0) ?? '∞'}',
        onDeleted: () {
          setState(() {
            _minPrice = null;
            _maxPrice = null;
            _minPriceController.clear();
            _maxPriceController.clear();
          });
        },
      ));
    }

    if (_minRating != null) {
      chips.add(_filterChip(
        label: '${_minRating!.toStringAsFixed(1)}+ stars',
        onDeleted: () {
          setState(() {
            _minRating = null;
          });
        },
      ));
    }

    if (_activityType != null) {
      chips.add(_filterChip(
        label: _activityType!,
        onDeleted: () {
          setState(() {
            _activityType = null;
          });
        },
      ));
    }

    if (_startDate != null || _endDate != null) {
      chips.add(_filterChip(
        label: '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
        onDeleted: () {
          setState(() {
            _startDate = null;
            _endDate = null;
          });
        },
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _openFiltersSheet() {
    final minPriceController =
    TextEditingController(text: _minPrice?.toString() ?? '');
    final maxPriceController =
    TextEditingController(text: _maxPrice?.toString() ?? '');

    double? tempMinPrice = _minPrice;
    double? tempMaxPrice = _maxPrice;
    double? tempMinRating = _minRating;
    String? tempActivityType = _activityType;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate(bool isStart) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isStart
                    ? (tempStartDate ?? DateTime.now())
                    : (tempEndDate ?? tempStartDate ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked == null) return;

              setModalState(() {
                if (isStart) {
                  tempStartDate = picked;
                  if (tempEndDate != null && tempEndDate!.isBefore(tempStartDate!)) {
                    tempEndDate = tempStartDate;
                  }
                } else {
                  tempEndDate = picked;
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Min price',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              tempMinPrice = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Max price',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              tempMaxPrice = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<double>(
                      value: tempMinRating,
                      decoration: InputDecoration(
                        labelText: 'Minimum rating',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1.0, child: Text('1.0+')),
                        DropdownMenuItem(value: 2.0, child: Text('2.0+')),
                        DropdownMenuItem(value: 3.0, child: Text('3.0+')),
                        DropdownMenuItem(value: 4.0, child: Text('4.0+')),
                        DropdownMenuItem(value: 4.5, child: Text('4.5+')),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempMinRating = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempActivityType,
                      decoration: InputDecoration(
                        labelText: 'Activity type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _activityTypes
                          .map(
                            (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempActivityType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('From: ${_formatDate(tempStartDate)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(false),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('To: ${_formatDate(tempEndDate)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _minPrice = null;
                                _maxPrice = null;
                                _minRating = null;
                                _activityType = null;
                                _startDate = null;
                                _endDate = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _minPrice = tempMinPrice;
                                _maxPrice = tempMaxPrice;
                                _minRating = tempMinRating;
                                _activityType = tempActivityType;
                                _startDate = tempStartDate;
                                _endDate = tempEndDate;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Choose your filters and tap Search to see events.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(
        child: Text(
          'No events found.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _events.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _events.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final event = _events[index];

        return EventCard(
          event: event,
          formattedDate: _formatEventDate(event),
          formattedPrice: _formatEventPrice(event),
          token: widget.token,
          userId: widget.userId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            _buildSearchHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }
}