import 'dart:async';
import 'dart:io';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../model/playermodel.dart';
import '../players/model/vdociphermodel.dart';
import '../provider/clipsprovider.dart';
import '../routes/routes_constant.dart';
import '../webwidget/interactive_icon.dart';
import '../widget/nodata.dart';
import '../model/sectionlistmodel.dart';
import '../provider/generalprovider.dart';
import '../provider/sectionviewallprovider.dart';
import '../webpages/webcomman.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/sharedpre.dart';
import '../model/sectiontypemodel.dart' as type;
import '../model/sectionlistmodel.dart' as list;
import '../model/sectionbannermodel.dart' as banner;
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../provider/homeprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../utils/color.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';
import '../widget/mynetworkimg.dart';
import '../widget/ai_section_widget.dart';
import '../widget/content_section_widget.dart';
import '../widget/genre_language_section_widget.dart';
import '../widget/shorts_section_widget.dart';

class WebHome extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebHome({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebHome> createState() => WebHomeState();
}

class WebHomeState extends State<WebHome> {
  SharedPre sharedPref = SharedPre();
  late SectionDataProvider sectionDataProvider;
  late HomeProvider homeProvider;

  final TextEditingController searchController = TextEditingController();
  CarouselSliderController carouselController = CarouselSliderController();

  bool isSearchEnable = false;
  String? currentPage,
      langCatName,
      mSearchText,
      subscriptionStatus,
      continueWatchingStatus;

  @override
  void initState() {
    super.initState();
    currentPage = widget.newPage ?? "";
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    Utils.getCurrencySymbol();
    final generalProvider = Provider.of<GeneralProvider>(
      context,
      listen: false,
    );

    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    continueWatchingStatus = await Utils.configByStatus(
      status: Constant.continueWatchingStatus,
    );
    printLog('_getData subscriptionStatus =======> $subscriptionStatus');
    printLog('_getData continueWatchingStatus ===> $continueWatchingStatus');

    Constant.userID = await sharedPref.read("userid");
    Constant.userIsKid = await sharedPref.readBool(Constant.profileUserKey);
    printLog('Constant userID =====> ${Constant.userID}');
    printLog('Constant userIsKid ==> ${Constant.userIsKid}');

    await homeProvider.setLoading(true);
    await homeProvider.getSectionType();

    printLog("<===============================>");
    printLog('_getData oldPage ==> ${widget.oldPage}');
    printLog('_getData newPage ==> ${widget.newPage}');
    printLog("<===============================>");
    if (!homeProvider.loading && widget.newPage == RoutesConstant.homePage) {
      if (homeProvider.sectionTypeModel.status == 200 &&
          homeProvider.sectionTypeModel.result != null) {
        if ((homeProvider.sectionTypeModel.result?.length ?? 0) > 0) {
          if ((sectionDataProvider.sectionBannerModel.result?.length ?? 0) ==
                  0 ||
              (sectionDataProvider.sectionList?.length ?? 0) == 0) {
            getTabData(-1, homeProvider.sectionTypeModel.result);
          }
        }
      }
    }

    Future.delayed(Duration.zero).then((value) {
      if (!context.mounted) return;
      setState(() {});
    });
    if (!mounted) return;
    generalProvider.getGeneralsetting(context);
  }

  Future<void> setSelectedTab(int tabPos) async {
    if (!mounted) return;
    homeProvider.setSelectedTab(tabPos);
    printLog("setSelectedTab position ====> $tabPos");
    printLog(
      "setSelectedTab lastTabPos ==> ${sectionDataProvider.lastTabPosition}",
    );
    if (sectionDataProvider.lastTabPosition == tabPos) {
      return;
    } else {
      sectionDataProvider.setTabPosition(tabPos);
    }
  }

  Future<void> getTabData(
    int position,
    List<type.Result>? sectionTypeList,
  ) async {
    await sectionDataProvider.clearOldData();
    sectionDataProvider.setLoading(true);
    final isDefaultTab = position == -1;
    final tabId = isDefaultTab
        ? "0"
        : (sectionTypeList?[position].id ?? 0).toString();
    final type = isDefaultTab ? "1" : "2";

    await setSelectedTab(isDefaultTab ? 0 : position + 1);

    await Future.wait([
      sectionDataProvider.getSectionBanner(tabId, type),
      sectionDataProvider.getSectionList(tabId, type, 1),
    ]);
  }

  Future<void> openDetailPage(
    int videoId,
    int subVideoType,
    int videoType,
    int typeId,
  ) async {
    printLog("videoId =========> $videoId");
    printLog("videoType =======> $videoType");
    printLog("subVideoType ====> $subVideoType");
    printLog("typeId ==========> $typeId");
    if (!mounted) return;
    Utils.openDetails(
      context: context,
      videoId: videoId,
      subVideoType: subVideoType,
      videoType: videoType,
      typeId: typeId,
      newPage: (videoType == Constant.shortsContentType)
          ? RoutesConstant.clipsEpisodesPage
          : RoutesConstant.contentDetailsPage,
      oldPage: widget.newPage ?? "",
      reqText: '',
    );
  }

  /* ========= Open Player ========= */
  Future<void> openPlayer(
    String playType,
    int index,
    List<list.Datum>? sectionList,
  ) async {
    printLog("index ==========> $index");

    /* CHECK SUBSCRIPTION */
    if (playType != "Trailer") {
      bool? isPrimiumUser = await Utils.checkSubsRentLogin(
        context: context,
        isPremium: sectionList?[index].isPremium ?? 0,
        isBuy: sectionList?[index].isBuy ?? 0,
        isRent: sectionList?[index].isRent ?? 0,
        rentBuy: sectionList?[index].rentBuy ?? 0,
        producerId: (sectionList?[index].producerId ?? 0).toString(),
        videoId: (sectionList?[index].id ?? 0).toString(),
        rentPrice: (sectionList?[index].price ?? 0).toString(),
        vTitle: (sectionList?[index].name ?? 0).toString(),
        typeId: (sectionList?[index].typeId ?? 0).toString(),
        vType: (sectionList?[index].videoType ?? 0).toString(),
        subVideoType: (sectionList?[index].subVideoType ?? 0).toString(),
        rentProductId: (kIsWeb)
            ? (sectionList?[index].webPriceId.toString() ?? '')
            : (Platform.isIOS
                  ? (sectionList?[index].iosProductPackage.toString() ?? '')
                  : (sectionList?[index].androidProductPackage.toString() ??
                        '')),
        newPage: widget.newPage ?? "",
        oldPage: widget.oldPage ?? "",
        reqText: widget.reqText ?? "",
      );
      printLog("isPrimiumUser =============> $isPrimiumUser");
      if (!isPrimiumUser) return;
    }
    /* CHECK SUBSCRIPTION */

    if (!mounted) return;
    /* Set-up Quality URLs */
    Utils.setQualityURLs(
      video320: (sectionList?[index].video320 ?? ""),
      video480: (sectionList?[index].video480 ?? ""),
      video720: (sectionList?[index].video720 ?? ""),
      video1080: (sectionList?[index].video1080 ?? ""),
    );

    /* VdoCipher OTP */
    VdoCipherModel? vdocipherDetails;
    if ((sectionList?[index].videoUploadType ?? "") ==
            Constant.vdocipherPlayType &&
        playType != "Trailer") {
      if (!mounted) return;
      vdocipherDetails = await Utils.getVdoCipherOTP(
        context: context,
        videoId: (sectionList?[index].episode != null)
            ? (sectionList?[index].episode?.video320 ?? "")
            : (sectionList?[index].video320 ?? ""),
      );
      printLog(
        "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
      );
    }
    /* VdoCipher OTP */

    PlayerModel playerModel = PlayerModel(
      playType:
          ((sectionList?[index].videoType ?? 0) == Constant.showContentType ||
              (sectionList?[index].subVideoType ?? 0) ==
                  Constant.showContentType)
          ? "Show"
          : "Video",
      isLive:
          ((sectionList?[index].videoUploadType ?? "") == "live_stream_url" &&
              playType != "Trailer")
          ? true
          : false,
      videoId: (sectionList?[index].id ?? 0),
      videoTitle: sectionList?[index].name ?? "",
      videoType: sectionList?[index].videoType ?? 0,
      subVideoType: sectionList?[index].subVideoType ?? 0,
      typeId: sectionList?[index].typeId ?? 0,
      episodeId: (sectionList?[index].episode != null)
          ? (sectionList?[index].episode?.id ?? 0)
          : 0,
      videoUrl: (sectionList?[index].episode != null)
          ? (sectionList?[index].episode?.video320 ?? "")
          : (sectionList?[index].video320 ?? ""),
      cipherMediaDetails:
          (vdocipherDetails != null && vdocipherDetails.result != null)
          ? (vdocipherDetails.result)
          : null,
      trailerUrl: sectionList?[index].trailerUrl ?? "",
      uploadType: sectionList?[index].videoUploadType ?? "",
      videoThumb: sectionList?[index].landscape ?? "",
      stopTime: sectionList?[index].stopTime ?? 0,
      isPremium: sectionList?[index].isPremium ?? 0,
      isBuy: sectionList?[index].isBuy ?? 0,
      isRent: sectionList?[index].isRent ?? 0,
      rentBuy: sectionList?[index].rentBuy ?? 0,
      securityKey: "",
      securityIVKey: null,
      currentEpiPos: 0,
      episodeList: null,
    );

    if (!mounted) return;
    var isContinues = await Utils.openPlayer(
      context: context,
      playerModel: playerModel,
    );
    if (isContinues != null && isContinues == true) {
      getTabData(0, homeProvider.sectionTypeModel.result);
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }
  /* ========= Open Player ========= */

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
    );
  }

  Widget _buildPageUI() {
    if (homeProvider.loading) {
      return ShimmerUtils.buildHomeMobileShimmer(context);
    } else {
      if (homeProvider.sectionTypeModel.status == 200) {
        if (homeProvider.sectionTypeModel.result != null ||
            (homeProvider.sectionTypeModel.result?.length ?? 0) > 0) {
          return _buildTypeTabData(homeProvider.sectionTypeModel.result);
        } else {
          return const SizedBox.shrink();
        }
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildTypeTabData(List<type.Result>? sectionTypeList) {
    return Consumer<SectionDataProvider>(
      builder: (context, sectionDataProvider, child) {
        if ((sectionDataProvider.sectionBannerModel.result == null ||
                (sectionDataProvider.sectionBannerModel.result?.length ?? 0) ==
                    0) &&
            (sectionDataProvider.sectionList?.length ?? 0) == 0 &&
            !sectionDataProvider.loadingBanner &&
            !sectionDataProvider.loadingSection) {
          return const Center(
            child: NoData(title: 'no_data', subTitle: 'no_video_show'),
          );
        } else {
          return _buildBannerSections();
        }
      },
    );
  }

  Widget _buildBannerSections() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          /* Banner */
          if (!sectionDataProvider.loadingBanner &&
              !Dimens.isBigScreen(context) &&
              sectionDataProvider.sectionBannerModel.status == 200 &&
              sectionDataProvider.sectionBannerModel.result != null)
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(
                left: 13,
                right: 13,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                bottom: 12,
              ),
              child: MyText(
                color: titleTextColor,
                text: "for_you",
                textalign: TextAlign.start,
                fontsizeNormal: 17,
                fontweight: FontWeight.w600,
                fontsizeWeb: 19,
                multilanguage: true,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
            ),
          if (sectionDataProvider.loadingBanner)
            if (Dimens.isBigScreen(context))
              ShimmerUtils.bannerWeb(context)
            else
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                ),
                child: ShimmerUtils.bannerMobile(context),
              )
          else if (sectionDataProvider.sectionBannerModel.status == 200 &&
              sectionDataProvider.sectionBannerModel.result != null)
            if (Dimens.isBigScreen(context))
              _tvHomeBanner(sectionDataProvider.sectionBannerModel.result)
            else
              _mobileHomeBanner(sectionDataProvider.sectionBannerModel.result)
          else
            SizedBox(height: Dimens.homeTabHeight),

          /* Continue Watching & Remaining Sections */
          if (sectionDataProvider.loadingSection &&
              !sectionDataProvider.loadMore)
            sectionShimmer()
          else if (sectionDataProvider.sectionList != null &&
              (sectionDataProvider.sectionList?.length ?? 0) > 0)
            setSectionByType(sectionDataProvider.sectionList)
          else
            const SizedBox.shrink(),

          /* Pagination loader */
          if (sectionDataProvider.loadMore)
            ShimmerUtils.sectionPortraitListView(context)
          else
            const SizedBox.shrink(),
          SizedBox(height: Dimens.homeTabHeight),
        ],
      ),
    );
  }

  /* Banner START ************** */
  Widget _tvHomeBanner(List<banner.Result>? sectionBannerList) {
    if ((sectionBannerList?.length ?? 0) == 0) return const SizedBox.shrink();

    final double sw = MediaQuery.of(context).size.width;
    final double sh = Dimens.getResponsiveHeight(context, 0);

    /* Responsive values */
    final double hPad = sw < 1200
        ? 40.0
        : sw < 1600
        ? 60.0
        : 80.0;
    final double bPad = sw < 1200
        ? 48.0
        : sw < 1600
        ? 60.0
        : 72.0;
    final double cw = sw < 1200
        ? sw * 0.52
        : sw < 1600
        ? sw * 0.44
        : sw * 0.38;
    final double tSize = sw < 1200
        ? 34.0
        : sw < 1600
        ? 42.0
        : 52.0;
    final double dSize = sw < 1200
        ? 14.0
        : sw < 1600
        ? 15.0
        : 16.0;

    return MouseRegion(
      onEnter: (_) => sectionDataProvider.setBannerHovered(true),
      onExit: (_) => sectionDataProvider.setBannerHovered(false),
      child: SizedBox(
        width: sw,
        height: sh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            /* ── A. Carousel — full-bleed ── */
            CarouselSlider.builder(
              itemCount: sectionBannerList!.length,
              carouselController: carouselController,
              options: CarouselOptions(
                initialPage: 0,
                height: sh,
                enlargeCenterPage: false,
                autoPlay: true,
                autoPlayCurve: Curves.easeInOutCubic,
                enableInfiniteScroll: sectionBannerList.length > 1,
                autoPlayInterval: Duration(
                  milliseconds: Constant.bannerDuration,
                ),
                autoPlayAnimationDuration: Duration(
                  milliseconds: Constant.animationDuration,
                ),
                viewportFraction: 1.0,
                onPageChanged: (val, _) async {
                  sectionDataProvider.setCurrentBanner(val);
                },
              ),
              itemBuilder:
                  (BuildContext context, int index, int pageViewIndex) {
                    final String imageUrl =
                        (sectionBannerList[index].landscape == null ||
                            (sectionBannerList[index].landscape ?? "")
                                .isEmpty ||
                            (sectionBannerList[index].landscape ?? "").contains(
                              "no_img",
                            ))
                        ? (sectionBannerList[index].thumbnail ?? "")
                        : (sectionBannerList[index].landscape ?? "");

                    return InkWell(
                      onTap: () async {
                        openDetailPage(
                          sectionBannerList[index].id ?? 0,
                          sectionBannerList[index].subVideoType ?? 0,
                          sectionBannerList[index].videoType ?? 0,
                          sectionBannerList[index].typeId ?? 0,
                        );
                      },
                      child: SizedBox.expand(
                        child: MyNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
            ),

            /* ── B. Right vignette — prevents raw image edge ── */
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sw * 0.32,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        black.withValues(alpha: 0.45),
                        black.withValues(alpha: 0.20),
                        black.withValues(alpha: 0.05),
                        transparent,
                      ],
                      stops: const [0.0, 0.40, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            /* ── C. Left gradient panel — content panel ── */
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: sw * 0.55,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        appBgColor,
                        appBgColor.withValues(alpha: 0.95),
                        appBgColor.withValues(alpha: 0.80),
                        appBgColor.withValues(alpha: 0.55),
                        appBgColor.withValues(alpha: 0.30),
                        appBgColor.withValues(alpha: 0.12),
                        appBgColor.withValues(alpha: 0.04),
                        transparent,
                      ],
                      stops: const [
                        0.0,
                        0.12,
                        0.25,
                        0.42,
                        0.60,
                        0.76,
                        0.90,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /* ── D. Bottom gradient — cinematic floor ── */
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: sh * 0.32,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        appBgColor,
                        appBgColor.withValues(alpha: 0.95),
                        appBgColor.withValues(alpha: 0.70),
                        appBgColor.withValues(alpha: 0.30),
                        appBgColor.withValues(alpha: 0.15),
                        appBgColor.withValues(alpha: 0.08),
                        transparent,
                      ],
                      stops: const [0.0, 0.10, 0.28, 0.55, 0.78, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            /* ── E. Top gradient — navbar readability ── */
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: sh * 0.20,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        black.withValues(alpha: 0.40),
                        black.withValues(alpha: 0.12),
                        transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            /* ── G + H. Prev/Next arrows — visible only on banner hover ── */
            if (sectionBannerList.length > 1)
              Consumer<SectionDataProvider>(
                builder: (context, sdp, _) {
                  final bool bannerHovered = sdp.isBannerHovered;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      /* Left arrow */
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: bannerHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: IgnorePointer(
                              ignoring: !bannerHovered,
                              child: InteractiveIcon(
                                builder: (isHovered) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isHovered
                                          ? white.withValues(alpha: 0.20)
                                          : white.withValues(alpha: 0.10),
                                      border: Border.all(
                                        color: white.withValues(
                                          alpha: isHovered ? 0.40 : 0.18,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        await carouselController.previousPage(
                                          duration: Duration(
                                            milliseconds:
                                                Constant.animationDuration,
                                          ),
                                          curve: Curves.easeInOutCubic,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(22),
                                      focusColor: transparent,
                                      hoverColor: transparent,
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        color: white.withValues(
                                          alpha: isHovered ? 1.0 : 0.70,
                                        ),
                                        size: 26,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      /* Right arrow */
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: bannerHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: IgnorePointer(
                              ignoring: !bannerHovered,
                              child: InteractiveIcon(
                                builder: (isHovered) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isHovered
                                          ? white.withValues(alpha: 0.20)
                                          : white.withValues(alpha: 0.10),
                                      border: Border.all(
                                        color: white.withValues(
                                          alpha: isHovered ? 0.40 : 0.18,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        await carouselController.nextPage(
                                          duration: Duration(
                                            milliseconds:
                                                Constant.animationDuration,
                                          ),
                                          curve: Curves.easeInOutCubic,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(22),
                                      focusColor: transparent,
                                      hoverColor: transparent,
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        color: white.withValues(
                                          alpha: isHovered ? 1.0 : 0.70,
                                        ),
                                        size: 26,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            /* ── F. Content column — bottom-left, Consumer rebuilds on slide change ── */
            Consumer<SectionDataProvider>(
              builder: (context, sdp, _) {
                final int idx = sdp.cBannerIndex ?? 0;
                final banner.Result item = sectionBannerList[idx];

                return Positioned(
                  left: hPad,
                  bottom: bPad,
                  width: cw,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /* Badge: LIVE / PREMIUM */
                      _buildBannerBadge(item),
                      const SizedBox(height: 14),

                      /* Title */
                      MyText(
                        color: white,
                        text: (item.name ?? "").isNotEmpty
                            ? (item.name ?? "")
                            : "",
                        multilanguage: false,
                        fontsizeNormal: tSize > 26 ? 26.0 : tSize,
                        fontsizeWeb: tSize,
                        fontweight: FontWeight.w800,
                        maxline: 2,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                        isShadowText: true,
                      ),
                      const SizedBox(height: 16),

                      /* Meta chips: language badge + category pills */
                      _buildTvBannerMetaChips(item),
                      const SizedBox(height: 14),

                      /* Description */
                      if ((item.description ?? "").isNotEmpty) ...[
                        ExpandableText(
                          item.description ?? "",
                          expandText: "",
                          collapseText: "",
                          maxLines: 2,
                          linkColor: descTextColor,
                          expandOnTextTap: true,
                          collapseOnTextTap: true,
                          style: kIsWeb
                              ? TextStyle(
                                  fontSize: dSize,
                                  fontStyle: FontStyle.normal,
                                  color: white.withValues(alpha: 0.60),
                                  fontWeight: FontWeight.w400,
                                  height: 1.60,
                                )
                              : GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: dSize,
                                    fontStyle: FontStyle.normal,
                                    color: white.withValues(alpha: 0.60),
                                    fontWeight: FontWeight.w400,
                                    height: 1.60,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 28),
                      ] else
                        const SizedBox(height: 24),

                      /* Action buttons */
                      _buildTvBannerActions(idx, sectionBannerList),
                      const SizedBox(height: 20),

                      /* Dot indicators — inline below actions */
                      if (sectionBannerList.length > 1)
                        AnimatedSmoothIndicator(
                          count: sectionBannerList.length,
                          activeIndex: idx,
                          onDotClicked: (i) async {
                            await carouselController.animateToPage(i);
                            sectionDataProvider.setCurrentBanner(i);
                          },
                          effect: ExpandingDotsEffect(
                            spacing: 5,
                            radius: 3,
                            dotWidth: 7,
                            dotHeight: 7,
                            expansionFactor: 3.5,
                            activeDotColor: white,
                            dotColor: white.withValues(alpha: 0.28),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileHomeBanner(List<banner.Result>? sectionBannerList) {
    if ((sectionBannerList?.length ?? 0) == 0) return const SizedBox.shrink();
    final list = sectionBannerList!;
    return SizedBox(
      height: Dimens.getBannerHeight(context),
      child: CarouselSlider.builder(
        itemCount: list.length,
        carouselController: carouselController,
        options: CarouselOptions(
          initialPage: 0,
          height: Dimens.getBannerHeight(context),
          enlargeCenterPage: true,
          enlargeFactor: 0.2,
          enlargeStrategy: CenterPageEnlargeStrategy.scale,
          enableInfiniteScroll: list.length > 1,
          autoPlay: true,
          autoPlayCurve: Curves.easeInOutCubic,
          autoPlayInterval: Duration(milliseconds: Constant.bannerDuration),
          autoPlayAnimationDuration: Duration(
            milliseconds: Constant.animationDuration,
          ),
          viewportFraction: 0.88,
          padEnds: true,
          onPageChanged: (val, _) async {
            sectionDataProvider.setCurrentBanner(val);
          },
        ),
        itemBuilder: (BuildContext context, int index, int pageViewIndex) {
          final imageUrl =
              (list[index].thumbnail == null ||
                  (list[index].thumbnail ?? "").isEmpty ||
                  (list[index].thumbnail ?? "").contains("no_img"))
              ? (list[index].landscape ?? "")
              : (list[index].thumbnail ?? "");
          final isLive =
              (list[index].videoUploadType ?? "") == "live_stream_url";
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: InkWell(
              focusColor: white,
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                openDetailPage(
                  list[index].id ?? 0,
                  list[index].subVideoType ?? 0,
                  list[index].videoType ?? 0,
                  list[index].typeId ?? 0,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  /* Poster image */
                  MyNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  /* Top gradient */
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          black.withValues(alpha: 0.45),
                          black.withValues(alpha: 0.20),
                          black.withValues(alpha: 0.05),
                          transparent,
                        ],
                        stops: const [0.0, 0.25, 0.50, 1.0],
                      ),
                    ),
                  ),
                  /* Bottom gradient */
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          black.withValues(alpha: 0.72),
                          black.withValues(alpha: 0.55),
                          black.withValues(alpha: 0.35),
                          black.withValues(alpha: 0.15),
                          black.withValues(alpha: 0.04),
                          transparent,
                        ],
                        stops: const [0.0, 0.15, 0.35, 0.55, 0.72, 1.0],
                      ),
                    ),
                  ),
                  /* Badge — top-left */
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _buildBannerBadge(list[index]),
                  ),
                  /* Title + Metadata — bottom-left */
                  Positioned(
                    left: 14,
                    right: 70,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(
                          color: white,
                          text: (list[index].name ?? "").isNotEmpty
                              ? (list[index].name ?? "")
                              : "-",
                          textalign: TextAlign.start,
                          fontsizeNormal: 26,
                          fontsizeWeb: 26,
                          fontweight: FontWeight.w800,
                          multilanguage: false,
                          maxline: 2,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                          isShadowText: true,
                        ),
                        const SizedBox(height: 8),
                        _buildBannerMetaRow(list[index]),
                      ],
                    ),
                  ),
                  /* Action buttons — bottom-right */
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isLive) ...[
                          _buildBannerCircleBtn(
                            iconPath: (list[index].isBookmark ?? 0) == 1
                                ? "ic_tick.png"
                                : "ic_plus.png",
                            onTap: () async {
                              if (Constant.userID != null) {
                                await sectionDataProvider.setBookMark(
                                  context,
                                  index,
                                );
                              } else {
                                await Utils.openLogin(
                                  context: context,
                                  newPage: "",
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildBannerCircleBtn(
                          iconPath: "ic_play.png",
                          onTap: () {
                            openDetailPage(
                              list[index].id ?? 0,
                              list[index].subVideoType ?? 0,
                              list[index].videoType ?? 0,
                              list[index].typeId ?? 0,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /* ---- Mobile Banner: badge pill ---- */
  Widget _buildBannerBadge(banner.Result item) {
    final isLive = (item.videoUploadType ?? "") == "live_stream_url";
    if (isLive) {
      return _badgePill(label: "LIVE", bgColor: colorAccent, showDot: true);
    }
    final isPremium = (item.isPremium ?? 0) == 1 && (item.isBuy ?? 0) == 0;
    if (isPremium) {
      return _badgePill(label: "PREMIUM", bgColor: colorPrimary);
    }
    return const SizedBox.shrink();
  }

  Widget _badgePill({
    required String label,
    required Color bgColor,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.55),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bgColor.withValues(alpha: 0.85), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          MyText(
            color: white,
            text: label,
            multilanguage: false,
            fontsizeNormal: 10,
            fontsizeWeb: 11,
            fontweight: FontWeight.w700,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerMetaRow(banner.Result item) {
    final List<String> parts = [];
    if ((item.totalLanguage ?? 0) > 0) {
      parts.add(
        "${item.totalLanguage} "
        "${(item.totalLanguage ?? 0) == 1 ? 'Language' : 'Languages'}",
      );
    }
    if ((item.categoryName ?? "").trim().isNotEmpty) {
      parts.addAll(
        (item.categoryName ?? "")
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return MyText(
      color: white.withValues(alpha: 0.75),
      text: parts.join("  •  "),
      textalign: TextAlign.start,
      fontsizeNormal: 13,
      fontsizeWeb: 14,
      fontweight: FontWeight.w500,
      multilanguage: false,
      maxline: 5,
      overflow: TextOverflow.ellipsis,
      fontstyle: FontStyle.normal,
      isShadowText: true,
    );
  }

  Widget _buildTvBannerMetaChips(banner.Result item) {
    final List<String> categories = (item.categoryName ?? "")
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final int langCount = item.totalLanguage ?? 0;

    if (langCount == 0 && categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        /* Language count badge — branded with colorPrimary tint */
        if (langCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorPrimary.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, color: colorPrimary, size: 13),
                const SizedBox(width: 5),
                MyText(
                  color: colorPrimary,
                  text:
                      "$langCount ${langCount == 1 ? Locales.string(context, 'language_singular') : Locales.string(context, 'language_plural')}",
                  multilanguage: false,
                  fontsizeNormal: 12,
                  fontsizeWeb: 12,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),

        /* Dot separator between language and categories */
        if (langCount > 0 && categories.isNotEmpty)
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),

        /* Category chips — frosted white pills */
        ...categories.map(
          (cat) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTvBannerActions(
    int index,
    List<banner.Result> sectionBannerList,
  ) {
    final bool isLive =
        (sectionBannerList[index].videoUploadType ?? "") == "live_stream_url";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /* Watch Now — solid white, dark text */
        InteractiveIcon(
          builder: (isHovered) {
            return InkWell(
              onTap: () {
                openDetailPage(
                  sectionBannerList[index].id ?? 0,
                  sectionBannerList[index].subVideoType ?? 0,
                  sectionBannerList[index].videoType ?? 0,
                  sectionBannerList[index].typeId ?? 0,
                );
              },
              focusColor: transparent,
              hoverColor: transparent,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: isHovered ? white.withValues(alpha: 0.88) : white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MyImage(
                      width: 13,
                      height: 13,
                      imagePath: "ic_play.png",
                      color: appBgColor,
                    ),
                    const SizedBox(width: 10),
                    MyText(
                      color: appBgColor,
                      text: "watch_now",
                      multilanguage: true,
                      fontsizeNormal: 14,
                      fontweight: FontWeight.w700,
                      fontsizeWeb: 15,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                      textalign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        /* Watchlist — frosted pill, hidden for LIVE */
        if (!isLive) ...[
          const SizedBox(width: 12),
          Consumer<SectionDataProvider>(
            builder: (context, sdp, _) {
              final bool bookmarked =
                  (sectionBannerList[sdp.cBannerIndex ?? 0].isBookmark ?? 0) ==
                  1;
              return InteractiveIcon(
                builder: (isHovered) {
                  return InkWell(
                    onTap: () async {
                      if (Constant.userID != null) {
                        await sectionDataProvider.setBookMark(
                          context,
                          sdp.cBannerIndex ?? 0,
                        );
                      } else {
                        Utils.openLogin(
                          context: context,
                          newPage: widget.newPage ?? "",
                        );
                      }
                    },
                    focusColor: transparent,
                    hoverColor: transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? white.withValues(alpha: 0.18)
                            : white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: white.withValues(
                            alpha: isHovered ? 0.30 : 0.16,
                          ),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: MyImage(
                        imagePath: bookmarked ? "ic_tick.png" : "ic_plus.png",
                        color: white,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBannerCircleBtn({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: white.withValues(alpha: 0.10), width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: MyImage(imagePath: iconPath, color: white),
      ),
    );
  }

  /* **************** Banner END */

  /* Sections START ************** */
  Widget setSectionByType(List<list.Result>? sectionList) {
    return ListView.builder(
      itemCount: sectionList?.length ?? 0,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        if (sectionList?[index].data != null &&
            (sectionList?[index].data?.length ?? 0) > 0) {
          if (sectionList?[index].videoType == Constant.continueWatchType &&
              continueWatchingStatus != null &&
              continueWatchingStatus != "1") {
            return const SizedBox.shrink();
          }

          /* ── AI Recommendation Section ──────────────────── */
          if ((sectionList?[index].sectionType ?? 0) ==
              Constant.aiContentType) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: Dimens.isBigScreen(context) ? 40 : 25,
                top: Dimens.isBigScreen(context) ? 40 : 20,
              ),
              child: AISectionWidget(
                section: sectionList![index],
                onItemTap: (datum, _) {
                  openDetailPage(
                    datum.id ?? 0,
                    datum.subVideoType ?? 0,
                    datum.videoType ?? 0,
                    datum.typeId ?? 0,
                  );
                },
                onViewAllTap: () {
                  if ((sectionList[index].viewAll ?? 0) == 1) {
                    final sectionViewAllProvider =
                        Provider.of<SectionViewAllProvider>(
                          context,
                          listen: false,
                        );
                    sectionViewAllProvider.setLoading(true);
                    context.go(
                      "/${RoutesConstant.sectionDetailsPage}/${(sectionList[index].id ?? 0)}/${(sectionList[index].videoType ?? 0)}/${sectionList[index].screenLayout}",
                      extra: {
                        'newpage': widget.newPage.toString(),
                        'itemid': (sectionList[index].id ?? 0).toString(),
                        'title': sectionList[index].title ?? '',
                        'screenlayout': sectionList[index].screenLayout ?? '',
                        'videotype': (sectionList[index].videoType ?? 0)
                            .toString(),
                      },
                    );
                  }
                },
              ),
            );
          }
          /* ─────────────────────────────────────────────────── */

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleViewAll(
                sectionList: sectionList,
                index: index,
                onViewAllClick: () async {
                  printLog("viewAll ====> ${sectionList?[index].viewAll}");
                  final sectionViewAllProvider =
                      Provider.of<SectionViewAllProvider>(
                        context,
                        listen: false,
                      );
                  if ((sectionList?[index].viewAll ?? 0) == 1) {
                    sectionViewAllProvider.setLoading(true);
                    if (!context.mounted) return;
                    context.go(
                      "/${RoutesConstant.sectionDetailsPage}/${(sectionList?[index].id ?? 0)}/${(sectionList?[index].videoType ?? 0)}/${sectionList?[index].screenLayout}",
                      extra: {
                        'newpage': widget.newPage.toString(),
                        'itemid': (sectionList?[index].id ?? 0).toString(),
                        'title': sectionList?[index].title ?? '',
                        'screenlayout': sectionList?[index].screenLayout ?? '',
                        'videotype': (sectionList?[index].videoType ?? 0)
                            .toString(),
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: getRemainingDataHeight(
                  sectionList?[index].videoType.toString() ?? "",
                  sectionList?[index].screenLayout ?? "",
                  sectionList,
                  index,
                ),
                child: setSectionData(sectionList: sectionList, index: index),
              ),
              SizedBox(height: Dimens.isBigScreen(context) ? 40 : 25),
            ],
          );
        } else {
          if ((sectionDataProvider.sectionBannerModel.result == null ||
                  (sectionDataProvider.sectionBannerModel.result?.length ??
                          0) ==
                      0) &&
              (sectionDataProvider.sectionList != null &&
                  (sectionDataProvider.sectionList?.length ?? 0) == 1) &&
              !sectionDataProvider.loadingBanner &&
              !sectionDataProvider.loadingSection) {
            return const Center(
              child: NoData(title: 'no_data', subTitle: 'no_video_show'),
            );
          } else {
            return const SizedBox.shrink();
          }
        }
      },
    );
  }

  Widget _buildTitleViewAll({
    required List<list.Result>? sectionList,
    required int index,
    required Function()? onViewAllClick,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 35 : 20,
        0,
        Dimens.isBigScreen(context) ? 35 : 20,
        0,
      ),
      child: InkWell(
        onTap: ((sectionList?[index].viewAll ?? 0) == 1)
            ? onViewAllClick
            : null,
        borderRadius: BorderRadius.circular(3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if ((sectionList?[index].videoType ?? 0) ==
                          Constant.channelType)
                        Container(
                          alignment: Alignment.centerRight,
                          height: 17,
                          width: 17,
                          margin: const EdgeInsets.only(right: 2),
                          child: MyImage(
                            imagePath: "ic_fire.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      if ((sectionList?[index].videoType ?? 0) ==
                          Constant.shortsContentType)
                        Container(
                          alignment: Alignment.centerRight,
                          height: 17,
                          width: 17,
                          margin: const EdgeInsets.only(right: 2),
                          child: MyImage(
                            imagePath: "ic_clips.png",
                            fit: BoxFit.contain,
                            color: colorAccent,
                          ),
                        ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: MyText(
                          color: titleTextColor,
                          text: sectionList?[index].title.toString() ?? "",
                          textalign: TextAlign.start,
                          fontsizeNormal: 16,
                          fontsizeWeb: 18,
                          fontweight: FontWeight.w600,
                          multilanguage: false,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                  if ((sectionList?[index].shortTitle.toString() ?? "")
                      .isNotEmpty)
                    Container(
                      alignment: Alignment.centerLeft,
                      child: MyText(
                        color: descTextColor,
                        text: sectionList?[index].shortTitle.toString() ?? "",
                        textalign: TextAlign.start,
                        fontsizeNormal: 12,
                        fontweight: FontWeight.w400,
                        fontsizeWeb: 16,
                        multilanguage: false,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                ],
              ),
            ),
            if ((sectionList?[index].viewAll ?? 0) == 1)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    child: MyText(
                      color: titleTextColor,
                      text: "viewall",
                      textalign: TextAlign.center,
                      fontsizeNormal: 14,
                      fontweight: FontWeight.w500,
                      fontsizeWeb: 16,
                      multilanguage: true,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 25,
                    padding: const EdgeInsets.all(5),
                    alignment: Alignment.centerRight,
                    child: MyImage(
                      imagePath: "ic_viewall.png",
                      fit: BoxFit.contain,
                      color: descTextColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget setSectionData({
    required List<list.Result>? sectionList,
    required int index,
  }) {
    /* screen_layout =>  landscape, big_landscape, index_landscape, portrait, big_portrait, index_portrait, 
                         square, category, language, channel */
    if ((sectionList?[index].screenLayout ?? "") == "landscape") {
      return _buildLandscapeUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "big_landscape") {
      return _buildLandscapeBigUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "index_landscape") {
      return _buildLandscapeIndexUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "portrait") {
      return _buildPortraitUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "big_portrait") {
      return _buildPortraitBigUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "index_portrait") {
      return _buildPortraitIndexUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "square") {
      return _buildSquareUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "shorts") {
      return _buildShortsUI(
        sectionList?[index].id,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "category") {
      return _buildGenresUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "language") {
      return _buildLanguageUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "channel") {
      return _buildChannelUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    } else {
      return _buildLandscapeUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
        sectionList?[index].scrollController,
      );
    }
  }

  double getRemainingDataHeight(
    String? videoType,
    String? layoutType,
    List<list.Result>? sectionList,
    int index,
  ) {
    if (layoutType == "landscape" || layoutType == "index_landscape") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightLandWeb
          : Dimens.heightLand;
    } else if (layoutType == "big_landscape") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightLandBigWeb
          : Dimens.heightLandBig;
    } else if (layoutType == "portrait" || layoutType == "index_portrait") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightPortWeb
          : Dimens.heightPort;
    } else if (layoutType == "big_portrait") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightPortBigWeb
          : Dimens.heightPortBig;
    } else if (layoutType == "square") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightSquareWeb
          : Dimens.heightSquare;
    } else if (layoutType == "shorts") {
      return ((sectionList?[index].data?.length ?? 0) < 12)
          ? (Dimens.isBigScreen(context)
                ? Dimens.heightShortsTotalWeb
                : Dimens.heightShortsTotal)
          : ((Dimens.isBigScreen(context)
                    ? Dimens.heightShortsTotalWeb
                    : Dimens.heightShortsTotal) *
                2);
    } else if (layoutType == "category") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightGenWeb + 36
          : Dimens.heightGen + 28;
    } else if (layoutType == "language") {
      return Dimens.isBigScreen(context)
          ? Dimens.heightLangWeb + 36
          : Dimens.heightLang + 28;
    } else if (layoutType == "channel") {
      return ((sectionList?[index].data?.length ?? 0) < 13)
          ? (Dimens.isBigScreen(context)
                ? Dimens.heightChannelTotalWeb
                : Dimens.heightChannelTotal)
          : ((Dimens.isBigScreen(context)
                    ? Dimens.heightChannelTotalWeb
                    : Dimens.heightChannelTotal) *
                2);
    } else {
      return Dimens.isBigScreen(context)
          ? Dimens.heightLandWeb
          : Dimens.heightLand;
    }
  }

  /* Continue Watching START ************** */
  Widget _buildContinueWatchingUI(
    int? videoType,
    int index,
    List<Datum>? sectionDataList,
  ) {
    if (videoType != Constant.continueWatchType) {
      if (sectionDataList?[index].isTitle == 0) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        decoration: Utils.setGradTTBBGWithCenter(
          transparent,
          appBgColor.withValues(alpha: 0.1),
          appBgColor,
          0,
        ),
        child: MyText(
          color: white,
          multilanguage: false,
          text: sectionDataList?[index].name.toString() ?? "",
          fontsizeNormal: 13,
          fontweight: FontWeight.w600,
          fontsizeWeb: 15,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
      );
    }
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
                  openPlayer("ContinueWatch", index, sectionDataList);
                },
                child: Row(
                  children: [
                    MyImage(width: 20, height: 20, imagePath: "play.png"),
                    if (sectionDataList?[index].isTitle != 0)
                      const SizedBox(width: 10),
                    if (sectionDataList?[index].isTitle == 0)
                      const SizedBox.shrink()
                    else
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: MyText(
                            color: white,
                            multilanguage: false,
                            text: sectionDataList?[index].name.toString() ?? "",
                            fontsizeNormal: 13,
                            fontweight: FontWeight.w600,
                            fontsizeWeb: 15,
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
                  (sectionDataList?[index].episode != null)
                      ? (sectionDataList?[index].episode?.videoDuration ?? 0)
                      : (sectionDataList?[index].videoDuration ?? 0),
                  sectionDataList?[index].stopTime ?? 0,
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

  Widget _buildLandscapeUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.landscape,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
      continueWatchingBuilder: (datum, index) =>
          _buildContinueWatchingUI(videoType, index, sectionDataList),
    );
  }

  Widget _buildLandscapeIndexUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.indexLandscape,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
    );
  }

  Widget _buildLandscapeBigUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.bigLandscape,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
      continueWatchingBuilder: (datum, index) =>
          _buildContinueWatchingUI(videoType, index, sectionDataList),
    );
  }

  Widget _buildPortraitUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.portrait,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
      continueWatchingBuilder: (datum, index) =>
          _buildContinueWatchingUI(videoType, index, sectionDataList),
    );
  }

  Widget _buildPortraitBigUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.bigPortrait,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
      continueWatchingBuilder: (datum, index) =>
          _buildContinueWatchingUI(videoType, index, sectionDataList),
    );
  }

  Widget _buildPortraitIndexUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.indexPortrait,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
    );
  }

  Widget _buildSquareUI(
    int? videoType,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.square,
      scrollController: scrollController,
      onItemTap: (datum, index) {
        printLog("Clicked on index ==> $index");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
      continueWatchingBuilder: (datum, index) =>
          _buildContinueWatchingUI(videoType, index, sectionDataList),
    );
  }

  Widget _buildShortsUI(
    int? sectionId,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return ShortsSectionWidget(
      section: list.Result()
        ..data = sectionDataList
        ..id = sectionId,
      scrollController: scrollController,
      onItemTap: (datum, index) async {
        final int typeId = datum.typeId ?? 0;
        final int videoType = datum.videoType ?? 0;
        final int videoId = datum.id ?? 0;
        const int subVideoType = 0;
        printLog("Clicked on index ======> $index");
        printLog("Clicked on sectionId ==> $sectionId");
        printLog("Clicked on typeId =====> $typeId");
        printLog("Clicked on videoType ==> $videoType");
        printLog("Clicked on videoId ====> $videoId");
        try {
          final clipsProvider = Provider.of<ClipsProvider>(
            context,
            listen: false,
          );
          clipsProvider.setEpiLoading(true);
          clipsProvider.getShortsDetails(
            typeId,
            videoType,
            videoId,
            subVideoType,
            forceRefresh: true,
          );
        } on Exception catch (e) {
          printLog("_buildShortsUI Episode Exception => $e");
        }
        openDetailPage(videoId, subVideoType, videoType, typeId);
      },
    );
  }

  Widget _buildChannelUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.channel,
      scrollController: scrollController,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        if (!mounted) return;
        context.go(
          "/${RoutesConstant.videoByChannelPage}/${datum.id ?? 0}",
          extra: {
            'newpage': widget.newPage.toString(),
            'itemid': (datum.id ?? 0).toString(),
            'title': datum.name ?? '',
            'layouttype': 'ByChannel',
          },
        );
      },
    );
  }

  Widget _buildLanguageUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.language,
      scrollController: scrollController,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        if (!mounted) return;
        context.go(
          "/${RoutesConstant.videoByLanguagePage}/${datum.id ?? 0}",
          extra: {
            'newpage': widget.newPage.toString(),
            'itemid': (datum.id ?? 0).toString(),
            'title': datum.name ?? '',
            'layouttype': 'ByLanguage',
          },
        );
      },
    );
  }

  Widget _buildGenresUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
    ScrollController? scrollController,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.genre,
      scrollController: scrollController,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        if (!mounted) return;
        context.go(
          "/${RoutesConstant.videoByCatPage}/${datum.id ?? 0}",
          extra: {
            'newpage': widget.newPage.toString(),
            'itemid': (datum.id ?? 0).toString(),
            'title': datum.name ?? '',
            'layouttype': 'ByCategory',
          },
        );
      },
    );
  }
  /* ***************** Sections END */

  /* Section Shimmer */
  Widget sectionShimmer() {
    return ListView.builder(
      itemCount: 10, // itemCount must be greater than 5
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        if (index == 1) {
          return ShimmerUtils.setHomeSections(context, "portrait");
        } else if (index == 2) {
          return ShimmerUtils.setHomeSections(context, "square");
        } else if (index == 3) {
          return ShimmerUtils.setHomeSections(context, "langGen");
        } else {
          return ShimmerUtils.setHomeSections(context, "landscape");
        }
      },
    );
  }
}
