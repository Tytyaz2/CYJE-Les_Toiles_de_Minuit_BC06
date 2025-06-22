import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/EventPage.dart';
import 'pages/AdminDashboardPage.dart';
import 'pages/OrganizerDashboardPage.dart';
import 'pages/AccessDeniedPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/events': (context) => const EventsPage(), // utilisateur normal
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/organizer_dashboard': (context) => const OrganizerDashboardPage(),
        '/access_denied': (context) => const AccessDeniedPage(),
      },
    );
  }
}
