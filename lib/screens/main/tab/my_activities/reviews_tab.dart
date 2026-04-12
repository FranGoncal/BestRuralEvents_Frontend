import 'package:flutter/material.dart';
import '../../../../widgets/expandable_text.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();

  DateTime? _selectedEventDate;

  final List<UserReview> _reviews = [
    UserReview(
      id: '1',
      eventName: 'Medieval Fair at the Castle',
      eventDate: DateTime(2024, 10, 14),
      rating: 5,
      comment: 'Loved the atmosphere, but it was very cold at night.',
    ),
    UserReview(
      id: '2',
      eventName: 'Medieval Fair in Alcains',
      eventDate: DateTime(2024, 9, 15),
      rating: 5,
      comment: 'Great food and music, would visit again.',
    ),
    UserReview(
      id: '3',
      eventName: 'Autumn Wine Festival',
      eventDate: DateTime(2024, 11, 2),
      rating: 4,
      comment:
      'Very well organized event with lots of local products. The lines were a bit long at some stands, but overall it was a great experience and I would recommend it.',
    ),
  ];

  String _searchQuery = '';

  List<UserReview> get _filteredReviews {
    return _reviews.where((review) {
      final matchesSearch = review.eventName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      final matchesDate =
          _selectedEventDate == null ||
              (review.eventDate.year == _selectedEventDate!.year &&
                  review.eventDate.month == _selectedEventDate!.month &&
                  review.eventDate.day == _selectedEventDate!.day);

      return matchesSearch && matchesDate;
    }).toList();
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

  Future<void> _removeReview(UserReview review) async {
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

    if (confirm == true) {
      setState(() {
        _reviews.removeWhere((r) => r.id == review.id);
      });

      _showMessage('Review removed', backgroundColor: Colors.red);
    }
  }

  void _updateReview({
    required String reviewId,
    required int newRating,
    required String newComment,
  }) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    setState(() {
      _reviews[index] = _reviews[index].copyWith(
        rating: newRating,
        comment: newComment,
      );
    });

    _showMessage('Review updated', backgroundColor: Colors.green);
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
                            suffixIcon: const Icon(Icons.calendar_today_outlined),
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

        if (filteredReviews.isEmpty)
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
                formattedDate: _formatDate(review.eventDate),
                onRemove: () => _removeReview(review),
                onUpdate: (newRating, newComment) {
                  _updateReview(
                    reviewId: review.id,
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
  final UserReview review;
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
                text: widget.review.comment,
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

class UserReview {
  final String id;
  final String eventName;
  final DateTime eventDate;
  final int rating;
  final String comment;

  UserReview({
    required this.id,
    required this.eventName,
    required this.eventDate,
    required this.rating,
    required this.comment,
  });

  UserReview copyWith({
    String? id,
    String? eventName,
    DateTime? eventDate,
    int? rating,
    String? comment,
  }) {
    return UserReview(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }
}