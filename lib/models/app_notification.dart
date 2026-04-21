class AppNotification {
  final String id;
  final String title;
  final String text;
  final DateTime time;

  AppNotification({
    required this.id,
    required this.title,
    required this.text,
    required this.time,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      time: DateTime.parse(json['time']),
    );
  }
}