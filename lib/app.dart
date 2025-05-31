import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Future<bool> isMissingDetails() async {
    // Check if the user is missing any details (age, school)
    try {
      User user = await Util.getUserModel();
      return user.age == null || user.school == null;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      authenticatorBuilder: (context, state) {
        if (state.currentStep == AuthenticatorStep.signIn) {
          return SignInScreen(state: state);
        } else if (state.currentStep == AuthenticatorStep.signUp) {
          return SignUpScreen(state: state);
        }
        return null;
      },
      child: MaterialApp(
        builder: Authenticator.builder(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.defaultTheme,
        home: const Navigation(),
      ),
    );
  }
}
