import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/event_review.dart';
import '../../services/event_service.dart';
import '../../widgets/expandable_text.dart';
import '../ticket/buy_ticket_page.dart';

class EventDetailsPage extends StatefulWidget {
  // Data passed INTO this page from previous screen
  final Event event;
  final String token;

  const EventDetailsPage({
    super.key,
    required this.event,
    required this.token,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  // Service responsible for API calls related to events to the backend
  final EventService _eventService = EventService();

  bool _isFavoriteLoading = true; // loading spinner for favorite
  bool _isFavorite = false; // actual favorite state

  bool _isReviewsLoading = true;
  List<EventReview> _reviews = [];

  // Error handling
  String? _favoriteError;
  String? _reviewsError;

  // Prevents multiple clicks while request is running
  bool _isTogglingFavorite = false;

  //runs once the page opens
  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  //used to load data from different resources
  Future<void> _loadExtraData() async {
    await _loadFavorite();
    await _loadReviews();
  }

  Future<void> _loadFavorite() async {
    try {
      final isFavorite = await _eventService.getIsFavorite(
        token: widget.token,
        eventId: widget.event.id,
      );

      if (!mounted) return;

      setState(() {
        _isFavorite = isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _favoriteError = 'Could not load favorite status';
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _eventService.getReviews(
        token: widget.token,
        eventId: widget.event.id,
      );

      if (!mounted) return;

      setState(() {
        _reviews = reviews;
        _isReviewsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _reviewsError = 'Could not load reviews';
        _isReviewsLoading = false;
      });
    }
  }

  // toggle this event fav (calls event service which calls the backend)
  Future<void> _toggleFavorite() async {

    //preventing multiple requests
    if (_isTogglingFavorite) return;
    setState(() {
      _isTogglingFavorite = true;
    });

    bool success = false;

    // If already fav, remove, else add
    if (_isFavorite) {
      success = await _eventService.removeFavorite(
        token: widget.token,
        eventId: widget.event.id,
      );
    } else {
      success = await _eventService.addFavorite(
        token: widget.token,
        eventId: widget.event.id,
      );
    }

    // async safety
    if (!mounted) return;

    //update screen depending on result
    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isTogglingFavorite = false;
      });
    } else {
      setState(() {
        _isTogglingFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favorite'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //Converts DateTime into readable string
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // if price is 0 then its Free, else it is a Euro char + value
  String _formatPrice(double price) {
    if (price == 0) return 'Free';
    return '€${price.toStringAsFixed(2)}';
  }

  //builds UI rating stars
  Widget _buildStars(double rating) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        //if its less than the total rating, use full star icon
        if (index < fullStars) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        }
        //if it is the last start and there is a half star, half star
        if (index == fullStars && hasHalf) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        }
        //else empty star
        return const Icon(Icons.star_border, size: 18, color: Colors.amber);
      }),
    );
  }

  // page structure
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event details'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.event.imageUrl,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              //fallback in case there is no img
              errorBuilder: (_, __, ___) {
                return Container(
                  width: double.infinity,
                  height: 240,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isFavoriteLoading)
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          onPressed: _isTogglingFavorite ? null : _toggleFavorite,
                          icon: _isTogglingFavorite
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildStars(widget.event.averageRating),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.event.averageRating.toStringAsFixed(1)} (${widget.event.totalReviews})',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: lightGray),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          offset: Offset(0, 4),
                          color: Color(0x14000000),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.event.location,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(widget.event.date),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.sell_outlined,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatPrice(widget.event.price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'About this event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ExpandableText(
                    text: widget.event.description ?? 'No description available.',
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final bookingDone = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyTicketPage(
                              event: widget.event,
                              token: widget.token,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        if (bookingDone == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking completed successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isReviewsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reviewsError != null)
                    Text(
                      _reviewsError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (_reviews.isEmpty)
                      const Text('No reviews yet.')
                    else
                      ..._reviews.map((review) => _ReviewCard(review: review)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//widget used only in this page, for single review representation
class _ReviewCard extends StatelessWidget {
  final EventReview review;

  const _ReviewCard({
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(review.comment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}