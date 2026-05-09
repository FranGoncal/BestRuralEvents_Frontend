class EventReview {
  final int id;
  final int eventId;
  final int userId;
  final String userName;
  final String eventName;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  EventReview({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.eventName,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  DateTime? get eventDate => eventStartDate; // temporary compatibility

  factory EventReview.fromJson(Map<String, dynamic> json) {
    return EventReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName']?.toString() ?? 'Unknown user',
      eventName: json['eventName']?.toString() ?? 'Unknown event',
      eventStartDate: DateTime.tryParse(
        json['eventStartDate']?.toString() ??
            json['eventDate']?.toString() ??
            '',
      ),
      eventEndDate: DateTime.tryParse(
        json['eventEndDate']?.toString() ??
            json['eventStartDate']?.toString() ??
            json['eventDate']?.toString() ??
            '',
      ),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}