import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:sighttrack/models/ModelProvider.dart';
import 'package:sighttrack/util.dart';

class CaptureTypeScreen extends StatefulWidget {
  const CaptureTypeScreen({super.key});

  @override
  State<CaptureTypeScreen> createState() => _CaptureTypeScreenState();
}

class _CaptureTypeScreenState extends State<CaptureTypeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeTitle;
  late Animation<double> _fadeButton1;
  late Animation<double> _fadeButton2;
  late Animation<double> _iconRotate;

  UserSettings? _userSettings;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWrapper();
  }

  void _initializeWrapper() async {
    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
    });
    if (_userSettings != null && _userSettings?.isAreaCaptureActive == true) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/ac_home');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeTitle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _fadeButton1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );
    _fadeButton2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
    _iconRotate = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void didUpdateWidget(CaptureTypeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetAnimations();
  }

  void _resetAnimations() {
    _fadeController.dispose();
    _pulseController.dispose();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBackground(
        behaviour: RacingLinesBehaviour(
          direction: LineDirection.Rtl,
          numLines: 50,
        ),
        vsync: this,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeTitle,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
                        ),
                      ),
                      child: const Text(
                        'Choose Capture Type',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  FadeTransition(
                    opacity: _fadeButton1,
                    child: _buildNeumorphicButton(
                      icon: Icons.camera_alt,
                      label: 'Quick Capture',
                      onPressed: () {
                        Navigator.pushNamed(context, '/capture');
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                  FadeTransition(
                    opacity: _fadeButton2,
                    child: _buildNeumorphicButton(
                      icon: Icons.map,
                      label: 'Area Capture',
                      onPressed: () {
                        Navigator.pushNamed(context, '/ac_setup');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 60,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.question_mark,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/info');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.grey[800]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: RotationTransition(
          turns: _iconRotate,
          child: Icon(icon, size: 32, color: Colors.white),
        ),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

class CaptureTypeInfoScreen extends StatelessWidget {
  const CaptureTypeInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Which type?',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey[900]!, Colors.grey[850]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(5, 5),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            offset: const Offset(-5, -5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Text(
                        'Quick capture is used for independent photos of a single animal/plant. ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey[900]!, Colors.grey[850]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(5, 5),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            offset: const Offset(-5, -5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Text(
                        'Area capture is when you want to capture a larger area with multiple animals/plants - primarily for data collection and research purposes',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
