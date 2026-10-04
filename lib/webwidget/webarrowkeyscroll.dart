import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WebArrowKeyScroll extends StatefulWidget {
  final Widget childToScroll;
  final ScrollController scrollController;
  const WebArrowKeyScroll({
    super.key,
    required this.childToScroll,
    required this.scrollController,
  });

  @override
  State<WebArrowKeyScroll> createState() => _WebArrowKeyScrollState();
}

class _WebArrowKeyScrollState extends State<WebArrowKeyScroll> {
  Timer? _repeatScrollTimer;
  FocusNode? _focusNode; // Only create on web

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _focusNode = FocusNode();
      // Delay focus request to avoid grabbing it during text input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode?.requestFocus();
      });
    }
  }

  void _startScrollLoop(KeyEvent key) {
    const duration = Duration(milliseconds: 50);
    _repeatScrollTimer?.cancel();
    _repeatScrollTimer = Timer.periodic(duration, (_) {
      _handleKeyPress(key);
    });
  }

  void _stopScrollLoop() {
    _repeatScrollTimer?.cancel();
    _repeatScrollTimer = null;
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final double offset = widget.scrollController.offset;
    final double maxScroll = widget.scrollController.position.maxScrollExtent;
    final double minScroll = widget.scrollController.position.minScrollExtent;
    const double step = 100;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.scrollController.animateTo(
        (offset + step).clamp(minScroll, maxScroll),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.scrollController.animateTo(
        (offset - step).clamp(minScroll, maxScroll),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      widget.scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      widget.scrollController.animateTo(
        minScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _repeatScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On non-web (mobile/desktop), just return the child without listener
    if (!kIsWeb) return widget.childToScroll;

    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode!,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _startScrollLoop(event);
          } else if (event.logicalKey == LogicalKeyboardKey.pageDown ||
              event.logicalKey == LogicalKeyboardKey.pageUp) {
            _handleKeyPress(event);
          }
        } else if (event is KeyUpEvent) {
          _stopScrollLoop();
        }
      },
      child: widget.childToScroll,
    );
  }
}
