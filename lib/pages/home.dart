import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

  @override
  void dispose() {
    super.dispose();
    LoadingOverlay().hide();
  }

  void _scrollToCurrent(int index) {
    if (!tabScrollController.hasClients) return;
    tabScrollController.animateTo(
      (index * 95.0).clamp(0.0, tabScrollController.position.maxScrollExtent),
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      extendBody: true,
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
          body: SafeArea(top: true, bottom: false, child: _buildPageUI()),
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
          return Consumer<SectionDataProvider>(
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

  /* Category Pills START (HiTV themed style) ************** */
  Widget _buildCategoryPillsRow(List<type.Result>? sectionTypeList) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final list = sectionTypeList ?? [];
        final int itemCount = 1 + list.length; // 1 for "Home" + all categories

        return SizedBox(
          height: 36,
          child: ListView.separated(
            controller: tabScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final bool isHomeTab = index == 0;
              final bool isSelected = isHomeTab
                  ? (homeProvider.selectedIndex == -1)
                  : (homeProvider.selectedIndex == (index - 1));

              final String title = isHomeTab
                  ? "Home"
                  : (list[index - 1].name?.toString() ?? "");

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: transparent,
                highlightColor: transparent,
                onTap: () async {
                  if (isSelected) return;
                  _scrollToCurrent(index);
                  AdHelper.checkAndShowAds(
                    context: context,
                    buttonKey: "",
                    adType: Constant.interstialAdType,
                    alwaysShowAd: false,
                    showOnByClick: true,
                    onAdComplete: () async {
                      await bottombarProvider.toggleVisibility(true);
                      await getTabData(
                        isHomeTab ? -1 : (index - 1),
                        sectionTypeList,
                      );
                    },
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 14 : 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colorPrimary : transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: MyText(
                    color: isSelected ? black : white.withValues(alpha: 0.90),
                    text: title,
                    multilanguage: false,
                    fontsizeNormal: 14,
                    fontsizeWeb: 15,
                    fontweight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  /* **************** Category Pills END */

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
    final bool hasTypes = homeProvider.sectionTypeModel.status == 200 &&
        (homeProvider.sectionTypeModel.result?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Top spacer to sit right below the pinned transparent SliverAppBar */
        const SizedBox(height: kToolbarHeight),

        /* Top Banner with Category Tabs embedded inside */
        if (sectionDataProvider.loadingBanner)
          Stack(
            children: [
              ShimmerUtils.bannerMobile(
                context,
                showCategoryPills: !hasTypes,
              ),
              if (hasTypes)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: _buildCategoryPillsRow(
                    homeProvider.sectionTypeModel.result,
                  ),
                ),
            ],
          )
        else if (sectionDataProvider.sectionBannerModel.status == 200 &&
            sectionDataProvider.sectionBannerModel.result != null &&
            (sectionDataProvider.sectionBannerModel.result?.isNotEmpty ?? false))
          _mobileHomeBanner(
            sectionDataProvider.sectionBannerModel.result,
            categoryList: hasTypes ? homeProvider.sectionTypeModel.result : null,
          )
        else if (hasTypes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildCategoryPillsRow(homeProvider.sectionTypeModel.result),
          )
        else
          const SizedBox.shrink(),

        /* Banner Ad */
        SmartBannerAd(isSpacing: false),

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
        SizedBox(height: Dimens.homeTabHeight + 25),
      ],
    );
  }
  /* **************** Type END */

  /* Banner START ************** */
  Widget _mobileHomeBanner(
    List<banner.Result>? sectionBannerList, {
    List<type.Result>? categoryList,
  }) {
    if ((sectionBannerList?.length ?? 0) == 0) return const SizedBox.shrink();
    final list = sectionBannerList!;
    final double screenW = MediaQuery.of(context).size.width;
    final double imageH = kIsWeb
        ? (screenW * 0.38).clamp(280.0, 420.0)
        : (screenW * 0.62).roundToDouble();
    final double carouselH = imageH + 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /* ── Landscape Carousel Slider with Category Tabs embedded ── */
        Stack(
          children: [
            CarouselSlider.builder(
              itemCount: list.length,
              carouselController: carouselController,
              options: CarouselOptions(
                initialPage: 0,
                height: carouselH,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                padEnds: false,
                enableInfiniteScroll: list.length > 1,
                autoPlay: true,
                autoPlayCurve: Curves.easeInOutCubic,
                autoPlayInterval: Duration(
                  milliseconds: Constant.bannerDuration,
                ),
                autoPlayAnimationDuration: Duration(
                  milliseconds: Constant.animationDuration,
                ),
                onPageChanged: (val, _) async {
                  sectionDataProvider.setCurrentBanner(val);
                },
              ),
              itemBuilder: (BuildContext context, int index, int pageViewIndex) {
                final item = list[index];
                final imageUrl = (item.landscape != null &&
                        (item.landscape ?? "").trim().isNotEmpty &&
                        !(item.landscape ?? "").contains("no_img"))
                    ? (item.landscape ?? "")
                    : (item.thumbnail ?? "");

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /* 16:9 Landscape Banner Image */
                    InkWell(
                      onTap: () {
                        openDetailPage(
                          item.id ?? 0,
                          item.subVideoType ?? 0,
                          item.videoType ?? 0,
                          item.typeId ?? 0,
                        );
                      },
                      child: SizedBox(
                        width: screenW,
                        height: imageH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MyNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: screenW,
                              height: imageH,
                            ),

                            /* Top gradient (HiTV style) to darken behind category tabs */
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 110,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.40, 0.75, 1.0],
                                      colors: [
                                        appBgColor.withValues(alpha: 0.95),
                                        appBgColor.withValues(alpha: 0.70),
                                        appBgColor.withValues(alpha: 0.30),
                                        transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /* Subtle bottom gradient to blend image into dark background */
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 52,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        transparent,
                                        appBgColor.withValues(alpha: 0.85),
                                        appBgColor,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /* Badge (top-left, below floating tabs) */
                            Positioned(
                              top: 50,
                              left: 14,
                              child: _buildBannerBadge(item),
                            ),

                            /* Optional Title if isTitle == 1 */
                            if ((item.isTitle ?? 0) == 1 &&
                                (item.name ?? "").trim().isNotEmpty)
                              Positioned(
                                bottom: 6,
                                left: 16,
                                right: 16,
                                child: MyText(
                                  color: white,
                                  text: item.name ?? "",
                                  textalign: TextAlign.center,
                                  fontsizeNormal: 18,
                                  fontsizeWeb: 20,
                                  fontweight: FontWeight.w800,
                                  multilanguage: false,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                  isShadowText: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /* Genres: e.g. Action • Adventure */
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildBannerGenres(item),
                    ),
                  ],
                );
              },
            ),

            /* Floating Category Tabs Row inside Banner (at the top over the dark gradient) */
            if (categoryList != null && categoryList.isNotEmpty)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: _buildCategoryPillsRow(categoryList),
              ),
          ],
        ),

        const SizedBox(height: 12),

        /* ── Action Buttons: [ ▶ Cek Sekarang ]  [ + Daftarku ] (Static, does not slide with carousel) ── */
        Consumer<SectionDataProvider>(
          builder: (context, sdp, _) {
            final int activeIndex =
                (sdp.cBannerIndex ?? 0).clamp(0, list.length - 1);
            final activeItem = list[activeIndex];
            final isLive =
                (activeItem.videoUploadType ?? "") == "live_stream_url";

            return Center(
              child: _buildBannerActionButtons(
                activeItem,
                activeIndex,
                isLive,
                screenW,
              ),
            );
          },
        ),

        /* ── Dot indicator ── */
        if (list.length > 1) ...[
          const SizedBox(height: 10),
          Center(
            child: Consumer<SectionDataProvider>(
              builder: (context, sdp, _) {
                final int activeIndex =
                    (sdp.cBannerIndex ?? 0).clamp(0, list.length - 1);
                return AnimatedSmoothIndicator(
                  count: list.length,
                  activeIndex: activeIndex,
                  effect: ScrollingDotsEffect(
                    spacing: 7,
                    radius: 4,
                    activeDotScale: 1.25,
                    activeDotColor: white,
                    dotColor: white.withValues(alpha: 0.30),
                    dotHeight: 5,
                    dotWidth: 5,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
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

  Widget _buildBannerGenres(banner.Result item) {
    final List<String> parts = [];
    if ((item.categoryName ?? "").trim().isNotEmpty) {
      parts.addAll(
        (item.categoryName ?? "")
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }
    if (parts.isEmpty) return const SizedBox(height: 18);

    return SizedBox(
      height: 18,
      child: Center(
        child: MyText(
          color: white.withValues(alpha: 0.95),
          text: parts.join("  •  "),
          textalign: TextAlign.center,
          fontsizeNormal: 13,
          fontsizeWeb: 14,
          fontweight: FontWeight.w600,
          letterSpacing: 0.3,
          multilanguage: false,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontstyle: FontStyle.normal,
          isShadowText: true,
        ),
      ),
    );
  }

  Widget _buildBannerActionButtons(
    banner.Result item,
    int index,
    bool isLive,
    double screenW,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /* Button 1: White pill button with black icon & text (Cek Sekarang / Watch Now) */
          Expanded(
            child: InkWell(
              onTap: () {
                openDetailPage(
                  item.id ?? 0,
                  item.subVideoType ?? 0,
                  item.videoType ?? 0,
                  item.typeId ?? 0,
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: black,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    MyText(
                      color: black,
                      text: "check_now",
                      fontsizeNormal: 13,
                      fontsizeWeb: 14,
                      fontweight: FontWeight.w700,
                      multilanguage: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /* Button 2: Dark translucent pill button with white border (Daftarku / + Watchlist) */
          Expanded(
            child: Consumer<SectionDataProvider>(
              builder: (context, sdp, _) {
                final bool isBookmarked = (item.isBookmark ?? 0) == 1;

                return InkWell(
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
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: white.withValues(alpha: 0.80),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isBookmarked
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          color: white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        MyText(
                          color: white,
                          text: "my_list",
                          fontsizeNormal: 13,
                          fontsizeWeb: 14,
                          fontweight: FontWeight.w700,
                          multilanguage: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
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
