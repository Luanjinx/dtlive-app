import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../model/devicesyncmodel.dart';
import '../pages/aboutprivacyterms.dart';
import '../pages/activetv.dart';
import '../pages/referandearn.dart';
import '../subscription/wallet.dart';
import '../pages/mydownloads.dart';
import '../pages/profile.dart';
import '../pages/profileedit.dart';
import '../provider/bottombarprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/myspaceprovider.dart';
import '../pages/mywatchlist.dart';
import '../provider/generalprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/subhistoryprovider.dart';
import '../provider/watchlistprovider.dart';
import '../pushservice/pushnotificationservice.dart';
import '../routes/routes_constant.dart';
import '../subscription/subscriptionhistory.dart';
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

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => SettingsState();
}

class SettingsState extends State<Settings> with RouteAware {
  late ProfileProvider profileProvider;
  late GeneralProvider generalProvider;
  late MySpaceProvider mySpaceProvider;
  late HomeProvider homeProvider;
  late SectionDataProvider sectionDataProvider;
  late BottombarProvider bottombarProvider;

  SharedPre sharedPref = SharedPre();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  final pinPutController = TextEditingController();

  bool? isSwitched;
  bool isParentLocked = false;
  String? userName,
      userFullname,
      userType,
      userMobileNo,
      userDeviceType,
      brandImage,
      userDeviceToken,
      webServerClientId;
  String? activeTvStatus,
      parentControlStatus,
      watchlistStatus,
      downloadStatus,
      rentFeatureStatus,
      subscriptionStatus;

  Future<void> toggleSwitch(bool value) async {
    if (isSwitched == false) {
      setState(() {
        isSwitched = true;
      });
    } else {
      setState(() {
        isSwitched = false;
      });
    }
    printLog('toggleSwitch isSwitched ==> $isSwitched');
    if (!kIsWeb) {
      if ((isSwitched ?? false)) {
        OneSignal.User.pushSubscription.optIn();
      } else {
        OneSignal.User.pushSubscription.optOut();
      }
      await sharedPref.saveBool("PUSH", isSwitched);
    }
  }

  Future<void> toggleParentLock(bool value) async {
    if (isParentLocked == false) {
      isParentLocked = true;
    } else {
      isParentLocked = false;
    }
    printLog('toggleParentLock isParentLocked ==> $isParentLocked');
    await Utils.setParentLock(isParentLocked);
    profileProvider.notifyProvider();

    if (isParentLocked == true) {
      await mySpaceProvider.getUpdatePCStatus("1");
    } else {
      await mySpaceProvider.getUpdatePCStatus("0");
    }
  }

