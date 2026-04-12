import 'event.dart';

class Ticket {
  final String id;
  final Event event;
  final double price;
  final String refundRules;
  final DateTime purchaseDate;
  final bool canCancel;
  final bool canReview;

  const Ticket({
    required this.id,
    required this.event,
    required this.price,
    required this.refundRules,
    required this.purchaseDate,
    required this.canCancel,
    required this.canReview,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      price: (json['price'] as num).toDouble(),
      refundRules: json['refundRules']?.toString() ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate'].toString()),
      canCancel: json['canCancel'] as bool? ?? false,
      canReview: json['canReview'] as bool? ?? false,
    );
  }
}