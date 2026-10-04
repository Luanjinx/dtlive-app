import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../model/sectionlistmodel.dart' as list;
import '../utils/color.dart';
import '../utils/dimens.dart';
import 'mynetworkimg.dart';
import 'mytext.dart';

enum GenreLangType { genre, language, channel }

class GenreLangSectionWidget extends StatelessWidget {
  final List<list.Datum>? items;
  final GenreLangType type;
  final bool showScrollArrows;
  final double? horizontalPadding;
  final double? itemSpacing;
  final int twoRowsThreshold;
  final ScrollController? scrollController;
  final Function(list.Datum datum, int index)? onItemTap;

  const GenreLangSectionWidget({
    super.key,
    required this.items,
    required this.type,
    this.showScrollArrows = true,
    this.horizontalPadding,
    this.itemSpacing,
    this.twoRowsThreshold = 13,
    this.scrollController,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool big = Dimens.isBigScreen(context);
    final double hPad = horizontalPadding ?? (big ? 35 : 20);
    final int count = items?.length ?? 0;

    if (type == GenreLangType.channel) {
      return _buildChannelLayout(context, big, hPad, count);
    }
    return _buildCircleLayout(context, big, hPad, count);
  }

  Widget _buildCircleLayout(
    BuildContext context,
    bool big,
    double hPad,
    int count,
  ) {
    final double itemW = _itemW(big);
    final double itemH = _itemH(big);
    final double labelH = big ? 36.0 : 28.0;
    final double gap =
        itemSpacing ?? (big ? Dimens.spaceBetweenLangCatWeb : _defaultGap());

    return SizedBox(
      width: double.infinity,
      height: itemH + labelH,
      child: ListView.separated(
        controller: scrollController,
        itemCount: count,
        shrinkWrap: true,
        clipBehavior: Clip.none,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: hPad, right: hPad),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, i) => SizedBox(width: gap),
        itemBuilder: (context, index) {
          final list.Datum datum = items![index];
          return _CircleCard(
            key: ValueKey(datum.id),
            datum: datum,
            itemW: itemW,
            itemH: itemH,
            labelH: labelH,
            onTap: () => onItemTap?.call(datum, index),
          );
        },
      ),
    );
  }

  Widget _buildChannelLayout(
    BuildContext context,
    bool big,
    double hPad,
    int count,
  ) {
    final double cardW = big ? Dimens.widthChannelWeb : Dimens.widthChannel;
    final double cardH = big ? Dimens.heightChannelWeb : Dimens.heightChannel;
    final double totalH = big
        ? Dimens.heightChannelTotalWeb
        : Dimens.heightChannelTotal;
    final bool twoRows = count >= twoRowsThreshold;
    final double gap =
        itemSpacing ??
        (big ? Dimens.spaceBetweenCardsWeb : Dimens.spaceBetweenChannel);

    return SizedBox(
      width: double.infinity,
      height: twoRows ? totalH * 2 : totalH,
      child: AlignedGridView.count(
        controller: scrollController,
        itemCount: count,
        shrinkWrap: true,
        clipBehavior: Clip.none,
        crossAxisCount: twoRows ? 2 : 1,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        padding: EdgeInsets.only(left: hPad, right: hPad),
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final list.Datum datum = items![index];
          return _ChannelCard(
            key: ValueKey(datum.id),
            datum: datum,
            cardW: cardW,
            cardH: cardH,
            onTap: () => onItemTap?.call(datum, index),
          );
        },
      ),
    );
  }

  double _itemW(bool big) {
    if (type == GenreLangType.language) {
      return big ? Dimens.widthLangWeb : Dimens.widthLang;
    }
    return big ? Dimens.widthGenWeb : Dimens.widthGen;
  }

  double _itemH(bool big) {
    if (type == GenreLangType.language) {
      return big ? Dimens.heightLangWeb : Dimens.heightLang;
    }
    return big ? Dimens.heightGenWeb : Dimens.heightGen;
  }

  double _defaultGap() {
    if (type == GenreLangType.language) return Dimens.spaceBetweenLang;
    return Dimens.spaceBetweenCategory;
  }
}

/* ─────────────────────────────────────────────────────────────────────────
   _CircleCard — Genre & Language circular items
   Hover: outer glow shadow + white border ring + scale. No image tint.
───────────────────────────────────────────────────────────────────────── */
class _CircleCard extends StatefulWidget {
  final list.Datum datum;
  final double itemW;
  final double itemH;
  final double labelH;
  final VoidCallback onTap;

  const _CircleCard({
    super.key,
    required this.datum,
    required this.itemW,
    required this.itemH,
    required this.labelH,
    required this.onTap,
  });

  @override
  State<_CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<_CircleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.07,
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
    final String imageUrl = widget.datum.image?.toString() ?? "";
    final String name = widget.datum.name?.toString() ?? "";
    final double radius = widget.itemH / 2;

    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.itemW,
              height: widget.itemH + widget.labelH,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /* Circle — scale + glow shadow + white border ring */
                  Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: widget.itemW,
                      height: widget.itemH,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        /* Outer glow — colorPrimary at low opacity */
                        boxShadow: _fade.value > 0
                            ? [
                                BoxShadow(
                                  color: colorPrimary.withValues(
                                    alpha: _fade.value * 0.50,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          /* Clean image — no tint overlay */
                          ClipRRect(
                            borderRadius: BorderRadius.circular(radius),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: MyNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: widget.itemW,
                              height: widget.itemH,
                            ),
                          ),

                          /* White border ring on hover */
                          if (_fade.value > 0)
                            Container(
                              width: widget.itemW,
                              height: widget.itemH,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: white.withValues(
                                    alpha: _fade.value * 0.85,
                                  ),
                                  width: 2.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /* Name label — white on hover, descTextColor at rest */
                  if (name.isNotEmpty)
                    Container(
                      height: widget.labelH,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 5),
                      child: MyText(
                        color: _fade.value > 0.5 ? white : descTextColor,
                        text: name,
                        multilanguage: false,
                        fontsizeNormal: 11,
                        fontsizeWeb: 12,
                        fontweight: FontWeight.w500,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    )
                  else
                    SizedBox(height: widget.labelH),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────
   _ChannelCard — landscape channel logo cards
   Hover: scale + outer glow + white border ring. No overlay text.
───────────────────────────────────────────────────────────────────────── */
class _ChannelCard extends StatefulWidget {
  final list.Datum datum;
  final double cardW;
  final double cardH;
  final VoidCallback onTap;

  const _ChannelCard({
    super.key,
    required this.datum,
    required this.cardW,
    required this.cardH,
    required this.onTap,
  });

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
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
    final String imageUrl = widget.datum.landscapeImg?.toString() ?? "";

    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.cardW,
                height: widget.cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
                  /* Outer glow on hover */
                  boxShadow: _fade.value > 0
                      ? [
                          BoxShadow(
                            color: white.withValues(alpha: _fade.value * 0.18),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      /* Channel logo image */
                      MyNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: widget.cardW,
                        height: widget.cardH,
                      ),

                      /* Subtle dark scrim on hover */
                      if (_fade.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: black.withValues(
                                alpha: _fade.value * 0.15,
                              ),
                            ),
                          ),
                        ),

                      /* White border ring on hover */
                      if (_fade.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Dimens.cardRadiusMedium,
                                ),
                                border: Border.all(
                                  color: white.withValues(
                                    alpha: _fade.value * 0.70,
                                  ),
                                  width: 1.5,
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
