import 'dart:async';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/nodata.dart';
import '../provider/videobyidprovider.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';

class ContentByID extends StatefulWidget {
  final String appBarTitle, layoutType;
  final int itemID;
  const ContentByID(
    this.itemID,
    this.appBarTitle,
    this.layoutType, {
    super.key,
  });

  @override
  State<ContentByID> createState() => ContentByIDState();
}

class ContentByIDState extends State<ContentByID> {
  late VideoByIDProvider videoByIDProvider;
  final nestedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    nestedScrollController.addListener(_nestedScrollListener);
    videoByIDProvider = Provider.of<VideoByIDProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    if (widget.layoutType == "ByCategory") {
      await videoByIDProvider.getVideoByCategory(widget.itemID, 1);
    } else if (widget.layoutType == "ByLanguage") {
      await videoByIDProvider.getVideoByLanguage(widget.itemID, 1);
    } else if (widget.layoutType == "ByChannel") {
      await videoByIDProvider.getVideoByChannel(widget.itemID, 1);
    } else if (widget.layoutType == "ByCast") {
      await videoByIDProvider.getCastDetails(widget.itemID);
      await videoByIDProvider.getVideoByCast(widget.itemID, 1);
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _nestedScrollListener() async {
    if (!nestedScrollController.hasClients) return;
    if (nestedScrollController.offset >=
            nestedScrollController.position.maxScrollExtent &&
        !nestedScrollController.position.outOfRange &&
        (videoByIDProvider.isMorePage ?? false)) {
      videoByIDProvider.setLoadMore(true);
      _fetchNewData(videoByIDProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchNewData(int? nextPage) async {
    printLog("_fetchNewData nextPage =========> $nextPage");
    printLog(
      "_fetchNewData isMorePage =======> ${videoByIDProvider.isMorePage}",
    );
    printLog(
      "_fetchNewData currentPage ======> ${videoByIDProvider.currentPage}",
    );
    printLog(
      "_fetchNewData totalPage ========> ${videoByIDProvider.totalPage}",
    );

    if (widget.layoutType == "ByCategory") {
      await videoByIDProvider.getVideoByCategory(
        widget.itemID,
        (nextPage ?? 0) + 1,
      );
    } else if (widget.layoutType == "ByLanguage") {
      await videoByIDProvider.getVideoByLanguage(
        widget.itemID,
        (nextPage ?? 0) + 1,
      );
    } else if (widget.layoutType == "ByChannel") {
      await videoByIDProvider.getVideoByChannel(
        widget.itemID,
        (nextPage ?? 0) + 1,
      );
    } else if (widget.layoutType == "ByCast") {
      await videoByIDProvider.getVideoByCast(
        widget.itemID,
        (nextPage ?? 0) + 1,
      );
    }
    printLog("contentList length ==> ${videoByIDProvider.contentList?.length}");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    videoByIDProvider.clearProvider();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, widget.appBarTitle, false),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: nestedScrollController,
          child: Column(children: [_buildCastDetails(), _buildPage()]),
        ),
      ),
    );
  }

