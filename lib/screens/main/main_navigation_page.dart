import 'package:flutter/material.dart';
import 'package:best_rural_events_frontend/screens/main/tab/home_tab.dart';
import 'package:best_rural_events_frontend/screens/main/tab/profile_tab.dart';
import 'package:best_rural_events_frontend/screens/main/tab/search_tab.dart';
import 'tab/my_activity_page.dart';

// The screen the user sees after login
// this screen manages tab navigation, not page/screen navigation
class MainNavigationPage extends StatefulWidget {
  final String token;
  final String userId;
  final String email;

  const MainNavigationPage({
    super.key,
    required this.token,
    required this.userId,
    required this.email,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  //defines the selected tab
  int _selectedIndex = 0;

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  //method for the logic in the top bar display depending on the tab
  PreferredSizeWidget _buildAppBar() {
    const primaryGreen = Color(0xFF2E7D32);

    switch (_selectedIndex) {
      case 0:
        return AppBar(
          backgroundColor: Colors.white,
          foregroundColor: primaryGreen,
          elevation: 0,
          toolbarHeight: 80,
          title: Row(
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Best Rural Events',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case 4:
        return AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: primaryGreen,
          elevation: 0,
        );
      default:
        return AppBar(
          title: Text(_titleForIndex(_selectedIndex)),
          backgroundColor: Colors.white,
          foregroundColor: primaryGreen,
          elevation: 0,
        );
    }
  }

  //method for the texts in the bottom tab select options
  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'My Activity';
      case 3:
        return 'My Events';
      case 4:
        return 'Profile';
      default:
        return 'Best Rural Events';
    }
  }

  // method for the build of the different tabs actual body (using tab widgets )
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(
          token: widget.token,
          userId: widget.userId,
          email: widget.email,
        );
      case 1:
        return SearchTab(
          token: widget.token,
        );
      case 2:
        return const MyActivityPage();
      case 3:
        return const Center(child: Text('My Events page coming next'));
      case 4:
        return ProfileTab(
          token: widget.token,
          userId: widget.userId,
          email: widget.email,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  //Actual build method of the MainNavPage
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_outlined),
            activeIcon: Icon(Icons.local_activity),
            label: 'My Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}