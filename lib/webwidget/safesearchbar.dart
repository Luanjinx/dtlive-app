import 'package:flutter/material.dart';

import '../utils/color.dart';

class SafeSearchBar extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const SafeSearchBar({
    super.key,
    required this.focusNode,
    required this.controller,
    this.hint = "Search...",
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onHover: (_) {},
      onExit: (_) {},
      child: TextField(
        key: const ValueKey('safe-search-bar'), // Prevents new DOM node
        controller: controller,
        focusNode: focusNode,
        autofocus: false, // Prevent iOS flicker
        textInputAction: TextInputAction.search,
        cursorColor: colorPrimary,
        cursorRadius: const Radius.circular(2),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: true,
          fillColor: transparent,
          hintStyle: TextStyle(
            color: descTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
        ),
        style: const TextStyle(
          fontSize: 14,
          color: black,
          fontWeight: FontWeight.w600,
        ),
        onSubmitted: (value) {
          onChanged?.call(value);
        },
        onChanged: (value) {
          onChanged?.call(value);
        },
      ),
    );
  }
}
