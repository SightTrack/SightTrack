import 'package:flutter/material.dart';

class STSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final TextEditingController? controller;
  final EdgeInsetsGeometry? padding;
  final bool filled;
  final Color? fillColor;
  final OutlineInputBorder? border;
  final BorderRadius? borderRadius;

  const STSearchBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.controller,
    this.padding = const EdgeInsets.all(16.0),
    this.filled = false,
    this.fillColor,
    this.border,
    this.borderRadius,
  });

  @override
  State<STSearchBar> createState() => _STSearchBarState();
}

class _STSearchBarState extends State<STSearchBar> {
  late TextEditingController _controller;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isControllerOwned = true;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSearchChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                  },
                )
              : null,
          filled: widget.filled,
          fillColor: widget.fillColor,
          border: widget.border ??
              (widget.borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: widget.borderRadius!,
                      borderSide: BorderSide.none,
                    )
                  : null),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }
}
