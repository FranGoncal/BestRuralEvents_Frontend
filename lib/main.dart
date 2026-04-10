//Flutter s Material Design widgets
import 'package:flutter/material.dart';
//Login screen (first screen)
import 'screens/auth/login_page.dart';

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
      home: const LoginPage(),
    );
  }
}