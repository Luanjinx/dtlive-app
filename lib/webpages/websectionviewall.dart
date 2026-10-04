import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/sectionviewallprovider.dart';
import '../provider/videobyidprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';
import '../webwidget/web_hover_card.dart';

class WebSectionViewAll extends StatefulWidget {
  final int sectionId, videoType;
  final String appBarTitle, screenLayout;
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebSectionViewAll({
    required this.appBarTitle,
    required this.screenLayout,
    required this.sectionId,
    required this.videoType,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebSectionViewAll> createState() => WebSectionViewAllState();
}

class WebSectionViewAllState extends State<WebSectionViewAll> {
  Timer? _timer;
  late SectionViewAllProvider sectionViewAllProvider;

  Future<void> _fetchSectionDetails(int? nextPage) async {
    printLog("_fetchSectionDetails nextPage  ========> $nextPage");
    printLog(
      "_fetchSectionDetails isMorePage  ======> ${sectionViewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchSectionDetails currentPage ======> ${sectionViewAllProvider.currentPage}",
    );
    printLog(
      "_fetchSectionDetails totalPage   ======> ${sectionViewAllProvider.totalPage}",
    );

    await sectionViewAllProvider.getSectionDetails(
      widget.sectionId,
      (nextPage ?? 0) + 1,
    );
    printLog(
      "sectionDetailsList length ==> ${sectionViewAllProvider.sectionDetailList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    sectionViewAllProvider = Provider.of<SectionViewAllProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    // Always load the first page
    await _fetchSectionDetails(0);

    final isAutoLoadType =
        (widget.videoType == Constant.genresType ||
        widget.videoType == Constant.languageType ||
        widget.videoType == Constant.channelType);

    if (isAutoLoadType) {
      _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
        if (sectionViewAllProvider.isMorePage == true) {
          sectionViewAllProvider.setLoadMore(true);
          await _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
        } else {
          printLog("======== CANCELLED ========");
          timer.cancel();
        }
      });
    } else if (!widget.screenLayout.contains("index")) {
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (sectionViewAllProvider.isMorePage == true) {
          sectionViewAllProvider.setLoadMore(true);
          await _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
        }
      });
    }
  }

  @override
  void dispose() {
    sectionViewAllProvider.clearProvider();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: widget.sectionId.toString(),
    );
  }

  Widget _buildAppbar() {
    if (widget.appBarTitle == "") {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
        child: SizedBox(),
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
      child: MyText(
        text: widget.appBarTitle,
        multilanguage: false,
        color: colorPrimary,
        fontsizeNormal: 20,
        fontsizeWeb: 25,
        maxline: 1,
        fontweight: FontWeight.w600,
        fontstyle: FontStyle.normal,
        textalign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPageUI() {
    return Consumer<SectionViewAllProvider>(
      builder: (context, sectionViewAllProvider, child) {
        if (sectionViewAllProvider.loading &&
            !sectionViewAllProvider.loadMore) {
          if (widget.videoType == Constant.genresType) {
            return ShimmerUtils.responsiveGrid2(
              context,
              Dimens.isBigScreen(context)
                  ? Dimens.heightGenWeb
                  : Dimens.heightGen,
              Dimens.isBigScreen(context)
                  ? Dimens.widthGenWeb
                  : Dimens.widthGen,
              3,
              3,
              3,
              25,
            );
          } else if (widget.videoType == Constant.languageType ||
              widget.videoType == Constant.channelType) {
            return ShimmerUtils.responsiveGrid2(
              context,
              Dimens.isBigScreen(context)
                  ? Dimens.heightChannelWeb
                  : Dimens.heightChannel,
              Dimens.isBigScreen(context)
                  ? Dimens.widthChannelWeb
                  : Dimens.widthChannel,
              3,
              3,
              3,
              25,
            );
          } else {
            return ShimmerUtils.responsiveGrid(
              context,
              Dimens.isBigScreen(context)
                  ? Dimens.heightPortOtherWeb
                  : Dimens.heightPortOther,
              Dimens.isBigScreen(context)
                  ? Dimens.widthPortOtherWeb
                  : Dimens.widthPortOther,
              2,
              Dimens.isBigScreen(context) ? 40 : 20,
            );
          }
        }
        if (sectionViewAllProvider.sectionDetailList == null ||
            (sectionViewAllProvider.sectionDetailList?.length ?? 0) > 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: Dimens.homeTabHeight),
              _buildAppbar(),
              if (widget.videoType == Constant.genresType)
                _buildGenres()
              else if (widget.videoType == Constant.languageType)
                _buildLanguage()
              else if (widget.videoType == Constant.channelType)
                _buildChannelItem()
              else
                _buildVideoItem(),
              /* Pagination loader */
              if (sectionViewAllProvider.loadMore)
                ShimmerUtils.responsiveGrid(
                  context,
                  Dimens.isBigScreen(context)
                      ? Dimens.heightPortOtherWeb
                      : Dimens.heightPortOther,
                  Dimens.isBigScreen(context)
                      ? Dimens.widthPortOtherWeb
                      : Dimens.widthPortOther,
                  2,
                  10,
                )
              else
                const SizedBox.shrink(),
            ],
          );
        } else {
          return NoData(
            title: (widget.videoType == Constant.genresType)
                ? 'no_category_title'
                : ((widget.videoType == Constant.languageType)
                      ? 'no_language_title'
                      : ((widget.videoType == Constant.channelType)
                            ? 'no_channel_title'
                            : 'no_data')),
            subTitle: (widget.videoType == Constant.genresType)
                ? 'no_category_desc'
                : ((widget.videoType == Constant.languageType)
                      ? 'no_language_desc'
                      : ((widget.videoType == Constant.channelType)
                            ? 'no_channel_desc'
                            : 'no_video_show')),
          );
        }
      },
    );
  }

  Widget _buildVideoItem() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double cardW = bigScreen
        ? Dimens.widthPortOtherWeb
        : Dimens.widthPortOther;
    final double cardH = bigScreen
        ? Dimens.heightPortOtherWeb
        : Dimens.heightPortOther;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Wrap(
        spacing: bigScreen ? 12 : 8,
        runSpacing: bigScreen ? 16 : 10,
        alignment: WrapAlignment.start,
        children: List.generate(
          sectionViewAllProvider.sectionDetailList?.length ?? 0,
          (position) => WebHoverCard(
            cardW: cardW,
            cardH: cardH,
            borderRadius: Dimens.cardRadiusMedium,
            imageUrl:
                sectionViewAllProvider.sectionDetailList?[position].thumbnail
                    .toString() ??
                "",
            onTap: () {
              printLog("Clicked on position ==> $position");
              Utils.openDetails(
                context: context,
                videoId:
                    sectionViewAllProvider.sectionDetailList?[position].id ?? 0,
                subVideoType:
                    sectionViewAllProvider
                        .sectionDetailList?[position]
                        .subVideoType ??
                    0,
                videoType:
                    sectionViewAllProvider
                        .sectionDetailList?[position]
                        .videoType ??
                    0,
                typeId:
                    sectionViewAllProvider
                        .sectionDetailList?[position]
                        .typeId ??
                    0,
                newPage: RoutesConstant.contentDetailsPage,
                oldPage: widget.newPage ?? "",
                reqText: "",
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChannelItem() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double cardW = bigScreen
        ? Dimens.widthChannelWeb
        : Dimens.widthChannel;
    final double cardH = bigScreen
        ? Dimens.heightChannelWeb
        : Dimens.heightChannel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Wrap(
        spacing: bigScreen ? 20 : 10,
        runSpacing: bigScreen ? 20 : 10,
        alignment: WrapAlignment.start,
        children: List.generate(
          sectionViewAllProvider.sectionDetailList?.length ?? 0,
          (position) => WebHoverCard(
            cardW: cardW,
            cardH: cardH,
            borderRadius: Dimens.cardRadiusMedium,
            imageUrl:
                sectionViewAllProvider.sectionDetailList?[position].landscapeImg
                    .toString() ??
                "",
            onTap: () async {
              printLog("Clicked on position ==> $position");
              final videoByIDProvider = Provider.of<VideoByIDProvider>(
                context,
                listen: false,
              );
              videoByIDProvider.setLoading(true);
              if (!mounted) return;
              context.go(
                "/${RoutesConstant.videoByChannelPage}/${sectionViewAllProvider.sectionDetailList?[position].id ?? 0}",
                extra: {
                  'newpage': widget.newPage.toString(),
                  'itemid':
                      (sectionViewAllProvider.sectionDetailList?[position].id ??
                              0)
                          .toString(),
                  'title':
                      sectionViewAllProvider
                          .sectionDetailList?[position]
                          .name ??
                      '',
                  'layouttype': 'ByChannel',
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguage() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double itemH = bigScreen
        ? Dimens.heightLangWeb
        : Dimens.heightLangViewAll;
    final double itemW = bigScreen
        ? Dimens.widthLangWeb
        : Dimens.widthLangViewAll;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Wrap(
        spacing: bigScreen ? 20 : 10,
        runSpacing: bigScreen ? 20 : 10,
        alignment: WrapAlignment.start,
        children: List.generate(
          sectionViewAllProvider.sectionDetailList?.length ?? 0,
          (position) => _HoverCircleCard(
            width: itemW,
            height: itemH,
            imageUrl:
                sectionViewAllProvider.sectionDetailList?[position].image
                    .toString() ??
                "",
            fit: BoxFit.contain,
            onTap: () async {
              printLog("Clicked on position ==> $position");
              final videoByIDProvider = Provider.of<VideoByIDProvider>(
                context,
                listen: false,
              );
              videoByIDProvider.setLoading(true);
              if (!mounted) return;
              context.go(
                "/${RoutesConstant.videoByLanguagePage}/${sectionViewAllProvider.sectionDetailList?[position].id ?? 0}",
                extra: {
                  'newpage': widget.newPage.toString(),
                  'itemid':
                      (sectionViewAllProvider.sectionDetailList?[position].id ??
                              0)
                          .toString(),
                  'title':
                      sectionViewAllProvider
                          .sectionDetailList?[position]
                          .name ??
                      '',
                  'layouttype': 'ByLanguage',
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGenres() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double itemH = bigScreen ? Dimens.heightGenWeb : Dimens.heightGen;
    final double itemW = bigScreen ? Dimens.widthGenWeb : Dimens.widthGen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Wrap(
        spacing: bigScreen ? 20 : 10,
        runSpacing: bigScreen ? 20 : 10,
        alignment: WrapAlignment.start,
        children: List.generate(
          sectionViewAllProvider.sectionDetailList?.length ?? 0,
          (position) => _HoverCircleCard(
            width: itemW,
            height: itemH,
            imageUrl:
                sectionViewAllProvider.sectionDetailList?[position].image
                    .toString() ??
                "",
            fit: BoxFit.cover,
            onTap: () async {
              printLog("Clicked on position ==> $position");
              final videoByIDProvider = Provider.of<VideoByIDProvider>(
                context,
                listen: false,
              );
              videoByIDProvider.setLoading(true);
              if (!mounted) return;
              context.go(
                "/${RoutesConstant.videoByCatPage}/${sectionViewAllProvider.sectionDetailList?[position].id ?? 0}",
                extra: {
                  'newpage': widget.newPage.toString(),
                  'itemid':
                      (sectionViewAllProvider.sectionDetailList?[position].id ??
                              0)
                          .toString(),
                  'title':
                      sectionViewAllProvider
                          .sectionDetailList?[position]
                          .name ??
                      '',
                  'layouttype': 'ByCategory',
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HoverCircleCard extends StatefulWidget {
  final double width;
  final double height;
  final String imageUrl;
  final BoxFit fit;
  final VoidCallback onTap;

  const _HoverCircleCard({
    required this.width,
    required this.height,
    required this.imageUrl,
    required this.fit,
    required this.onTap,
  });

  @override
  State<_HoverCircleCard> createState() => _HoverCircleCardState();
}

class _HoverCircleCardState extends State<_HoverCircleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => SizedBox(
            width: widget.width,
            height: widget.height,
            child: Transform.scale(
              scale: _scale.value,
              alignment: Alignment.center,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _ctrl.value > 0
                      ? [
                          BoxShadow(
                            color: colorPrimary.withValues(
                              alpha: _ctrl.value * 0.35,
                            ),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                  border: _ctrl.value > 0
                      ? Border.all(
                          color: colorPrimary.withValues(alpha: _ctrl.value),
                          width: 2,
                        )
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: MyNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: widget.fit,
                    height: widget.height,
                    width: widget.width,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
