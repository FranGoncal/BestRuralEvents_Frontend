import 'package:flutter/material.dart';
import 'my_activities/tickets_tab.dart';
import 'my_activities/favorites_tab.dart';
import 'my_activities/reviews_tab.dart';

class MyActivityPage extends StatelessWidget {
  const MyActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16), // less circular
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12), // smaller radius
              ),
              labelColor: primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab, // makes it fill tab width
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Tickets'),
                Tab(text: 'Favorites'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: TabBarView(
              children: [
                TicketsTab(),
                FavoritesTab(),
                ReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}