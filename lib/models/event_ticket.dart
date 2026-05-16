class EventTicket {
  final String id;
  final int quantity;
  final String customerName;
  final String customerEmail;
  final DateTime? createdAt;
  final String status;

  final List<DateTime> selectedDays;

  const EventTicket({
    required this.id,
    required this.quantity,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.status,
    required this.selectedDays,
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
      selectedDays: json['selectedDays'] is List
          ? (json['selectedDays'] as List)
          .map((day) => DateTime.parse(day.toString()))
          .toList()
          : [],
    );
  }

  String get selectedDaysText {
    if (selectedDays.isEmpty) return 'Full event pass';

    return selectedDays.map((date) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month';
    }).join(', ');
  }
}