import 'package:flutter/material.dart';

class InteractiveIcon extends StatefulWidget {
  final Widget Function(bool isHovered) builder;

  const InteractiveIcon({super.key, required this.builder});

  @override
  InteractiveIconState createState() => InteractiveIconState();
}

class InteractiveIconState extends State<InteractiveIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => _hovered(true),
      onExit: (_) => _hovered(false),
      child: widget.builder(_hovering),
    );
  }

  void _hovered(bool hovered) {
    setState(() {
      _hovering = hovered;
    });
  }
}
