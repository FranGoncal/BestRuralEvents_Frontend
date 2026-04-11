//Flutter s Material Design widgets
import 'package:flutter/material.dart';
//Login screen (first screen)
import 'screens/auth/login_page.dart';

import 'services/session_service.dart';
import 'screens/main/main_navigation_page.dart';

//Entry point of the whole Flutter app

//first function run
void main() {
  //runApp lauching root Widget (top level)
  runApp(const BestRuralEventsApp());
}

//Whole app = this class, stateless -> this widget does not manage changing data
class BestRuralEventsApp extends StatelessWidget {
  //constructure
  const BestRuralEventsApp({super.key});

  //build describes what the widget should look like
  @override
  Widget build(BuildContext context) {
    //main App container
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Best Rural Events',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      //first screen shown
      home: const SessionDeciderPage(),
    );
  }
}




class SessionDeciderPage extends StatefulWidget {
  const SessionDeciderPage({super.key});

  @override
  State<SessionDeciderPage> createState() => _SessionDeciderPageState();
}

class _SessionDeciderPageState extends State<SessionDeciderPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await SessionService().getSession();

    if (!mounted) return;

    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationPage(
            token: session['token']!,
            userId: session['userId']!,
            email: session['email']!,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}