  Widget _buildCastDetails() {
    return Consumer<VideoByIDProvider>(
      builder: (context, videoByIDProvider, child) {
        if (widget.layoutType == "ByCast" &&
            videoByIDProvider.castDetailModel.status == 200 &&
            videoByIDProvider.castDetailModel.result != null &&
            (videoByIDProvider.castDetailModel.result?.length ?? 0) > 0) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: MyNetworkImage(
                    imageUrl:
                        videoByIDProvider.castDetailModel.result?[0].image
                            .toString() ??
                        "",
                    fit: BoxFit.cover,
                    height: 90,
                    width: 90,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: const BoxConstraints(minHeight: 0),
                  alignment: Alignment.centerLeft,
                  child: ExpandableText(
                    videoByIDProvider.castDetailModel.status == 200
                        ? videoByIDProvider.castDetailModel.result != null
                              ? (videoByIDProvider
                                        .castDetailModel
                                        .result?[0]
                                        .personalInfo
                                        .toString() ??
                                    "-")
                              : "-"
                        : "-",
                    expandText: Locales.string(context, "more"),
                    collapseText: Locales.string(context, "less"),
                    maxLines: 10,
                    linkColor: descTextColor,
                    textAlign: TextAlign.start,
                    expandOnTextTap: true,
                    collapseOnTextTap: true,
                    style: GoogleFonts.inter(
                      letterSpacing: 0.5,
                      wordSpacing: 0.2,
                      fontSize: 14,
                      fontStyle: FontStyle.normal,
                      color: descTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPage() {
    if (videoByIDProvider.loading) {
      return ShimmerUtils.responsiveGrid2(
        context,
        Dimens.heightPortOther,
        Dimens.widthPortOther,
        3,
        3,
        3,
        12,
      );
    }
    if (videoByIDProvider.contentList != null &&
        (videoByIDProvider.contentList?.length ?? 0) > 0) {
      return Column(
        children: [
          _buildVideoItem(),

          /* Pagination loader */
          Consumer<VideoByIDProvider>(
            builder: (context, videoByIDProvider, child) {
              if (videoByIDProvider.loadMore) {
                return ShimmerUtils.responsiveGrid2(
                  context,
                  Dimens.heightPortOther,
                  Dimens.widthPortOther,
                  3,
                  3,
                  3,
                  3,
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      );
    } else {
      return NoData(
        title: (widget.layoutType == "ByCategory")
            ? 'no_category_data_title'
            : ((widget.layoutType == "ByLanguage")
                  ? 'no_language_data_title'
                  : 'no_cast_data_title'),
        subTitle: (widget.layoutType == "ByCategory")
            ? 'no_category_data_desc'
            : ((widget.layoutType == "ByLanguage")
                  ? 'no_language_data_desc'
                  : 'no_cast_data_desc'),
      );
    }
  }

  Widget _buildVideoItem() {
    return RefreshIndicator(
      backgroundColor: white,
      color: complimentryColor,
      displacement: 80,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1500)).then((value) {
          videoByIDProvider.setLoading(true);
          Future.delayed(Duration.zero).then((value) {
            if (!mounted) return;
            setState(() {});
          });
          _getData();
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
        child: ResponsiveGridList(
          minItemWidth: Dimens.widthPortOther,
          verticalGridSpacing: 3,
          horizontalGridSpacing: 3,
          minItemsPerRow: 3,
          maxItemsPerRow: 8,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(
            (videoByIDProvider.contentList?.length ?? 0),
            (position) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
                child: InkWell(
                  onTap: () {
                    printLog("Clicked on position ==> $position");
                    if (widget.layoutType == "ByCast") {
                      Utils.exitPage(context);
                      Utils.openDetailsWithReplace(
                        context: context,
                        videoId:
                            videoByIDProvider.contentList?[position].id ?? 0,
                        subVideoType:
                            videoByIDProvider
                                .contentList?[position]
                                .subVideoType ??
                            0,
                        videoType:
                            videoByIDProvider
                                .contentList?[position]
                                .videoType ??
                            0,
                        typeId:
                            videoByIDProvider.contentList?[position].typeId ??
                            0,
                        newPage:
                            ((videoByIDProvider
                                            .contentList?[position]
                                            .subVideoType ??
                                        0) ==
                                    2 ||
                                (videoByIDProvider
                                            .contentList?[position]
                                            .videoType ??
                                        0) ==
                                    2)
                            ? RoutesConstant.contentDetailsPage
                            : RoutesConstant.contentDetailsPage,
                        oldPage: "",
                        reqText: "",
                      );
                    } else {
                      Utils.openDetails(
                        context: context,
                        videoId:
                            videoByIDProvider.contentList?[position].id ?? 0,
                        subVideoType:
                            videoByIDProvider
                                .contentList?[position]
                                .subVideoType ??
                            0,
                        videoType:
                            videoByIDProvider
                                .contentList?[position]
                                .videoType ??
                            0,
                        typeId:
                            videoByIDProvider.contentList?[position].typeId ??
                            0,
                        newPage:
                            ((videoByIDProvider
                                            .contentList?[position]
                                            .subVideoType ??
                                        0) ==
                                    2 ||
                                (videoByIDProvider
                                            .contentList?[position]
                                            .videoType ??
                                        0) ==
                                    2)
                            ? RoutesConstant.contentDetailsPage
                            : RoutesConstant.contentDetailsPage,
                        oldPage: "",
                        reqText: "",
                      );
                    }
                  },
                  child: Container(
                    width: Dimens.widthPortOther,
                    height: Dimens.heightPortOther,
                    alignment: Alignment.center,
                    child: MyNetworkImage(
                      imageUrl:
                          videoByIDProvider.contentList?[position].thumbnail
                              .toString() ??
                          "",
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
