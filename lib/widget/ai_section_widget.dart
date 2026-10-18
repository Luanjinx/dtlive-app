import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../model/sectionlistmodel.dart' as list;
import '../utils/color.dart';
import '../utils/dimens.dart';
import 'myimage.dart';
import 'mynetworkimg.dart';
import 'mytext.dart';
import '../webwidget/interactive_icon.dart';

class AISectionWidget extends StatefulWidget {
  final list.Result section;
  final Function(list.Datum datum, int index)? onItemTap;
  final VoidCallback? onViewAllTap;

  const AISectionWidget({
    super.key,
    required this.section,
    this.onItemTap,
    this.onViewAllTap,
  });

  @override
  State<AISectionWidget> createState() => _AISectionWidgetState();
}

class _AISectionWidgetState extends State<AISectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.data ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final bool bigScreen = Dimens.isBigScreen(context);
    final double hMargin = bigScreen ? 35.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 4),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _shimmerAnim]),
        builder: (context, child) {
          return _buildCard(context, items, bigScreen);
        },
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<list.Datum> items,
    bool bigScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        /* Deep card background */
        color: const Color(0xFF0F1410),
        boxShadow: [
          /* Wide outer neon glow — animated */
          BoxShadow(
            color: colorPrimary.withValues(
              alpha: 0.18 + (_pulseAnim.value * 0.14),
            ),
            blurRadius: 32,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          /* Base drop shadow */
          BoxShadow(
            color: black.withValues(alpha: 0.70),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      /* Foreground border is always on top so it never gets obscured */
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorPrimary.withValues(
            alpha: 0.50 + (_pulseAnim.value * 0.25),
          ),
          width: 1.5,
        ),
      ),
      /* Inner clipping prevents cards from overflowing past the container line when swiped */
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            /* Background layers */
            Positioned.fill(
              child: Stack(
                children: [
                  _buildStarfield(context),
                  _buildOrbLayer(context),
                  _buildShimmerSweep(context),
                ],
              ),
            ),

            /* Foreground content */
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildPosterList(context, items),
                _buildViewAllButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ── Background: tiny star dots ──────────────────────── */
  Widget _buildStarfield(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _StarfieldPainter(seed: 42)),
    );
  }

  /* ── Background: soft color orbs ─────────────────────── */
  Widget _buildOrbLayer(BuildContext context) {
    final double pulse = _pulseAnim.value;
    return Positioned.fill(
      child: Stack(
        children: [
          /* Top-right orb — colorPrimary */
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorPrimary.withValues(alpha: 0.22 + pulse * 0.10),
                    colorPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          /* Bottom-left orb — infoBG */
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    infoBG.withValues(alpha: 0.16 + pulse * 0.06),
                    transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ── Shimmer diagonal sweep ───────────────────────────── */
  Widget _buildShimmerSweep(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_shimmerAnim.value - 1, -1),
              end: Alignment(_shimmerAnim.value, 1),
              colors: [
                transparent,
                white.withValues(alpha: 0.03),
                white.withValues(alpha: 0.07),
                white.withValues(alpha: 0.03),
                transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: Container(color: white),
        ),
      ),
    );
  }

  /* ── Header ─────────────────────────────────────────────── */
  Widget _buildHeader(BuildContext context) {
    final title = (widget.section.title ?? "").trim();
    final subtitle = (widget.section.shortTitle ?? "").trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* AI Badge — bright lime green pill */
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorPrimary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyImage(
                  imagePath: "ic_ai.png",
                  height: 12,
                  width: 12,
                  color: black,
                ),
                const SizedBox(width: 5),
                const Text(
                  "AI POWERED",
                  style: TextStyle(
                    color: black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          /* Title */
          MyText(
            color: white,
            text: title.isNotEmpty ? title : "Recommendations for you",
            multilanguage: false,
            textalign: TextAlign.start,
            fontsizeNormal: 20,
            fontsizeWeb: 24,
            fontweight: FontWeight.w700,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),

          /* Subtitle */
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            MyText(
              color: descTextColor,
              text: subtitle,
              multilanguage: false,
              fontweight: FontWeight.w400,
              fontsizeNormal: 12,
              fontsizeWeb: 14,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ] else ...[
            const SizedBox(height: 4),
            MyText(
              color: descTextColor,
              text: "Top Picks For You",
              multilanguage: false,
              fontweight: FontWeight.w400,
              fontsizeNormal: 12,
              fontsizeWeb: 14,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ],
        ],
      ),
    );
  }

  /* ── Poster list ─────────────────────────────────────────── */
  Widget _buildPosterList(BuildContext context, List<list.Datum> items) {
    final bool bigScreen = Dimens.isBigScreen(context);
    final String layout = widget.section.screenLayout ?? "portrait";
    final bool isLandscape = layout == "landscape" || layout == "big_landscape";

    final double cardW = isLandscape
        ? (bigScreen ? 230.0 : 160.0)
        : (bigScreen ? 160.0 : 120.0);
    final double posterH = isLandscape
        ? (bigScreen ? 140.0 : 98.0)
        : (bigScreen ? 232.0 : 174.0);

    /* Total list height: posterH + spacing (8) + title (18) + vertical padding (8) */
    final double listH = posterH + 34.0;

    return SizedBox(
      height: listH,
      child: ListView.separated(
        clipBehavior: Clip.hardEdge,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final datum = items[index];
          final imageUrl = isLandscape
              ? (datum.landscape ?? datum.thumbnail ?? "")
              : (datum.thumbnail ?? datum.landscape ?? "");
          return _buildPosterCard(
            context,
            datum,
            index,
            imageUrl,
            cardW,
            posterH,
          );
        },
      ),
    );
  }

  Widget _buildPosterCard(
    BuildContext context,
    list.Datum datum,
    int index,
    String imageUrl,
    double cardW,
    double posterH,
  ) {
    final bool isPremium =
        (datum.isPremium ?? 0) == 1 || (datum.isRent ?? 0) == 1;

    return _AIHoverPoster(
      onTap: () => widget.onItemTap?.call(datum, index),
      child: SizedBox(
        width: cardW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /* Poster image container with badges */
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  /* Poster Network Image */
                  MyNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: cardW,
                    height: posterH,
                  ),

                  /* Subtle gradient at bottom of poster */
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              transparent,
                              transparent,
                              black.withValues(alpha: 0.35),
                            ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  /* Top-Left: PREMIUM Badge if premium or rent */
                  if (isPremium)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: complimentryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "PREMIUM",
                          style: TextStyle(
                            color: white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),

                  /* Top-Right: AI Sparkle Circle Badge */
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimary.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: MyImage(
                          imagePath: "ic_ai.png",
                          height: 11,
                          width: 11,
                          color: black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /* Movie Title below poster (NO rating, NO text movie as requested) */
            if ((datum.name ?? "").isNotEmpty) ...[
              const SizedBox(height: 8),
              MyText(
                color: white,
                text: datum.name ?? "",
                multilanguage: false,
                fontsizeNormal: 12,
                fontsizeWeb: 13,
                fontweight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /* ── View All button ─────────────────────────────────────── */
  Widget _buildViewAllButton(BuildContext context) {
    final bool bigScreen = Dimens.isWeb(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: bigScreen
              ? (MediaQuery.sizeOf(context).width * 0.26).clamp(240.0, 360.0)
              : double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            /* Dark fill */
            color: lightBlack,
            border: Border.all(
              color: colorPrimary.withValues(
                alpha: 0.70 + _pulseAnim.value * 0.30,
              ),
              width: 1.5,
            ),
            boxShadow: [
              /* Animated outer glow */
              BoxShadow(
                color: colorPrimary.withValues(
                  alpha: 0.15 + _pulseAnim.value * 0.15,
                ),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InteractiveIcon(
            builder: (isHovered) => InkWell(
              onTap: widget.onViewAllTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: isHovered
                    ? colorPrimary.withValues(alpha: 0.12)
                    : transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyImage(
                      imagePath: "ic_ai.png",
                      height: 14,
                      width: 14,
                      color: colorPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: MyText(
                        color: colorPrimary,
                        text: "view_all_recommendations",
                        multilanguage: true,
                        fontsizeNormal: 13,
                        fontsizeWeb: 14,
                        fontweight: FontWeight.w600,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ── Interactive hover wrapper for poster cards ────────────── */
class _AIHoverPoster extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _AIHoverPoster({required this.child, this.onTap});

  @override
  State<_AIHoverPoster> createState() => _AIHoverPosterState();
}

class _AIHoverPosterState extends State<_AIHoverPoster> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/* ── Starfield painter ────────────────────────────────────── */
class _StarfieldPainter extends CustomPainter {
  final int seed;
  _StarfieldPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.1 + 0.3;
      final opacity = rng.nextDouble() * 0.30 + 0.10;
      paint.color = white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.seed != seed;
}
