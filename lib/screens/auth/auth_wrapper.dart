import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isSignedIn;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (mounted) {
        setState(() {
          _isSignedIn = session.isSignedIn;
        });
      }
    } catch (e) {
      Log.e('Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _isSignedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn == null) {
      // Still checking auth state
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSignedIn!) {
      // User is authenticated, show loading screen for DataStore sync
      return const LoadingScreen();
    } else {
      // User is not authenticated, show main navigation
      // The Authenticator will handle showing sign-in/sign-up screens
      return const Navigation();
    }
  }
}
