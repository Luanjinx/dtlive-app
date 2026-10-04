import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../model/playermodel.dart';
import '../players/model/vdociphermodel.dart' as vdocipher;
import '../provider/viewallprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';

class ViewAll extends StatefulWidget {
  final String appBarTitle;
  final int videoId, subVideoType, videoType, typeId;
  const ViewAll({
    required this.appBarTitle,
    required this.videoId,
    required this.subVideoType,
    required this.videoType,
    required this.typeId,
    super.key,
  });

  @override
  State<ViewAll> createState() => ViewAllState();
}

class ViewAllState extends State<ViewAll> {
  late ViewAllProvider viewAllProvider;
  final _scrollController = ScrollController();

  Future<void> _nestedScrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (viewAllProvider.isMorePage ?? false)) {
      viewAllProvider.setLoadMore(true);
      if (widget.appBarTitle == RoutesConstant.relatedContentPage) {
        _fetchRelatedContent(viewAllProvider.currentPage ?? 0);
      } else if (widget.appBarTitle == RoutesConstant.continueWatchPage) {
        _fetchContinueWatch(viewAllProvider.currentPage ?? 0);
      }
    }
  }

  Future<void> _fetchRelatedContent(int? nextPage) async {
    printLog("_fetchRelatedContent nextPage  ========> $nextPage");
    printLog(
      "_fetchRelatedContent isMorePage  ======> ${viewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchRelatedContent currentPage ======> ${viewAllProvider.currentPage}",
    );
    printLog(
      "_fetchRelatedContent totalPage   ======> ${viewAllProvider.totalPage}",
    );

    await viewAllProvider.getRelatedContent(
      widget.typeId,
      widget.videoType,
      widget.videoId,
      widget.subVideoType,
      (nextPage ?? 0) + 1,
    );
    printLog(
      "_fetchRelatedContent length ==> ${viewAllProvider.relatedList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchContinueWatch(int? nextPage) async {
    printLog("_fetchContinueWatch nextPage  ========> $nextPage");
    printLog(
      "_fetchContinueWatch isMorePage  ======> ${viewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchContinueWatch currentPage ======> ${viewAllProvider.currentPage}",
    );
    printLog(
      "_fetchContinueWatch totalPage   ======> ${viewAllProvider.totalPage}",
    );

    await viewAllProvider.getContinueWatching((nextPage ?? 0) + 1);
    printLog(
      "_fetchContinueWatch length ==> ${viewAllProvider.continueWatchList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_nestedScrollListener);
    viewAllProvider = Provider.of<ViewAllProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    if (widget.appBarTitle == RoutesConstant.relatedContentPage) {
      viewAllProvider.relatedList?.clear();
      viewAllProvider.relatedList = [];
      _fetchRelatedContent(0);
    } else if (widget.appBarTitle == RoutesConstant.continueWatchPage) {
      viewAllProvider.continueWatchList?.clear();
      viewAllProvider.continueWatchList = [];
      _fetchContinueWatch(0);
    }
  }

  /* ========= Open Player ========= */
  Future<void> openPlayer({required int position}) async {
    printLog("position ==========> $position");

    /* CHECK SUBSCRIPTION */
    bool? isPrimiumUser = await Utils.checkSubsRentLogin(
      context: context,
      isPremium: viewAllProvider.continueWatchList?[position].isPremium ?? 0,
      isBuy: viewAllProvider.continueWatchList?[position].isBuy ?? 0,
      isRent: viewAllProvider.continueWatchList?[position].isRent ?? 0,
      rentBuy: viewAllProvider.continueWatchList?[position].rentBuy ?? 0,
      producerId: (viewAllProvider.continueWatchList?[position].producerId ?? 0)
          .toString(),
      videoId: (viewAllProvider.continueWatchList?[position].id ?? 0)
          .toString(),
      rentPrice: (viewAllProvider.continueWatchList?[position].price ?? 0)
          .toString(),
      vTitle: (viewAllProvider.continueWatchList?[position].name ?? 0)
          .toString(),
      typeId: (viewAllProvider.continueWatchList?[position].typeId ?? 0)
          .toString(),
      vType: (viewAllProvider.continueWatchList?[position].videoType ?? 0)
          .toString(),
      subVideoType:
          (viewAllProvider.continueWatchList?[position].subVideoType ?? 0)
              .toString(),
      rentProductId: (kIsWeb)
          ? (viewAllProvider.continueWatchList?[position].webPriceId
                    .toString() ??
                '')
          : (Platform.isIOS
                ? (viewAllProvider
                          .continueWatchList?[position]
                          .iosProductPackage
                          .toString() ??
                      '')
                : (viewAllProvider
                          .continueWatchList?[position]
                          .androidProductPackage
                          .toString() ??
                      '')),
      newPage: '',
      oldPage: '',
      reqText: '',
    );
    printLog("isPrimiumUser =============> $isPrimiumUser");
    if (!isPrimiumUser) return;
    /* CHECK SUBSCRIPTION */

    /* Set-up Quality URLs */
    Utils.setQualityURLs(
      video320: (viewAllProvider.continueWatchList?[position].video320 ?? ""),
      video480: (viewAllProvider.continueWatchList?[position].video480 ?? ""),
      video720: (viewAllProvider.continueWatchList?[position].video720 ?? ""),
      video1080: (viewAllProvider.continueWatchList?[position].video1080 ?? ""),
    );

    /* VdoCipher OTP */
    vdocipher.VdoCipherModel? vdocipherDetails;
    if ((viewAllProvider.continueWatchList?[position].videoUploadType ?? "") ==
        Constant.vdocipherPlayType) {
      if (!mounted) return;
      vdocipherDetails = await Utils.getVdoCipherOTP(
        context: context,
        videoId: (viewAllProvider.continueWatchList?[position].episode != null)
            ? (viewAllProvider.continueWatchList?[position].episode?.video320 ??
                  "")
            : (viewAllProvider.continueWatchList?[position].video320 ?? ""),
      );
      printLog(
        "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
      );
    }
    /* VdoCipher OTP */

    PlayerModel playerModel = PlayerModel(
      playType:
          ((viewAllProvider.continueWatchList?[position].videoType ?? 0) ==
                  Constant.showContentType ||
              (viewAllProvider.continueWatchList?[position].subVideoType ??
                      0) ==
                  Constant.showContentType)
          ? "Show"
          : "Video",
      isLive:
          ((viewAllProvider.continueWatchList?[position].videoUploadType ??
                  "") ==
              "live_stream_url")
          ? true
          : false,
      videoId: (viewAllProvider.continueWatchList?[position].id ?? 0),
      videoTitle: viewAllProvider.continueWatchList?[position].name ?? "",
      videoType: viewAllProvider.continueWatchList?[position].videoType ?? 0,
      subVideoType:
          viewAllProvider.continueWatchList?[position].subVideoType ?? 0,
      typeId: viewAllProvider.continueWatchList?[position].typeId ?? 0,
      episodeId: (viewAllProvider.continueWatchList?[position].episode != null)
          ? (viewAllProvider.continueWatchList?[position].episode?.id ?? 0)
          : 0,
      videoUrl: (viewAllProvider.continueWatchList?[position].episode != null)
          ? (viewAllProvider.continueWatchList?[position].episode?.video320 ??
                "")
          : (viewAllProvider.continueWatchList?[position].video320 ?? ""),
      cipherMediaDetails:
          (vdocipherDetails != null && vdocipherDetails.result != null)
          ? (vdocipherDetails.result)
          : null,
      trailerUrl: viewAllProvider.continueWatchList?[position].trailerUrl ?? "",
      uploadType:
          viewAllProvider.continueWatchList?[position].videoUploadType ?? "",
      videoThumb: viewAllProvider.continueWatchList?[position].landscape ?? "",
      stopTime: viewAllProvider.continueWatchList?[position].stopTime ?? 0,
      isPremium: viewAllProvider.continueWatchList?[position].isPremium ?? 0,
      isBuy: viewAllProvider.continueWatchList?[position].isBuy ?? 0,
      isRent: viewAllProvider.continueWatchList?[position].isRent ?? 0,
      rentBuy: viewAllProvider.continueWatchList?[position].rentBuy ?? 0,
      securityKey: "",
      securityIVKey: null,
      currentEpiPos: 0,
      episodeList: null,
    );
    if (!mounted) return;
    AdHelper.checkAndShowAds(
      context: context,
      buttonKey: "",
      adType: Constant.interstialAdType,
      alwaysShowAd: false,
      showOnByClick: true,
      onAdComplete: () async {
        dynamic isContinue = await Utils.openPlayer(
          context: context,
          playerModel: playerModel,
        );
        printLog("isContinue ===> $isContinue");
        if (isContinue != null && isContinue == true) {
          Future.delayed(Duration.zero).then((value) {
            if (!mounted) return;
            setState(() {});
          });
        }
      },
    );
  }
  /* ========= Open Player ========= */

  @override
  void dispose() {
    super.dispose();
    viewAllProvider.clearProvider();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, widget.appBarTitle, true),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(child: _buildPage()),
    );
  }

  Widget _buildPage() {
    if (viewAllProvider.loading) {
      return SingleChildScrollView(
        child: ShimmerUtils.responsiveGrid2(
          context,
          Dimens.heightPortOther,
          Dimens.widthPortOther,
          3,
          3,
          3,
          12,
        ),
      );
    }
    if ((widget.appBarTitle == RoutesConstant.relatedContentPage &&
            viewAllProvider.relatedContentModel.status == 200 &&
            (viewAllProvider.relatedList?.length ?? 0) > 0) ||
        widget.appBarTitle == RoutesConstant.continueWatchPage &&
            viewAllProvider.continueWatchingModel.status == 200 &&
            (viewAllProvider.continueWatchList?.length ?? 0) > 0) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _setContentByType(),

            /* Pagination loader */
            Consumer<ViewAllProvider>(
              builder: (context, sectionViewAllProvider, child) {
                if (sectionViewAllProvider.loadMore) {
                  return Container(
                    height: 80,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Utils.pageLoader(),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      );
    } else {
      return const NoData(title: 'no_data', subTitle: 'no_video_show');
    }
  }

  Widget _setContentByType() {
    switch (widget.appBarTitle) {
      case RoutesConstant.relatedContentPage:
        return _buildRelatedItem();
      case RoutesConstant.continueWatchPage:
        return _buildContinueWatchItem();
      default:
        return _buildRelatedItem();
    }
  }

  Widget _buildRelatedItem() {
    return RefreshIndicator(
      backgroundColor: white,
      color: complimentryColor,
      displacement: 80,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1500)).then((value) {
          viewAllProvider.setLoading(true);
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
          children: List.generate((viewAllProvider.relatedList?.length ?? 0), (
            position,
          ) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
              child: InkWell(
                onTap: () async {
                  printLog("Clicked on position ==> $position");
                  Utils.openDetailsWithReplace(
                    context: context,
                    videoId: viewAllProvider.relatedList?[position].id ?? 0,
                    subVideoType:
                        viewAllProvider.relatedList?[position].subVideoType ??
                        0,
                    videoType:
                        viewAllProvider.relatedList?[position].videoType ?? 0,
                    typeId: viewAllProvider.relatedList?[position].typeId ?? 0,
                    newPage:
                        ((viewAllProvider.relatedList?[position].subVideoType ??
                                    0) ==
                                2 ||
                            (viewAllProvider.relatedList?[position].videoType ??
                                    0) ==
                                2)
                        ? RoutesConstant.contentDetailsPage
                        : RoutesConstant.contentDetailsPage,
                    oldPage: "",
                    reqText: "",
                  );
                },
                child: Container(
                  width: Dimens.widthPortOther,
                  height: Dimens.heightPortOther,
                  alignment: Alignment.center,
                  child: MyNetworkImage(
                    imageUrl:
                        viewAllProvider.relatedList?[position].thumbnail
                            .toString() ??
                        "",
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContinueWatchItem() {
    return RefreshIndicator(
      backgroundColor: white,
      color: complimentryColor,
      displacement: 80,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1500)).then((value) {
          viewAllProvider.setLoading(true);
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
          minItemWidth: Dimens.widthLand,
          verticalGridSpacing: 3,
          horizontalGridSpacing: 3,
          minItemsPerRow: 2,
          maxItemsPerRow: 8,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(
            (viewAllProvider.continueWatchList?.length ?? 0),
            (position) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.cardRadius),
                child: InkWell(
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    Utils.openDetails(
                      context: context,
                      videoId:
                          viewAllProvider.continueWatchList?[position].id ?? 0,
                      subVideoType:
                          viewAllProvider
                              .continueWatchList?[position]
                              .subVideoType ??
                          0,
                      videoType:
                          viewAllProvider
                              .continueWatchList?[position]
                              .videoType ??
                          0,
                      typeId:
                          viewAllProvider.continueWatchList?[position].typeId ??
                          0,
                      newPage:
                          ((viewAllProvider
                                          .continueWatchList?[position]
                                          .subVideoType ??
                                      0) ==
                                  2 ||
                              (viewAllProvider
                                          .continueWatchList?[position]
                                          .videoType ??
                                      0) ==
                                  2)
                          ? RoutesConstant.contentDetailsPage
                          : RoutesConstant.contentDetailsPage,
                      oldPage: "",
                      reqText: "",
                    );
                  },
                  child: Container(
                    width: Dimens.widthLand,
                    height: (Dimens.widthLand / Dimens.landRatio),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: AlignmentDirectional.bottomStart,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimens.cardRadius,
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: MyNetworkImage(
                            imageUrl:
                                viewAllProvider
                                    .continueWatchList?[position]
                                    .landscape
                                    .toString() ??
                                "",
                            fit: BoxFit.cover,
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                          ),
                        ),
                        continueWatchingLayout(position: position),
                      ],
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

  /* Continue Watching START ************** */
  Widget continueWatchingLayout({required int position}) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        /* Bottom Gradient */
        Container(
          padding: const EdgeInsets.all(0),
          width: MediaQuery.of(context).size.width,
          height: Dimens.getBannerHeight(context),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                transparent,
                transparent,
                transparent,
                appBgColor.withValues(alpha: 0.1),
                appBgColor.withValues(alpha: 0.5),
                appBgColor.withValues(alpha: 0.9),
                appBgColor,
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  openPlayer(position: position);
                },
                child: Row(
                  children: [
                    MyImage(width: 20, height: 20, imagePath: "play.png"),
                    if (viewAllProvider.continueWatchList?[position].isTitle !=
                        0)
                      const SizedBox(width: 10),
                    if (viewAllProvider.continueWatchList?[position].isTitle ==
                        0)
                      const SizedBox.shrink()
                    else
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: MyText(
                            color: white,
                            multilanguage: false,
                            text:
                                viewAllProvider
                                    .continueWatchList?[position]
                                    .name
                                    .toString() ??
                                "",
                            fontsizeNormal: 12,
                            fontweight: FontWeight.w600,
                            fontsizeWeb: 14,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                            isShadowText: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              padding: const EdgeInsets.all(0),
              child: LinearPercentIndicator(
                padding: const EdgeInsets.all(0),
                barRadius: const Radius.circular(2),
                lineHeight: 4,
                percent: Utils.getPercentage(
                  (viewAllProvider.continueWatchList?[position].episode != null)
                      ? (viewAllProvider
                                .continueWatchList?[position]
                                .episode
                                ?.videoDuration ??
                            0)
                      : (viewAllProvider
                                .continueWatchList?[position]
                                .videoDuration ??
                            0),
                  viewAllProvider.continueWatchList?[position].stopTime ?? 0,
                ),
                backgroundColor: secProgressColor,
                progressColor: colorPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /* **************** Continue Watching END */
}
