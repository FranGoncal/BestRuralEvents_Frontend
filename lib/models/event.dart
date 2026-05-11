import '../config/app_config.dart';

class EventDayCapacity {
  final DateTime date;
  final int capacity;

  EventDayCapacity({
    required this.date,
    required this.capacity,
  });

  factory EventDayCapacity.fromJson(Map<String, dynamic> json) {
    return EventDayCapacity(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class Event {
  final int id;
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls;
  final double price;
  final double averageRating;
  final int totalReviews;
  final String? description;

  final String ticketMode;
  final int capacity;
  final List<EventDayCapacity> dailyCapacities;

  final bool refundable;
  final int? refundDeadlineDays;
  final String? refundPolicy;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.imageUrls,
    required this.price,
    required this.averageRating,
    required this.totalReviews,
    this.description,
    required this.ticketMode,
    required this.capacity,
    required this.dailyCapacities,
    required this.refundable,
    this.refundDeadlineDays,
    this.refundPolicy,
  });

  DateTime get date => startDate;

  bool get isEventPass => ticketMode == 'EVENT_PASS';
  bool get isPerDay => ticketMode == 'PER_DAY';

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = json['images'];

    List<String> imageUrls = [];

    if (images is List) {
      imageUrls = images.map((item) {
        final rawUrl = item.toString();

        if (rawUrl.startsWith('http')) return rawUrl;

        return '${AppConfig.baseUrl}$rawUrl';
      }).toList();
    }

    if (imageUrls.isEmpty) {
      final fallback = json['imageUrl']?.toString() ?? '';

      if (fallback.isNotEmpty) {
        imageUrls = [
          fallback.startsWith('http')
              ? fallback
              : '${AppConfig.baseUrl}$fallback',
        ];
      }
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

    final dailyCapacitiesJson = json['dailyCapacities'];

    final dailyCapacities = dailyCapacitiesJson is List
        ? dailyCapacitiesJson
        .whereType<Map<String, dynamic>>()
        .map(EventDayCapacity.fromJson)
        .toList()
        : <EventDayCapacity>[];

    return Event(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Untitled event',
      location: json['location']?.toString() ?? 'Location unavailable',
      startDate: parsedStartDate ?? DateTime.now(),
      endDate: parsedEndDate ?? parsedStartDate ?? DateTime.now(),
      imageUrls: imageUrls,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),

      ticketMode: json['ticketMode']?.toString() ?? 'EVENT_PASS',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      dailyCapacities: dailyCapacities,

      refundable: json['refundable'] as bool? ?? false,
      refundDeadlineDays: (json['refundDeadlineDays'] as num?)?.toInt(),
      refundPolicy: json['refundPolicy']?.toString(),
    );
  }
}