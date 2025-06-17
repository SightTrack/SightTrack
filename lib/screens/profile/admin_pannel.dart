import 'package:flutter/material.dart';

class AdminPannelScreen extends StatelessWidget {
  const AdminPannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: const Center(
        child: Text('Admin Panel Screen Placeholder'),
      ),
    );
  }
}