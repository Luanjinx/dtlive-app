import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/sectionlistmodel.dart' as list;
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import 'mynetworkimg.dart';
import 'mytext.dart';

enum ContentCardLayout {
  landscape,
  bigLandscape,
  indexLandscape,
  portrait,
  bigPortrait,
  indexPortrait,
  square,
}

/// Shared horizontal-scroll section widget for all standard card types.
/// Used by both home.dart (mobile) and webhome.dart (web).
///
/// [continueWatchingBuilder]: optional per-item callback; when non-null its result
/// replaces the default title overlay at the card bottom. Pass null for regular sections.
class ContentSectionWidget extends StatelessWidget {
  final List<list.Datum>? items;
  final ContentCardLayout layout;
  final bool showScrollArrows;
  final double? horizontalPadding;
  final ScrollController? scrollController;
  final Function(list.Datum datum, int index) onItemTap;
  final Widget? Function(list.Datum datum, int index)? continueWatchingBuilder;

  const ContentSectionWidget({
    super.key,
    required this.items,
    required this.layout,
    required this.onItemTap,
    this.showScrollArrows = true,
    this.horizontalPadding,
    this.scrollController,
    this.continueWatchingBuilder,
  });

  bool get _isPortrait =>
      layout == ContentCardLayout.portrait ||
      layout == ContentCardLayout.bigPortrait ||
      layout == ContentCardLayout.indexPortrait;

  bool get _isIndexed =>
      layout == ContentCardLayout.indexLandscape ||
      layout == ContentCardLayout.indexPortrait;

  double _cardW(bool big) {
    switch (layout) {
      case ContentCardLayout.landscape:
      case ContentCardLayout.indexLandscape:
        return big ? Dimens.widthLandWeb : Dimens.widthLand;
      case ContentCardLayout.bigLandscape:
        return big ? Dimens.widthLandBigWeb : Dimens.widthLandBig;
      case ContentCardLayout.portrait:
      case ContentCardLayout.indexPortrait:
        return big ? Dimens.widthPortWeb : Dimens.widthPort;
      case ContentCardLayout.bigPortrait:
        return big ? Dimens.widthPortBigWeb : Dimens.widthPortBig;
      case ContentCardLayout.square:
        return big ? Dimens.widthSquareWeb : Dimens.widthSquare;
    }
  }

  double _cardH(bool big) {
    switch (layout) {
      case ContentCardLayout.landscape:
      case ContentCardLayout.indexLandscape:
        return big ? Dimens.heightLandWeb : Dimens.heightLand;
      case ContentCardLayout.bigLandscape:
        return big ? Dimens.heightLandBigWeb : Dimens.heightLandBig;
      case ContentCardLayout.portrait:
      case ContentCardLayout.indexPortrait:
        return big ? Dimens.heightPortWeb : Dimens.heightPort;
      case ContentCardLayout.bigPortrait:
        return big ? Dimens.heightPortBigWeb : Dimens.heightPortBig;
      case ContentCardLayout.square:
        return big ? Dimens.heightSquareWeb : Dimens.heightSquare;
    }
  }

  String _imageUrl(list.Datum datum) {
    if (_isPortrait || layout == ContentCardLayout.square) {
      return datum.thumbnail?.toString() ?? "";
    }
    return datum.landscape?.toString() ?? "";
  }

  double _indexedLeftPad(bool big) {
    if (big) return _isPortrait ? 56.0 : 55.0;
    if (kIsWeb) return _isPortrait ? 35.0 : 40.0;
    return _isPortrait ? 28.0 : 34.0;
  }

  double _indexMainSpacing(bool big) {
    if (big) return _isPortrait ? 35.0 : 40.0;
    if (kIsWeb) return _isPortrait ? 30.0 : 35.0;
    return _isPortrait ? 25.0 : 30.0;
  }

  double _numOffsetX(bool big) {
    if (_isPortrait) return big ? -13.0 : -11.0;
    return big ? -20.0 : (kIsWeb ? -15.0 : -17.0);
  }

