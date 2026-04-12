
// event cards displayed in the main page home
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../screens/event/event_details_page.dart';


class EventCard extends StatelessWidget {
  final Event event;
  final String formattedDate;
  final String formattedPrice;
  final String token;

  const EventCard({
    required this.event,
    required this.formattedDate,
    required this.formattedPrice,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: lightGray),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              event.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event.location)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(formattedDate)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sell_outlined,
                        size: 18, color: primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsPage(event: event, token: token,),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                    ),
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}