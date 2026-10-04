import 'package:flutter/material.dart';

import '../utils/color.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import 'interactive_icon.dart';

class LeftRightScrollOnHover extends StatefulWidget {
  final Widget child;
  final double height;
  final double itemWidth;
  final int itemCount;
  final double itemSpacing;
  final ScrollController? scrollController;
  final void Function()? onLeftTap;
  final void Function()? onRightTap;
  // You can also pass the translation in here if you want to
  const LeftRightScrollOnHover({
    super.key,
    required this.child,
    required this.scrollController,
    required this.height,
    required this.itemWidth,
    required this.itemCount,
    required this.itemSpacing,
    required this.onLeftTap,
    required this.onRightTap,
  });

  @override
  State<LeftRightScrollOnHover> createState() => _LeftRightScrollOnHoverState();
}

class _LeftRightScrollOnHoverState extends State<LeftRightScrollOnHover> {
  Offset translate = const Offset(0, 0);

  bool _hovering = false;
  List<int> visibleItems = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController != null &&
          widget.scrollController!.hasClients) {
        visibleItems = Utils.getVisibleIndexes(
          controller: widget.scrollController!,
          itemWidth: widget.itemWidth,
          spacing: widget.itemSpacing,
          itemCount: widget.itemCount,
        );
      }
    });

    widget.scrollController?.addListener(() {
      visibleItems = Utils.getVisibleIndexes(
        controller: widget.scrollController!,
        itemWidth: widget.itemWidth,
        spacing: widget.itemSpacing,
        itemCount: widget.itemCount,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => _mouseEnter(true),
      onExit: (e) => _mouseEnter(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (visibleItems.length < widget.itemCount && _hovering)
            _buildLeftRightArrows(),
        ],
      ),
    );
  }

  Widget _buildLeftRightArrows() {
    return Container(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InteractiveIcon(
            builder: (isHovered) => InkWell(
              onTap: widget.onLeftTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 70,
                height: widget.height,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      appBgColor,
                      appBgColor.withValues(alpha: isHovered ? 0.98 : 0.9),
                      appBgColor.withValues(alpha: isHovered ? 0.90 : 0.8),
                      appBgColor.withValues(alpha: isHovered ? 0.80 : 0.7),
                      appBgColor.withValues(alpha: isHovered ? 0.40 : 0.2),
                      transparent,
                    ],
                  ),
                ),
                child: MyImage(
                  height: 40,
                  width: 40,
                  color: isHovered ? white : white.withValues(alpha: 0.70),
                  imagePath: "ic_left.png",
                ),
              ),
            ),
          ),
          InteractiveIcon(
            builder: (isHovered) => InkWell(
              onTap: widget.onRightTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 70,
                height: widget.height,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      transparent,
                      appBgColor.withValues(alpha: isHovered ? 0.40 : 0.2),
                      appBgColor.withValues(alpha: isHovered ? 0.80 : 0.7),
                      appBgColor.withValues(alpha: isHovered ? 0.90 : 0.8),
                      appBgColor.withValues(alpha: isHovered ? 0.98 : 0.9),
                      appBgColor,
                    ],
                  ),
                ),
                child: MyImage(
                  height: 40,
                  width: 40,
                  color: isHovered ? white : white.withValues(alpha: 0.70),
                  imagePath: "ic_right2.png",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mouseEnter(bool hover) {
    if (hover) {
      setState(() {
        _hovering = true;
      });
    } else {
      setState(() {
        _hovering = false;
      });
    }
  }
}
