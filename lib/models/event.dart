class Event {
  final int id;
  final String title;
  final String location;
  final DateTime date;
  final String imageUrl;
  final double price;
  final double averageRating;
  final int totalReviews;
  final String? description;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.price,
    required this.averageRating,
    required this.totalReviews,
    this.description,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      location: json['location'] as String,
      date: DateTime.parse(json['date'] as String),
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }
}