import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../model/sectionlistmodel.dart' as list;
import '../utils/color.dart';
import '../utils/dimens.dart';
import 'myimage.dart';
import 'mytext.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/web_hover_card.dart';

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
        color: secondaryBgColor,
        boxShadow: [
          /* Wide outer glow — animated */
          BoxShadow(
            color: colorPrimary.withValues(
              alpha: 0.22 + (_pulseAnim.value * 0.16),
            ),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          /* Tight inner glow */
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.10),
            blurRadius: 10,
            spreadRadius: 0,
          ),
          /* Deep base shadow */
          BoxShadow(
            color: black.withValues(alpha: 0.70),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorPrimary.withValues(
            alpha: 0.28 + (_pulseAnim.value * 0.18),
          ),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /* Background layers clipped inside the rounded card */
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  _buildStarfield(context),
                  _buildOrbLayer(context),
                  _buildShimmerSweep(context),
                ],
              ),
            ),
          ),

          /* Content — NOT clipped so hover scale can paint outside card bounds */
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildPosterList(context, items),
              _buildViewAllButton(context),
            ],
          ),
        ],
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
                    colorPrimary.withValues(alpha: 0.28 + pulse * 0.12),
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
                    infoBG.withValues(alpha: 0.20 + pulse * 0.08),
                    transparent,
                  ],
                ),
              ),
            ),
          ),
          /* Center orb — colorPrimaryDark */
          Positioned(
            top: 40,
            left: 60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorPrimaryDark.withValues(
                      alpha: 0.12 + (1 - pulse) * 0.08,
                    ),
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
                white.withValues(alpha: 0.04),
                white.withValues(alpha: 0.09),
                white.withValues(alpha: 0.04),
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
    final bool bigScreen = Dimens.isWeb(context);
    final title = (widget.section.title ?? "").trim();
    final subtitle = (widget.section.shortTitle ?? "").trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 15, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* AI Badge */
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colorPrimary.withValues(alpha: 0.18),
                    border: Border.all(
                      color: colorPrimary.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyImage(
                        imagePath: "ic_ai.png",
                        height: 12,
                        width: 12,
                        color: colorPrimary,
                      ),
                      const SizedBox(width: 5),
                      MyText(
                        color: colorPrimary,
                        text: "AI Powered",
                        multilanguage: false,
                        textalign: TextAlign.start,
                        fontsizeNormal: 10,
                        fontsizeWeb: 11,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                /* Title */
                if (title.isNotEmpty)
                  MyText(
                    color: white,
                    text: title,
                    multilanguage: false,
                    textalign: TextAlign.start,
                    fontsizeNormal: 18,
                    fontsizeWeb: 24,
                    fontweight: FontWeight.w700,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),

                /* Subtitle */
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
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
                ],
              ],
            ),
          ),
          MyImage(
            imagePath: "ic_ai_3d.png",
            height: bigScreen ? 110 : 75,
            width: bigScreen ? 110 : 75,
          ),
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
        ? (bigScreen ? Dimens.widthLandWeb : Dimens.widthLand)
        : (bigScreen ? Dimens.widthPortWeb : Dimens.widthPort);
    final double cardH = isLandscape
        ? (bigScreen ? Dimens.heightLandWeb : Dimens.heightLand)
        : (bigScreen ? Dimens.heightPortWeb : Dimens.heightPort);

    return SizedBox(
      height: cardH + 20,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            cardH,
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
    double cardH,
  ) {
    return WebHoverCard(
      cardW: cardW,
      cardH: cardH,
      borderRadius: Dimens.cardRadius,
      imageUrl: imageUrl,
      onTap: () => widget.onItemTap?.call(datum, index),
      overlay: Stack(
        fit: StackFit.expand,
        children: [
          /* Subtle primary color tint overlay */
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorPrimary.withValues(alpha: 0.05),
                      transparent,
                      appBgColor.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          /* Content name at bottom */
          if ((datum.name ?? "").isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
                child: MyText(
                  color: white,
                  text: datum.name ?? "",
                  multilanguage: false,
                  fontsizeNormal: 10,
                  fontsizeWeb: 11,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),

          /* Top-right AI spark dot */
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrimary.withValues(alpha: 0.90),
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: 0.6),
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
    );
  }

  /* ── View All button ─────────────────────────────────────── */
  Widget _buildViewAllButton(BuildContext context) {
    final bool bigScreen = Dimens.isWeb(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: bigScreen
              ? (MediaQuery.sizeOf(context).width * 0.22)
              : double.infinity,
          height: bigScreen ? 50 : 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            /* Dark fill so colorPrimary text/icon are always visible */
            color: appBgColor,
            border: Border.all(
              color: colorPrimary.withValues(
                alpha: 0.70 + _pulseAnim.value * 0.30,
              ),
              width: 2,
            ),
            boxShadow: [
              /* Animated outer glow */
              BoxShadow(
                color: colorPrimary.withValues(
                  alpha: 0.30 + _pulseAnim.value * 0.20,
                ),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              /* Inner light to lift button off card */
              BoxShadow(
                color: colorPrimary.withValues(alpha: 0.08),
                blurRadius: 6,
                spreadRadius: -2,
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
                    ? colorPrimary.withValues(alpha: 0.10)
                    : transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyImage(
                      imagePath: "ic_ai.png",
                      height: 16,
                      width: 16,
                      color: colorPrimary,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: MyText(
                        color: colorPrimary,
                        text: "view_all_recommendations",
                        multilanguage: true,
                        fontsizeNormal: 13,
                        fontsizeWeb: 15,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorPrimary,
                      size: 22,
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

/* ── Starfield painter ────────────────────────────────────── */
class _StarfieldPainter extends CustomPainter {
  final int seed;
  _StarfieldPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 55; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.2 + 0.3;
      final opacity = rng.nextDouble() * 0.35 + 0.10;
      paint.color = white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.seed != seed;
}
