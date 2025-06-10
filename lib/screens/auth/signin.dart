import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class SignInScreen extends StatelessWidget {
  final AuthenticatorState state;

  const SignInScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/logo_transparent.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to SightTrack',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              SignInForm.custom(
                fields: [
                  SignInFormField.username(),
                  SignInFormField.password(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed:
                          () => state.changeStep(AuthenticatorStep.signUp),
                      child: AutoSizeText(
                        'Don\'t have an account? Create one instead',
                        maxLines: 2,
                        minFontSize: 5,
                        maxFontSize: 12,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