  @override
  void didPopNext() {
    printLog("didPopNext");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    super.didPopNext();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      webServerClientId = await sharedPref.read(Constant.googleClientIdKey);
      printLog("_initGoogleSignIn webServerClientId ===> $webServerClientId");
      await googleSignIn.initialize(
        clientId: webServerClientId,
        serverClientId: webServerClientId,
      );
    } catch (e) {
      printLog("_initGoogleSignIn GoogleSignIn Error ===> $e");
    }
  }

  @override
  void initState() {
    super.initState();
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    mySpaceProvider = Provider.of<MySpaceProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initGoogleSignIn();
      await _getData();
      PushNotificationService.getAccessToken();
    });
  }

  Future<void> _getData() async {
    if (!mounted) return;
    profileProvider.getProfile(context);
    userName = await sharedPref.read("username");
    userFullname = await sharedPref.read("userfullname");
    userType = await sharedPref.read("usertype");
    userMobileNo = await sharedPref.read("usermobile");
    userDeviceType = await sharedPref.read("devicetype");
    userDeviceToken = await sharedPref.read("devicetoken");
    brandImage = await sharedPref.read(Constant.brandImageKey);
    printLog('_getData userName ========> $userName');
    printLog('_getData userFullname ====> $userFullname');
    printLog('_getData userType ========> $userType');
    printLog('_getData userMobileNo ====> $userMobileNo');
    printLog('_getData userDeviceType ==> $userDeviceType');
    printLog('_getData userDeviceToken => $userDeviceToken');

    if (!mounted) return;
    if (Constant.userID != null) {
      mySpaceProvider.getProfile(context);
    }

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    generalProvider.getPages();

    isSwitched = await sharedPref.readBool("PUSH");
    printLog('_getData isSwitched ==> $isSwitched');
    isParentLocked = await Utils.checkParentLock();
    printLog('_getData isParentLocked =======> $isParentLocked');

    /* Show/Hide by Admin Status =========== */
    activeTvStatus = await Utils.configByStatus(
      status: Constant.activeTvStatus,
    );
    printLog('_getData activeTvStatus =======> $activeTvStatus');
    parentControlStatus = await Utils.configByStatus(
      status: Constant.parentControlStatus,
    );
    printLog('_getData parentControlStatus ==> $parentControlStatus');
    watchlistStatus = await Utils.configByStatus(
      status: Constant.watchlistStatus,
    );
    printLog('_getData watchlistStatus ======> $watchlistStatus');
    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    printLog('_getData subscriptionStatus ===> $subscriptionStatus');
    rentFeatureStatus = await Utils.configByStatus(status: Constant.rentStatus);
    printLog('_getData rentFeatureStatus ====> $rentFeatureStatus');
    downloadStatus = await Utils.configByStatus(
      status: Constant.downloadStatus,
    );
    printLog('_getData downloadStatus =======> $downloadStatus');
    /* =========== Show/Hide by Admin Status */

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });

    await profileProvider.getDeviceSyncList();

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

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
  void dispose() {
    super.dispose();
    pinPutController.dispose();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      resizeToAvoidBottomInset: true,
      appBar: Utils.myAppBarWithBack(context, "setting", true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 22),
            child: Column(
              children: [
                /* Profiles */
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    (Constant.userID != null) ? 25 : 5,
                    0,
                    8,
                  ),
                  color: lightBlack,
                  margin: const EdgeInsets.only(bottom: 3),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Constant.userID != null) _buildProfiles(),
                      if (Constant.userID != null) const SizedBox(height: 12),

                      /* My Account */
                      if (Constant.userIsKid == false)
                        _buildSettingButton(
                          title: Constant.userID == null
                              ? Locales.string(context, "not_signin")
                              : ((userMobileNo ?? "").isEmpty
                                    ? (((userFullname ?? "").isEmpty ||
                                              (userFullname ?? "").contains(
                                                "null",
                                              ))
                                          ? ("${userName ?? ""} (${Locales.string(context, "myaccount")})")
                                          : ("${userFullname ?? ""} (${Locales.string(context, "myaccount")})"))
                                    : ("${userMobileNo ?? ""} (${Locales.string(context, "myaccount")})")),
                          subTitle: Constant.userID == null
                              ? "sign_in"
                              : "sign_out",
                          titleMultilang: false,
                          subTitleMultilang: true,
                          startIconColor: white,
                          startIconName: "",
                          endIconColor: colorPrimary,
                          endIconName: 'ic_right',
                          isEndIcon: true,
                          onClick: () async {
                            AdHelper.checkAndShowAds(
                              context: context,
                              buttonKey: "",
                              adType: Constant.rewardAdType,
                              alwaysShowAd: false,
                              showOnByClick: true,
                              onAdComplete: () async {
                                if (Constant.userID != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfileEdit(),
                                    ),
                                  );
                                } else {
                                  await Utils.openLogin(
                                    context: context,
                                    newPage: "",
                                  );
                                  setState(() {});
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),

                /* Watchlist */
                if (watchlistStatus != null && watchlistStatus == "1")
                  _buildSettingButton(
                    title: 'watchlist',
                    subTitle: 'view_your_watchlist',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_plus',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Constant.userID != null) {
                            final watchlistProvider =
                                Provider.of<WatchlistProvider>(
                                  context,
                                  listen: false,
                                );
                            watchlistProvider.setLoading(true);
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyWatchlist(),
                              ),
                            );
                          } else {
                            Utils.openLogin(context: context, newPage: "");
                          }
                        },
                      );
                    },
                  ),
                if (watchlistStatus != null && watchlistStatus == "1")
                  _buildLine(5.0, 5.0),

                /* Downloads */
                if (((subscriptionStatus != null &&
                            subscriptionStatus == "1") ||
                        (downloadStatus != null && downloadStatus == "1")) &&
                    Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'downloads',
                    subTitle: 'view_your_downloads',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_download',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Utils.checkLoginUser(context)) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const MyDownloads(
                                    viewFrom: RoutesConstant.settingsPage,
                                  );
                                },
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                if (((subscriptionStatus != null &&
                            subscriptionStatus == "1") ||
                        (downloadStatus != null && downloadStatus == "1")) &&
                    Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* Manage Devices */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'manage_devices',
                    subTitle: 'manage_devices_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_devices',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Utils.checkLoginUser(context)) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const Profile();
                                },
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Subscription ******************* */
                if ((subscriptionStatus != null && subscriptionStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildMenuTitle(title: "subscription", isMultilang: true),
                /* ******************* Subscription */

                /* Subscription */
                if ((subscriptionStatus != null && subscriptionStatus == "1") &&
                    Constant.userIsKid == false)
                  Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      if (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0 &&
                          (profileProvider.profileModel.result?[0].isBuy ??
                                  0) ==
                              1) {
                        return _buildSettingButton(
                          title: 'my_subscription',
                          subTitle: 'my_subscription_desc',
                          titleMultilang: true,
                          subTitleMultilang: true,
                          startIconColor: white,
                          startIconName: 'ic_subscribe',
                          endIconColor: colorPrimary,
                          endIconName: 'ic_right',
                          isEndIcon: true,
                          onClick: () {
                            AdHelper.checkAndShowAds(
                              context: context,
                              buttonKey: "",
                              adType: Constant.rewardAdType,
                              alwaysShowAd: false,
                              showOnByClick: true,
                              onAdComplete: () async {
                                if (Constant.userID != null) {
                                  Utils.openSubscription(
                                    context: context,
                                    oldPage: "",
                                  );
                                } else {
                                  Utils.openLogin(
                                    context: context,
                                    newPage: "",
                                  );
                                }
                              },
                            );
                          },
                        );
                      }
                      return _buildSettingButton(
                        title: 'subscription',
                        subTitle: 'subsciptionnotes',
                        titleMultilang: true,
                        subTitleMultilang: true,
                        startIconColor: white,
                        startIconName: 'ic_subscribe',
                        endIconColor: colorPrimary,
                        endIconName: 'ic_right',
                        isEndIcon: true,
                        onClick: () {
                          AdHelper.checkAndShowAds(
                            context: context,
                            buttonKey: "",
                            adType: Constant.rewardAdType,
                            alwaysShowAd: false,
                            showOnByClick: true,
                            onAdComplete: () async {
                              if (Constant.userID != null) {
                                Utils.openSubscription(
                                  context: context,
                                  oldPage: "",
                                );
                              } else {
                                Utils.openLogin(context: context, newPage: "");
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                if ((subscriptionStatus != null && subscriptionStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* Transactions */
                if ((subscriptionStatus != null && subscriptionStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'transactions',
                    subTitle: 'transactions_notes',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_transaction',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () async {
                      final subHistoryProvider =
                          Provider.of<SubHistoryProvider>(
                            context,
                            listen: false,
                          );
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (!mounted) return;
                          if (Utils.checkLoginUser(context)) {
                            subHistoryProvider.setLoading(true);
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionHistory(
                                  newPage: RoutesConstant.subsHistoryPage,
                                  oldPage: '',
                                  reqText: '',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                if ((subscriptionStatus != null && subscriptionStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* Purchases */
                if ((rentFeatureStatus != null && rentFeatureStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'purchases',
                    subTitle: 'view_your_purchases',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_purchase',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Utils.checkLoginUser(context)) {
                            Utils.openRentPurchase(
                              context: context,
                              oldPage: RoutesConstant.settingsPage,
                            );
                          }
                        },
                      );
                    },
                  ),
                if ((rentFeatureStatus != null && rentFeatureStatus == "1") &&
                    Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* Wallet */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'wallet',
                    subTitle: 'wallet_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_wallet',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      if (Utils.checkLoginUser(context)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Wallet(),
                          ),
                        );
                      }
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Setting ******************* */
                if (Constant.userIsKid == false)
                  _buildMenuTitle(title: "setting", isMultilang: true),
                /* ******************* Setting */

                /* Active TV */
                if (activeTvStatus != null && activeTvStatus == "1")
                  _buildSettingButton(
                    title: 'activetv',
                    subTitle: 'activetv_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_tv_active',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Utils.checkLoginUser(context)) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActiveTV(
                                  newPage: RoutesConstant.activeTVPage,
                                  oldPage: '',
                                  reqText: '',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                if (activeTvStatus != null && activeTvStatus == "1")
                  _buildLine(5.0, 5.0),

                /* Exit Kids Profile */
                if (Constant.userIsKid != false)
                  _buildSettingButton(
                    title: 'exit_kids_profile',
                    subTitle: 'exit_kids_profile_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_exit',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      AdHelper.checkAndShowAds(
                        context: context,
                        buttonKey: "",
                        adType: Constant.rewardAdType,
                        alwaysShowAd: false,
                        showOnByClick: true,
                        onAdComplete: () async {
                          if (Utils.checkLoginUser(context)) {
                            printLog("isParentLocked ====> $isParentLocked");
                            printLog(
                              "userIsKid ====1====> ${Constant.userIsKid}",
                            );
                            if (isParentLocked == true &&
                                Constant.userIsKid == true &&
                                (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .parentControlStatus
                                            .toString() ??
                                        "") ==
                                    "1" &&
                                (profileProvider
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
                              _clickToChangeProfiles(
                                userIsKid: false,
                                clickFrom: '',
                              );
                            }
                            printLog(
                              "userIsKid ====2====> ${Constant.userIsKid}",
                            );
                          }
                        },
                      );
                    },
                  ),
                if (Constant.userIsKid != false) _buildLine(5.0, 5.0),

                /* Parental Controls */
                if (parentControlStatus != null &&
                    parentControlStatus == "1" &&
                    Constant.userID != null &&
                    Constant.userIsKid == false)
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 6, 15, 6),
                    child: _buildParentControls(),
                  ),
                if (parentControlStatus != null &&
                    parentControlStatus == "1" &&
                    Constant.userID != null &&
                    Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* MaltiLanguage */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'change_language',
                    subTitle: 'change_language_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_language',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      _languageChangeDialog();
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Push Notification enable/disable */
                if (Constant.userIsKid == false)
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildSettingButton(
                            title: 'notification',
                            subTitle: 'recivepushnotification',
                            titleMultilang: true,
                            subTitleMultilang: true,
                            startIconColor: white,
                            startIconName: 'ic_notification',
                            endIconColor: transparent,
                            endIconName: '',
                            isEndIcon: false,
                            onClick: () {
                              toggleSwitch(!(isSwitched ?? false));
                            },
                          ),
                        ),
                        Switch(
                          activeThumbColor: secProgressColor,
                          activeTrackColor: colorPrimaryDark,
                          inactiveTrackColor: gray,
                          value: isSwitched ?? true,
                          onChanged: toggleSwitch,
                        ),
                      ],
                    ),
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Clear Cache */
                if (!Platform.isIOS && Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'clearcatch',
                    subTitle: 'clearlocallycatch',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_clear',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () async {
                      if (!(kIsWeb) || !(Constant.isTV)) {
                        Utils.deleteCacheDir();
                      }
                      if (!mounted) return;
                      Utils.showSnackbar(
                        context,
                        "success",
                        "cacheclearmsg",
                        true,
                      );
                    },
                  ),
                if (!Platform.isIOS && Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* SignIn / SignOut */
                // _buildSettingButton(
                //   title: Constant.userID == null
                //       ? youAreNotSignIn
                //       : (userType == "3" &&
                //               ((userFullname ?? "").isEmpty ||
                //                   (userFullname ?? "").contains("null")))
                //           ? ((userMobileNo ?? "").isEmpty
                //               ? ("$signedInAs ${userName ?? ""}")
                //               : ("$signedInAs ${userMobileNo ?? ""}"))
                //           : (((userFullname ?? "").isEmpty ||
                //                   (userFullname ?? "").contains("null"))
                //               ? ("$signedInAs ${userMobileNo ?? ""}")
                //               : ("$signedInAs ${userFullname ?? ""}")),
                //   subTitle: Constant.userID == null ? "sign_in" : "sign_out",
                //   titleMultilang: false,
                //   subTitleMultilang: true,
                //   iconColor: transparent,
                //   iconName: '',
                //   isEndIcon: false,
                //   onClick: () async {
                //     if (Constant.userID != null) {
                //       logoutConfirmDialog();
                //     } else {
                //       await Utils.openLogin(context: context, newPage: "");
                //       setState(() {});
                //     }
                //   },
                // ),
                // _buildLine(5.0, 5.0),

                /* Support ******************* */
                if (Constant.userIsKid == false)
                  _buildMenuTitle(title: "support", isMultilang: true),
                /* ******************* Support */

                /* Rate App */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'rateus',
                    subTitle: 'rateourapp',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_rateapp',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () async {
                      printLog("Clicked on rateApp");
                      await Utils.redirectToStore();
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Refer & Earn */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'refer_and_earn',
                    subTitle: 'refer_earn_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_referral',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () {
                      if (Utils.checkLoginUser(context)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReferEarn(),
                          ),
                        );
                      }
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Share App */
                if (Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'shareapp',
                    subTitle: 'sharewithfriends',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: 'ic_shareapp',
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () async {
                      await Utils.shareApp(
                        Platform.isIOS
                            ? Constant.iosAppShareUrlDesc
                            : Constant.androidAppShareUrlDesc,
                      );
                    },
                  ),
                if (Constant.userIsKid == false) _buildLine(5.0, 5.0),

                /* Pages */
                if (Constant.userIsKid == false) _buildPages(),

                /* Delete Account */
                if (Constant.userID != null && Constant.userIsKid == false)
                  _buildSettingButton(
                    title: 'delete_account',
                    subTitle: 'delete_account_desc',
                    titleMultilang: true,
                    subTitleMultilang: true,
                    startIconColor: redColor,
                    startIconName: 'ic_lock',
                    endIconColor: transparent,
                    endIconName: '',
                    isEndIcon: false,
                    onClick: () async {
                      if (Constant.userID != null) {
                        deleteConfirmDialog();
                      } else {
                        await Utils.openLogin(context: context, newPage: "");
                        setState(() {});
                      }
                    },
                  ),
                if (Constant.userID != null && Constant.userIsKid == false)
                  _buildLine(5.0, 5.0),

                /* Logout */
                if (Constant.userID != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(15, 22, 15, 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(2),
                      onTap: () async {
                        logoutConfirmDialog();
                      },
                      child: Container(
                        height: 45,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        decoration: Utils.setBackground(colorPrimary, 8),
                        child: MyText(
                          color: black,
                          text: "logout",
                          maxline: 1,
                          fontsizeNormal: 15,
                          fontsizeWeb: 17,
                          fontweight: FontWeight.w700,
                          multilanguage: true,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),

                /* App Icon */
                Container(
                  height: Dimens.appIconSettingHeight,
                  width: Dimens.appIconSettingWidth,
                  margin: const EdgeInsets.fromLTRB(15, 25, 15, 12),
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  alignment: Alignment.center,
                  decoration: Utils.setBGWithBorder(
                    transparent,
                    descTextColor.withValues(alpha: 0.3),
                    10,
                    0.5,
                  ),
                  child: MyImage(imagePath: "appicon.png", fit: BoxFit.contain),
                ),
                /* Branding Icon */
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText(
                        color: white,
                        multilanguage: true,
                        text: "powered_by",
                        fontweight: FontWeight.w500,
                        fontsizeNormal: Dimens.textSmall,
                        fontsizeWeb: Dimens.textMedium,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                        letterSpacing: 2.0,
                      ),
                      Container(
                        height: Dimens.brandIconHeight,
                        width: Dimens.brandIconWidth,
                        margin: const EdgeInsets.only(top: 8),
                        alignment: Alignment.bottomCenter,
                        child: MyNetworkImage(
                          imageUrl: brandImage ?? "",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                /* App version */
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.fromLTRB(15, 40, 15, 40),
                  child: MyText(
                    color: descTextColor.withValues(alpha: 0.7),
                    text: "App Version: ${Constant.appVersion}",
                    maxline: 1,
                    fontsizeNormal: 13,
                    fontsizeWeb: 16,
                    fontweight: FontWeight.w500,
                    multilanguage: false,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* Menu Title */
  Widget _buildMenuTitle({required String title, required bool isMultilang}) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 20, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: MyText(
              color: white,
              text: title,
              fontsizeNormal: 16,
              fontsizeWeb: 18,
              maxline: 1,
              multilanguage: isMultilang,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w700,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ),
          _buildLine(25.0, 5.0),
        ],
      ),
    );
  }

  /* Profiles START *************** */
  Widget _buildProfiles() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
      child: Consumer<ProfileProvider>(
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
                        (profileProvider
                                    .profileModel
                                    .result?[0]
                                    .parentControlStatus
                                    .toString() ??
                                "") ==
                            "1" &&
                        (profileProvider
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
                const SizedBox(width: 25),
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.heightProfiles / 2),
              shape: BoxShape.rectangle,
              border: isActive ? Border.all(color: white, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? colorPrimary.withValues(alpha: 0.8)
                      : transparent,
                  offset: const Offset(2, 2),
                  blurRadius: 22,
                ),
                BoxShadow(
                  color: isActive
                      ? colorAccent.withValues(alpha: 0.8)
                      : transparent,
                  offset: const Offset(1, 1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.heightProfiles / 2),
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
          ),
          Container(
            width: Dimens.widthProfiles,
            padding: const EdgeInsets.fromLTRB(5, 12, 5, 5),
            alignment: Alignment.center,
            child: MyText(
              color: isActive ? colorPrimary : titleTextColor,
              multilanguage: false,
              text: profileName,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              fontweight: FontWeight.w400,
              maxline: 1,
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
    await mySpaceProvider.pcCheckPassword(pinPutController.text.toString());
    if (!mySpaceProvider.loadingPCCheck) {
      if (mySpaceProvider.successModel.status == 200) {
        _clickToChangeProfiles(userIsKid: false, clickFrom: 'dialog');
      } else {
        Utils.showToast(mySpaceProvider.successModel.message ?? "");
      }
    }
  }
  /* **************** Profiles END */

  Widget _buildParentControls() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return ExpandableNotifier(
          child: Wrap(
            children: [
              ScrollOnExpand(
                scrollOnExpand: true,
                scrollOnCollapse: false,
                child: ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                    tapBodyToCollapse: true,
                    tapBodyToExpand: true,
                    iconColor: colorPrimary,
                    iconSize: 20,
                  ),
                  header: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        child: MyImage(
                          width: 20,
                          height: 20,
                          imagePath: "ic_lock.png",
                          color: white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MyText(
                        color: titleTextColor,
                        text: "parental_controls",
                        fontsizeNormal: 15,
                        fontsizeWeb: 17,
                        fontweight: FontWeight.w400,
                        maxline: 1,
                        multilanguage: true,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                      ),
                      // const SizedBox(height: 5),
                      // MyText(
                      //   color: descTextColor,
                      //   text: "parental_lock",
                      //   fontsizeNormal: 12,
                      //   fontsizeWeb: 14,
                      //   multilanguage: true,
                      //   maxline: 2,
                      //   overflow: TextOverflow.ellipsis,
                      //   fontweight: FontWeight.w500,
                      //   textalign: TextAlign.start,
                      //   fontstyle: FontStyle.normal,
                      // ),
                    ],
                  ),
                  collapsed: const SizedBox.shrink(),
                  expanded: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, right: 60),
                        child: _buildLine(5.0, 5.0),
                      ),

                      /* Set PIN */
                      if (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0 &&
                          (profileProvider
                                      .profileModel
                                      .result?[0]
                                      .parentControlPassword ??
                                  "")
                              .isEmpty &&
                          isParentLocked)
                        Column(
                          children: [
                            _buildSettingButton(
                              title: 'set_pin',
                              subTitle: 'set_pin_desc',
                              titleMultilang: true,
                              subTitleMultilang: true,
                              startIconColor: white,
                              startIconName: 'ic_lock',
                              endIconColor: transparent,
                              endIconName: '',
                              isEndIcon: false,
                              onClick: () {
                                pinPutController.clear();
                                setPINDialog();
                              },
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 0, right: 60),
                              child: _buildLine(5.0, 5.0),
                            ),
                          ],
                        ),

                      /* ON/OFF Parent Control */
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildSettingButton(
                              title: 'parental_lock',
                              subTitle: 'parental_lock_desc',
                              titleMultilang: true,
                              subTitleMultilang: true,
                              startIconColor: white,
                              startIconName: 'ic_lock',
                              endIconColor: transparent,
                              endIconName: '',
                              isEndIcon: false,
                              onClick: () {
                                toggleParentLock(!isParentLocked);
                              },
                            ),
                          ),
                          Switch(
                            activeThumbColor: secProgressColor,
                            activeTrackColor: colorPrimaryDark,
                            inactiveTrackColor: gray,
                            value: isParentLocked,
                            onChanged: toggleParentLock,
                          ),
                        ],
                      ),

                      /* Change PIN */
                      if (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0 &&
                          (profileProvider
                                      .profileModel
                                      .result?[0]
                                      .parentControlPassword ??
                                  "")
                              .isNotEmpty &&
                          isParentLocked)
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 0, right: 60),
                              child: _buildLine(5.0, 5.0),
                            ),
                            _buildSettingButton(
                              title: 'change_pin',
                              subTitle: 'change_pin_desc',
                              titleMultilang: true,
                              subTitleMultilang: true,
                              startIconColor: white,
                              startIconName: 'ic_lock',
                              endIconColor: transparent,
                              endIconName: '',
                              isEndIcon: false,
                              onClick: () {
                                pinPutController.clear();
                                changePINDialog();
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  builder: (_, collapsed, expanded) {
                    return Expandable(
                      collapsed: collapsed,
                      expanded: expanded,
                      theme: const ExpandableThemeData(crossFadePoint: 0),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPages() {
    return Consumer<GeneralProvider>(
      builder: (context, generalProvider, child) {
        if (generalProvider.loading) {
          return const SizedBox.shrink();
        } else {
          if (generalProvider.pagesModel.status == 200 &&
              generalProvider.pagesModel.result != null) {
            return AlignedGridView.count(
              shrinkWrap: true,
              crossAxisCount: 1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              itemCount: (generalProvider.pagesModel.result?.length ?? 0),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int position) {
                return Column(
                  children: [
                    _buildSettingButton(
                      title:
                          generalProvider.pagesModel.result?[position].title ??
                          '',
                      subTitle:
                          generalProvider
                              .pagesModel
                              .result?[position]
                              .pageSubtitle ??
                          '',
                      titleMultilang: false,
                      subTitleMultilang: false,
                      startIconColor: white,
                      startIconName:
                          generalProvider.pagesModel.result?[position].icon ??
                          '',
                      endIconColor: colorPrimary,
                      endIconName: 'ic_right',
                      isEndIcon: true,
                      onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPrivacyTerms(
                              appBarTitle:
                                  generalProvider
                                      .pagesModel
                                      .result?[position]
                                      .title ??
                                  '',
                              loadURL:
                                  generalProvider
                                      .pagesModel
                                      .result?[position]
                                      .url ??
                                  '',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildLine(
                      5.0,
                      (position ==
                              ((generalProvider.pagesModel.result?.length ??
                                      0) -
                                  1))
                          ? 5.0
                          : 0.0,
                    ),
                  ],
                );
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        }
      },
    );
  }

  Widget _buildSettingButton({
    required String title,
    required String subTitle,
    required bool titleMultilang,
    required bool subTitleMultilang,
    required String startIconName,
    required Color startIconColor,
    required bool isEndIcon,
    required String endIconName,
    required Color endIconColor,
    required Function() onClick,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onClick,
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(minHeight: Dimens.minHeightSettings),
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (startIconName != "")
                Container(
                  padding: const EdgeInsets.all(5),
                  child: (startIconName.contains("http"))
                      ? MyNetworkImage(
                          width: 20,
                          height: 20,
                          imageUrl: startIconName,
                          fit: BoxFit.contain,
                        )
                      : MyImage(
                          width: 20,
                          height: 20,
                          imagePath: "$startIconName.png",
                          color: startIconColor,
                        ),
                ),
              if (startIconName != "") const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      color: (title == "delete_account")
                          ? redColor
                          : titleTextColor,
                      text: title,
                      maxline: 1,
                      fontsizeNormal: 15,
                      fontsizeWeb: 17,
                      fontweight: FontWeight.w400,
                      multilanguage: titleMultilang,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                    // SizedBox(height: subTitle.isEmpty ? 0 : 5),
                    // subTitle.isEmpty
                    //     ? const SizedBox.shrink()
                    //     : MyText(
                    //         color: descTextColor,
                    //         text: subTitle,
                    //         fontsizeNormal: 12,
                    //         fontsizeWeb: 14,
                    //         multilanguage: subTitleMultilang,
                    //         maxline: 2,
                    //         overflow: TextOverflow.ellipsis,
                    //         fontweight: FontWeight.w500,
                    //         textalign: TextAlign.start,
                    //         fontstyle: FontStyle.normal,
                    //       ),
                  ],
                ),
              ),
              if (isEndIcon)
                Container(
                  padding: const EdgeInsets.all(5),
                  child: MyImage(
                    width: 10,
                    height: 10,
                    imagePath: "$endIconName.png",
                    color: endIconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLine(double topMargin, double bottomMargin) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 0.5,
      margin: EdgeInsets.only(left: 15, top: topMargin, bottom: bottomMargin),
      color: descTextColor.withValues(alpha: 0.3),
    );
  }

  /* Set New PIN for Parent Control ************ */
  void setPINDialog() {
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
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        color: titleTextColor,
                        text: "set_pin",
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
                        text: "enter_pin_desc",
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
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Pinput(
                      length: 4,
                      keyboardType: TextInputType.number,
                      readOnly: profileProvider.loadingPCCheck,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      controller: pinPutController,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      onCompleted: (value) async {
                        if (value.toString().isNotEmpty) {
                          profileProvider.notifyProvider();
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
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Container(
                      alignment: Alignment.centerRight,
                      child: _buildDialogBtn(
                        title: 'submit',
                        isPositive: true,
                        isMultilang: true,
                        onClick: () async {
                          _checkPINAndUpdate();
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

  Future<void> _checkPINAndUpdate() async {
    if (pinPutController.text.toString().isEmpty) {
      Utils.showToast(Locales.string(context, "enter_pin"));
      return;
    }
    printLog("pinPutController ======> ${pinPutController.text}");
    profileProvider.setPCLoading(true);
    await profileProvider.getUpdatePCPassword(pinPutController.text.toString());
    if (!profileProvider.loadingPCCheck) {
      if (!mounted) return;
      Utils.exitDialog(context);
      Utils.showToast(Locales.string(context, "pin_updated_success"));
      profileProvider.getProfile(context);
    }
  }
  /* ************ Set New PIN for Parent Control */

  /* Change PIN for Parent Control ************ */
  void changePINDialog() {
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
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        color: titleTextColor,
                        text: "change_pin",
                        multilanguage: true,
                        textalign: TextAlign.start,
                        fontsizeNormal: 16,
                        fontweight: FontWeight.bold,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 3),
                      MyText(
                        color: descTextColor,
                        text: "change_pin_desc",
                        multilanguage: true,
                        textalign: TextAlign.start,
                        fontsizeNormal: 12,
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
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Pinput(
                      length: 4,
                      keyboardType: TextInputType.number,
                      readOnly: profileProvider.loadingPCCheck,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      controller: pinPutController,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      onCompleted: (value) async {
                        if (value.toString().isNotEmpty) {
                          profileProvider.notifyProvider();
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
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Container(
                      alignment: Alignment.centerRight,
                      child: _buildDialogBtn(
                        title: 'submit',
                        isPositive: true,
                        isMultilang: true,
                        onClick: () async {
                          _checkPINAndChange();
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

  Future<void> _checkPINAndChange() async {
    if (pinPutController.text.toString().isEmpty) {
      Utils.showToast(Locales.string(context, "enter_pin"));
      return;
    }
    printLog("pinPutController ======> ${pinPutController.text}");
    profileProvider.setPCLoading(true);
    await profileProvider.getUpdatePCPassword(pinPutController.text.toString());
    if (!profileProvider.loadingPCCheck) {
      if (!mounted) return;
      Utils.exitDialog(context);
      Utils.showToast(Locales.string(context, "pin_updated_success"));
      profileProvider.getProfile(context);
    }
  }
  /* ************ Change PIN for Parent Control */

  void _languageChangeDialog() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, state) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: lightBlack,
                    padding: const EdgeInsets.all(23),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                color: titleTextColor,
                                text: "changelanguage",
                                multilanguage: true,
                                textalign: TextAlign.start,
                                fontsizeNormal: 16,
                                fontweight: FontWeight.bold,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(height: 3),
                              MyText(
                                color: descTextColor,
                                text: "selectyourlanguage",
                                multilanguage: true,
                                textalign: TextAlign.start,
                                fontsizeNormal: 12,
                                fontweight: FontWeight.w500,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                            ],
                          ),
                        ),

                        /* English */
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "English",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('en');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Afrikaans */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Afrikaans",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('af');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Arabic */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Arabic",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('ar');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* German */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "German",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('de');

                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Spanish */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Spanish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('es');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* French */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "French",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('fr');

                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Gujarati */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Gujarati",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('gu');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Hindi */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Hindi",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('hi');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Indonesian */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Indonesian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('id');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Dutch */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Dutch",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('nl');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Portuguese (Brazil) */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Portuguese (Brazil)",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('pt');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Albanian */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Albanian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('sq');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Turkish */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Turkish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('tr');
                                    Utils.exitDialog(context);
                                  },
                                ),

                                /* Vietnamese */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Vietnamese",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('vi');
                                    Utils.exitDialog(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLanguage({
    required String langName,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        height: 48,
        padding: const EdgeInsets.only(left: 10, right: 10),
        alignment: Alignment.center,
        decoration: Utils.setBGWithBorder(appBgColor, colorPrimary, 5, 0.5),
        child: MyText(
          color: titleTextColor,
          text: langName,
          textalign: TextAlign.center,
          fontsizeNormal: 16,
          multilanguage: false,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }

  void logoutConfirmDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              color: lightBlack,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: titleTextColor,
                          text: "confirmsognout",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsizeNormal: 16,
                          fontweight: FontWeight.bold,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        MyText(
                          color: descTextColor,
                          text: "areyousurewanrtosignout",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildDialogBtn(
                          title: 'cancel',
                          isPositive: false,
                          isMultilang: true,
                          onClick: () {
                            Utils.exitDialog(context);
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildDialogBtn(
                          title: 'sign_out',
                          isPositive: true,
                          isMultilang: true,
                          onClick: () async {
                            Utils.exitDialog(context);
                            _onLogoutDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    ).then((value) {
      if (!mounted) return;
      Utils.loadAds(context);
      if (!mounted) return;
      Future.delayed(Duration.zero, () {
        setState(() {});
      });
    });
  }

  Future<void> _onLogoutDelete() async {
    final sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    final mySpaceProvider = Provider.of<MySpaceProvider>(
      context,
      listen: false,
    );

    try {
      await Future.forEach<Result>(
        profileProvider.deviceSyncModel.result ?? [],
        (syncDeviceItem) async {
          printLog(
            "_onLogoutDelete cDeviceId ====> ${Constant.currentDeviceId}",
          );
          printLog(
            "_onLogoutDelete deviceId =====> ${syncDeviceItem.deviceId}",
          );
          if (Constant.currentDeviceId == (syncDeviceItem.deviceId ?? "")) {
            if (!mounted) return;
            await Utils.logoutFromApp(
              context,
              syncDeviceItem.id ?? 0,
              syncDeviceItem.deviceType ?? 0,
              syncDeviceItem.deviceToken ?? "",
              syncDeviceItem.deviceId ?? "",
            );
          }
        },
      );
    } on Exception catch (e) {
      printLog("_onLogoutDelete Exception =====> $e");
    }

    if (!mounted) return;
    LoadingOverlay().show(context);
    await mySpaceProvider.getUpdatePCStatus("0");
    // Firebase Signout
    try {
      await _auth.signOut();
      googleSignIn.signOut();
    } on Exception catch (e) {
      printLog("_onLogoutDelete Firebase-Gmail Exception =====> $e");
    }
    await Utils.setUserId(null);
    sectionDataProvider.clearProvider();
    profileProvider.clearProvider();
    sectionDataProvider.getSectionBanner("0", "1");
    sectionDataProvider.getSectionList("0", "1", 1);
    if (!mounted) return;
    Utils.loadAds(context);
    /* Initialize Hive */
    await Utils.initializeHiveBoxes();
    if (!mounted) return;
    _getData();
    if (!mounted) return;
    LoadingOverlay().hide();
    Utils.openLogin(context: context, newPage: "");
  }

  void deleteConfirmDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              color: lightBlack,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: titleTextColor,
                          text: "confirm_delete_account",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 16,
                          fontweight: FontWeight.bold,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        MyText(
                          color: descTextColor,
                          text: "delete_account_msg",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildDialogBtn(
                          title: 'cancel',
                          isPositive: false,
                          isMultilang: true,
                          onClick: () {
                            Utils.exitDialog(context);
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildDialogBtn(
                          title: 'delete',
                          isPositive: true,
                          isMultilang: true,
                          onClick: () async {
                            Utils.exitDialog(context);
                            _onLogoutDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    ).then((value) {
      if (!mounted) return;
      Utils.loadAds(context);
      if (!mounted) return;
      Future.delayed(Duration.zero, () {
        setState(() {});
      });
    });
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
}
