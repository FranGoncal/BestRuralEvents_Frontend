class EventTicket {
  final String id;
  final int quantity;
  final String customerName;
  final String customerEmail;
  final DateTime? createdAt;
  final String status;

  const EventTicket({
    required this.id,
    required this.quantity,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.status,
  });

  factory EventTicket.fromJson(Map<String, dynamic> json) {
    return EventTicket(
      id: json['id'].toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
    );
  }
}
