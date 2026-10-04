import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/devicesyncmodel.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/myspaceprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/subhistoryprovider.dart';
import '../provider/watchlistprovider.dart';
import '../pushservice/pushnotificationservice.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../webwidget/interactive_icon.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../widget/myusernetworkimg.dart';
import '../web_js/js_helper.dart';

class WebSettings extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebSettings({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebSettings> createState() => WebSettingsState();
}

class WebSettingsState extends State<WebSettings> with RouteAware {
  late ProfileProvider profileProvider;
  late GeneralProvider generalProvider;
  late MySpaceProvider mySpaceProvider;
  late HomeProvider homeProvider;
  late SectionDataProvider sectionDataProvider;

  final JSHelper _jsHelper = JSHelper();
  SharedPre sharedPref = SharedPre();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  final pinPutController = TextEditingController();

  bool isParentLocked = false;
  String? userName,
      userFullname,
      userType,
      userMobileNo,
      brandImage,
      userDeviceType,
      userDeviceToken;
  String? activeTvStatus,
      parentControlStatus,
      watchlistStatus,
      downloadStatus,
      rentFeatureStatus,
      subscriptionStatus;

  Future<void> _redirectToUrl(String loadingUrl, bool openInNew) async {
    printLog("loadingUrl -----------> $loadingUrl");
    printLog("openInNew ------------> $openInNew");
    /*
      _blank => open new Tab
      _self => open in current Tab
    */
    String dataFromJS;
    if (openInNew) {
      dataFromJS = await _jsHelper.callOpenTab(loadingUrl, '_blank');
    } else {
      dataFromJS = await _jsHelper.callOpenTab(loadingUrl, '_self');
    }
    printLog("dataFromJS -----------> $dataFromJS");
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
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
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
      await googleSignIn.initialize();
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

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    generalProvider.getPages();

    isParentLocked = await Utils.checkParentLock();
    printLog('_getData isParentLocked =======> $isParentLocked');

    if (!mounted) return;
    await generalProvider.getGeneralsetting(context);
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
    downloadStatus = await Utils.configByStatus(
      status: Constant.downloadStatus,
    );
    printLog('_getData downloadStatus =======> $downloadStatus');
    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    printLog('_getData subscriptionStatus ===> $subscriptionStatus');
    rentFeatureStatus = await Utils.configByStatus(status: Constant.rentStatus);
    printLog('_getData rentFeatureStatus ====> $rentFeatureStatus');
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
  void dispose() {
    routeObserver.unsubscribe(this);
    pinPutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
      newChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 40 : 25,
              (Dimens.homeTabHeight + 20),
              Dimens.isBigScreen(context) ? 40 : 25,
              0,
            ),
            child: MyText(
              text: 'setting',
              multilanguage: true,
              color: colorPrimary,
              fontsizeNormal: 20,
              fontsizeWeb: 25,
              maxline: 1,
              fontweight: FontWeight.w600,
              fontstyle: FontStyle.normal,
              textalign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 30),
          /* Profiles */
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 50 : 25,
              (Constant.userID != null) ? 25 : 5,
              Dimens.isBigScreen(context) ? 50 : 25,
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
                                        (userFullname ?? "").contains("null"))
                                    ? ("${userName ?? ""} (${Locales.string(context, "myaccount")})")
                                    : ("${userFullname ?? ""} (${Locales.string(context, "myaccount")})"))
                              : ("${userMobileNo ?? ""} (${Locales.string(context, "myaccount")})")),
                    subTitle: Constant.userID == null ? "sign_in" : "sign_out",
                    titleMultilang: false,
                    subTitleMultilang: true,
                    startIconColor: white,
                    startIconName: "",
                    endIconColor: colorPrimary,
                    endIconName: 'ic_right',
                    isEndIcon: true,
                    onClick: () async {
                      if (Constant.userID != null) {
                        context.go(
                          "/${RoutesConstant.editProfilePage}",
                          extra: RoutesConstant.settingsPage,
                        );
                      } else {
                        await Utils.openLogin(context: context, newPage: "");
                        setState(() {});
                      }
                    },
                  ),
              ],
            ),
          ),
          _buildPageUI(),
        ],
      ),
    );
  }

  Widget _buildPageUI() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 50 : 25,
        0,
        Dimens.isBigScreen(context) ? 50 : 25,
        25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              onClick: () async {
                if (Constant.userID != null) {
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
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
              },
            ),
          if (watchlistStatus != null && watchlistStatus == "1")
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
                if (Constant.userID != null) {
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.myProfilePage}",
                    extra: widget.newPage ?? "",
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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
                    (profileProvider.profileModel.result?.length ?? 0) > 0 &&
                    (profileProvider.profileModel.result?[0].isBuy ?? 0) == 1) {
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
                    onClick: () async {
                      if (Constant.userID != null) {
                        await Utils.openSubscription(
                          context: context,
                          oldPage: "",
                        );
                      } else {
                        Utils.openLogin(context: context, newPage: "");
                      }
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
                  onClick: () async {
                    if (Constant.userID != null) {
                      await Utils.openSubscription(
                        context: context,
                        oldPage: "",
                      );
                    } else {
                      Utils.openLogin(context: context, newPage: "");
                    }
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
                final subHistoryProvider = Provider.of<SubHistoryProvider>(
                  context,
                  listen: false,
                );
                if (!mounted) return;
                if (Constant.userID != null) {
                  subHistoryProvider.setLoading(true);
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.subsHistoryPage}",
                    extra: widget.newPage,
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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
                if (Constant.userID != null) {
                  context.go(
                    "/${RoutesConstant.rentPurchasePage}",
                    extra: widget.newPage,
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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
                if (Constant.userID != null) {
                  context.go(
                    "/${RoutesConstant.walletPage}",
                    extra: widget.newPage,
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
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
                if (Constant.userID != null) {
                  if (!mounted) return;
                  Utils.openWebDialog(
                    context: context,
                    newPage: RoutesConstant.activeTVPage,
                    oldPage: widget.oldPage ?? "",
                    reqText: "",
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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
                if (Constant.userID != null) {
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
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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

          /* Support ******************* */
          if (Constant.userIsKid == false)
            _buildMenuTitle(title: "support", isMultilang: true),
          /* ******************* Support */

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
                if (Constant.userID != null) {
                  context.go(
                    "/${RoutesConstant.referEarnPage}",
                    extra: widget.newPage,
                  );
                } else {
                  Utils.openLogin(context: context, newPage: "");
                }
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
            Align(
              alignment: Alignment.center,
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.fromLTRB(15, 30, 15, 10),
                child: FittedBox(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(2),
                    onTap: () async {
                      _buildLogoutDialog();
                    },
                    child: Container(
                      height: Dimens.isBigScreen(context) ? 45 : 55,
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      constraints: BoxConstraints(
                        minWidth: Dimens.isBigScreen(context)
                            ? (MediaQuery.of(context).size.width * 0.33)
                            : (MediaQuery.of(context).size.width * 0.5),
                      ),
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
              ),
            ),

          /* App Icon */
          Align(
            alignment: Alignment.center,
            child: Container(
              height: Dimens.isBigScreen(context)
                  ? Dimens.appIconSettingHeightWeb
                  : Dimens.appIconSettingHeight,
              width: Dimens.isBigScreen(context)
                  ? Dimens.appIconSettingWidthWeb
                  : Dimens.appIconSettingWidth,
              margin: const EdgeInsets.fromLTRB(15, 45, 15, 12),
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
          ),
          /* Branding Icon */
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
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
                    height: Dimens.isBigScreen(context)
                        ? Dimens.brandIconHeightWeb
                        : Dimens.brandIconHeight,
                    width: Dimens.isBigScreen(context)
                        ? Dimens.brandIconWidthWeb
                        : Dimens.brandIconWidth,
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
          ),
        ],
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
      borderRadius: BorderRadius.circular(
        (Dimens.isBigScreen(context)
                ? Dimens.heightProfilesWeb
                : Dimens.heightProfiles) /
            2,
      ),
      onTap: onClick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: Dimens.isBigScreen(context)
                ? Dimens.widthProfilesWeb
                : Dimens.widthProfiles,
            height: Dimens.isBigScreen(context)
                ? Dimens.heightProfilesWeb
                : Dimens.heightProfiles,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                (Dimens.isBigScreen(context)
                        ? Dimens.heightProfilesWeb
                        : Dimens.heightProfiles) /
                    2,
              ),
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
              borderRadius: BorderRadius.circular(
                (Dimens.isBigScreen(context)
                        ? Dimens.heightProfilesWeb
                        : Dimens.heightProfiles) /
                    2,
              ),
              child: (profileType == "user")
                  ? MyUserNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      width: Dimens.isBigScreen(context)
                          ? Dimens.widthProfilesWeb
                          : Dimens.widthProfiles,
                      height: Dimens.isBigScreen(context)
                          ? Dimens.heightProfilesWeb
                          : Dimens.heightProfiles,
                    )
                  : MyImage(
                      imagePath: profileImage,
                      fit: BoxFit.cover,
                      width: Dimens.isBigScreen(context)
                          ? Dimens.widthProfilesWeb
                          : Dimens.widthProfiles,
                      height: Dimens.isBigScreen(context)
                          ? Dimens.heightProfilesWeb
                          : Dimens.heightProfiles,
                    ),
            ),
          ),
          Container(
            width: Dimens.isBigScreen(context)
                ? Dimens.widthProfilesWeb
                : Dimens.widthProfiles,
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
                        _redirectToUrl(
                          generalProvider.pagesModel.result?[position].url ??
                              "",
                          false,
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
    return InteractiveIcon(
      builder: (isHovered) {
        return InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            decoration: BoxDecoration(
              color: isHovered ? white.withValues(alpha: 0.05) : transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                minHeight: Dimens.isBigScreen(context)
                    ? Dimens.minHeightSettingsWeb
                    : Dimens.minHeightSettings,
              ),
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
      },
    );
  }

  Widget _buildLine(double topMargin, double bottomMargin) {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(
        left: 10,
        right: 10,
        top: topMargin,
        bottom: bottomMargin,
      ),
      color: descTextColor.withValues(alpha: 0.3),
    );
  }

  /* Set New PIN for Parent Control ************ */
  void setPINDialog() {
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
                              color: defaultIconColor,
                            ),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
      if (context.canPop()) {
        context.pop();
      }
      Utils.showToast(profileProvider.successModel.message ?? "");
    }
  }
  /* ************ Set New PIN for Parent Control */

  /* Change PIN for Parent Control ************ */
  void changePINDialog() {
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
                                  color: titleTextColor,
                                  text: "change_pin",
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
                                  text: "change_pin_desc",
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
                              color: defaultIconColor,
                            ),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
      if (context.canPop()) {
        context.pop();
      }
      Utils.showToast(profileProvider.successModel.message ?? "");
      profileProvider.getProfile(context);
    }
  }
  /* ************ Change PIN for Parent Control */

  void _languageChangeDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              width: Dimens.isBigScreen(context)
                  ? (MediaQuery.of(context).size.width * 0.35)
                  : (MediaQuery.of(context).size.width),
              margin: const EdgeInsets.fromLTRB(50, 50, 50, 50),
              padding: const EdgeInsets.all(23),
              decoration: Utils.setBackground(lightBlack, 5),
              child: StatefulBuilder(
                builder: (BuildContext context, state) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                                    color: titleTextColor,
                                    text: "changelanguage",
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
                                    text: "selectyourlanguage",
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
                                color: defaultIconColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /* English */
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "English",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('en');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Afrikaans */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Afrikaans",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('af');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Arabic */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Arabic",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('ar');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* German */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "German",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('de');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Spanish */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Spanish",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('es');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* French */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "French",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('fr');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Gujarati */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Gujarati",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('gu');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Hindi */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Hindi",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('hi');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Indonesian */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Indonesian",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('id');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Dutch */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Dutch",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('nl');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Portuguese (Brazil) */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Portuguese (Brazil)",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('pt');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Albanian */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Albanian",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('sq');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Turkish */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Turkish",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('tr');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),

                              /* Vietnamese */
                              const SizedBox(height: 20),
                              _buildLanguage(
                                langName: "Vietnamese",
                                onClick: () {
                                  state(() {});
                                  LocaleNotifier.of(context)?.change('vi');
                                  if (context.canPop()) {
                                    context.pop();
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguage({
    required String langName,
    required Function() onClick,
  }) {
    return InteractiveIcon(
      builder: (isHovered) {
        return InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isHovered
                  ? colorPrimary.withValues(alpha: 0.12)
                  : appBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovered
                    ? colorPrimary
                    : colorPrimary.withValues(alpha: 0.5),
                width: isHovered ? 1.5 : 0.5,
              ),
            ),
            child: MyText(
              color: white,
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
      },
    );
  }

  Future<void> _buildLogoutDialog() async {
    return showDialog<void>(
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            textalign: TextAlign.center,
                            fontsizeNormal: 16,
                            fontsizeWeb: 16,
                            fontweight: FontWeight.w600,
                            maxline: 2,
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal,
                          ),
                          const SizedBox(height: 8),
                          MyText(
                            color: descTextColor,
                            text: "areyousurewanrtosignout",
                            multilanguage: true,
                            textalign: TextAlign.center,
                            fontsizeNormal: 13,
                            fontsizeWeb: 14,
                            fontweight: FontWeight.w500,
                            maxline: 2,
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
                              await _onLogoutDelete();
                              _getData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((value) {
      if (!mounted) return;
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

    sectionDataProvider.clearProvider();
    profileProvider.clearProvider();
    await mySpaceProvider.getUpdatePCStatus("0");
    // Firebase Signout
    try {
      await _auth.signOut();
      googleSignIn.signOut();
    } on Exception catch (e) {
      printLog("_onLogoutDelete Firebase-Gmail Exception =====> $e");
    }
    await Utils.setUserId(null);
    sectionDataProvider.getSectionBanner("0", "1");
    sectionDataProvider.getSectionList("0", "1", 1);
    if (!mounted) return;
    _getData();
    Utils.openLogin(context: context, newPage: widget.newPage ?? "");
  }

  Future<void> deleteConfirmDialog() async {
    return showDialog<void>(
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
                            fontsizeWeb: 16,
                            fontweight: FontWeight.w600,
                            maxline: 2,
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal,
                          ),
                          const SizedBox(height: 3),
                          MyText(
                            color: descTextColor,
                            text: "delete_account_msg",
                            multilanguage: true,
                            textalign: TextAlign.center,
                            fontsizeNormal: 13,
                            fontsizeWeb: 14,
                            fontweight: FontWeight.w500,
                            maxline: 2,
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
                              await _onLogoutDelete();
                              _getData();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((value) {
      if (!mounted) return;
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
