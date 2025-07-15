import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _loadingMessage = 'Syncing your data...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _waitForDataStoreSync();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _waitForDataStoreSync() async {
    try {
      // Set initial loading message
      setState(() {
        _loadingMessage = 'Setting up your account...';
      });

      // Wait for user authentication to be fully established
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if user settings exist and create if needed
      setState(() {
        _loadingMessage = 'Configuring preferences...';
      });

      // This function already exists in your app.dart
      await _ensureUserSettings();

      // Wait for DataStore to sync
      setState(() {
        _loadingMessage = 'Syncing your data...';
      });

      // Wait for DataStore sync with timeout
      await _waitForDataStoreSyncWithTimeout();

      setState(() {
        _loadingMessage = 'Almost ready...';
      });

      // Small delay to show completion message
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Navigation()),
        );
      }
    } catch (e) {
      Log.e('Error during loading: $e');
      // Still navigate to main app even if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Navigation()),
        );
      }
    }
  }

  Future<void> _ensureUserSettings() async {
    try {
      User user = await Util.getUserModel();
      String userId = user.id;

      final existingSettings = await Amplify.DataStore.query(
        UserSettings.classType,
        where: UserSettings.USERID.eq(userId),
      );

      if (existingSettings.isEmpty) {
        final newSettings = UserSettings(
          userId: userId,
          isAreaCaptureActive: false,
          areaCaptureEnd: null,
        );

        await Amplify.DataStore.save(newSettings);
        Log.i('New user settings created for $userId');
      } else {
        Log.i('User settings exist: ${existingSettings.first.toJson()}');
      }
    } catch (e) {
      Log.e('Error ensuring user settings: $e');
      // Don't throw, just log the error
    }
  }

  Future<void> _waitForDataStoreSyncWithTimeout() async {
    const timeout = Duration(seconds: 10); // 10 second timeout
    const checkInterval = Duration(milliseconds: 500);

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      try {
        // Try to query the DataStore to see if it's responsive
        final user = await Util.getUserModel();
        final userSettings = await Amplify.DataStore.query(
          UserSettings.classType,
          where: UserSettings.USERID.eq(user.id),
        );

        // If we can successfully query, consider sync ready
        if (userSettings.isNotEmpty ||
            stopwatch.elapsed > const Duration(seconds: 3)) {
          Log.i('DataStore sync appears ready');
          break;
        }
      } catch (e) {
        Log.w('DataStore not ready yet: $e');
      }

      await Future.delayed(checkInterval);
    }

    stopwatch.stop();
    Log.i('DataStore sync wait completed in ${stopwatch.elapsed}');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  size: 60,
                  color: isDarkMode ? Colors.white : Colors.grey[700],
                ),
              ),

              const SizedBox(height: 40),

              // Animated loading indicator
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.white : Colors.grey[700]!,
                          width: 3,
                        ),
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white : Colors.grey[700]!,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Loading message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingMessage,
                  key: ValueKey(_loadingMessage),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Additional info text
              Text(
                'This may take a few moments...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white54 : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
