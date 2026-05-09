import 'package:flutter/material.dart';

import '../../../../models/event_review.dart';
import '../../../../services/review_service.dart';
import '../../../../widgets/expandable_text.dart';

class ReviewsTab extends StatefulWidget {
  final String token;
  final String userId;

  const ReviewsTab({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  final ReviewService _reviewService = ReviewService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();

  List<EventReview> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _selectedEventDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  List<EventReview> get _filteredReviews {
    return _reviews.where((review) {
      final matchesSearch = review.eventName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      final eventDate = review.eventDate;

      final matchesDate =
          _selectedEventDate == null ||
              (eventDate != null &&
                  eventDate.year == _selectedEventDate!.year &&
                  eventDate.month == _selectedEventDate!.month &&
                  eventDate.day == _selectedEventDate!.day);

      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _reviewService.getMyReviews(
      token: widget.token,
      userId: widget.userId,
    );

    if (!mounted) return;

    setState(() {
      _reviews = result.reviews;
      _isLoading = false;
      _errorMessage = result.success ? null : result.message;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedEventDate = pickedDate;
        _eventDateController.text = _formatDate(pickedDate);
      });
    }
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) return 'Unknown date';

    final start = _formatDate(startDate);

    if (endDate == null) return start;

    final end = _formatDate(endDate);

    if (start == end) return start;

    return '$start - $end';
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedEventDate = null;
      _eventDateController.clear();
    });
  }

  Future<void> _removeReview(EventReview review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove review'),
          content: Text(
            'Are you sure you want to remove your review for "${review.eventName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await _reviewService.deleteReview(
      token: widget.token,
      userId: widget.userId,
      reviewId: review.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _reviews.removeWhere((r) => r.id == review.id);
      });
    }

    _showMessage(
      result.message,
      backgroundColor: result.success ? Colors.green : Colors.red,
    );
  }

  Future<void> _updateReview({
    required EventReview review,
    required int newRating,
    required String newComment,
  }) async {
    final result = await _reviewService.updateReview(
      token: widget.token,
      userId: widget.userId,
      reviewId: review.id,
      eventId: review.eventId,
      rating: newRating,
      comment: newComment,
    );

    if (!mounted) return;

    if (result.success && result.review != null) {
      setState(() {
        final index = _reviews.indexWhere((r) => r.id == review.id);
        if (index != -1) {
          _reviews[index] = result.review!;
        }
      });
    }

    _showMessage(
      result.message,
      backgroundColor: result.success ? Colors.green : Colors.red,
    );
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    final filteredReviews = _filteredReviews;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Reviews I wrote',
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
                onSubmitted: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Search by event name',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search),
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
                    borderSide: BorderSide(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Event date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEventDate,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _eventDateController,
                          decoration: InputDecoration(
                            hintText: 'Select date',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            suffixIcon:
                            const Icon(Icons.calendar_today_outlined),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
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
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Filter'),
                  ),
                ],
              ),

              if (_selectedEventDate != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearDateFilter,
                    child: const Text('Clear date filter'),
                  ),
                ),
              ],
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
                const Icon(Icons.error_outline, color: Colors.red, size: 42),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadReviews,
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (filteredReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'No reviews found.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ...filteredReviews.map(
                  (review) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ReviewCard(
                  review: review,
                  formattedDate: _formatDateRange(
                    review.eventStartDate,
                    review.eventEndDate,
                  ),
                  onRemove: () => _removeReview(review),
                  onUpdate: (newRating, newComment) {
                    _updateReview(
                      review: review,
                      newRating: newRating,
                      newComment: newComment,
                    );
                  },
                ),
              ),
            ),
      ],
    );
  }
}

class ReviewCard extends StatefulWidget {
  final EventReview review;
  final String formattedDate;
  final VoidCallback onRemove;
  final void Function(int rating, String comment) onUpdate;

  const ReviewCard({
    super.key,
    required this.review,
    required this.formattedDate,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late bool _isEditing;
  late int _editedRating;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _editedRating = widget.review.rating;
    _commentController = TextEditingController(text: widget.review.comment);
  }

  @override
  void didUpdateWidget(covariant ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.review.id != widget.review.id ||
        oldWidget.review.comment != widget.review.comment ||
        oldWidget.review.rating != widget.review.rating) {
      _editedRating = widget.review.rating;
      _commentController.text = widget.review.comment;
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editedRating = widget.review.rating;
      _commentController.text = widget.review.comment;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editedRating = widget.review.rating;
      _commentController.text = widget.review.comment;
    });
  }

  void _submitUpdate() {
    final updatedComment = _commentController.text.trim();

    if (updatedComment.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review text cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onUpdate(_editedRating, updatedComment);

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Container(
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
            widget.review.eventName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Event date: ${widget.formattedDate}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          _isEditing
              ? EditableStarRating(
            initialRating: _editedRating,
            onRatingChanged: (value) {
              setState(() {
                _editedRating = value;
              });
            },
          )
              : StarRating(rating: widget.review.rating),

          const SizedBox(height: 10),

          Text(
            'Your review',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          if (_isEditing)
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Edit your review',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(12),
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ExpandableText(
                text: widget.review.comment.isEmpty
                    ? 'No comment.'
                    : widget.review.comment,
                maxLines: 3,
              ),
            ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isEditing ? _cancelEditing : widget.onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isEditing ? 'Cancel' : 'Remove'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isEditing ? _submitUpdate : _startEditing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isEditing ? 'Update' : 'Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;

  const StarRating({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 24,
        );
      }),
    );
  }
}

class EditableStarRating extends StatelessWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;

  const EditableStarRating({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;

        return IconButton(
          onPressed: () => onRatingChanged(starValue),
          icon: Icon(
            index < initialRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }),
    );
  }
}