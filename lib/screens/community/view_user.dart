import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class ViewUserScreen extends StatefulWidget {
  final User user;

  const ViewUserScreen({super.key, required this.user});

  @override
  State<ViewUserScreen> createState() => _ViewUserScreenState();
}

class _ViewUserScreenState extends State<ViewUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(widget.user.school ?? 'No school')),
    );
  }
}
