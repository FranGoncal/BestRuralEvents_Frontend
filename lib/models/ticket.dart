import 'event.dart';

class Ticket {
  final String id;

  // Original user-ticket fields
  final Event event;
  final double price;
  final String refundRules;
  final DateTime purchaseDate;
  final bool canCancel;
  final bool canReview;

  // Event management fields
  final int quantity;
  final String customerName;
  final String customerEmail;
  final DateTime? createdAt;
  final String status;

  const Ticket({
    required this.id,
    required this.event,
    required this.price,
    required this.refundRules,
    required this.purchaseDate,
    required this.canCancel,
    required this.canReview,
    required this.quantity,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.status,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      event: json['event'] is Map<String, dynamic>
          ? Event.fromJson(json['event'] as Map<String, dynamic>)
          : _emptyEvent(),
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : 0.0,
      refundRules: json['refundRules']?.toString() ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now()),
      canCancel: json['canCancel'] as bool? ?? false,
      canReview: json['canReview'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
    );
  }

  static Event _emptyEvent() {
    return Event(
      id: 0,
      title: '',
      location: '',
      date: DateTime.now(),
      imageUrl: '',
      price: 0.0,
      averageRating: 0.0,
      totalReviews: 0,
      description: null,
    );
  }
}