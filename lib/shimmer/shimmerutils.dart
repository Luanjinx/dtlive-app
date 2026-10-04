import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../utils/color.dart';
import '../utils/dimens.dart';
import '../shimmer/shimmerwidget.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';

class ShimmerUtils {
  static Widget buildHomeMobileShimmer(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: kIsWeb ? null : const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Dimens.isBigScreen(context)
                ? bannerWeb(context)
                : bannerMobile(context),
            ListView.builder(
              itemCount: 10, // itemCount must be greater than 5
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                if (index == 1) {
                  return setHomeSections(context, "portrait");
                } else if (index == 2) {
                  return setHomeSections(context, "square");
                } else if (index == 3) {
                  return setHomeSections(context, "langGen");
                } else {
                  return setHomeSections(context, "landscape");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget bannerMobile(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double bannerH = Dimens.getBannerHeight(context);

    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      children: [
        /* ── Poster shimmer ── */
        SizedBox(
          height: bannerH,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              /* Poster block */
              Container(
                width: screenW,
                height: bannerH,
                margin: EdgeInsets.only(bottom: Dimens.homeTabHeight),
                child: ShimmerWidget.roundcorner(
                  height: bannerH,
                  shapeBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              /* Top-fade gradient */
              Container(
                width: screenW,
                height: bannerH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      appBgColor.withValues(alpha: 0.9),
                      appBgColor.withValues(alpha: 0.5),
                      appBgColor.withValues(alpha: 0.1),
                      transparent,
                      transparent,
                    ],
                  ),
                ),
              ),
              /* Bottom-fade gradient */
              Container(
                width: screenW,
                height: bannerH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      transparent,
                      appBgColor.withValues(alpha: 0.3),
                      appBgColor.withValues(alpha: 0.6),
                      appBgColor.withValues(alpha: 0.85),
                      appBgColor,
                      appBgColor,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /* ── Title, meta, category at bottom ── */
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              /* Title — 2 lines */
              ShimmerWidget.roundrectborder(
                height: 22,
                width: screenW * 0.68,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 7),
              ShimmerWidget.roundrectborder(
                height: 22,
                width: screenW * 0.48,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 10),
              /* Category / language meta */
              ShimmerWidget.roundrectborder(
                height: 13,
                width: screenW * 0.42,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 6),
              ShimmerWidget.roundrectborder(
                height: 13,
                width: screenW * 0.58,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),

        /* ── Buttons & dot indicator ── */
        Positioned(
          bottom: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              /* Watch Now + Watchlist icon */
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerWidget.roundrectborder(
                    height: 45,
                    width: screenW * 0.45,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShimmerWidget.roundrectborder(
                    height: 45,
                    width: 45,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ],
              ),
              /* Dot indicator */
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 14, 5, 5),
                child: const AnimatedSmoothIndicator(
                  count: 5,
                  activeIndex: 2,
                  effect: ScrollingDotsEffect(
                    spacing: 8,
                    radius: 4,
                    activeDotScale: 1.2,
                    activeDotColor: colorPrimary,
                    dotColor: defaultIconColor,
                    dotHeight: 6,
                    dotWidth: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget bannerWeb(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double bannerH = Dimens.getResponsiveHeight(context, 0);
    final double contentW = Dimens.isBigScreen(context)
        ? (screenW * 0.35)
        : (screenW * 0.5);

    Widget line({
      required double width,
      double height = 13,
      double radius = 5,
    }) => ShimmerWidget.roundrectborder(
      height: height,
      width: width,
      shimmerBgColor: shimmerItemColor,
      shapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );

    return SizedBox(
      width: screenW,
      height: bannerH,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          /* ── Poster shimmer ── */
          ShimmerWidget.roundcorner(
            height: bannerH,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),

          /* ── Left gradient overlay (50% width) ── */
          Container(
            width: screenW * 0.5,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  appBgColor,
                  appBgColor.withValues(alpha: 0.9),
                  appBgColor.withValues(alpha: 0.7),
                  appBgColor.withValues(alpha: 0.5),
                  appBgColor.withValues(alpha: 0.3),
                  appBgColor.withValues(alpha: 0.1),
                  transparent,
                ],
              ),
            ),
          ),

          /* ── Bottom gradient overlay ── */
          Container(
            width: screenW,
            transform: Matrix4.translationValues(0, 1, 0),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  appBgColor,
                  appBgColor.withValues(alpha: 0.9),
                  appBgColor.withValues(alpha: 0.7),
                  appBgColor.withValues(alpha: 0.5),
                  appBgColor.withValues(alpha: 0.3),
                  appBgColor.withValues(alpha: 0.1),
                  transparent,
                ],
              ),
            ),
          ),

          /* ── Title, category, description, Watch Now (bottom-left) ── */
          Positioned(
            left: 35,
            bottom: 35,
            child: SizedBox(
              width: contentW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* Title: 33px, 2 lines */
                  line(width: contentW * 0.75, height: 33, radius: 7),
                  const SizedBox(height: 8),
                  line(width: contentW * 0.52, height: 33, radius: 7),
                  const SizedBox(height: 14),

                  /* Category */
                  line(width: contentW * 0.58, height: 13, radius: 4),
                  const SizedBox(height: 10),

                  /* Description: 2 lines */
                  line(width: contentW * 0.88, height: 12, radius: 4),
                  const SizedBox(height: 5),
                  line(width: contentW * 0.65, height: 12, radius: 4),
                  const SizedBox(height: 20),

                  /* Watch Now + Watchlist button */
                  Row(
                    children: [
                      line(width: 155, height: 45, radius: 8),
                      const SizedBox(width: 10),
                      line(width: 45, height: 45, radius: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /* ── Dot indicator (bottom-right) ── */
          Positioned(
            bottom: bannerH / 5,
            right: 80,
            child: const AnimatedSmoothIndicator(
              count: 5,
              activeIndex: 2,
              effect: ScrollingDotsEffect(
                spacing: 8,
                radius: 4,
                activeDotScale: 1.2,
                activeDotColor: colorPrimary,
                dotColor: defaultIconColor,
                dotHeight: 7,
                dotWidth: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget continueWatching(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ShimmerWidget.roundrectborder(
            height: 15,
            width: 100,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: Dimens.heightContiLand,
          child: ListView.separated(
            itemCount: kIsWeb ? 6 : 3,
            shrinkWrap: true,
            padding: const EdgeInsets.only(left: 20, right: 20),
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            separatorBuilder: (context, index) =>
                SizedBox(width: Dimens.spaceBetweenCards),
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                alignment: AlignmentDirectional.bottomStart,
                children: [
                  Container(
                    width: Dimens.widthContiLand,
                    height: Dimens.heightContiLand,
                    alignment: Alignment.center,
                    child: ShimmerWidget.roundcorner(
                      width: Dimens.widthContiLand,
                      height: Dimens.heightContiLand,
                      shimmerBgColor: shimmerItemColor,
                      shapeBorder: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 8),
                        child: ShimmerWidget.circular(
                          width: 30,
                          height: 30,
                          shimmerBgColor: black,
                        ),
                      ),
                      Container(
                        width: Dimens.widthContiLand,
                        constraints: const BoxConstraints(minWidth: 0),
                        padding: const EdgeInsets.all(3),
                        child: ShimmerWidget.roundcorner(
                          width: Dimens.widthContiLand,
                          height: 4,
                          shimmerBgColor: black,
                          shapeBorder: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget setHomeSections(BuildContext context, String layoutType) {
    final double hPad = Dimens.isBigScreen(context) ? 35 : 20;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /* Section title */
              ShimmerWidget.roundrectborder(
                height: 16,
                width: 130,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              /* "See All" link */
              ShimmerWidget.roundrectborder(
                height: 13,
                width: 55,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (layoutType == "portrait") portraitListView(context),
        if (layoutType == "landscape") landscapeListView(context),
        if (layoutType == "square") squareListView(context),
        if (layoutType == "langGen") langGenListView(context),
        const SizedBox(height: 28),
      ],
    );
  }

  static Widget buildRentShimmer(
    BuildContext context,
    double itemHeight,
    double itemWidth,
  ) {
    return normalHorizontalGrid(context, itemHeight, itemWidth, 3);
  }

  static Widget buildFindShimmer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 100, 8, 8),
      child: StaggeredGrid.count(
        crossAxisCount: 6, // Keep this Fix
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: Utils.buildGroupedTiles(
          dataCount: 9,
          contentItem: buildFindShimmerItem,
        ),
      ),
    );
  }

  static Widget buildFindShimmerItem({required int position}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
      child: Container(
        alignment: Alignment.center,
        child: ShimmerWidget.roundcorner(
          height: double.infinity,
          shapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
          ),
        ),
      ),
    );
  }

  static Widget landscapeListView(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.isBigScreen(context)
          ? Dimens.heightLandWeb
          : Dimens.heightLand,
      child: ListView.separated(
        itemCount: kIsWeb ? 20 : 10,
        shrinkWrap: true,
        physics: const PageScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) =>
            SizedBox(width: Dimens.spaceBetweenCards),
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              Dimens.isBigScreen(context)
                  ? Dimens.cardRadiusMedium
                  : Dimens.cardRadius,
            ),
            child: Container(
              width: Dimens.isBigScreen(context)
                  ? Dimens.widthLandWeb
                  : Dimens.widthLand,
              height: Dimens.isBigScreen(context)
                  ? Dimens.heightLandWeb
                  : Dimens.heightLand,
              alignment: Alignment.center,
              child: ShimmerWidget.roundcorner(
                height: Dimens.isBigScreen(context)
                    ? Dimens.heightLandWeb
                    : Dimens.heightLand,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Dimens.isBigScreen(context)
                        ? Dimens.cardRadiusMedium
                        : Dimens.cardRadius,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget portraitListView(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.isBigScreen(context)
          ? Dimens.heightPortWeb
          : Dimens.heightPort,
      child: ListView.separated(
        itemCount: kIsWeb ? 20 : 10,
        shrinkWrap: true,
        physics: const PageScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) =>
            SizedBox(width: Dimens.spaceBetweenCards),
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              Dimens.isBigScreen(context)
                  ? Dimens.cardRadiusMedium
                  : Dimens.cardRadius,
            ),
            child: Container(
              width: Dimens.isBigScreen(context)
                  ? Dimens.widthPortWeb
                  : Dimens.widthPort,
              height: Dimens.isBigScreen(context)
                  ? Dimens.heightPortWeb
                  : Dimens.heightPort,
              alignment: Alignment.center,
              child: ShimmerWidget.roundcorner(
                height: Dimens.isBigScreen(context)
                    ? Dimens.heightPortWeb
                    : Dimens.heightPort,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Dimens.isBigScreen(context)
                        ? Dimens.cardRadiusMedium
                        : Dimens.cardRadius,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget sectionPortraitListView(BuildContext context) {
    final double hPad = Dimens.isBigScreen(context) ? 35 : 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget.roundrectborder(
                height: 16,
                width: 130,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              ShimmerWidget.roundrectborder(
                height: 13,
                width: 55,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        portraitListView(context),
        const SizedBox(height: 28),
      ],
    );
  }

  static Widget squareListView(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.isBigScreen(context)
          ? Dimens.heightSquareWeb
          : Dimens.heightSquare,
      child: ListView.separated(
        itemCount: kIsWeb ? 20 : 10,
        shrinkWrap: true,
        physics: const PageScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) =>
            SizedBox(width: Dimens.spaceBetweenCards),
        itemBuilder: (BuildContext context, int index) {
          return Container(
            width: Dimens.isBigScreen(context)
                ? Dimens.widthSquareWeb
                : Dimens.widthSquare,
            height: Dimens.isBigScreen(context)
                ? Dimens.heightSquareWeb
                : Dimens.heightSquare,
            alignment: Alignment.center,
            child: ShimmerWidget.roundcorner(
              height: Dimens.isBigScreen(context)
                  ? Dimens.heightSquareWeb
                  : Dimens.heightSquare,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Dimens.isBigScreen(context)
                      ? Dimens.cardRadiusMedium
                      : Dimens.cardRadius,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget langGenListView(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLang,
      child: ListView.separated(
        itemCount: kIsWeb ? 20 : 10,
        shrinkWrap: true,
        physics: const PageScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) =>
            SizedBox(width: Dimens.spaceBetweenCards),
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            width: Dimens.widthLang,
            height: Dimens.heightLang,
            child: Stack(
              alignment: AlignmentDirectional.bottomStart,
              children: [
                Container(
                  width: Dimens.widthLang,
                  height: Dimens.heightLang,
                  alignment: Alignment.center,
                  child: ShimmerWidget.roundcorner(
                    height: Dimens.heightLang,
                    shapeBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(3),
                  child: ShimmerWidget.roundrectborder(
                    height: 10,
                    shimmerBgColor: black,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget normalHorizontalGrid(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int crossAxisCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      height: itemHeight * crossAxisCount,
      child: AlignedGridView.count(
        shrinkWrap: true,
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        itemCount: kIsWeb ? 40 : 20,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int position) {
          return Container(
            width: itemWidth,
            height: itemHeight,
            alignment: Alignment.center,
            child: ShimmerWidget.roundcorner(
              height: itemHeight,
              shapeBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget normalVerticalGrid(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int crossAxisCount,
    int itemCount,
  ) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      itemCount: kIsWeb ? (itemCount + 10) : itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: itemWidth,
          height: itemHeight,
          alignment: Alignment.center,
          child: ShimmerWidget.roundcorner(
            height: itemHeight,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        );
      },
    );
  }

  static Widget responsiveGrid(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int minCrossCount,
    int itemCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ResponsiveGridList(
        minItemWidth: itemWidth,
        verticalGridSpacing: 8,
        horizontalGridSpacing: 8,
        minItemsPerRow: minCrossCount,
        maxItemsPerRow: 20,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(itemCount, (position) {
          return Container(
            width: itemWidth,
            height: itemHeight,
            alignment: Alignment.center,
            child: ShimmerWidget.roundcorner(
              height: itemHeight,
              shapeBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          );
        }),
      ),
    );
  }

  static Widget responsiveGrid2(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int minCrossCount,
    double verticalGridSpacing,
    double horizontalGridSpacing,
    int itemCount,
  ) {
    return Column(
      children: [
        kIsWeb
            ? SizedBox(height: Dimens.homeTabHeight)
            : const SizedBox.shrink(),
        ResponsiveGridList(
          minItemWidth: itemWidth,
          minItemsPerRow: minCrossCount,
          verticalGridSpacing: verticalGridSpacing,
          horizontalGridSpacing: horizontalGridSpacing,
          maxItemsPerRow: 20,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(itemCount, (position) {
            return Container(
              width: itemWidth,
              height: itemHeight,
              alignment: Alignment.center,
              child: ShimmerWidget.roundcorner(
                height: itemHeight,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  static Widget buildDetailMobileShimmer(
    BuildContext context,
    String detailType,
  ) {
    final double screenW = MediaQuery.of(context).size.width;
    // Poster height matches _buildMobilePoster: (screenW - 24) / landRatio
    final double posterH = Dimens.getResponsiveHeight(context, 24);
    // Feature icon size matches _buildFeatureBtnItem: Dimens.featureIconSize (15px)
    final double featureIconH = Dimens.featureIconSize;
    // Label size below feature icon: 11px
    const double featureLabelH = 11;
    // Horizontal padding used throughout the page
    const double hPad = 12.0;

    Widget line({double? width, double height = 13, double radius = 5}) =>
        ShimmerWidget.roundrectborder(
          height: height,
          width: width ?? (screenW - hPad * 2),
          shimmerBgColor: shimmerItemColor,
          shapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
        );

    // Feature button: just icon shimmer + label below (no circle border)
    // Matches _buildFeatureBtnItem: padding all(5), minWidth featureSize+20
    Widget featureBtn() => Container(
      width: Dimens.featureSize + 20,
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerWidget.roundrectborder(
            height: featureIconH,
            width: featureIconH,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          const SizedBox(height: 10),
          ShimmerWidget.roundrectborder(
            height: featureLabelH,
            width: 36,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /* ── 1. POSTER (padded + rounded, matches _buildMobilePoster) ── */
        Padding(
          padding: const EdgeInsets.fromLTRB(hPad, 5, hPad, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ShimmerWidget.roundcorner(
              height: posterH,
              shapeBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        /* ── 2. TITLE (center-aligned, 25px) ────────────────────────── */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              line(width: screenW * 0.72, height: 22, radius: 6),
              const SizedBox(height: 6),
              line(width: screenW * 0.5, height: 22, radius: 6),
            ],
          ),
        ),
        const SizedBox(height: 8),

        /* ── 3. META ROW (year • duration, centered) ─────────────────── */
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            line(width: 50, height: 13),
            const SizedBox(width: 8),
            const ShimmerWidget.circular(
              height: 4,
              width: 4,
              shimmerBgColor: shimmerItemColor,
            ),
            const SizedBox(width: 8),
            line(width: 70, height: 13),
          ],
        ),
        const SizedBox(height: 18),

        /* ── 4. WATCH NOW BUTTON (height 45, radius 8) ───────────────── */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: ShimmerWidget.roundrectborder(
            height: 45,
            width: screenW,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        /* ── 5. PREMIUM / RENT TAGS (left-aligned, 12px lines) ──────── */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(width: 110, height: 12, radius: 4),
              const SizedBox(height: 4),
              line(width: 160, height: 12, radius: 4),
            ],
          ),
        ),
        const SizedBox(height: 8),

        /* ── 6. CATEGORY line (left-aligned, 13px) ───────────────────── */
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: 5),
            child: line(width: screenW * 0.55, height: 13, radius: 4),
          ),
        ),

        /* ── 7. LANGUAGE line (left-aligned, 13px) ───────────────────── */
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: 5),
            child: line(width: screenW * 0.42, height: 13, radius: 4),
          ),
        ),
        const SizedBox(height: 7),

        /* ── 8. DESCRIPTION (3 lines, varying widths) ────────────────── */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(height: 12),
              const SizedBox(height: 6),
              line(height: 12),
              const SizedBox(height: 6),
              line(width: screenW * 0.65, height: 12),
            ],
          ),
        ),

        /* ── 9. FEATURE BUTTONS (horizontal scroll, icon + label) ────── */
        /* Matches _buildFeatureBtns: margin top 25, padding fromLTRB(8,0,8,0) */
        Container(
          margin: const EdgeInsets.only(top: 25),
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                featureBtn(), // Rent
                featureBtn(), // Trailer / StartOver
                if (!kIsWeb) featureBtn(), // Download
                featureBtn(), // Watchlist
                featureBtn(), // Rate
                if (!kIsWeb) featureBtn(), // More
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        /* ── 10. RELATED CONTENT (horizontal shimmer list) ───────────── */
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: hPad),
            child: line(width: 130, height: 15, radius: 5),
          ),
        ),
        const SizedBox(height: 12),
        landscapeListView(context),
        const SizedBox(height: 24),

        /* ── 11. CAST & CREW ─────────────────────────────────────────── */
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: hPad),
            child: line(width: 100, height: 15, radius: 5),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad),
            child: line(width: 80, height: 13, radius: 4),
          ),
        ),
        const SizedBox(height: 12),
        responsiveGrid(
          context,
          kIsWeb ? Dimens.heightCastWeb : Dimens.heightCast,
          kIsWeb ? Dimens.widthCastWeb : Dimens.widthCast,
          3,
          6,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static Widget buildDetailWebShimmer(BuildContext context, String detailType) {
    final double screenW = MediaQuery.of(context).size.width;
    final double posterH = Dimens.getResponsiveHeight(context, 0);
    // Content on the left overlaid on poster: half-screen on small, full on large
    final double contentW = (screenW < 1000)
        ? (screenW * 0.5)
        : (screenW * 0.55);
    const double leftPad = 35.0;

    Widget line({double? width, double height = 13, double radius = 5}) =>
        ShimmerWidget.roundrectborder(
          height: height,
          width: width ?? screenW,
          shimmerBgColor: shimmerItemColor,
          shapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
        );

    Widget featureBtn() => Container(
      width: Dimens.featureSize + 20,
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerWidget.roundrectborder(
            height: Dimens.featureIconSize,
            width: Dimens.featureIconSize,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 6),
          ShimmerWidget.roundrectborder(
            height: 10,
            width: Dimens.featureSize,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* ── 1. POSTER STACK (full-width, no padding, no border radius) ── */
        SizedBox(
          height: posterH,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              /* Poster shimmer */
              ShimmerWidget.roundrectborder(
                height: posterH,
                width: screenW,
                shimmerBgColor: shimmerItemColor,
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              /* Left gradient overlay (50% width) */
              Container(
                width: screenW * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      appBgColor,
                      appBgColor.withValues(alpha: 0.9),
                      appBgColor.withValues(alpha: 0.7),
                      appBgColor.withValues(alpha: 0.5),
                      appBgColor.withValues(alpha: 0.3),
                      appBgColor.withValues(alpha: 0.1),
                      transparent,
                    ],
                  ),
                ),
              ),
              /* Bottom gradient overlay */
              Container(
                width: screenW,
                transform: Matrix4.translationValues(0, 1, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      appBgColor,
                      appBgColor.withValues(alpha: 0.9),
                      appBgColor.withValues(alpha: 0.7),
                      appBgColor.withValues(alpha: 0.5),
                      appBgColor.withValues(alpha: 0.3),
                      appBgColor.withValues(alpha: 0.1),
                      transparent,
                    ],
                  ),
                ),
              ),
              /* Title, meta, tags, category, language, description — overlaid */
              Positioned(
                left: leftPad,
                bottom: leftPad,
                child: SizedBox(
                  width: contentW - leftPad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /* Title: 33px, 2 lines */
                      line(width: contentW * 0.62, height: 33, radius: 7),
                      const SizedBox(height: 8),
                      line(width: contentW * 0.42, height: 33, radius: 7),
                      const SizedBox(height: 12),

                      /* Meta: year • duration */
                      Row(
                        children: [
                          line(width: 55, height: 13),
                          const SizedBox(width: 8),
                          const ShimmerWidget.circular(
                            height: 4,
                            width: 4,
                            shimmerBgColor: shimmerItemColor,
                          ),
                          const SizedBox(width: 8),
                          line(width: 75, height: 13),
                        ],
                      ),
                      const SizedBox(height: 10),

                      /* Prime / Rent tag lines */
                      line(width: 110, height: 12, radius: 4),
                      const SizedBox(height: 4),
                      line(width: 170, height: 12, radius: 4),
                      const SizedBox(height: 8),

                      /* Category */
                      line(width: contentW * 0.48, height: 13, radius: 4),
                      const SizedBox(height: 6),

                      /* Language */
                      line(width: contentW * 0.35, height: 13, radius: 4),
                      const SizedBox(height: 10),

                      /* Description: 3 lines varying widths */
                      line(width: contentW * 0.88, height: 12, radius: 4),
                      const SizedBox(height: 5),
                      line(width: contentW * 0.88, height: 12, radius: 4),
                      const SizedBox(height: 5),
                      line(width: contentW * 0.58, height: 12, radius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /* ── 2. FEATURE BUTTONS (Watch Now + icon buttons, margin left 35) ── */
        Container(
          margin: const EdgeInsets.fromLTRB(leftPad, 16, 0, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* Watch Now button */
                ShimmerWidget.roundrectborder(
                  height: 45,
                  width: 160,
                  shimmerBgColor: shimmerItemColor,
                  shapeBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                featureBtn(), // Rent
                featureBtn(), // Trailer / StartOver
                featureBtn(), // Watchlist
                featureBtn(), // Rate
                featureBtn(), // Share
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        /* ── 3. RELATED CONTENT ──────────────────────────────────────────── */
        Padding(
          padding: const EdgeInsets.only(left: leftPad),
          child: line(width: 130, height: 15, radius: 5),
        ),
        const SizedBox(height: 12),
        landscapeListView(context),
        const SizedBox(height: 28),

        /* ── 4. CAST & CREW ──────────────────────────────────────────────── */
        Padding(
          padding: const EdgeInsets.only(left: leftPad),
          child: line(width: 100, height: 15, radius: 5),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: leftPad),
          child: line(width: 80, height: 13, radius: 4),
        ),
        const SizedBox(height: 12),
        responsiveGrid(
          context,
          kIsWeb ? Dimens.heightCastWeb : Dimens.heightCast,
          kIsWeb ? Dimens.widthCastWeb : Dimens.widthCast,
          3,
          10,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static Widget buildWatchlistShimmer(BuildContext context, int itemCount) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 0,
      mainAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kIsWeb ? (itemCount + 10) : itemCount,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(minHeight: Dimens.heightWatchlist),
          color: shimmerItemColor,
          child: Row(
            children: [
              Container(
                constraints: BoxConstraints(
                  minHeight: Dimens.heightWatchlist,
                  maxWidth: MediaQuery.of(context).size.width * 0.44,
                ),
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: Dimens.heightWatchlist,
                      alignment: Alignment.center,
                      child: ShimmerWidget.roundcorner(
                        width: MediaQuery.of(context).size.width,
                        height: Dimens.heightWatchlist,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 8),
                          child: ShimmerWidget.circular(
                            width: 30,
                            height: 30,
                            shimmerBgColor: black,
                          ),
                        ),
                        Container(
                          width: Dimens.widthContiLand,
                          constraints: const BoxConstraints(minWidth: 0),
                          padding: const EdgeInsets.all(3),
                          child: ShimmerWidget.roundcorner(
                            width: Dimens.widthContiLand,
                            height: 4,
                            shimmerBgColor: black,
                            shapeBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: Dimens.heightWatchlist,
                    maxWidth: MediaQuery.of(context).size.width * 0.66,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            /* Title */
                            const ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 100,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            /* Release Year & Video Duration */
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: const ShimmerWidget.roundrectborder(
                                    height: 15,
                                    width: 60,
                                    shimmerBgColor: black,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 20),
                                  child: const ShimmerWidget.roundrectborder(
                                    height: 15,
                                    width: 80,
                                    shimmerBgColor: black,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            /* Prime TAG  & Rent TAG */
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /* Prime TAG */
                                ShimmerWidget.roundrectborder(
                                  height: 13,
                                  width: 80,
                                  shimmerBgColor: black,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3),
                                /* Rent TAG */
                                ShimmerWidget.roundrectborder(
                                  height: 13,
                                  width: 80,
                                  shimmerBgColor: black,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(6),
                          child: const ShimmerWidget.circular(
                            height: 18,
                            width: 18,
                            shimmerBgColor: black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildDownloadShimmer(BuildContext context, int itemCount) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 0,
      mainAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kIsWeb ? (itemCount + 10) : itemCount,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(minHeight: Dimens.heightWatchlist),
          color: shimmerItemColor,
          child: Row(
            children: [
              Container(
                constraints: BoxConstraints(
                  minHeight: Dimens.heightWatchlist,
                  maxWidth: MediaQuery.of(context).size.width * 0.44,
                ),
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: Dimens.heightWatchlist,
                      alignment: Alignment.center,
                      child: ShimmerWidget.roundcorner(
                        width: MediaQuery.of(context).size.width,
                        height: Dimens.heightWatchlist,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 8),
                          child: ShimmerWidget.circular(
                            width: 30,
                            height: 30,
                            shimmerBgColor: black,
                          ),
                        ),
                        Container(
                          width: Dimens.widthContiLand,
                          constraints: const BoxConstraints(minWidth: 0),
                          padding: const EdgeInsets.all(3),
                          child: ShimmerWidget.roundcorner(
                            width: Dimens.widthContiLand,
                            height: 4,
                            shimmerBgColor: black,
                            shapeBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: Dimens.heightWatchlist,
                    maxWidth: MediaQuery.of(context).size.width * 0.66,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            /* Title */
                            const ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 100,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            /* Release Year & Video Duration */
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: const ShimmerWidget.roundrectborder(
                                    height: 15,
                                    width: 60,
                                    shimmerBgColor: black,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 20),
                                  child: const ShimmerWidget.roundrectborder(
                                    height: 15,
                                    width: 80,
                                    shimmerBgColor: black,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            /* Prime TAG  & Rent TAG */
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /* Prime TAG */
                                ShimmerWidget.roundrectborder(
                                  height: 13,
                                  width: 80,
                                  shimmerBgColor: black,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3),
                                /* Rent TAG */
                                ShimmerWidget.roundrectborder(
                                  height: 13,
                                  width: 80,
                                  shimmerBgColor: black,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(6),
                          child: const ShimmerWidget.circular(
                            height: 18,
                            width: 18,
                            shimmerBgColor: black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildSubscribeShimmer(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 20, right: 20),
          alignment: Alignment.center,
          child: ShimmerWidget.roundrectborder(
            height: 20,
            width: MediaQuery.of(context).size.width,
            shimmerBgColor: black,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 30, right: 30),
          alignment: Alignment.center,
          child: ShimmerWidget.roundrectborder(
            height: 20,
            width: MediaQuery.of(context).size.width,
            shimmerBgColor: black,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        /* Remaining Data */
        Padding(
          padding: const EdgeInsets.all(10),
          child: Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: 5,
            color: black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  constraints: const BoxConstraints(minHeight: 55),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerWidget.roundrectborder(
                        height: 18,
                        width: 120,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                      ShimmerWidget.roundrectborder(
                        height: 16,
                        width: 80,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 0.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: shimmerItemColor,
                ),
                AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  itemCount: 7,
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int position) {
                    return Container(
                      constraints: const BoxConstraints(minHeight: 30),
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: const Row(
                        children: [
                          Expanded(
                            child: ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 100,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          ShimmerWidget.circular(
                            height: 30,
                            width: 30,
                            shimmerBgColor: shimmerItemColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                /* Choose Plan */
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: ShimmerWidget.roundrectborder(
                      height: 52,
                      width: MediaQuery.of(context).size.width * 0.5,
                      shimmerBgColor: shimmerItemColor,
                      shapeBorder: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSubscribeWebShimmer(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 20, right: 20),
          alignment: Alignment.center,
          child: ShimmerWidget.roundrectborder(
            height: 20,
            width: MediaQuery.of(context).size.width,
            shimmerBgColor: black,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 30, right: 30),
          alignment: Alignment.center,
          child: ShimmerWidget.roundrectborder(
            height: 20,
            width: MediaQuery.of(context).size.width,
            shimmerBgColor: black,
            shapeBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        /* Remaining Data */
        Container(
          height: 350,
          padding: const EdgeInsets.only(left: 30, right: 30, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  elevation: 5,
                  color: black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        constraints: const BoxConstraints(minHeight: 55),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 120,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            ShimmerWidget.roundrectborder(
                              height: 16,
                              width: 80,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: shimmerItemColor,
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      /* Choose Plan */
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ShimmerWidget.roundrectborder(
                            height: 52,
                            width: MediaQuery.of(context).size.width * 0.5,
                            shimmerBgColor: shimmerItemColor,
                            shapeBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  elevation: 5,
                  color: black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        constraints: const BoxConstraints(minHeight: 55),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 120,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            ShimmerWidget.roundrectborder(
                              height: 16,
                              width: 80,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: shimmerItemColor,
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      /* Choose Plan */
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ShimmerWidget.roundrectborder(
                            height: 52,
                            width: MediaQuery.of(context).size.width * 0.5,
                            shimmerBgColor: shimmerItemColor,
                            shapeBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  elevation: 5,
                  color: black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        constraints: const BoxConstraints(minHeight: 55),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerWidget.roundrectborder(
                              height: 18,
                              width: 120,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            ShimmerWidget.roundrectborder(
                              height: 16,
                              width: 80,
                              shimmerBgColor: shimmerItemColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: shimmerItemColor,
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 100,
                                shimmerBgColor: shimmerItemColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            ShimmerWidget.circular(
                              height: 30,
                              width: 30,
                              shimmerBgColor: shimmerItemColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      /* Choose Plan */
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ShimmerWidget.roundrectborder(
                            height: 52,
                            width: MediaQuery.of(context).size.width * 0.5,
                            shimmerBgColor: shimmerItemColor,
                            shapeBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildAvatarGridShimmer(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int crossAxisCount,
    int itemCount,
  ) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: kIsWeb ? (itemCount + 10) : itemCount,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: itemWidth,
          height: itemHeight,
          alignment: Alignment.center,
          child: ShimmerWidget.circular(
            height: itemHeight,
            shimmerBgColor: shimmerItemColor,
          ),
        );
      },
    );
  }

  static Widget buildAvatarGridWebShimmer(
    BuildContext context,
    double itemHeight,
    double itemWidth,
    int crossAxisCount,
    int itemCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ResponsiveGridList(
        minItemWidth: itemWidth,
        verticalGridSpacing: 15,
        horizontalGridSpacing: 15,
        minItemsPerRow: 3,
        maxItemsPerRow: crossAxisCount,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(itemCount, (position) {
          return Container(
            width: itemWidth,
            height: itemHeight,
            alignment: Alignment.center,
            child: ShimmerWidget.roundcorner(
              height: itemHeight,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(itemHeight / 2),
              ),
            ),
          );
        }),
      ),
    );
  }

  static Widget buildHistoryShimmer(BuildContext context, int itemCount) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 0,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.only(left: 15, right: 15),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kIsWeb ? (itemCount + 10) : itemCount,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(minHeight: Dimens.heightHistory),
          decoration: Utils.setBackground(lightBlack, 5),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /* Title */
                      const ShimmerWidget.roundrectborder(
                        height: 20,
                        width: 120,
                        shimmerBgColor: black,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),

                      /* Price */
                      Container(
                        constraints: const BoxConstraints(minHeight: 0),
                        margin: const EdgeInsets.only(top: 5),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerWidget.roundrectborder(
                              height: 15,
                              width: 80,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            ShimmerWidget.roundrectborder(
                              height: 15,
                              width: 3,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 120,
                                shimmerBgColor: black,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /* Expire On */
                      Container(
                        constraints: const BoxConstraints(minHeight: 0),
                        margin: const EdgeInsets.only(top: 5),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerWidget.roundrectborder(
                              height: 15,
                              width: 80,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            ShimmerWidget.roundrectborder(
                              height: 15,
                              width: 3,
                              shimmerBgColor: black,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: ShimmerWidget.roundrectborder(
                                height: 18,
                                width: 120,
                                shimmerBgColor: black,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 30,
                constraints: const BoxConstraints(minWidth: 0),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                alignment: Alignment.center,
                child: const ShimmerWidget.roundrectborder(
                  height: 20,
                  width: 100,
                  shimmerBgColor: black,
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildEpisodeShimmer(BuildContext context, int itemCount) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 0,
      mainAxisSpacing: 15,
      padding: const EdgeInsets.only(left: 0, right: 0),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            minHeight: kIsWeb ? Dimens.heightEpiLandWeb : Dimens.heightEpiLand,
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    kIsWeb ? Dimens.cardRadiusMedium : Dimens.cardRadius,
                  ),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: ShimmerWidget.roundrectborder(
                    height: kIsWeb
                        ? Dimens.heightEpiLandWeb
                        : Dimens.heightEpiLand,
                    width: kIsWeb
                        ? Dimens.widthEpiLandWeb
                        : Dimens.widthEpiLand,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        kIsWeb ? Dimens.cardRadiusMedium : Dimens.cardRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ShimmerWidget.roundrectborder(
                      height: 20,
                      shapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minHeight: 0),
                      margin: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ShimmerWidget.roundrectborder(
                              height: 17,
                              width: 50,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: ShimmerWidget.roundrectborder(
                              height: 20,
                              width: 80,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minHeight: 0),
                      margin: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ShimmerWidget.roundrectborder(
                          height: 15,
                          shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: ShimmerWidget.roundrectborder(
                  height: 30,
                  width: 30,
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildClipsShimmer(BuildContext context, bool isFromBottomBar) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ShimmerWidget.roundrectborder(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),

        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: ShimmerWidget.roundrectborder(
              width: 50,
              height: 50,
              shimmerBgColor: appBgColor,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        // Overlays: progress + icons
        SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: kToolbarHeight,
                  padding: EdgeInsets.fromLTRB(4, 0, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isFromBottomBar)
                        InkWell(
                          onTap: () {
                            Utils.exitPage(context);
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            padding: EdgeInsets.all(12),
                            child: MyImage(
                              imagePath: "back.png",
                              fit: BoxFit.contain,
                              color: white,
                            ),
                          ),
                        ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: ShimmerWidget.roundrectborder(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 20,
                              shimmerBgColor: appBgColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SizedBox()),
                Container(
                  padding: EdgeInsets.fromLTRB(12, 0, 0, 20),
                  constraints: BoxConstraints(
                    minHeight: 0,
                    minWidth: 0,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: 18,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 15),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      /* Feature Buttons */
                      Container(
                        padding: EdgeInsets.only(right: 20),
                        constraints: const BoxConstraints(minWidth: 45),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /* Mute/Unmute */
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ShimmerWidget.roundrectborder(
                                width: 32,
                                height: 32,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            /* Like */
                            buildFeatureIcon(context),

                            /* BookMark */
                            buildFeatureIcon(context),

                            /* Episodes */
                            buildFeatureIcon(context),

                            /* Share */
                            buildFeatureIcon(context),

                            /* Report */
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ShimmerWidget.roundrectborder(
                                width: 32,
                                height: 32,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ShimmerWidget.roundrectborder(
                    width: MediaQuery.of(context).size.width,
                    height: 5,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildClipsEpisodeShimmer(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ShimmerWidget.roundrectborder(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),

        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: ShimmerWidget.roundrectborder(
              width: 50,
              height: 50,
              shimmerBgColor: appBgColor,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        // Overlays: progress + icons
        SafeArea(
          child: Column(
            children: [
              Container(
                height: kToolbarHeight,
                padding: EdgeInsets.fromLTRB(4, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Utils.exitPage(context);
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        padding: EdgeInsets.all(12),
                        child: MyImage(
                          imagePath: "back.png",
                          fit: BoxFit.contain,
                          color: white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: ShimmerWidget.roundrectborder(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 20,
                            shimmerBgColor: appBgColor,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ShimmerWidget.roundrectborder(
                        height: 32,
                        width: 32,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ShimmerWidget.roundrectborder(
                        height: 32,
                        width: 32,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.fromLTRB(12, 0, 0, 0),
                constraints: BoxConstraints(
                  minHeight: 0,
                  minWidth: 0,
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: SizedBox()),
                    /* Feature Buttons */
                    Container(
                      padding: EdgeInsets.only(right: 20),
                      constraints: const BoxConstraints(minWidth: 45),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /* View */
                          buildFeatureIcon(context),

                          /* Episodes */
                          buildFeatureIcon(context),

                          /* Share */
                          buildFeatureIcon(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ShimmerWidget.roundrectborder(
                    width: MediaQuery.of(context).size.width,
                    height: 5,
                    shimmerBgColor: appBgColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: ShimmerWidget.roundrectborder(
                        width: 50,
                        height: 15,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: ShimmerWidget.roundrectborder(
                        width: 50,
                        height: 15,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: ShimmerWidget.roundrectborder(
                        width: 60,
                        height: 15,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ShimmerWidget.roundrectborder(
                        width: 25,
                        height: 25,
                        shimmerBgColor: appBgColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildClipsWEBShimmer(
    BuildContext context,
    bool isFromBottomBar,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ShimmerWidget.roundrectborder(
          width: (MediaQuery.of(context).size.width > 1080)
              ? (MediaQuery.of(context).size.width * 0.3)
              : ((MediaQuery.of(context).size.width <= 1080 &&
                        MediaQuery.of(context).size.width > 720)
                    ? (MediaQuery.of(context).size.width * 0.5)
                    : MediaQuery.of(context).size.width),
          height: MediaQuery.of(context).size.height * 0.85,
        ),

        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: ShimmerWidget.roundrectborder(
              width: 50,
              height: 50,
              shimmerBgColor: appBgColor,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        // Overlays: progress + icons
        SafeArea(
          child: Container(
            margin: EdgeInsets.only(top: Dimens.homeTabHeight),
            width: (MediaQuery.of(context).size.width > 1080)
                ? (MediaQuery.of(context).size.width * 0.3)
                : ((MediaQuery.of(context).size.width <= 1080 &&
                          MediaQuery.of(context).size.width > 720)
                      ? (MediaQuery.of(context).size.width * 0.5)
                      : MediaQuery.of(context).size.width),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: kToolbarHeight,
                  padding: EdgeInsets.fromLTRB(4, 0, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isFromBottomBar)
                        InkWell(
                          onTap: () {
                            Utils.exitPage(context);
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            padding: EdgeInsets.all(12),
                            child: MyImage(
                              imagePath: "back.png",
                              fit: BoxFit.contain,
                              color: white,
                            ),
                          ),
                        ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: ShimmerWidget.roundrectborder(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 20,
                              shimmerBgColor: appBgColor,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SizedBox()),
                Container(
                  padding: EdgeInsets.fromLTRB(12, 0, 0, 20),
                  constraints: BoxConstraints(
                    minHeight: 0,
                    minWidth: 0,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: 18,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 15),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              alignment: Alignment.centerLeft,
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 12,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      /* Feature Buttons */
                      Container(
                        padding: EdgeInsets.only(right: 20),
                        constraints: const BoxConstraints(minWidth: 45),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /* Mute/Unmute */
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ShimmerWidget.roundrectborder(
                                width: 32,
                                height: 32,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            /* Like */
                            buildFeatureIcon(context),

                            /* BookMark */
                            buildFeatureIcon(context),

                            /* Episodes */
                            buildFeatureIcon(context),

                            /* Share */
                            buildFeatureIcon(context),

                            /* Report */
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ShimmerWidget.roundrectborder(
                                width: 32,
                                height: 32,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ShimmerWidget.roundrectborder(
                    width: MediaQuery.of(context).size.width,
                    height: 5,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildClipsEpisodeWEBShimmer(BuildContext context) {
    if (MediaQuery.of(context).size.width > 1200) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(top: Dimens.homeTabHeight),
                  child: ShimmerWidget.roundrectborder(
                    width: (MediaQuery.of(context).size.width > 1080)
                        ? (MediaQuery.of(context).size.width * 0.3)
                        : ((MediaQuery.of(context).size.width <= 1080 &&
                                  MediaQuery.of(context).size.width > 720)
                              ? (MediaQuery.of(context).size.width * 0.5)
                              : MediaQuery.of(context).size.width),
                    height: MediaQuery.of(context).size.height * 0.85,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width > 1100)
                      ? (MediaQuery.of(context).size.width * 0.3)
                      : ((MediaQuery.of(context).size.width <= 1100 &&
                                MediaQuery.of(context).size.width > 720)
                            ? (MediaQuery.of(context).size.width * 0.5)
                            : MediaQuery.of(context).size.width),
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: SizedBox()),
                          Container(
                            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: ShimmerWidget.roundrectborder(
                                width: MediaQuery.of(context).size.width,
                                height: 5,
                                shimmerBgColor: appBgColor,
                                shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: ShimmerWidget.roundrectborder(
                                    width: 50,
                                    height: 15,
                                    shimmerBgColor: appBgColor,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: ShimmerWidget.roundrectborder(
                                    width: 50,
                                    height: 15,
                                    shimmerBgColor: appBgColor,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                Spacer(),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: ShimmerWidget.roundrectborder(
                                    width: 25,
                                    height: 25,
                                    shimmerBgColor: appBgColor,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: ShimmerWidget.roundrectborder(
                                    width: 25,
                                    height: 25,
                                    shimmerBgColor: appBgColor,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: ShimmerWidget.roundrectborder(
                                    width: 25,
                                    height: 25,
                                    shimmerBgColor: appBgColor,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                /* Page Change Buttons */
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: ShimmerWidget.roundrectborder(
                          width: 45,
                          height: 45,
                          shimmerBgColor: shimmerItemColor,
                          shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: ShimmerWidget.roundrectborder(
                          width: 45,
                          height: 45,
                          shimmerBgColor: shimmerItemColor,
                          shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
            height: MediaQuery.of(context).size.height,
            decoration: Utils.setBackground(secondaryBgColor, 2),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10, Dimens.homeTabHeight, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* Show Title */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  /* Episode Title */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  /* Feature button */
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Utils.buildGradLine(),
                  SizedBox(height: 20),
                  /* Description */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Utils.buildGradLine(),
                  SizedBox(height: 25),
                  /* Episodes */
                  Container(
                    alignment: Alignment.centerLeft,
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: 120,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 15),
                    child: ResponsiveGridList(
                      minItemWidth: Dimens.isBigScreen(context)
                          ? Dimens.widthEpiBigWeb
                          : Dimens.widthEpiWeb,
                      verticalGridSpacing: 8,
                      horizontalGridSpacing: 8,
                      minItemsPerRow: 4,
                      maxItemsPerRow: 8,
                      listViewBuilderOptions: ListViewBuilderOptions(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                      children: List.generate(8, (position) {
                        return Material(
                          type: MaterialType.transparency,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: Dimens.isBigScreen(context)
                                  ? Dimens.widthEpiBigWeb
                                  : Dimens.widthEpiWeb,
                              height: Dimens.isBigScreen(context)
                                  ? Dimens.heightEpiBigWeb
                                  : Dimens.heightEpiWeb,
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: ShimmerWidget.roundrectborder(
                                        width: Dimens.isBigScreen(context)
                                            ? Dimens.widthEpiBigWeb
                                            : Dimens.widthEpiWeb,
                                        height: Dimens.isBigScreen(context)
                                            ? Dimens.heightEpiBigWeb
                                            : Dimens.heightEpiWeb,
                                        shimmerBgColor: shimmerItemColor,
                                        shapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      child: ShimmerWidget.roundrectborder(
                                        height: 20,
                                        width: 20,
                                        shimmerBgColor: secondaryBgColor,
                                        shapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: Dimens.getResponsivePortHeight(context, 50),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: Dimens.homeTabHeight),
                    child: ShimmerWidget.roundrectborder(
                      width: (MediaQuery.of(context).size.width > 1080)
                          ? (MediaQuery.of(context).size.width * 0.3)
                          : ((MediaQuery.of(context).size.width <= 1080 &&
                                    MediaQuery.of(context).size.width > 720)
                                ? (MediaQuery.of(context).size.width * 0.5)
                                : MediaQuery.of(context).size.width),
                      height: MediaQuery.of(context).size.height * 0.85,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width > 1100)
                        ? (MediaQuery.of(context).size.width * 0.3)
                        : ((MediaQuery.of(context).size.width <= 1100 &&
                                  MediaQuery.of(context).size.width > 720)
                              ? (MediaQuery.of(context).size.width * 0.5)
                              : MediaQuery.of(context).size.width),
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: SizedBox()),
                            Container(
                              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: ShimmerWidget.roundrectborder(
                                  width: MediaQuery.of(context).size.width,
                                  height: 5,
                                  shimmerBgColor: appBgColor,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: ShimmerWidget.roundrectborder(
                                      width: 50,
                                      height: 15,
                                      shimmerBgColor: appBgColor,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: ShimmerWidget.roundrectborder(
                                      width: 50,
                                      height: 15,
                                      shimmerBgColor: appBgColor,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: ShimmerWidget.roundrectborder(
                                      width: 25,
                                      height: 25,
                                      shimmerBgColor: appBgColor,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: ShimmerWidget.roundrectborder(
                                      width: 25,
                                      height: 25,
                                      shimmerBgColor: appBgColor,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: ShimmerWidget.roundrectborder(
                                      width: 25,
                                      height: 25,
                                      shimmerBgColor: appBgColor,
                                      shapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  /* Page Change Buttons */
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: ShimmerWidget.roundrectborder(
                            width: 45,
                            height: 45,
                            shimmerBgColor: shimmerItemColor,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: ShimmerWidget.roundrectborder(
                            width: 45,
                            height: 45,
                            shimmerBgColor: shimmerItemColor,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 1,
              margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
              decoration: Utils.setBackground(secondaryBgColor, 2),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.fromLTRB(25, 20, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* Show Title */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  /* Episode Title */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  /* Feature button */
                  SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                        buildFeatureIconWEB(context),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Utils.buildGradLine(),
                  SizedBox(height: 20),
                  /* Description */
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 10,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Utils.buildGradLine(),
                  SizedBox(height: 25),
                  /* Episodes */
                  Container(
                    alignment: Alignment.centerLeft,
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ShimmerWidget.roundrectborder(
                        width: 120,
                        height: 15,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 15),
                    child: ResponsiveGridList(
                      minItemWidth: Dimens.isBigScreen(context)
                          ? Dimens.widthEpiBigWeb
                          : Dimens.widthEpiWeb,
                      verticalGridSpacing: 8,
                      horizontalGridSpacing: 8,
                      minItemsPerRow: 4,
                      maxItemsPerRow: 8,
                      listViewBuilderOptions: ListViewBuilderOptions(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                      children: List.generate(8, (position) {
                        return Material(
                          type: MaterialType.transparency,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: Dimens.isBigScreen(context)
                                  ? Dimens.widthEpiBigWeb
                                  : Dimens.widthEpiWeb,
                              height: Dimens.isBigScreen(context)
                                  ? Dimens.heightEpiBigWeb
                                  : Dimens.heightEpiWeb,
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: ShimmerWidget.roundrectborder(
                                        width: Dimens.isBigScreen(context)
                                            ? Dimens.widthEpiBigWeb
                                            : Dimens.widthEpiWeb,
                                        height: Dimens.isBigScreen(context)
                                            ? Dimens.heightEpiBigWeb
                                            : Dimens.heightEpiWeb,
                                        shimmerBgColor: shimmerItemColor,
                                        shapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      child: ShimmerWidget.roundrectborder(
                                        height: 20,
                                        width: 20,
                                        shimmerBgColor: secondaryBgColor,
                                        shapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  static Widget buildFeatureIcon(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ShimmerWidget.roundrectborder(
            width: 32,
            height: 32,
            shimmerBgColor: appBgColor,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ShimmerWidget.roundrectborder(
            width: 32,
            height: 15,
            shimmerBgColor: appBgColor,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  static Widget buildFeatureIconWEB(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ShimmerWidget.roundrectborder(
            width: 32,
            height: 32,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ShimmerWidget.roundrectborder(
            width: 32,
            height: 15,
            shimmerBgColor: shimmerItemColor,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  /* ── Wallet History shimmer ────────────────────────────── */

  static Widget buildWalletHistoryShimmer(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildWalletHistoryItemShimmer(),
    );
  }

  static Widget _buildWalletHistoryItemShimmer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: secondaryBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          /* Circle icon placeholder */
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(30),
            child: ShimmerWidget.circular(
              width: 42,
              height: 42,
              shimmerBgColor: shimmerItemColor,
            ),
          ),
          const SizedBox(width: 12),
          /* Text lines */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(6),
                  child: ShimmerWidget.roundrectborder(
                    height: 14,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(4),
                  child: ShimmerWidget.roundrectborder(
                    width: 120,
                    height: 11,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          /* Trailing amount placeholder */
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(6),
            child: ShimmerWidget.roundrectborder(
              width: 56,
              height: 16,
              shimmerBgColor: shimmerItemColor,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ── Refer & Earn History shimmer ──────────────────────── */

  static Widget buildReferEarnHistoryShimmer(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildReferEarnHistoryItemShimmer(),
    );
  }

  static Widget _buildReferEarnHistoryItemShimmer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: secondaryBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Avatar circle */
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(30),
            child: ShimmerWidget.circular(
              width: 44,
              height: 44,
              shimmerBgColor: shimmerItemColor,
            ),
          ),
          const SizedBox(width: 12),
          /* Text lines */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(6),
                  child: ShimmerWidget.roundrectborder(
                    width: double.infinity,
                    height: 14,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(4),
                  child: ShimmerWidget.roundrectborder(
                    width: 140,
                    height: 12,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(4),
                  child: ShimmerWidget.roundrectborder(
                    width: 100,
                    height: 11,
                    shimmerBgColor: shimmerItemColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
