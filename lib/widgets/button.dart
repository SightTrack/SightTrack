import 'package:flutter/material.dart';

class SightTrackButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final Gradient? gradient;
  final Color? textColor;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final Duration animationDuration;

  const SightTrackButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.gradient,
    this.textColor,
    this.height = 50.0,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.textStyle,
    this.padding,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SightTrackButton> createState() => _SightTrackButtonState();
}

class _SightTrackButtonState extends State<SightTrackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      lowerBound: 0.8,
      upperBound: 1.0,
    )..value = 1.0; // Start at full scale.
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant SightTrackButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading && !widget.loading) {
      _controller.animateTo(1.0, duration: widget.animationDuration);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Gradient gradient =
        widget.gradient ??
        const LinearGradient(colors: [Colors.teal, Colors.green]);

    // Default text style if none provided
    final TextStyle style =
        widget.textStyle ??
        TextStyle(
          color: widget.textColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

    return GestureDetector(
      onTap: widget.enabled && !widget.loading ? widget.onPressed : null,
      onTapDown: (details) {
        if (widget.enabled && !widget.loading) {
          _controller.animateTo(
            0.9,
            duration: const Duration(milliseconds: 100),
          );
        }
      },
      onTapUp: (details) {
        if (widget.enabled && !widget.loading) {
          _controller.animateTo(
            1.0,
            duration: const Duration(milliseconds: 100),
          );
        }
      },
      onTapCancel: () {
        if (widget.enabled && !widget.loading) {
          _controller.animateTo(
            1.0,
            duration: const Duration(milliseconds: 100),
          );
        }
      },
      child: AnimatedOpacity(
        duration: widget.animationDuration,
        opacity: widget.enabled ? 1.0 : 0.6,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: widget.height,
            width: widget.width,
            padding:
                widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child:
                  widget.loading
                      ? SizedBox(
                        height: widget.height / 2,
                        width: widget.height / 2,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.textColor ?? Colors.white,
                          ),
                          strokeWidth: 2.5,
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.textColor ?? Colors.white,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(widget.text, style: style),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class NiceButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const NiceButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 200,
    this.height = 50,
  });

  @override
  NiceButtonState createState() => NiceButtonState();
}

class NiceButtonState extends State<NiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
