import 'package:flutter/material.dart';
import 'package:omm_admin/dashboard.dart';
import 'package:omm_admin/events/festival_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardPage(), // Our main screen for events
    );
  }
}
