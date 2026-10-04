import 'package:flutter/material.dart';
import 'package:sprung/sprung.dart';

class InteractiveItem extends StatefulWidget {
  final Widget Function(bool isHovered) builder;

  const InteractiveItem({
    super.key,
    required this.builder,
  });

  @override
  InteractiveItemState createState() => InteractiveItemState();
}

class InteractiveItemState extends State<InteractiveItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverTransform = Matrix4.identity()
      ..translateByDouble(-30, -30, 20, 0)
      ..scaleByDouble(1.15, 0, 0, 0);
    final transform = _hovering ? hoverTransform : Matrix4.identity();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => _hovered(true),
      onExit: (_) => _hovered(false),
      child: AnimatedContainer(
        curve: Sprung.overDamped,
        duration: const Duration(milliseconds: 300),
        transform: transform,
        child: widget.builder(_hovering),
      ),
    );
  }

  void _hovered(bool hovered) {
    setState(() {
      _hovering = hovered;
    });
  }
}