  double _numOffsetY(bool big) {
    if (!_isPortrait) return 0.0;
    return big ? 20.0 : 15.0;
  }

  double _numFontSize(bool big) {
    if (_isPortrait) return big ? 80.0 : 55.0;
    return big ? 85.0 : 60.0;
  }

  double _numStroke(bool big) => big ? 8.0 : 6.0;

  @override
  Widget build(BuildContext context) {
    final bool big = Dimens.isBigScreen(context);
    final double cardW = _cardW(big);
    final double cardH = _cardH(big);
    final double hPad = horizontalPadding ?? (big ? 35.0 : 20.0);
    final double gap = big
        ? Dimens.spaceBetweenCardsWeb
        : Dimens.spaceBetweenCards;
    final int count = items?.length ?? 0;

    if (_isIndexed) {
      return _buildIndexedLayout(
        context: context,
        big: big,
        cardW: cardW,
        cardH: cardH,
        hPad: hPad,
        count: count,
      );
    }
    return _buildListLayout(
      context: context,
      big: big,
      cardW: cardW,
      cardH: cardH,
      hPad: hPad,
      gap: gap,
      count: count,
    );
  }

  Widget _buildListLayout({
    required BuildContext context,
    required bool big,
    required double cardW,
    required double cardH,
    required double hPad,
    required double gap,
    required int count,
  }) {
    return SizedBox(
      width: double.infinity,
      height: cardH,
      child: ListView.separated(
        controller: scrollController,
        itemCount: count,
        shrinkWrap: true,
        clipBehavior: Clip.none,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: hPad, right: hPad),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (ctx, i) => SizedBox(width: gap),
        itemBuilder: (ctx, index) {
          final list.Datum datum = items![index];
          return _ContentCard(
            key: ValueKey(datum.id),
            datum: datum,
            cardW: cardW,
            cardH: cardH,
            imageUrl: _imageUrl(datum),
            isBig: big,
            onTap: () => onItemTap(datum, index),
            continueWatching: continueWatchingBuilder?.call(datum, index),
          );
        },
      ),
    );
  }

  Widget _buildIndexedLayout({
    required BuildContext context,
    required bool big,
    required double cardW,
    required double cardH,
    required double hPad,
    required int count,
  }) {
    final double leftPad = _indexedLeftPad(big);
    final double mainSpacing = _indexMainSpacing(big);
    final double fontSize = _numFontSize(big);
    final double strokeW = _numStroke(big);
    final double offsetX = _numOffsetX(big);
    final double offsetY = _numOffsetY(big);

    return SizedBox(
      width: double.infinity,
      height: cardH,
      child: AlignedGridView.count(
        controller: scrollController,
        itemCount: count,
        shrinkWrap: true,
        clipBehavior: Clip.none,
        crossAxisCount: 1,
        mainAxisSpacing: mainSpacing,
        padding: EdgeInsets.only(left: leftPad, right: hPad),
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) {
          final list.Datum datum = items![index];
          return Stack(
            alignment: _isPortrait
                ? Alignment.bottomLeft
                : Alignment.centerLeft,
            children: [
              _ContentCard(
                key: ValueKey(datum.id),
                datum: datum,
                cardW: cardW,
                cardH: cardH,
                imageUrl: _imageUrl(datum),
                isBig: big,
                onTap: () => onItemTap(datum, index),
                continueWatching: null,
              ),
              _IndexNumber(
                number: index + 1,
                fontSize: fontSize,
                strokeWidth: strokeW,
                offsetX: offsetX,
                offsetY: offsetY,
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────
   _ContentCard — single card for all standard layout types
   Hover (web): scale 1.04 + dark overlay + white play button + border ring
   Mobile: no hover, static card
───────────────────────────────────────────────────────────────────────── */
class _ContentCard extends StatefulWidget {
  final list.Datum datum;
  final double cardW;
  final double cardH;
  final String imageUrl;
  final bool isBig;
  final VoidCallback onTap;
  final Widget? continueWatching;

  const _ContentCard({
    super.key,
    required this.datum,
    required this.cardW,
    required this.cardH,
    required this.imageUrl,
    required this.isBig,
    required this.onTap,
    this.continueWatching,
  });

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard>
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
      end: 1.04,
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
    final double radius = widget.isBig ? 10.0 : 8.0;
    final String name = widget.datum.name?.toString() ?? "";
    final bool showTitle = (widget.datum.isTitle ?? 0) != 0 && name.isNotEmpty;
    final double btnSize = widget.isBig ? 52.0 : 44.0;
    final double iconSize = widget.isBig ? 30.0 : 26.0;

    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.cardW,
                height: widget.cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: _fade.value > 0
                      ? [
                          BoxShadow(
                            color: black.withValues(alpha: _fade.value * 0.28),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      /* Poster / thumbnail */
                      MyNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        width: widget.cardW,
                        height: widget.cardH,
                      ),

                      /* Bottom gradient + title (standard sections) */
                      if (widget.continueWatching == null && showTitle)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 30, 8, 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  transparent,
                                  appBgColor.withValues(alpha: 0.65),
                                  appBgColor.withValues(alpha: 0.92),
                                ],
                                stops: const [0.0, 0.50, 1.0],
                              ),
                            ),
                            child: MyText(
                              color: white,
                              text: name,
                              multilanguage: false,
                              fontsizeNormal: 12,
                              fontsizeWeb: 14,
                              fontweight: FontWeight.w600,
                              maxline: 2,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                              fontstyle: FontStyle.normal,
                              isShadowText: true,
                            ),
                          ),
                        ),

                      /* Continue watching widget (progress bar + play) */
                      if (widget.continueWatching != null)
                        widget.continueWatching!,

                      /* Premium / rent tag */
                      Positioned(
                        top: 8,
                        right: 0,
                        child: Utils.buildRentPremiumTAG(
                          context: context,
                          isPremium: widget.datum.isPremium ?? 0,
                          isRent: widget.datum.isRent ?? 0,
                          rentPrice: widget.datum.price ?? 0,
                        ),
                      ),

                      /* Hover: dark scrim */
                      if (_fade.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: black.withValues(
                                alpha: _fade.value * 0.22,
                              ),
                            ),
                          ),
                        ),

                      /* Hover: centered play button */
                      if (_fade.value > 0)
                        Center(
                          child: Opacity(
                            opacity: _fade.value,
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

                      /* Hover: white border ring */
                      if (_fade.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(radius),
                                border: Border.all(
                                  color: white.withValues(
                                    alpha: _fade.value * 0.60,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────
   _IndexNumber — premium rank number for indexLandscape / indexPortrait
   Two-layer render: dark shadow stroke → colorPrimary solid fill
───────────────────────────────────────────────────────────────────────── */
class _IndexNumber extends StatelessWidget {
  final int number;
  final double fontSize;
  final double strokeWidth;
  final double offsetX;
  final double offsetY;

  const _IndexNumber({
    required this.number,
    required this.fontSize,
    required this.strokeWidth,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    final String numText = "$number";

    final TextStyle shadowStyle = kIsWeb
        ? TextStyle(
            fontSize: fontSize,
            letterSpacing: -3,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 5
              ..color = black.withValues(alpha: 0.55),
          )
        : GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: fontSize,
              letterSpacing: -3,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth + 5
                ..color = black.withValues(alpha: 0.55),
            ),
          );

    final TextStyle fillStyle = kIsWeb
        ? TextStyle(
            fontSize: fontSize,
            letterSpacing: -3,
            foreground: Paint()
              ..style = PaintingStyle.fill
              ..color = colorPrimary,
          )
        : GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: fontSize,
              letterSpacing: -3,
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = colorPrimary,
            ),
          );

    return Container(
      transform: Matrix4.translationValues(offsetX, offsetY, 0),
      child: Stack(
        children: [
          Text(numText, style: shadowStyle),
          Text(numText, style: fillStyle),
        ],
      ),
    );
  }
}
