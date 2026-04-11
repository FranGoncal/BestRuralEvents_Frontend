//Flutter s Material Design (gives you widgets like MaterialApp, Scaffold, Center, Text, buttons ...)
import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'services/session_service.dart';
import 'screens/main/main_navigation_page.dart';

//Entry point of the whole Flutter app

// This is the App's entry point
// The app starts running here first
void main() {
  //runApp lauching root Widget (top level)
  runApp(const BestRuralEventsApp());
}



// root widget of the whole app,
// stateless -> this widget itself does NOT store changing state
class BestRuralEventsApp extends StatelessWidget {
  //Constructor
  const BestRuralEventsApp({super.key});

  //build describes what the widget should display on screen
  //Flutter calls build() when it needs to render the widget
  @override
  Widget build(BuildContext context) {
    //main App container
    // It sets global app configuration like theme, title...
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Best Rural Events',
      theme: ThemeData(
        // Material Design 3 styling
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      // first screen shown
      // Instead of going directly to LoginPage,
      // it first opens SessionDeciderPage to check if the user is already logged in
      home: const SessionDeciderPage(),
    );
  }
}




// This widget decides which screen to show:
// - MainNavigationPage if the user already has a saved session
// - LoginPage if the user is not logged in
//
// Must be stateful because it runs async code after it appears
class SessionDeciderPage extends StatefulWidget {
  const SessionDeciderPage({super.key});

  @override
  State<SessionDeciderPage> createState() => _SessionDeciderPageState();
}

// logic and mutable behavior for SessionDeciderPage widget
class _SessionDeciderPageState extends State<SessionDeciderPage> {
  @override
  void initState() {
    super.initState();
    //checking login/session
    _checkSession();
  }

  // This async function checks whether a saved user session exists
  Future<void> _checkSession() async {
    // "await" means: pause this function until getSession() finishes
    final session = await SessionService().getSession();

    // After awaiting async code, the widget might already be removed from the screen.
    // "mounted" checks whether this State object is still active in the widget tree.
    //
    // If it's no longer mounted, using context would cause errors.
    if (!mounted) return;

    // If session exists, the user is already logged in.
    if (session != null) {
      // Goes to the main page
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
      // Goes to to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  // While the session is being checked, showing a simple loading screen
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}