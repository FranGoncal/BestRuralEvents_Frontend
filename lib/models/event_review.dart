class EventReview {
  final int id;
  final int eventId;
  final String userId;
  final String userName;
  final String eventName;
  final DateTime? eventDate;
  final int rating;
  final String comment;
  final DateTime createdAt;

  EventReview({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.eventName,
    required this.eventDate,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory EventReview.fromJson(Map<String, dynamic> json) {
    return EventReview(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      userId: json['userId'].toString(),

      // Add this:
      userName: json['userName']?.toString() ?? 'User ${json['userId']}',

      eventName: json['eventName']?.toString() ?? 'Event #${json['eventId']}',
      eventDate: json['eventDate'] == null
          ? null
          : DateTime.parse(json['eventDate'].toString()),
      rating: json['rating'] as int,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }

  EventReview copyWith({
    int? rating,
    String? comment,
  }) {
    return EventReview(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      eventName: eventName,
      eventDate: eventDate,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt,
    );
  }
}