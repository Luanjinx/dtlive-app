import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../model/playermodel.dart';
import '../pages/sectionviewall.dart';
import '../pages/contentbyid.dart';
import '../pages/settings.dart';
import '../players/model/vdociphermodel.dart';
import '../provider/bottombarprovider.dart';
import '../provider/connectivityprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectionviewallprovider.dart';
import '../provider/videobyidprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../model/sectionlistmodel.dart';
import '../model/sectiontypemodel.dart' as type;
import '../model/sectionlistmodel.dart' as list;
import '../model/sectionbannermodel.dart' as banner;
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../widget/morehomedialog.dart';
import '../widget/myusernetworkimg.dart';
import '../widget/nodata.dart';
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

class Home extends StatefulWidget {
  final String? pageName;
  const Home({super.key, required this.pageName});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  late HomeProvider homeProvider;
  late BottombarProvider bottombarProvider;
  late SectionDataProvider sectionDataProvider;
  late VideoByIDProvider videoByIDProvider;
  late ConnectivityProvider connectivityProvider;
  CarouselSliderController carouselController = CarouselSliderController();
  final nestedScrollController = ScrollController();
  final tabScrollController = ScrollController();
  late ListObserverController observerController;
  String? currentPage, subscriptionStatus, continueWatchingStatus;

