import 'package:flutter/material.dart';

/// A customizable animated text widget that displays a list of strings with a typewriter effect.
/// Will display each string and loop back to the beginning of the given list
class TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration transitionDuration;

  const TypewriterText({
    super.key,
    required this.texts,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 100),
    this.pauseDuration = const Duration(seconds: 2),
    this.transitionDuration = const Duration(seconds: 1),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  String _currentText = '';
  int _currentTextIndex = 0;
  int _charIndex = 0;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startTyping();
  }

  void _startTyping() async {
    while (mounted) {
      if (_isTyping) {
        if (_charIndex < widget.texts[_currentTextIndex].length) {
          setState(() {
            _currentText = widget.texts[_currentTextIndex].substring(
              0,
              _charIndex + 1,
            );
            _charIndex++;
          });
          await Future.delayed(widget.typingSpeed);
        } else {
          _isTyping = false;
          await Future.delayed(widget.pauseDuration);
          _controller.forward();
          await Future.delayed(widget.transitionDuration);
          _controller.reset();
        }
      } else {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % widget.texts.length;
          _charIndex = 0;
          _currentText = '';
          _isTyping = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        _currentText,
        style: widget.textStyle ?? const TextStyle(fontSize: 24),
        textAlign: TextAlign.center,
      ),
    );
  }
}
