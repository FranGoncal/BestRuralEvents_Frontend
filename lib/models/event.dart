// This class represents a single "Event" object (structured way to represent an Event)
class Event {

  final int id;
  final String title;
  final String location;
  final DateTime date;
  final String imageUrl;
  final double price;
  final double averageRating;
  final int totalReviews;
  // optional
  final String? description;

  // Constructor used to create a new Event object manually
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

  // Factory method is used to create an Event from JSON
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