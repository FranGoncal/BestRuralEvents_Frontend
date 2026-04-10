class EventReview {
  final String userName;
  final int rating;
  final String comment;

  EventReview({
    required this.userName,
    required this.rating,
    required this.comment,
  });

  factory EventReview.fromJson(Map<String, dynamic> json) {
    return EventReview(
      userName: json['userName'] as String? ?? 'Anonymous',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
    );
  }
}