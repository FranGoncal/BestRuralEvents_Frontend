import 'package:best_rural_events_frontend/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'services/session_service.dart';
import 'screens/main/main_navigation_page.dart';

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Background message: ${message.messageId}');
}

// Entry point of the whole Flutter app
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(initSettings);

  runApp(const BestRuralEventsApp());
}
class BestRuralEventsApp extends StatelessWidget {
  const BestRuralEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    _initApp();
  }

  Future<void> _initApp() async {
    _setupPush();
    await _checkSession();
  }

  Future<void> _setupPush() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Push permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    debugPrint('================ FCM TOKEN ================');
    debugPrint(token ?? 'NO TOKEN');
    debugPrint('===========================================');

    final session = await SessionService().getSession();

    if (session != null && token != null) {
      final authToken = session['token']!;
      final userId = session['userId']!;

      await NotificationService().registerDeviceToken(
        token: authToken,
        userId: userId,
        fcmToken: token,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      const androidDetails = AndroidNotificationDetails(
        'main_notifications',
        'Main Notifications',
        channelDescription: 'Notifications for Best Rural Events',
        importance: Importance.max,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await localNotifications.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
        payload: message.data.toString(),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
    });
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