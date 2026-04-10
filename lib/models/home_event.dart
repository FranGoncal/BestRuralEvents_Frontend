class HomeEvent {
  final int id;
  final String title;
  final String location;
  final DateTime date;
  final String imageUrl;
  final double price;

  HomeEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.price,
  });

  factory HomeEvent.fromJson(Map<String, dynamic> json) {
    return HomeEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      location: json['location'] as String,
      date: DateTime.parse(json['date'] as String),
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}