import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';

/// Reusable hover card for web grid views.
/// Scale 1.05 + dark scrim + play button + white border ring on hover.
/// Uses Transform.scale OUTSIDE ClipRRect so the scale is never clipped.
/// On non-web: renders as plain card with no hover.
class WebHoverCard extends StatefulWidget {
  final double cardW;
  final double cardH;
  final double borderRadius;
  final String imageUrl;
  final bool showPlayButton;
  final VoidCallback onTap;
  final Widget? overlay;

  const WebHoverCard({
    super.key,
    required this.cardW,
    required this.cardH,
    required this.borderRadius,
    required this.imageUrl,
    required this.onTap,
    this.showPlayButton = true,
    this.overlay,
  });

  @override
  State<WebHoverCard> createState() => _WebHoverCardState();
}

class _WebHoverCardState extends State<WebHoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return GestureDetector(
        onTap: widget.onTap,
        child: _buildInner(scale: 1.0, fade: 0.0),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => GestureDetector(
          onTap: widget.onTap,
          child: _buildInner(scale: _scale.value, fade: _fade.value),
        ),
      ),
    );
  }

  Widget _buildInner({required double scale, required double fade}) {
    final double btnSize = widget.cardH > 160 ? 52.0 : 40.0;
    final double iconSize = widget.cardH > 160 ? 30.0 : 24.0;

    // SizedBox gives the card its exact layout footprint — ListView item stays
    // the correct size with normalized constraints. Transform.scale is applied
    // before ClipRRect so the scale expands outward and is never clipped.
    return SizedBox(
      width: widget.cardW,
      height: widget.cardH,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        child: Container(
          width: widget.cardW,
          height: widget.cardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: fade > 0
                ? [
                    BoxShadow(
                      color: black.withValues(alpha: fade * 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: colorPrimary.withValues(alpha: fade * 0.18),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MyNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  width: widget.cardW,
                  height: widget.cardH,
                ),
                if (widget.overlay != null) widget.overlay!,
                if (fade > 0) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: black.withValues(alpha: fade * 0.22),
                      ),
                    ),
                  ),
                  if (widget.showPlayButton)
                    Center(
                      child: Opacity(
                        opacity: fade,
                        child: Container(
                          width: btnSize,
                          height: btnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: white.withValues(alpha: 0.92),
                            boxShadow: [
                              BoxShadow(
                                color: black.withValues(alpha: 0.30),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: appBgColor,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          border: Border.all(
                            color: white.withValues(alpha: fade * 0.60),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
