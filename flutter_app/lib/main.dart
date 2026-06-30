import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'home/home_page.dart';
import 'home/dashboard_page.dart';
import 'microcontrollers/pin_mapping_page.dart';
import 'network_scanner/network_scanner_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/microcontrollers': (context) => const PinMappingPage(),
        '/network_scanner': (context) => const NetworkScannerPage(),
      },
    );
  }
}
