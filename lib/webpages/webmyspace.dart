import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/continuewatchingmodel.dart';
import '../model/playermodel.dart';
import '../players/model/vdociphermodel.dart' as vdocipher;
import '../provider/homeprovider.dart';
import '../provider/myspaceprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/viewallprovider.dart';
import '../provider/watchlistprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/leftright_scroll_on_hover.dart';
import '../webwidget/web_hover_card.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/myusernetworkimg.dart';

class WebMySpace extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebMySpace({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebMySpace> createState() => WebMySpaceState();
}

class WebMySpaceState extends State<WebMySpace> with RouteAware {
  late MySpaceProvider mySpaceProvider;
  late HomeProvider homeProvider;
  late SectionDataProvider sectionDataProvider;
  late ProfileProvider profileProvider;
  SharedPre sharedPref = SharedPre();
  bool? isParentLocked;
  String? subscriptionStatus, continueWatchingStatus, watchlistStatus;

  final pinPutController = TextEditingController();
  final watchlistScrollController = ScrollController();
  final continueWatchScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    mySpaceProvider = Provider.of<MySpaceProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPop() {
    printLog("didPop");
    super.didPop();
  }

  @override
  void didPopNext() {
    printLog("didPopNext");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    super.didPopNext();
  }

  @override
  void didPush() {
    printLog("didPush");
    super.didPush();
  }

  @override
  void didPushNext() {
    printLog("didPushNext");
    super.didPushNext();
  }

  @override
  void dispose() {
    super.dispose();
    pinPutController.dispose();
    watchlistScrollController.dispose();
    continueWatchScrollController.dispose();
    printLog("dispose");
  }

  Future<void> _getData() async {
    isParentLocked = await Utils.checkParentLock();
    printLog("_getData isParentLocked ======> $isParentLocked");

    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    continueWatchingStatus = await Utils.configByStatus(
      status: Constant.continueWatchingStatus,
    );
    watchlistStatus = await Utils.configByStatus(
      status: Constant.watchlistStatus,
    );
    printLog('_getData subscriptionStatus ===> $subscriptionStatus');
    printLog('_getData continueWatchStatus ==> $continueWatchingStatus');
    printLog('_getData watchlistStatus ======> $watchlistStatus');

    if (!mounted) return;
    if (Constant.userID != null) {
      mySpaceProvider.getProfile(context);
      mySpaceProvider.getContinueWatching(1);
      mySpaceProvider.getWatchlist(1);
    }

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  /* ========= Open Player ========= */
  Future<void> openPlayer(
    String playType,
    int position,
    List<Result>? continueWatchingList,
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
        newPage: widget.newPage ?? "",
        oldPage: widget.oldPage ?? "",
        reqText: widget.reqText ?? "",
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
    vdocipher.VdoCipherModel? vdocipherDetails;
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
          (continueWatchingList?[position].videoType ?? 0) ==
              Constant.showContentType
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
  }
  /* ========= Open Player ========= */

  Future _clickToChangeProfiles({
    required bool userIsKid,
    required String clickFrom,
  }) async {
    printLog("userIsKid ===> $userIsKid");
    printLog("clickFrom ===> $clickFrom");
    if (!mounted) return;
    LoadingOverlay().show(context);
    if (userIsKid == true) {
      await mySpaceProvider.changeUserMode("1");
    } else {
      await mySpaceProvider.changeUserMode("0");
    }
    LoadingOverlay().hide();
    printLog("userIsKid ========> ${Constant.userIsKid}");
    if (mySpaceProvider.successModel.status == 200) {
      await Utils.setUserMode(userIsKid);
      homeProvider.clearProvider();
      sectionDataProvider.clearProvider();
      if (!mounted) return;
      profileProvider.notifyProvider();
      await homeProvider.setLoading(true);
      sectionDataProvider.setLoading(true);
      if (!mounted) return;
      if (clickFrom == 'dialog' && context.canPop()) {
        printLog("=====================REMOVE=====================");
        context.pop();
      }
      if (!mounted) return;
      context.pushReplacementNamed(RoutesConstant.homePage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
    );
  }

  Widget _buildUI() {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colorPrimary.withValues(alpha: 0.3),
            colorPrimary.withValues(alpha: 0.2),
            colorPrimary.withValues(alpha: 0.1),
            appBgColor.withValues(alpha: 0.1),
            appBgColor,
          ],
        ),
        borderRadius: BorderRadius.circular(0),
        shape: BoxShape.rectangle,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* AppIcon & Settings */
            _buildIconSettings(),
            _buildPage(),
          ],
        ),
      ),
    );
  }

  /* App Icon & Settings */
  Widget _buildIconSettings() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 40 : 25,
        (Dimens.homeTabHeight + 20),
        Dimens.isBigScreen(context) ? 40 : 25,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: MyImage(
              height: (Dimens.isBigScreen(context)) ? 40 : 32,
              imagePath: "appicon.png",
              fit: BoxFit.contain,
            ),
          ),
          if (Constant.userIsKid == false)
            InkWell(
              borderRadius: BorderRadius.circular(Dimens.cardRadius),
              onTap: () async {
                if (!mounted) return;
                context.go(
                  "/${RoutesConstant.settingsPage}",
                  extra: widget.newPage ?? "",
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: Utils.setBackground(
                  appBgColor.withValues(alpha: 0.1),
                  Dimens.cardRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 25,
                      width: 25,
                      alignment: Alignment.centerLeft,
                      child: MyImage(
                        imagePath: "ic_setting.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(left: 15),
                      child: MyText(
                        color: white,
                        text: "help_setting",
                        multilanguage: true,
                        textalign: TextAlign.start,
                        fontsizeNormal: 13,
                        fontsizeWeb: 18,
                        fontweight: FontWeight.w500,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 40 : 25,
        0,
        Dimens.isBigScreen(context) ? 40 : 25,
        0,
      ),
      child: Consumer2<ProfileProvider, MySpaceProvider>(
        builder: (context, profileProvider, mySpaceProvider, child) {
          if (Constant.userID != null) {
            return _buildForLogin();
          } else {
            return _buildForNotLogin();
          }
        },
      ),
    );
  }

  /* If User Login */
  Widget _buildForLogin() {
    return Column(
      children: [
        /* Subscribe */
        if (Constant.userIsKid == false) _buildSubscribe(),
        _buildLine(0, 35.0, 0, 35.0),

        /* Profiles */
        _buildProfiles(),
        /* Watchlist */
        const SizedBox(height: 40),
        _buildWatchlist(),
        /* Continue Watching */
        const SizedBox(height: 40),
        _buildContinueWatching(),
      ],
    );
  }

  Widget _buildSubscribe() {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /* Current Plan */
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(Dimens.cardRadius),
                onTap: () async {
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.myProfilePage}",
                    extra: widget.newPage ?? "",
                  );
                },
                child: _buildSubscribeText(),
              ),
            ),
          ),
          /* Subscribe */
          if (profileProvider.profileModel.result != null &&
              (profileProvider.profileModel.result?.length ?? 0) > 0 &&
              (profileProvider.profileModel.result?[0].isBuy ?? 0) != 1 &&
              Constant.userIsKid == false &&
              (subscriptionStatus != null && subscriptionStatus == "1"))
            InkWell(
              borderRadius: BorderRadius.circular(Dimens.cardRadius),
              onTap: () async {
                await Utils.openSubscription(context: context, oldPage: "");
              },
              child: Container(
                height: Dimens.defaultBtnHeightWeb,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                decoration: Utils.setBackground(colorPrimary, 10),
                child: MyText(
                  color: black,
                  text: "subscribe",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 13,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscribeText() {
    if (profileProvider.profileModel.result != null &&
        (profileProvider.profileModel.result?.length ?? 0) > 0 &&
        (profileProvider.profileModel.result?[0].isBuy ?? 0) != 1) {
      return Container(
        constraints: const BoxConstraints(minHeight: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (subscriptionStatus != null && subscriptionStatus == "1")
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(right: 3),
                child: MyText(
                  color: white,
                  text: "subscribe_to_enjoy",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 15,
                  fontsizeWeb: 17,
                  fontweight: FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(right: 8),
                  child: MyText(
                    color: colorPrimary,
                    text: Constant.appName,
                    multilanguage: false,
                    textalign: TextAlign.start,
                    fontsizeNormal: 15,
                    fontsizeWeb: 17,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
                Container(
                  height: 12,
                  width: 12,
                  alignment: Alignment.centerLeft,
                  child: MyImage(
                    imagePath: "ic_right.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(minHeight: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* Current Plan */
            if (subscriptionStatus != null && subscriptionStatus == "1")
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(right: 8),
                    child: MyText(
                      color: titleTextColor,
                      text:
                          (profileProvider.profileModel.result != null &&
                              (profileProvider.profileModel.result?.length ??
                                      0) >
                                  0)
                          ? (profileProvider
                                    .profileModel
                                    .result?[0]
                                    .packageName ??
                                "")
                          : "-",
                      multilanguage: false,
                      textalign: TextAlign.center,
                      fontsizeNormal: 18,
                      fontsizeWeb: 22,
                      fontweight: FontWeight.w700,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                      withShaderMask: true,
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 15,
                    alignment: Alignment.centerLeft,
                    child: MyImage(
                      imagePath: "ic_right.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            /* Mobile Number / Email Address */
            Container(
              margin: const EdgeInsets.fromLTRB(0, 3, 0, 0),
              child: MyText(
                color: titleTextColor,
                text:
                    (profileProvider.profileModel.result == null ||
                        (profileProvider.profileModel.result?.length ?? 0) == 0)
                    ? "-"
                    : (Utils.convertToStar(
                        (profileProvider.profileModel.result?[0].type == 1)
                            ? (profileProvider
                                      .profileModel
                                      .result?[0]
                                      .mobileNumber ??
                                  "")
                            : ((profileProvider.profileModel.result?[0].email ??
                                          "")
                                      .isNotEmpty
                                  ? (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .email ??
                                        "")
                                  : "-"),
                      )),
                multilanguage: false,
                textalign: TextAlign.start,
                fontsizeNormal: 15,
                fontsizeWeb: 17,
                fontweight: FontWeight.w500,
                maxline: 2,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                withShaderMask: false,
              ),
            ),
          ],
        ),
      );
    }
  }

  /* Profiles START *************** */
  Widget _buildProfiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Title & Edit */
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(right: 10),
                child: MyText(
                  color: white,
                  text: "profiles",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 15,
                  fontsizeWeb: 18,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),
            if (Constant.userIsKid == false)
              InkWell(
                borderRadius: BorderRadius.circular(Dimens.cardRadius),
                onTap: () async {
                  context.go(
                    "/${RoutesConstant.editProfilePage}",
                    extra: widget.oldPage,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 15,
                        width: 15,
                        alignment: Alignment.center,
                        child: MyImage(
                          imagePath: "ic_edit.png",
                          fit: BoxFit.contain,
                          color: white,
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 10),
                        child: MyText(
                          color: colorPrimary,
                          text: "edit",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsizeNormal: 15,
                          fontsizeWeb: 17,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        /* Data */
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileItem(
                    profileType: "user",
                    isActive: Constant.userIsKid == false,
                    profileImage:
                        (mySpaceProvider.profileModel.result != null &&
                            (mySpaceProvider.profileModel.result?.length ?? 0) >
                                0)
                        ? (mySpaceProvider.profileModel.result?[0].image ?? "")
                        : "",
                    profileName:
                        (mySpaceProvider.profileModel.result != null &&
                            (mySpaceProvider.profileModel.result?.length ?? 0) >
                                0)
                        ? (((mySpaceProvider.profileModel.result?[0].fullName ??
                                          "")
                                      .isEmpty ||
                                  (mySpaceProvider
                                              .profileModel
                                              .result?[0]
                                              .fullName ??
                                          "")
                                      .contains("null"))
                              ? (mySpaceProvider
                                        .profileModel
                                        .result?[0]
                                        .userName ??
                                    "")
                              : (mySpaceProvider
                                        .profileModel
                                        .result?[0]
                                        .fullName ??
                                    ""))
                        : "",
                    onClick: () async {
                      printLog("isParentLocked ====> $isParentLocked");
                      printLog("userIsKid ====1====> ${Constant.userIsKid}");
                      if (isParentLocked == true &&
                          Constant.userIsKid == true &&
                          (mySpaceProvider
                                      .profileModel
                                      .result?[0]
                                      .parentControlStatus
                                      .toString() ??
                                  "") ==
                              "1" &&
                          (mySpaceProvider
                                      .profileModel
                                      .result?[0]
                                      .parentControlPassword ??
                                  "")
                              .isNotEmpty) {
                        parentPINDialog();
                      } else {
                        if (Constant.userIsKid == false) {
                          return;
                        }
                        await _clickToChangeProfiles(
                          userIsKid: false,
                          clickFrom: '',
                        );
                      }
                      printLog("userIsKid ====2====> ${Constant.userIsKid}");
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildProfileItem(
                    profileType: "kids",
                    profileImage: "kids.png",
                    profileName: "Kids",
                    isActive: Constant.userIsKid == true,
                    onClick: () async {
                      printLog("userIsKid ====1====> ${Constant.userIsKid}");
                      if (Constant.userIsKid != null &&
                          Constant.userIsKid == true) {
                        return;
                      }
                      await _clickToChangeProfiles(
                        userIsKid: true,
                        clickFrom: '',
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileItem({
    required String profileType,
    required String profileImage,
    required String profileName,
    required bool isActive,
    required Function() onClick,
  }) {
    return InteractiveIcon(
      builder: (isHovered) {
        return GestureDetector(
          onTap: onClick,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (Dimens.isBigScreen(context))
                    ? Dimens.widthProfilesWeb
                    : Dimens.widthProfiles,
                height: (Dimens.isBigScreen(context))
                    ? Dimens.heightProfilesWeb
                    : Dimens.heightProfiles,
                padding: const EdgeInsets.all(2),
                alignment: Alignment.center,
                transform: isHovered
                    ? Matrix4.diagonal3Values(1.08, 1.08, 1.0)
                    : Matrix4.identity(),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isHovered
                        ? colorPrimary
                        : isActive
                        ? white
                        : transparent,
                    width: 2,
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: colorPrimary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: (profileType == "user")
                          ? MyUserNetworkImage(
                              imageUrl: profileImage,
                              fit: BoxFit.cover,
                              width: (Dimens.isBigScreen(context))
                                  ? Dimens.widthProfilesWeb
                                  : Dimens.widthProfiles,
                              height: (Dimens.isBigScreen(context))
                                  ? Dimens.heightProfilesWeb
                                  : Dimens.heightProfiles,
                            )
                          : MyImage(
                              imagePath: profileImage,
                              fit: BoxFit.cover,
                              width: (Dimens.isBigScreen(context))
                                  ? Dimens.widthProfilesWeb
                                  : Dimens.widthProfiles,
                              height: (Dimens.isBigScreen(context))
                                  ? Dimens.heightProfilesWeb
                                  : Dimens.heightProfiles,
                            ),
                    ),
                    if (isActive)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          transform: Matrix4.translationValues(0, 8, 0),
                          decoration: Utils.setBackground(white, 15),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            height: 12,
                            width: 12,
                            decoration: Utils.setBackground(colorAccent, 6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: (Dimens.isBigScreen(context))
                    ? Dimens.widthProfilesWeb
                    : Dimens.widthProfiles,
                padding: const EdgeInsets.all(5),
                alignment: Alignment.center,
                child: MyText(
                  color: isHovered ? colorPrimary : white,
                  multilanguage: false,
                  text: profileName,
                  fontsizeNormal: 12,
                  fontweight: FontWeight.w500,
                  fontsizeWeb: 15,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void parentPINDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: Dimens.isBigScreen(context)
                    ? (MediaQuery.of(context).size.width * 0.3)
                    : (MediaQuery.of(context).size.width),
                margin: const EdgeInsets.fromLTRB(50, 50, 50, 50),
                padding: const EdgeInsets.all(23),
                decoration: Utils.setBackground(lightBlack, 5),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  color: white,
                                  text: "parental_lock",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 16,
                                  fontsizeWeb: 18,
                                  fontweight: FontWeight.bold,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                                const SizedBox(height: 3),
                                MyText(
                                  color: white,
                                  text: "enter_pin",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 12,
                                  fontsizeWeb: 15,
                                  fontweight: FontWeight.w500,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              }
                            },
                            icon: MyImage(
                              imagePath: "ic_close.png",
                              fit: BoxFit.contain,
                              height: 17,
                              width: 17,
                              color: white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    /* PIN */
                    Consumer<MySpaceProvider>(
                      builder: (context, mySpaceProvider, child) {
                        return Pinput(
                          length: 4,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                          controller: pinPutController,
                          readOnly: mySpaceProvider.loadingPCCheck,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          onCompleted: (value) async {
                            if (value.toString().isNotEmpty) {
                              mySpaceProvider.notifyProvider();
                            }
                          },
                          onChanged: (value) async {
                            if (value.toString().isNotEmpty) {
                              mySpaceProvider.notifyProvider();
                            }
                          },
                          defaultPinTheme: PinTheme(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorPrimary,
                                width: 0.7,
                              ),
                              shape: BoxShape.rectangle,
                              color: edtShadowColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: kIsWeb
                                ? const TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w800,
                                  )
                                : GoogleFonts.inter(
                                    color: white,
                                    fontSize: 16,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w800,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Consumer<MySpaceProvider>(
                      builder: (context, mySpaceProvider, child) {
                        if (pinPutController.text.toString().isEmpty ||
                            pinPutController.text.toString().length < 4) {
                          return const SizedBox.shrink();
                        }
                        if (mySpaceProvider.loadingPCCheck) {
                          return Container(
                            alignment: Alignment.centerRight,
                            height: 50,
                            width: 50,
                            child: Utils.pageLoader(),
                          );
                        }
                        return Container(
                          alignment: Alignment.centerRight,
                          child: _buildDialogBtn(
                            title: 'submit',
                            isPositive: true,
                            isMultilang: true,
                            onClick: () async {
                              _checkPINAndChangeMode();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((value) {
      pinPutController.clear();
    });
  }

  Future<void> _checkPINAndChangeMode() async {
    if (pinPutController.text.toString().isEmpty) {
      Utils.showToast(Locales.string(context, "enter_pin"));
      return;
    }
    printLog("pinPutController =====> ${pinPutController.text}");
    mySpaceProvider.setUpdateLoading(true);
    await mySpaceProvider.pcCheckPassword(pinPutController.text.toString());
    if (!mySpaceProvider.loadingPCCheck) {
      if (mySpaceProvider.successModel.status == 200) {
        await _clickToChangeProfiles(userIsKid: false, clickFrom: 'dialog');
      } else {
        Utils.showToast(mySpaceProvider.successModel.message ?? "");
      }
    }
  }

  Widget _buildDialogBtn({
    required String title,
    required bool isPositive,
    required bool isMultilang,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      child: Container(
        constraints: const BoxConstraints(minWidth: 75),
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 10),
        alignment: Alignment.center,
        decoration: Utils.setBGWithBorder(
          isPositive ? colorPrimary : transparent,
          isPositive ? transparent : descTextColor,
          5,
          0.5,
        ),
        child: MyText(
          color: isPositive ? black : white,
          text: title,
          multilanguage: isMultilang,
          textalign: TextAlign.center,
          fontsizeNormal: 16,
          fontsizeWeb: 18,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }
  /* **************** Profiles END */

  /* Watchlist START *************** */
  Widget _buildWatchlist() {
    if (watchlistStatus != null && watchlistStatus != "1") {
      return const SizedBox.shrink();
    }
    if (mySpaceProvider.watchlistModel.result != null &&
        (mySpaceProvider.watchlistModel.result?.length ?? 0) > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Title */
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(right: 10),
                  child: MyText(
                    color: white,
                    text: "watchlist",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final watchlistProvider = Provider.of<WatchlistProvider>(
                    context,
                    listen: false,
                  );
                  watchlistProvider.setLoading(true);
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.myWatchlistPage}",
                    extra: widget.oldPage ?? "",
                  );
                  mySpaceProvider.getWatchlist(1);
                },
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  alignment: Alignment.centerRight,
                  height: 25,
                  padding: const EdgeInsets.all(6),
                  child: MyImage(
                    imagePath: "ic_viewall.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height:
                  (Dimens.isBigScreen(context)
                      ? Dimens.heightPortWeb
                      : Dimens.heightPort) +
                  20,
              child: LeftRightScrollOnHover(
                scrollController: watchlistScrollController,
                itemCount: (mySpaceProvider.watchlistModel.result?.length ?? 0),
                itemSpacing: Dimens.isBigScreen(context)
                    ? Dimens.spaceBetweenCardsWeb
                    : Dimens.spaceBetweenCards,
                itemWidth: Dimens.isBigScreen(context)
                    ? Dimens.widthPortWeb
                    : Dimens.widthPort,
                height: Dimens.isBigScreen(context)
                    ? Dimens.heightPortWeb
                    : Dimens.heightPort,
                onLeftTap: () {
                  Utils.scrollContentView(
                    context: context,
                    forward: false,
                    scrollController: watchlistScrollController,
                  );
                },
                onRightTap: () {
                  Utils.scrollContentView(
                    context: context,
                    forward: true,
                    scrollController: watchlistScrollController,
                  );
                },
                child: ListView.separated(
                  controller: watchlistScrollController,
                  clipBehavior: Clip.none,
                  itemCount: mySpaceProvider.watchlistModel.result?.length ?? 0,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  separatorBuilder: (context, position) => SizedBox(
                    width: Dimens.isBigScreen(context)
                        ? Dimens.spaceBetweenCardsWeb
                        : Dimens.spaceBetweenCards,
                  ),
                  itemBuilder: (BuildContext context, int position) {
                    final item =
                        mySpaceProvider.watchlistModel.result?[position];
                    final bool bigScreen = Dimens.isBigScreen(context);
                    final double cardW = bigScreen
                        ? Dimens.widthPortWeb
                        : Dimens.widthPort;
                    final double cardH = bigScreen
                        ? Dimens.heightPortWeb
                        : Dimens.heightPort;

                    return WebHoverCard(
                      cardW: cardW,
                      cardH: cardH,
                      borderRadius: bigScreen
                          ? Dimens.cardRadiusMedium
                          : Dimens.cardRadius,
                      imageUrl: item?.thumbnail?.toString() ?? "",
                      onTap: () async {
                        printLog("Clicked on position ==> $position");
                        await Utils.openDetails(
                          context: context,
                          videoId: item?.id ?? 0,
                          subVideoType: item?.subVideoType ?? 0,
                          videoType: item?.videoType ?? 0,
                          typeId: item?.typeId ?? 0,
                          newPage: RoutesConstant.contentDetailsPage,
                          oldPage: widget.newPage ?? "",
                          reqText: Constant.userID ?? "",
                        );
                        await mySpaceProvider.getWatchlist(1);
                      },
                      overlay: (item?.isTitle == 1)
                          ? Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(6, 20, 6, 7),
                                decoration: Utils.setGradTTBBGWithCenter(
                                  transparent,
                                  appBgColor.withValues(alpha: 0.1),
                                  appBgColor,
                                  0,
                                ),
                                child: MyText(
                                  color: white,
                                  multilanguage: false,
                                  text: item?.name?.toString() ?? "",
                                  fontsizeNormal: 13,
                                  fontweight: FontWeight.w600,
                                  fontsizeWeb: 15,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textalign: TextAlign.start,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
  /* ***************** Watchlist END */

  /* Continue Watching START *************** */
  Widget _buildContinueWatching() {
    if (continueWatchingStatus != null && continueWatchingStatus != "1") {
      return const SizedBox.shrink();
    }
    if (mySpaceProvider.continueWatchingModel.result != null &&
        (mySpaceProvider.continueWatchingModel.result?.length ?? 0) > 0) {
      return Column(
        children: [
          /* Title */
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(right: 10),
                  child: MyText(
                    color: white,
                    text: RoutesConstant.continueWatchPage,
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final viewAllProvider = Provider.of<ViewAllProvider>(
                    context,
                    listen: false,
                  );
                  viewAllProvider.setLoading(true);
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.continueWatchPage}",
                    extra: {
                      'newpage': widget.oldPage.toString(),
                      'title': RoutesConstant.continueWatchPage,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  alignment: Alignment.centerRight,
                  height: 25,
                  padding: const EdgeInsets.all(6),
                  child: MyImage(
                    imagePath: "ic_viewall.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          /* Data — extra height for hover scale overshoot */
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height:
                (Dimens.isBigScreen(context)
                    ? Dimens.heightLandWeb
                    : Dimens.heightLand) +
                28,
            child: LeftRightScrollOnHover(
              scrollController: continueWatchScrollController,
              itemCount:
                  (mySpaceProvider.continueWatchingModel.result?.length ?? 0),
              itemSpacing: Dimens.isBigScreen(context)
                  ? Dimens.spaceBetweenCardsWeb
                  : Dimens.spaceBetweenCards,
              itemWidth: Dimens.isBigScreen(context)
                  ? Dimens.widthLandWeb
                  : Dimens.widthLand,
              height: Dimens.isBigScreen(context)
                  ? Dimens.heightLandWeb
                  : Dimens.heightLand,
              onLeftTap: () {
                Utils.scrollContentView(
                  context: context,
                  forward: false,
                  scrollController: continueWatchScrollController,
                );
              },
              onRightTap: () {
                Utils.scrollContentView(
                  context: context,
                  forward: true,
                  scrollController: continueWatchScrollController,
                );
              },
              child: ListView.separated(
                clipBehavior: Clip.none,
                controller: continueWatchScrollController,
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                separatorBuilder: (context, index) => SizedBox(
                  width: Dimens.isBigScreen(context)
                      ? Dimens.spaceBetweenCardsWeb
                      : Dimens.spaceBetweenCards,
                ),
                itemCount:
                    (mySpaceProvider.continueWatchingModel.result?.length ?? 0),
                itemBuilder: (BuildContext context, int position) {
                  return _buildContinueWatchingItem(position: position);
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildContinueWatchingItem({required int position}) {
    final item = mySpaceProvider.continueWatchingModel.result?[position];
    final bool bigScreen = Dimens.isBigScreen(context);
    final double cardW = bigScreen ? Dimens.widthLandWeb : Dimens.widthLand;
    final double cardH = bigScreen ? Dimens.heightLandWeb : Dimens.heightLand;

    return WebHoverCard(
      cardW: cardW,
      cardH: cardH,
      borderRadius: Dimens.cardRadius,
      imageUrl: item?.landscape?.toString() ?? "",
      showPlayButton: false,
      onTap: () {
        printLog("Clicked on position ==> $position");
        if (!mounted) return;
        Utils.openDetails(
          context: context,
          videoId: item?.id ?? 0,
          subVideoType: item?.subVideoType ?? 0,
          videoType: item?.videoType ?? 0,
          typeId: item?.typeId ?? 0,
          newPage: RoutesConstant.contentDetailsPage,
          oldPage: widget.newPage ?? "",
          reqText: '',
        );
      },
      overlay: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: continueWatchingLayout(position: position),
          ),
        ],
      ),
    );
  }

  Widget continueWatchingLayout({required int position}) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        /* Bottom gradient — only covers bottom 45% of the card */
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: Dimens.isBigScreen(context)
                ? Dimens.heightLandWeb * 0.45
                : Dimens.heightLand * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  transparent,
                  black.withValues(alpha: 0.55),
                  black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
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
                  openPlayer(
                    "ContinueWatch",
                    position,
                    mySpaceProvider.continueWatchingModel.result,
                  );
                },
                child: Row(
                  children: [
                    MyImage(width: 20, height: 20, imagePath: "play.png"),
                    if (mySpaceProvider
                            .continueWatchingModel
                            .result?[position]
                            .isTitle !=
                        0)
                      const SizedBox(width: 10),
                    if (mySpaceProvider
                            .continueWatchingModel
                            .result?[position]
                            .isTitle ==
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
                                mySpaceProvider
                                    .continueWatchingModel
                                    .result?[position]
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
                  (mySpaceProvider
                              .continueWatchingModel
                              .result?[position]
                              .episode !=
                          null)
                      ? (mySpaceProvider
                                .continueWatchingModel
                                .result?[position]
                                .episode
                                ?.videoDuration ??
                            0)
                      : (mySpaceProvider
                                .continueWatchingModel
                                .result?[position]
                                .videoDuration ??
                            0),
                  mySpaceProvider
                          .continueWatchingModel
                          .result?[position]
                          .stopTime ??
                      0,
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
  /* ***************** Continue Watching END */

  /* If User Not Login START *************** */
  Widget _buildForNotLogin() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: MyImage(
              height: 180,
              fit: BoxFit.contain,
              imagePath: "ic_not_login.png",
            ),
          ),
          const SizedBox(height: 15),
          MyText(
            color: white,
            text: "no_login_title",
            fontsizeNormal: 23,
            fontsizeWeb: 25,
            maxline: 5,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 5),
          MyText(
            color: descTextColor,
            text: "no_login_desc",
            fontsizeNormal: 13,
            fontsizeWeb: 15,
            maxline: 5,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w400,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          /* Login Button */
          const SizedBox(height: 25),
          _buildLoginBtn(),
          /* Login Trouble Desc */
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
                child: MyText(
                  color: descTextColor,
                  text: "login_trouble",
                  fontsizeNormal: 13,
                  fontsizeWeb: 15,
                  maxline: 1,
                  multilanguage: true,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.w400,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () async {
                  // Navigator.push(context,
                  //   MaterialPageRoute(
                  //     builder: (context) => AboutPrivacyTerms(
                  //       appBarTitle: '',
                  //       loadURL: '',
                  //     ),
                  //   ),
                  // );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
                  child: MyText(
                    color: colorAccent,
                    text: "get_help",
                    fontsizeNormal: 13,
                    fontsizeWeb: 15,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w600,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(45),
      onTap: () {
        Utils.openLogin(context: context, newPage: '');
      },
      child: FittedBox(
        child: Container(
          height: 45,
          constraints: BoxConstraints(
            minWidth: Dimens.isBigScreen(context)
                ? (MediaQuery.of(context).size.width * 0.4)
                : MediaQuery.of(context).size.width,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          decoration: Utils.setGradientBGWithCenter(
            colorPrimary,
            colorPrimary.withValues(alpha: 0.6),
            colorPrimary.withValues(alpha: 0.4),
            45,
          ),
          child: MyText(
            color: white,
            text: "log_in",
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            maxline: 5,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
        ),
      ),
    );
  }
  /* **************** If User Not Login END */

  Widget _buildLine(
    double leftMargin,
    double topMargin,
    double rightMargin,
    double bottomMargin,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 0.7,
      margin: EdgeInsets.fromLTRB(
        leftMargin,
        topMargin,
        rightMargin,
        bottomMargin,
      ),
      decoration: Utils.setBackground(gray.withValues(alpha: 0.3), 0.7),
    );
  }
}
