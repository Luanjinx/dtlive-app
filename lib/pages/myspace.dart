import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/continuewatchingmodel.dart';
import '../model/playermodel.dart';
import '../players/model/vdociphermodel.dart' as vdocipher;
import '../pages/mywatchlist.dart';
import '../pages/profile.dart';
import '../pages/profileedit.dart';
import '../pages/settings.dart';
import '../pages/viewall.dart';
import '../provider/bottombarprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/myspaceprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/viewallprovider.dart';
import '../provider/watchlistprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../widget/myusernetworkimg.dart';

class MySpace extends StatefulWidget {
  const MySpace({super.key});

  @override
  State<MySpace> createState() => MySpaceState();
}

class MySpaceState extends State<MySpace> with RouteAware {
  SharedPre sharedPref = SharedPre();
  late MySpaceProvider mySpaceProvider;
  late ProfileProvider profileProvider;
  late HomeProvider homeProvider;
  late SectionDataProvider sectionDataProvider;
  late BottombarProvider bottombarProvider;

  bool? isParentLocked;
  String? subscriptionStatus, continueWatchingStatus, watchlistStatus;

  final pinPutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mySpaceProvider = Provider.of<MySpaceProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
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
    mySpaceProvider.clearProvider();
    LoadingOverlay().hide();
    super.dispose();
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
          ((continueWatchingList?[position].videoType ?? 0) ==
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
          Future.delayed(Duration.zero).then((value) {
            if (!mounted) return;
            setState(() {});
          });
        }
      },
    );
  }
  /* ========= Open Player ========= */

  Future _clickToChangeProfiles({
    required bool userIsKid,
    required String clickFrom,
  }) async {
    printLog("userIsKid ===> $userIsKid");
    printLog("clickFrom ===> $clickFrom");
    if (!mounted) return;
    // Utils.showProgress(context);
    if (userIsKid == true) {
      await mySpaceProvider.changeUserMode("1");
    } else {
      await mySpaceProvider.changeUserMode("0");
    }
    // Utils.hideProgress();
    printLog("userIsKid ========> ${Constant.userIsKid}");
    if (mySpaceProvider.successModel.status == 200) {
      await Utils.setUserMode(userIsKid);
      /* Initialize Hive */
      await Utils.initializeHiveBoxes();
      homeProvider.clearProvider();
      sectionDataProvider.clearProvider();
      if (!mounted) return;
      profileProvider.notifyProvider();
      await homeProvider.setLoading(true);
      sectionDataProvider.setLoading(true);
      await bottombarProvider.setBottomNavIndex(0);
      if (!mounted) return;
      if (clickFrom == 'dialog') {
        Utils.exitDialog(context);
      }
      if (!mounted) return;
      Utils.redirectToMainPage(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
              Expanded(child: _buildPage()),
            ],
          ),
        ),
      ),
    );
  }

  /* App Icon & Settings */
  Widget _buildIconSettings() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(5),
                child: MyImage(
                  height: 20,
                  width: 62,
                  imagePath: "appicon.png",
                  fit: BoxFit.contain,
                ),
              ),
              if (Constant.userIsKid == false)
                InkWell(
                  borderRadius: BorderRadius.circular(Dimens.cardRadius),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const Settings();
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 15,
                          width: 15,
                          alignment: Alignment.centerLeft,
                          child: MyImage(
                            imagePath: "ic_setting.png",
                            fit: BoxFit.contain,
                            color: titleTextColor,
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.only(left: 5),
                          child: MyText(
                            color: titleTextColor,
                            text: "help_setting",
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
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        /* Subscribe */
        if (Constant.userID != null && Constant.userIsKid == false)
          _buildSubscribe(),
        if (Constant.userID != null) _buildLine(18.0, 18.0, 18.0, 0.0),
      ],
    );
  }

  Widget _buildPage() {
    return Consumer2<ProfileProvider, MySpaceProvider>(
      builder: (context, profileProvider, mySpaceProvider, child) {
        if (Constant.userID != null) {
          return _buildForLogin();
        } else {
          return _buildForNotLogin();
        }
      },
    );
  }

  /* If User Login */
  Widget _buildForLogin() {
    return SingleChildScrollView(
      child: Column(
        children: [
          /* Profiles */
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: _buildProfiles(),
          ),
          /* Watchlist */
          _buildWatchlist(),
          /* Continue Watching */
          const SizedBox(height: 18),
          _buildContinueWatching(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildSubscribe() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /* Current Plan */
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimens.cardRadius),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Profile();
                    },
                  ),
                );
              },
              child: _buildSubscribeText(),
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
                height: 32,
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
                  color: titleTextColor,
                  text: "subscribe_to_enjoy",
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
                    fontsizeNormal: 13,
                    fontsizeWeb: 15,
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
                fontsizeNormal: 13,
                fontsizeWeb: 15,
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
                  color: titleTextColor,
                  text: "profiles",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 15,
                  fontsizeWeb: 17,
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const ProfileEdit();
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 10,
                        width: 10,
                        alignment: Alignment.center,
                        child: MyImage(
                          imagePath: "ic_edit.png",
                          fit: BoxFit.contain,
                          color: titleTextColor,
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 5),
                        child: MyText(
                          color: colorPrimary,
                          text: "edit",
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
                      printLog(
                        "PCPassword ====> ${mySpaceProvider.profileModel.result?[0].parentControlPassword}",
                      );
                      printLog(
                        "PCStatus ====> ${mySpaceProvider.profileModel.result?[0].parentControlStatus}",
                      );
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
                        _clickToChangeProfiles(userIsKid: false, clickFrom: '');
                      }
                      printLog("userIsKid ====2====> ${Constant.userIsKid}");
                    },
                  ),
                  const SizedBox(width: 15),
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
                      _clickToChangeProfiles(userIsKid: true, clickFrom: '');
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onClick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: Dimens.widthProfiles,
            height: Dimens.heightProfiles,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: Utils.setBGWithBorder(
              transparent,
              isActive ? white : transparent,
              40,
              1,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: (profileType == "user")
                      ? MyUserNetworkImage(
                          imageUrl: profileImage,
                          fit: BoxFit.cover,
                          width: Dimens.widthProfiles,
                          height: Dimens.heightProfiles,
                        )
                      : MyImage(
                          imagePath: profileImage,
                          fit: BoxFit.cover,
                          width: Dimens.widthProfiles,
                          height: Dimens.heightProfiles,
                        ),
                ),
                if (isActive)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      transform: Matrix4.translationValues(0, 8, 0),
                      decoration: Utils.setBackground(white, 10),
                      padding: const EdgeInsets.all(1),
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: Utils.setBackground(colorAccent, 5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: Dimens.widthProfiles,
            padding: const EdgeInsets.all(5),
            alignment: Alignment.center,
            child: MyText(
              color: titleTextColor,
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
  }

  void parentPINDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      isDismissible: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              23,
              23,
              23,
              MediaQuery.of(context).viewInsets.bottom,
            ),
            color: lightBlack,
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyText(
                        color: titleTextColor,
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
                        color: descTextColor,
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
                const SizedBox(height: 20),
                /* PIN */
                Consumer<MySpaceProvider>(
                  builder: (context, mySpaceProvider, child) {
                    return Pinput(
                      length: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          border: Border.all(color: colorPrimary, width: 0.7),
                          shape: BoxShape.rectangle,
                          color: edtShadowColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: GoogleFonts.inter(
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
                const SizedBox(height: 30),
              ],
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
    await mySpaceProvider.pcCheckPassword(
      pinPutController.text.toString(),
    );
    if (!mySpaceProvider.loadingPCCheck) {
      if (mySpaceProvider.successModel.status == 200) {
        _clickToChangeProfiles(userIsKid: false, clickFrom: 'dialog');
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
          const SizedBox(height: 10),
          /* Title */
          Container(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Row(
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
                    if (!mounted) return;
                    AdHelper.checkAndShowAds(
                      context: context,
                      buttonKey: "",
                      adType: Constant.rewardAdType,
                      alwaysShowAd: false,
                      showOnByClick: true,
                      onAdComplete: () async {
                        if (Utils.checkLoginUser(context)) {
                          watchlistProvider.setLoading(true);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyWatchlist(),
                            ),
                          );
                        }
                      },
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
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: Dimens.isBigScreen(context)
                  ? Dimens.heightPortWeb
                  : Dimens.heightPort,
              child: ListView.separated(
                itemCount: mySpaceProvider.watchlistModel.result?.length ?? 0,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                separatorBuilder: (context, position) => SizedBox(
                  width: Dimens.isBigScreen(context)
                      ? Dimens.spaceBetweenCardsWeb
                      : Dimens.spaceBetweenCards,
                ),
                itemBuilder: (BuildContext context, int position) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(
                      Dimens.isBigScreen(context)
                          ? Dimens.cardRadiusMedium
                          : Dimens.cardRadius,
                    ),
                    focusColor: white,
                    onTap: () async {
                      printLog("Clicked on position ==> $position");
                      await Utils.openDetails(
                        context: context,
                        videoId:
                            mySpaceProvider
                                .watchlistModel
                                .result?[position]
                                .id ??
                            0,
                        subVideoType:
                            mySpaceProvider
                                .watchlistModel
                                .result?[position]
                                .subVideoType ??
                            0,
                        videoType:
                            mySpaceProvider
                                .watchlistModel
                                .result?[position]
                                .videoType ??
                            0,
                        typeId:
                            mySpaceProvider
                                .watchlistModel
                                .result?[position]
                                .typeId ??
                            0,
                        newPage:
                            ((mySpaceProvider
                                            .watchlistModel
                                            .result?[position]
                                            .subVideoType ??
                                        0) ==
                                    2 ||
                                (mySpaceProvider
                                            .watchlistModel
                                            .result?[position]
                                            .videoType ??
                                        0) ==
                                    2)
                            ? RoutesConstant.contentDetailsPage
                            : RoutesConstant.contentDetailsPage,
                        oldPage: "",
                        reqText: Constant.userID ?? "",
                      );
                      await mySpaceProvider.getWatchlist(1);
                    },
                    child: Container(
                      width: Dimens.isBigScreen(context)
                          ? Dimens.widthPortWeb
                          : Dimens.widthPort,
                      height: Dimens.isBigScreen(context)
                          ? Dimens.heightPortWeb
                          : Dimens.heightPort,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(2.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Dimens.isBigScreen(context)
                                  ? Dimens.cardRadiusMedium
                                  : Dimens.cardRadius,
                            ),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: MyNetworkImage(
                              imageUrl:
                                  mySpaceProvider
                                      .watchlistModel
                                      .result?[position]
                                      .thumbnail
                                      .toString() ??
                                  "",
                              fit: BoxFit.cover,
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                          if (mySpaceProvider
                                  .watchlistModel
                                  .result?[position]
                                  .isTitle ==
                              1)
                            Container(
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
                                text:
                                    mySpaceProvider
                                        .watchlistModel
                                        .result?[position]
                                        .name
                                        .toString() ??
                                    "",
                                fontsizeNormal: 13,
                                fontweight: FontWeight.w600,
                                fontsizeWeb: 15,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.start,
                                fontstyle: FontStyle.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
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
          Container(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(right: 10),
                    child: MyText(
                      color: titleTextColor,
                      text: RoutesConstant.continueWatchPage,
                      multilanguage: true,
                      textalign: TextAlign.start,
                      fontsizeNormal: 15,
                      fontsizeWeb: 17,
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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const ViewAll(
                            appBarTitle: RoutesConstant.continueWatchPage,
                            videoId: 0,
                            subVideoType: 0,
                            videoType: 0,
                            typeId: 0,
                          );
                        },
                      ),
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
          ),
          const SizedBox(height: 10),
          /* Data */
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: Dimens.heightLand,
            child: ListView.separated(
              itemCount:
                  (mySpaceProvider.continueWatchingModel.result?.length ?? 0),
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 18, right: 18),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, position) =>
                  SizedBox(width: Dimens.spaceBetweenCards),
              itemBuilder: (BuildContext context, int position) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.cardRadius),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
                    width: Dimens.widthLand,
                    height: Dimens.heightLand,
                    child: InkWell(
                      focusColor: white,
                      onTap: () {
                        printLog("Clicked on position ==> $position");
                        if (!mounted) return;
                        Utils.openDetails(
                          context: context,
                          videoId:
                              mySpaceProvider
                                  .continueWatchingModel
                                  .result?[position]
                                  .id ??
                              0,
                          subVideoType:
                              mySpaceProvider
                                  .continueWatchingModel
                                  .result?[position]
                                  .subVideoType ??
                              0,
                          videoType:
                              mySpaceProvider
                                  .continueWatchingModel
                                  .result?[position]
                                  .videoType ??
                              0,
                          typeId:
                              mySpaceProvider
                                  .continueWatchingModel
                                  .result?[position]
                                  .typeId ??
                              0,
                          newPage:
                              ((mySpaceProvider
                                              .continueWatchingModel
                                              .result?[position]
                                              .subVideoType ??
                                          0) ==
                                      2 ||
                                  (mySpaceProvider
                                              .continueWatchingModel
                                              .result?[position]
                                              .videoType ??
                                          0) ==
                                      2)
                              ? RoutesConstant.contentDetailsPage
                              : RoutesConstant.contentDetailsPage,
                          oldPage: '',
                          reqText: '',
                        );
                      },
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
                                  mySpaceProvider
                                      .continueWatchingModel
                                      .result?[position]
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
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

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
  /* **************** Continue Watching END */

  /* If User Not Login START *************** */
  Widget _buildForNotLogin() {
    return Center(
      child: SingleChildScrollView(
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
              color: titleTextColor,
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
                  onTap: () async {},
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
            minWidth: MediaQuery.of(context).size.width * 0.5,
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
