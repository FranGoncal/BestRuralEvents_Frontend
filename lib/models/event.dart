import '../config/app_config.dart';

class Event {
  final int id;
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final double price;
  final double averageRating;
  final int totalReviews;
  final String? description;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.price,
    required this.averageRating,
    required this.totalReviews,
    this.description,
  });

  DateTime get date => startDate; // temporary compatibility

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = json['images'];

    String imageUrl = '';

    if (images is List && images.isNotEmpty) {
      final rawUrl = images.first.toString();

      if (rawUrl.startsWith('http')) {
        imageUrl = rawUrl;
      } else {
        imageUrl = '${AppConfig.baseUrl}$rawUrl';
      }
    } else {
      imageUrl = json['imageUrl']?.toString() ?? '';
    }

    final parsedStartDate = DateTime.tryParse(
      json['startDate']?.toString() ??
          json['date']?.toString() ??
          '',
    );

    final parsedEndDate = DateTime.tryParse(
      json['endDate']?.toString() ??
          json['startDate']?.toString() ??
          json['date']?.toString() ??
          '',
    );

    return Event(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Untitled event',
      location: json['location']?.toString() ?? 'Location unavailable',
      startDate: parsedStartDate ?? DateTime.now(),
      endDate: parsedEndDate ?? parsedStartDate ?? DateTime.now(),
      imageUrl: imageUrl,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
    );
  }
}