  Future<void> _nestedScrollListener() async {
    if (!nestedScrollController.hasClients) return;
    if (nestedScrollController.offset >=
            nestedScrollController.position.maxScrollExtent &&
        !nestedScrollController.position.outOfRange &&
        (sectionDataProvider.isMorePage ?? false)) {
      sectionDataProvider.setLoadMore(true);
      _fetchSectionData(sectionDataProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchSectionData(int? nextPage) async {
    printLog("_fetchSectionData nextPage  ========> $nextPage");
    printLog(
      "_fetchSectionData isMorePage  ======> ${sectionDataProvider.isMorePage}",
    );
    printLog(
      "_fetchSectionData currentPage ======> ${sectionDataProvider.currentPage}",
    );
    printLog(
      "_fetchSectionData totalPage   ======> ${sectionDataProvider.totalPage}",
    );

    await sectionDataProvider.getSectionList(
      (homeProvider.selectedIndex == -1)
          ? 0
          : (homeProvider
                    .sectionTypeModel
                    .result?[homeProvider.selectedIndex]
                    .id ??
                0),
      (homeProvider.selectedIndex == -1) ? "1" : "2",
      (nextPage ?? 0) + 1,
    );
    printLog(
      "sectionList length ==> ${sectionDataProvider.sectionList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    nestedScrollController.addListener(_nestedScrollListener);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: transparent,
        systemNavigationBarColor: secondaryBgColor,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    videoByIDProvider = Provider.of<VideoByIDProvider>(context, listen: false);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    observerController = ListObserverController(
      controller: tabScrollController,
    );
    currentPage = widget.pageName ?? "";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future _getData() async {
    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    continueWatchingStatus = await Utils.configByStatus(
      status: Constant.continueWatchingStatus,
    );
    printLog('_getData subscriptionStatus =======> $subscriptionStatus');
    printLog('_getData continueWatchingStatus ===> $continueWatchingStatus');
    await homeProvider.setLoading(true);
    if (connectivityProvider.isOnline) {
      await homeProvider.getSectionType();

      if (!homeProvider.loading) {
        printLog(
          '_getData sectionBanner ===> ${sectionDataProvider.sectionBannerModel.result?.length}',
        );
        printLog(
          '_getData sectionList =====> ${sectionDataProvider.sectionList?.length}',
        );
        if (homeProvider.sectionTypeModel.status == 200 &&
            homeProvider.sectionTypeModel.result != null) {
          if ((homeProvider.sectionTypeModel.result?.length ?? 0) > 0) {
            if ((sectionDataProvider.sectionBannerModel.result?.length ?? 0) ==
                    0 ||
                (sectionDataProvider.sectionList?.length ?? 0) == 0) {
              printLog('_getData INITIAL Fetching');
              getTabData(-1, homeProvider.sectionTypeModel.result);
            }
          }
        }
      }
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    if (connectivityProvider.isOnline) {
      await Future.wait([
        homeProvider.getGenres(),
        homeProvider.getChannel(),
        homeProvider.getLanguage(),
      ]);
    }
    Utils.getCurrencySymbol();
  }

  Future<void> setSelectedTab(int tabPos) async {
    printLog("setSelectedTab tabPos ====> $tabPos");
    if (!mounted) return;
    homeProvider.setSelectedTab(tabPos);
    printLog(
      "setSelectedTab selectedIndex ====> ${homeProvider.selectedIndex}",
    );
    printLog(
      "setSelectedTab lastTabPosition ====> ${sectionDataProvider.lastTabPosition}",
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
    printLog("getTabData position ====> $position");
    try {
      await sectionDataProvider.clearOldData();
      sectionDataProvider.setLoading(true);
      await bottombarProvider.toggleVisibility(true);

      if (nestedScrollController.hasClients) {
        await nestedScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }

      final isDefaultTab = position == -1;
      final tabId = isDefaultTab
          ? "0"
          : (sectionTypeList?[position].id ?? 0).toString();
      final type = isDefaultTab ? "1" : "2";

      // set selected tab index
      await setSelectedTab(isDefaultTab ? -1 : position);

      // parallel API calls
      await Future.wait([
        sectionDataProvider.getSectionBanner(tabId, type),
        sectionDataProvider.getSectionList(tabId, type, 1),
      ]);
    } on Exception catch (e) {
      printLog("getTabData Error :====>  $e");
    }
  }

  Future<void> openDetailPage(
    int videoId,
    int subVideoType,
    int videoType,
    int typeId,
  ) async {
    printLog("videoId ========> $videoId");
    printLog("subVideoType ===> $subVideoType");
    printLog("videoType ======> $videoType");
    printLog("typeId =========> $typeId");
    if (!mounted) return;
    AdHelper.checkAndShowAds(
      context: context,
      buttonKey: "",
      adType: Constant.rewardAdType,
      alwaysShowAd: false,
      showOnByClick: true,
      onAdComplete: () async {
        Utils.openDetails(
          context: context,
          videoId: videoId,
          subVideoType: subVideoType,
          videoType: videoType,
          typeId: typeId,
          newPage: (videoType == Constant.shortsContentType)
              ? RoutesConstant.clipsEpisodesPage
              : RoutesConstant.contentDetailsPage,
          oldPage: '',
          reqText: '',
        );
      },
    );
  }

  /* ========= Open Player ========= */
  Future<void> openPlayer(
    String playType,
    int position,
    List<Datum>? continueWatchingList,
  ) async {
    printLog("position ==========> $position");

    /* CHECK SUBSCRIPTION */
    if (playType != "Trailer") {
      bool? isPrimiumUser = await Utils.checkSubsRentLogin(
        context: context,
        isPremium: continueWatchingList?[position].isPremium ?? 0,
        isBuy: continueWatchingList?[position].isBuy ?? 0,
        isRent: continueWatchingList?[position].isRent ?? 0,
        rentBuy: continueWatchingList?[position].rentBuy ?? 0,
        producerId: (continueWatchingList?[position].producerId ?? 0)
            .toString(),
        videoId: (continueWatchingList?[position].id ?? 0).toString(),
        rentPrice: (continueWatchingList?[position].price ?? 0).toString(),
        vTitle: (continueWatchingList?[position].name ?? 0).toString(),
        typeId: (continueWatchingList?[position].typeId ?? 0).toString(),
        vType: (continueWatchingList?[position].videoType ?? 0).toString(),
        subVideoType: (continueWatchingList?[position].subVideoType ?? 0)
            .toString(),
        rentProductId: (kIsWeb)
            ? (continueWatchingList?[position].webPriceId.toString() ?? '')
            : (Platform.isIOS
                  ? (continueWatchingList?[position].iosProductPackage
                            .toString() ??
                        '')
                  : (continueWatchingList?[position].androidProductPackage
                            .toString() ??
                        '')),
        newPage: '',
        oldPage: '',
        reqText: '',
      );
      printLog("isPrimiumUser =============> $isPrimiumUser");
      if (!isPrimiumUser) return;
    }
    /* CHECK SUBSCRIPTION */

    /* Set-up Quality URLs */
    Utils.setQualityURLs(
      video320: (continueWatchingList?[position].video320 ?? ""),
      video480: (continueWatchingList?[position].video480 ?? ""),
      video720: (continueWatchingList?[position].video720 ?? ""),
      video1080: (continueWatchingList?[position].video1080 ?? ""),
    );

    /* VdoCipher OTP */
    VdoCipherModel? vdocipherDetails;
    if ((continueWatchingList?[position].videoUploadType ?? "") ==
            Constant.vdocipherPlayType &&
        playType != "Trailer") {
      if (!mounted) return;
      vdocipherDetails = await Utils.getVdoCipherOTP(
        context: context,
        videoId: (continueWatchingList?[position].episode != null)
            ? (continueWatchingList?[position].episode?.video320 ?? "")
            : (continueWatchingList?[position].video320 ?? ""),
      );
      printLog(
        "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
      );
    }
    /* VdoCipher OTP */

    PlayerModel playerModel = PlayerModel(
      playType:
          ((continueWatchingList?[position].videoType ?? 0) ==
                  Constant.showContentType ||
              (continueWatchingList?[position].subVideoType ?? 0) ==
                  Constant.showContentType)
          ? "Show"
          : "Video",
      isLive:
          ((continueWatchingList?[position].videoUploadType ?? "") ==
                  "live_stream_url" &&
              playType != "Trailer")
          ? true
          : false,
      videoId: (continueWatchingList?[position].id ?? 0),
      videoTitle: continueWatchingList?[position].name ?? "",
      videoType: continueWatchingList?[position].videoType ?? 0,
      subVideoType: continueWatchingList?[position].subVideoType ?? 0,
      typeId: continueWatchingList?[position].typeId ?? 0,
      episodeId: (continueWatchingList?[position].episode != null)
          ? (continueWatchingList?[position].episode?.id ?? 0)
          : 0,
      videoUrl: (continueWatchingList?[position].episode != null)
          ? (continueWatchingList?[position].episode?.video320 ?? "")
          : (continueWatchingList?[position].video320 ?? ""),
      cipherMediaDetails:
          (vdocipherDetails != null && vdocipherDetails.result != null)
          ? (vdocipherDetails.result)
          : null,
      trailerUrl: continueWatchingList?[position].trailerUrl ?? "",
      uploadType: continueWatchingList?[position].videoUploadType ?? "",
      videoThumb: continueWatchingList?[position].landscape ?? "",
      stopTime: continueWatchingList?[position].stopTime ?? 0,
      isPremium: continueWatchingList?[position].isPremium ?? 0,
      isBuy: continueWatchingList?[position].isBuy ?? 0,
      isRent: continueWatchingList?[position].isRent ?? 0,
      rentBuy: continueWatchingList?[position].rentBuy ?? 0,
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
          await getTabData(-1, homeProvider.sectionTypeModel.result);
          Future.delayed(Duration.zero).then((value) {
            if (!mounted) return;
            setState(() {});
          });
        }
      },
    );
  }
  /* ========= Open Player ========= */

  void _openMoreDialog() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: transparent,
      builder: (BuildContext context) {
        return const Wrap(
          alignment: WrapAlignment.center,
          children: [MoreHomeDialog()],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    LoadingOverlay().hide();
  }

  void _scrollToCurrent() {
    if (homeProvider.selectedIndex == -1) return;
    observerController.animateTo(
      index: homeProvider.selectedIndex,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (!nestedScrollController.hasClients) return false;
          if (!mounted) return false;
          if (nestedScrollController.position.userScrollDirection ==
                  ScrollDirection.reverse &&
              sectionDataProvider.sectionList != null &&
              (sectionDataProvider.sectionList?.length ?? 0) > 2) {
            bottombarProvider.toggleVisibility(false);
          } else if (nestedScrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
            bottombarProvider.toggleVisibility(true);
          }
          return true;
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: Consumer2<HomeProvider, BottombarProvider>(
                  builder: (context, homeProvider, bottombarProvider, child) {
                    return _buildAppBar(innerBoxIsScrolled);
                  },
                ),
              ),
            ];
          },
          body: SafeArea(child: _buildPageUI()),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      titleSpacing: 10,
      backgroundColor: transparent,
      flexibleSpace: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: bottombarProvider.isShowBottombar ? 0.0 : 1.0,
        child: ClipRRect(
          child: Container(color: appBgColor.withValues(alpha: 0.8)),
        ),
      ),
      leading: Container(
        height: kToolbarHeight,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.zero,
        child: MyImage(imagePath: "appicon.png"),
      ),
      title: _buildAppBarSubscribeBtn(),
      actions: [
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(right: 15),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: transparent,
            highlightColor: transparent,
            onTap: () async {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return const Settings();
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                ),
              );
            },
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                if (profileProvider.profileModel.result != null &&
                    (profileProvider.profileModel.result?.length ?? 0) > 0) {
                  return Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: (Constant.userIsKid == true)
                          ? MyImage(
                              imagePath: 'kids.png',
                              fit: BoxFit.cover,
                              width: 23,
                              height: 23,
                            )
                          : MyUserNetworkImage(
                              imageUrl:
                                  profileProvider
                                      .profileModel
                                      .result?[0]
                                      .image ??
                                  "",
                              fit: BoxFit.cover,
                              width: 23,
                              height: 23,
                            ),
                    ),
                  );
                } else {
                  return MyImage(
                    width: 20,
                    height: 20,
                    imagePath: "ic_stuff.png",
                    color: white,
                  );
                }
              },
            ),
          ),
        ),
      ],
      pinned: true,
      floating: true,
      expandedHeight: 0,
      forceElevated: innerBoxIsScrolled,
    );
  }

  Widget _buildAppBarSubscribeBtn() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (Constant.userIsKid == false &&
            (subscriptionStatus != null && subscriptionStatus == "1")) {
          return Container(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () async {
                if (Constant.userID != null) {
                  Utils.openSubscription(
                    context: context,
                    oldPage: RoutesConstant.homePage,
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
              },
              child: FittedBox(
                child: Container(
                  height: 30,
                  alignment: Alignment.centerLeft,
                  decoration: Utils.subscribeGradBorderBG(
                    (profileProvider.profileModel.result != null &&
                        (profileProvider.profileModel.result?.length ?? 0) >
                            0 &&
                        (profileProvider.profileModel.result?[0].isBuy ?? 0) ==
                            1),
                    40,
                    1,
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0 &&
                          (profileProvider.profileModel.result?[0].isBuy ??
                                  0) !=
                              1)
                        MyImage(
                          width: 15,
                          height: 15,
                          imagePath: "ic_subscribe.png",
                          withShaderMask: true,
                        ),
                      if (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0 &&
                          (profileProvider.profileModel.result?[0].isBuy ??
                                  0) !=
                              1)
                        const SizedBox(width: 4),
                      MyText(
                        color:
                            (profileProvider.profileModel.result != null &&
                                (profileProvider.profileModel.result?.length ??
                                        0) >
                                    0 &&
                                (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .isBuy ??
                                        0) ==
                                    1)
                            ? white
                            : colorPrimary,
                        text:
                            (profileProvider.profileModel.result != null &&
                                (profileProvider.profileModel.result?.length ??
                                        0) >
                                    0 &&
                                (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .isBuy ??
                                        0) ==
                                    1)
                            ? (profileProvider
                                      .profileModel
                                      .result?[0]
                                      .packageName ??
                                  "")
                            : "subscribe",
                        multilanguage:
                            (profileProvider.profileModel.result != null &&
                                (profileProvider.profileModel.result?.length ??
                                        0) >
                                    0 &&
                                (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .isBuy ??
                                        0) ==
                                    1)
                            ? false
                            : true,
                        fontsizeNormal: 12,
                        fontsizeWeb: 15,
                        maxline: 1,
                        fontweight: FontWeight.w700,
                        textalign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPageUI() {
    if (homeProvider.loading) {
      return ShimmerUtils.buildHomeMobileShimmer(context);
    } else {
      if (homeProvider.sectionTypeModel.status == 200) {
        if (homeProvider.sectionTypeModel.result != null ||
            (homeProvider.sectionTypeModel.result?.length ?? 0) > 0) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              /* Banner & Sections */
              Consumer<SectionDataProvider>(
                builder: (context, sectionDataProvider, child) {
                  if ((sectionDataProvider.sectionBannerModel.result == null ||
                          (sectionDataProvider
                                      .sectionBannerModel
                                      .result
                                      ?.length ??
                                  0) ==
                              0) &&
                      (sectionDataProvider.sectionList?.length ?? 0) == 0 &&
                      !sectionDataProvider.loadingBanner &&
                      !sectionDataProvider.loadingSection) {
                    return const Center(
                      child: NoData(
                        title: 'no_data',
                        subTitle: 'no_video_show',
                      ),
                    );
                  } else {
                    return _buildTypeTabData(
                      homeProvider.sectionTypeModel.result,
                    );
                  }
                },
              ),

              /* Types */
              FittedBox(
                child: Container(
                  height: Dimens.homeTabHeightSmall,
                  padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: _buildTypeTabs(homeProvider.sectionTypeModel.result),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: NoData(title: 'no_data', subTitle: 'no_video_show'),
          );
        }
      } else {
        return const Center(
          child: NoData(title: 'no_data', subTitle: 'no_video_show'),
        );
      }
    }
  }

  /* Type START ************** */
  Widget _buildTypeTabs(List<type.Result>? sectionTypeList) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.selectedIndex != -1) {
          return _buildSelectedTypeView(sectionTypeList);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (tabScrollController.hasClients) {
              _scrollToCurrent();
            }
          });
          return Visibility(
            visible: (homeProvider.selectedIndex == -1),
            maintainAnimation: true,
            maintainState: true,
            child: AnimatedOpacity(
              opacity: (homeProvider.selectedIndex == -1) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1000),
              child: ListViewObserver(
                controller: observerController,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 30),
                  decoration: Utils.setBGWithBorder(
                    secondaryBgColor,
                    transparent,
                    Dimens.menuRadius,
                    0,
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ListView.separated(
                    itemCount: (sectionTypeList?.length ?? 0) > 3
                        ? 3
                        : (sectionTypeList?.length ?? 0),
                    shrinkWrap: true,
                    controller: tabScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    separatorBuilder: (context, index) => Container(
                      width: 1.5,
                      margin: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                      decoration: Utils.setBackground(grayDark, 5),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 2) {
                        return _buildMoreBtn();
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () async {
                          printLog("index ===========> $index");
                          AdHelper.checkAndShowAds(
                            context: context,
                            buttonKey: "",
                            adType: Constant.interstialAdType,
                            alwaysShowAd: false,
                            showOnByClick: true,
                            onAdComplete: () async {
                              await bottombarProvider.toggleVisibility(true);
                              await getTabData(
                                index,
                                homeProvider.sectionTypeModel.result,
                              );
                            },
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: MyText(
                            color: white,
                            multilanguage: false,
                            text:
                                (sectionTypeList?[index].name.toString() ?? ""),
                            fontsizeNormal: 14,
                            fontweight: FontWeight.w600,
                            fontsizeWeb: 15,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.center,
                            fontstyle: FontStyle.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSelectedTypeView(List<type.Result>? sectionTypeList) {
    return Visibility(
      visible: (homeProvider.selectedIndex != -1),
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        opacity: (homeProvider.selectedIndex != -1) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 1000),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 35),
              decoration: Utils.setBGWithBorder(
                secondaryBgColor,
                transparent,
                Dimens.menuRadius,
                0,
              ),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: MyText(
                  color: white,
                  multilanguage: false,
                  text:
                      (sectionTypeList?[(homeProvider.selectedIndex)].name
                          .toString() ??
                      ""),
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 15,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            /* Close */
            InkWell(
              onTap: () async {
                await getTabData(-1, sectionTypeList);
              },
              focusColor: white,
              borderRadius: BorderRadius.circular(Dimens.menuRadius),
              child: FittedBox(
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: secondaryBgColor,
                    borderRadius: BorderRadius.circular(Dimens.menuRadius),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: MyImage(imagePath: "ic_close.png", color: white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () async {
        _openMoreDialog();
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: MyText(
          color: white,
          multilanguage: true,
          text: "more",
          fontsizeNormal: 14,
          fontweight: FontWeight.w600,
          fontsizeWeb: 15,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.center,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildTypeTabData(List<type.Result>? sectionTypeList) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: RefreshIndicator(
        backgroundColor: white,
        color: complimentryColor,
        displacement: 80,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 1500)).then((
            value,
          ) async {
            printLog(
              "getTabData selectedIndex ===========> ${homeProvider.selectedIndex}",
            );
            await _getData();
            getTabData(
              homeProvider.selectedIndex,
              homeProvider.sectionTypeModel.result,
            );
          });
        },
        child: SingleChildScrollView(
          controller: nestedScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildBannerSections(),
        ),
      ),
    );
  }

  Widget _buildBannerSections() {
    return Column(
      children: [
        /* Banner */
        if (!sectionDataProvider.loadingBanner &&
            sectionDataProvider.sectionBannerModel.status == 200 &&
            sectionDataProvider.sectionBannerModel.result != null)
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(
              left: 13,
              right: 13,
              top: MediaQuery.of(context).padding.top + 30,
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
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
            child: ShimmerUtils.bannerMobile(context),
          )
        else if (sectionDataProvider.sectionBannerModel.status == 200 &&
            sectionDataProvider.sectionBannerModel.result != null)
          _mobileHomeBanner(sectionDataProvider.sectionBannerModel.result)
        else
          SafeArea(child: SizedBox(height: Dimens.homeTabHeightSmall)),

        /* Banner Ad */
        SmartBannerAd(isSpacing: true, topSpace: 10, bottomSpace: 10),

        /* Remaining Sections */
        if (sectionDataProvider.loadingSection && !sectionDataProvider.loadMore)
          sectionShimmer()
        else if (sectionDataProvider.sectionList != null &&
            (sectionDataProvider.sectionList?.length ?? 0) > 0)
          setSectionByType()
        else
          const SizedBox.shrink(),

        /* Pagination loader */
        if (sectionDataProvider.loadMore)
          ShimmerUtils.sectionPortraitListView(context)
        else
          const SizedBox.shrink(),
        SizedBox(height: Dimens.homeTabHeight),
      ],
    );
  }
  /* **************** Type END */

  /* Banner START ************** */
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
          viewportFraction: 0.8,
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
                  MyNetworkImage(imageUrl: imageUrl, fit: BoxFit.fill),
                  /* Top gradient */
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          black.withValues(alpha: 0.55),
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
                          black.withValues(alpha: 0.82),
                          black.withValues(alpha: 0.70),
                          black.withValues(alpha: 0.50),
                          black.withValues(alpha: 0.28),
                          black.withValues(alpha: 0.08),
                          transparent,
                        ],
                        stops: const [0.0, 0.18, 0.38, 0.58, 0.75, 1.0],
                      ),
                    ),
                  ),
                  /* Badge — top-left */
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _buildBannerBadge(list[index]),
                  ),
                  /* Title + Metadata — bottom-left :: Action buttons — bottom-right */
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                color: white,
                                text: (list[index].name ?? "").isNotEmpty
                                    ? (list[index].name ?? "")
                                    : "-",
                                textalign: TextAlign.start,
                                fontsizeNormal: 24,
                                fontsizeWeb: 26,
                                fontweight: FontWeight.w800,
                                multilanguage: false,
                                maxline: 2,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                                isShadowText: true,
                              ),
                              const SizedBox(height: 3),
                              _buildBannerMetaRow(list[index]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
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

  Widget _buildBannerBadge(banner.Result item) {
    final isLive = (item.videoUploadType ?? "") == "live_stream_url";
    if (isLive) {
      return _badgePill(label: "LIVE", bgColor: colorAccent, showDot: true);
    }
    final isPremium = (item.isPremium ?? 0) == 1 && (item.isBuy ?? 0) == 0;
    if (isPremium) {
      return _badgePill(label: "PREMIUM", bgColor: secondaryBgColor);
    }
    return SizedBox.shrink();
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
      fontsizeNormal: 12,
      fontsizeWeb: 14,
      fontweight: FontWeight.w500,
      multilanguage: false,
      maxline: 5,
      overflow: TextOverflow.ellipsis,
      fontstyle: FontStyle.normal,
      isShadowText: true,
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: white.withValues(alpha: 0.10), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: MyImage(imagePath: iconPath, color: white),
      ),
    );
  }

  /* **************** Banner END */

  /* Sections START ************** */
  Widget setSectionByType() {
    final sectionList = sectionDataProvider.sectionList;
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

          /* AI Recommendation Section */
          if ((sectionList?[index].sectionType ?? 0) ==
              Constant.aiContentType) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 25),
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
                onViewAllTap: () async {
                  final sectionViewAllProvider =
                      Provider.of<SectionViewAllProvider>(
                        context,
                        listen: false,
                      );
                  if ((sectionList[index].viewAll ?? 0) == 1) {
                    sectionViewAllProvider.setLoading(true);
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SectionViewAll(
                          appBarTitle: sectionList[index].title ?? "",
                          screenLayout: sectionList[index].screenLayout ?? "",
                          sectionId: sectionList[index].id ?? 0,
                          videoType: sectionList[index].videoType ?? 0,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }
          /* ───────────────────────── */

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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return SectionViewAll(
                            sectionId: sectionList?[index].id ?? 0,
                            appBarTitle: sectionList?[index].title ?? "",
                            screenLayout:
                                sectionList?[index].screenLayout ?? "",
                            videoType: sectionList?[index].videoType ?? 0,
                          );
                        },
                      ),
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
              const SizedBox(height: 25),
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
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.only(left: 13, right: 13),
        child: InkWell(
          onTap: ((sectionList?[index].viewAll ?? 0) == 1)
              ? onViewAllClick
              : null,
          borderRadius: BorderRadius.circular(3),
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
                      fontsizeNormal: 15,
                      fontweight: FontWeight.w600,
                      fontsizeWeb: 17,
                      multilanguage: false,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                  if ((sectionList?[index].viewAll ?? 0) == 1)
                    Container(
                      alignment: Alignment.centerRight,
                      height: 20,
                      margin: const EdgeInsets.only(left: 5, top: 2),
                      padding: const EdgeInsets.all(5),
                      child: MyImage(
                        imagePath: "ic_viewall.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
              if ((sectionList?[index].shortTitle.toString() ?? "").isNotEmpty)
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
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "big_landscape") {
      return _buildLandscapeBigUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "index_landscape") {
      return _buildLandscapeIndexUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "portrait") {
      return _buildPortraitUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "big_portrait") {
      return _buildPortraitBigUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "index_portrait") {
      return _buildPortraitIndexUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "square") {
      return _buildSquareUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "shorts") {
      return _buildShortsUI(sectionList?[index].id, sectionList?[index].data);
    } else if ((sectionList?[index].screenLayout ?? "") == "category") {
      return _buildGenresUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "language") {
      return _buildLanguageUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
      );
    } else if ((sectionList?[index].screenLayout ?? "") == "channel") {
      return _buildChannelUI(
        sectionList?[index].videoType,
        sectionList?[index].typeId ?? 0,
        sectionList?[index].data,
      );
    } else {
      return _buildLandscapeUI(
        sectionList?[index].videoType,
        sectionList?[index].data,
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
      return Dimens.heightLand;
    } else if (layoutType == "big_landscape") {
      return Dimens.heightLandBig;
    } else if (layoutType == "portrait" || layoutType == "index_portrait") {
      return Dimens.heightPort;
    } else if (layoutType == "big_portrait") {
      return Dimens.heightPortBig;
    } else if (layoutType == "square") {
      return Dimens.heightSquare;
    } else if (layoutType == "shorts") {
      return ((sectionList?[index].data?.length ?? 0) < 4)
          ? (Dimens.heightShortsTotal)
          : (Dimens.heightShortsTotal * 2);
    } else if (layoutType == "category") {
      return Dimens.heightGen + 28;
    } else if (layoutType == "language") {
      return Dimens.heightLang + 28;
    } else if (layoutType == "channel") {
      return ((sectionList?[index].data?.length ?? 0) < 4)
          ? (Dimens.heightChannelTotal)
          : (Dimens.heightChannelTotal * 2);
    } else {
      return Dimens.heightLand;
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

  Widget _buildLandscapeUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.landscape,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildLandscapeIndexUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.indexLandscape,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildLandscapeBigUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.bigLandscape,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildPortraitUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.portrait,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildPortraitBigUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.bigPortrait,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildPortraitIndexUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.indexPortrait,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildSquareUI(int? videoType, List<Datum>? sectionDataList) {
    return ContentSectionWidget(
      items: sectionDataList,
      layout: ContentCardLayout.square,
      showScrollArrows: false,
      horizontalPadding: 14,
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

  Widget _buildShortsUI(int? sectionId, List<Datum>? sectionDataList) {
    return ShortsSectionWidget(
      section: list.Result()
        ..data = sectionDataList
        ..id = sectionId,
      showScrollArrows: false,
      twoRowsThreshold: 4,
      horizontalPadding: 14,
      onItemTap: (datum, index) {
        printLog("Clicked on index ======> $index");
        printLog("Clicked on sectionId ==> $sectionId");
        openDetailPage(
          datum.id ?? 0,
          datum.subVideoType ?? 0,
          datum.videoType ?? 0,
          datum.typeId ?? 0,
        );
      },
    );
  }

  Widget _buildChannelUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.channel,
      showScrollArrows: false,
      horizontalPadding: 14,
      itemSpacing: Dimens.spaceBetweenChannel,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        videoByIDProvider.setLoading(true);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ContentByID(datum.id ?? 0, datum.name ?? "", "ByChannel");
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.language,
      showScrollArrows: false,
      horizontalPadding: 14,
      itemSpacing: Dimens.spaceBetweenLang,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        videoByIDProvider.setLoading(true);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ContentByID(datum.id ?? 0, datum.name ?? "", "ByLanguage");
            },
          ),
        );
      },
    );
  }

  Widget _buildGenresUI(
    int? videoType,
    int? typeId,
    List<Datum>? sectionDataList,
  ) {
    return GenreLangSectionWidget(
      items: sectionDataList,
      type: GenreLangType.genre,
      showScrollArrows: false,
      horizontalPadding: 14,
      itemSpacing: Dimens.spaceBetweenCategory,
      onItemTap: (datum, index) async {
        printLog("Clicked on index ==> $index");
        videoByIDProvider.setLoading(true);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ContentByID(datum.id ?? 0, datum.name ?? "", "ByCategory");
            },
          ),
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
