import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../model/sectionlistmodel.dart' as list;
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import 'mynetworkimg.dart';
import 'mytext.dart';

class ShortsSectionWidget extends StatelessWidget {
  final list.Result section;
  final bool showScrollArrows;
  final int twoRowsThreshold;
  final double? horizontalPadding;
  final ScrollController? scrollController;
  final Function(list.Datum datum, int index)? onItemTap;

  const ShortsSectionWidget({
    super.key,
    required this.section,
    this.showScrollArrows = true,
    this.twoRowsThreshold = 12,
    this.horizontalPadding,
    this.scrollController,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<list.Datum>? data = section.data;
    final int count = data?.length ?? 0;
    final bool big = Dimens.isBigScreen(context);
    final double cardW = big ? Dimens.widthShortsWeb : Dimens.widthShorts;
    final double cardH = big ? Dimens.heightShortsWeb : Dimens.heightShorts;
    final bool twoRows = count >= twoRowsThreshold;
    final double hPad = horizontalPadding ?? (big ? 35 : 20);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: twoRows
          ? (big ? Dimens.heightShortsTotalWeb : Dimens.heightShortsTotal) * 2
          : (big ? Dimens.heightShortsTotalWeb : Dimens.heightShortsTotal),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: AlignedGridView.count(
          itemCount: count,
          shrinkWrap: true,
          crossAxisCount: twoRows ? 2 : 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final list.Datum datum = data![index];
            return _ShortsSectionCard(
              key: ValueKey(datum.id),
              datum: datum,
              cardW: cardW,
              cardH: cardH,
              onTap: () => onItemTap?.call(datum, index),
            );
          },
        ),
      ),
    );
  }
}

class _ShortsSectionCard extends StatefulWidget {
  final list.Datum datum;
  final double cardW;
  final double cardH;
  final VoidCallback onTap;

  const _ShortsSectionCard({
    super.key,
    required this.datum,
    required this.cardW,
    required this.cardH,
    required this.onTap,
  });

  @override
  State<_ShortsSectionCard> createState() => _ShortsSectionCardState();
}

class _ShortsSectionCardState extends State<_ShortsSectionCard>
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
    final String thumb = widget.datum.thumbnail?.toString() ?? "";
    final String name = widget.datum.name?.toString() ?? "";

    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Transform.scale(
            scale: _scale.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: SizedBox(
                width: widget.cardW,
                height: widget.cardH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      /* Thumbnail */
                      MyNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        height: widget.cardH,
                        width: widget.cardW,
                      ),

                      /* Left colorAccent edge stripe */
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorAccent,
                                colorAccent.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      /* Bottom gradient + content */
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 32, 10, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                transparent,
                                appBgColor.withValues(alpha: 0.75),
                                appBgColor.withValues(alpha: 0.96),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /* Shorts pill */
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                margin: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  color: colorAccent.withValues(alpha: 0.90),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: white,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 3),
                                    MyText(
                                      color: white,
                                      text: "Shorts",
                                      multilanguage: false,
                                      fontsizeNormal: 9,
                                      fontsizeWeb: 10,
                                      fontweight: FontWeight.w700,
                                      maxline: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textalign: TextAlign.start,
                                      fontstyle: FontStyle.normal,
                                    ),
                                  ],
                                ),
                              ),
                              /* Title */
                              if (name.isNotEmpty)
                                MyText(
                                  color: white,
                                  text: name,
                                  multilanguage: false,
                                  fontsizeNormal: 13,
                                  fontsizeWeb: 15,
                                  fontweight: FontWeight.w600,
                                  maxline: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textalign: TextAlign.start,
                                  fontstyle: FontStyle.normal,
                                  isShadowText: true,
                                ),
                            ],
                          ),
                        ),
                      ),

                      /* Premium / rent tag */
                      Positioned(
                        top: 8,
                        right: 6,
                        child: Utils.buildRentPremiumTAG(
                          context: context,
                          isPremium: widget.datum.isPremium ?? 0,
                          isRent: widget.datum.isRent ?? 0,
                          rentPrice: widget.datum.price ?? 0,
                        ),
                      ),

                      /* Hover play overlay */
                      if (_fade.value > 0)
                        Opacity(
                          opacity: _fade.value,
                          child: Container(
                            color: black.withValues(alpha: 0.28),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorAccent.withValues(alpha: 0.92),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorAccent.withValues(
                                        alpha: 0.55,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),

                      /* Hover border ring */
                      if (_fade.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorAccent.withValues(
                                    alpha: _fade.value * 0.65,
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
