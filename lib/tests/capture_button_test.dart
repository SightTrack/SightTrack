import 'package:flutter/material.dart';

class CaptureButtonTest extends StatefulWidget {
  const CaptureButtonTest({super.key});

  @override
  State<CaptureButtonTest> createState() => _CaptureButtonTestState();
}

class _CaptureButtonTestState extends State<CaptureButtonTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            print('✅ CENTER BUTTON WORKS');
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
