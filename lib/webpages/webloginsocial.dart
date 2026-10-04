import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../provider/generalprovider.dart';
import '../utils/loadingoverlay.dart';
import '../provider/homeprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/webfooter.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class WebLoginSocial extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebLoginSocial({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebLoginSocial> createState() => _WebLoginSocialState();
}

class _WebLoginSocialState extends State<WebLoginSocial> {
  SharedPre sharedPre = SharedPre();
  final numberController = TextEditingController();
  String? mobileNumber, email, userName, strType, strDeviceType, strDeviceToken;
  File? mProfileImg;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool initialized = false;
  String? webServerClientId;

  final ScrollController _mainScrollController = ScrollController();

  bool get _isDesktop => MediaQuery.of(context).size.width >= 800;
  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;

  double _formWidth() {
    if (_sw >= 1400) return _sw * 0.40;
    if (_sw >= 1080) return _sw * 0.45;
    if (_sw >= 800) return _sw * 0.50;
    return _sw;
  }

  Future<void> _scrollListener() async {
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
    if (_mainScrollController.offset <=
            _mainScrollController.position.minScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_scrollListener);
    _getDeviceToken();
  }

  Future<void> _getDeviceToken() async {
    webServerClientId = await sharedPre.read(Constant.googleClientIdKey);
    printLog("_getDeviceToken webServerClientId ===> $webServerClientId");
    String? token = await Utils.getFirebaseWebToken();
    strDeviceToken = token;
    strDeviceType = "3";
    printLog("_getDeviceToken strDeviceToken ===> $strDeviceToken");
    printLog("_getDeviceToken strDeviceType ====> $strDeviceType");
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 55, child: _buildLeftPanel()),
        SizedBox(width: _formWidth(), child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildRightPanel(),
          if (kIsWeb)
            WebFooter(
              newPage: widget.newPage,
              oldPage: widget.oldPage,
              reqText: '',
              onTypeClick: () {
                _mainScrollController.animateTo(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return SizedBox(
      height: _sh,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MyImage(
            imagePath: "login_bg_land.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: _sh,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  black.withValues(alpha: 0.82),
                  black.withValues(alpha: 0.58),
                  black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 48,
                  child: MyImage(fit: BoxFit.contain, imagePath: "appicon.png"),
                ),
                const Spacer(),
                MyText(
                  color: white,
                  text: "stream_live",
                  multilanguage: true,
                  fontsizeNormal: 34,
                  fontsizeWeb: 40,
                  fontweight: FontWeight.w800,
                  maxline: 1,
                  overflow: TextOverflow.clip,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                MyText(
                  color: colorPrimary,
                  text: "scale_fast",
                  multilanguage: true,
                  fontsizeNormal: 34,
                  fontsizeWeb: 40,
                  fontweight: FontWeight.w800,
                  maxline: 1,
                  overflow: TextOverflow.clip,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 14),
                MyText(
                  color: white.withValues(alpha: 0.60),
                  text: "auth_tagline_desc",
                  multilanguage: true,
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w400,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _featureChip("feature_video", Icons.video_library_outlined),
                    _featureChip("feature_livestream", Icons.live_tv_rounded),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _statItem("stat_value_24_7", "stat_uptime"),
                    _statDivider(),
                    _statItem("stat_value_hd", "stat_quality"),
                    _statDivider(),
                    _statItem("stat_value_infinity", "stat_streams"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String key, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: white.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorPrimary, size: 13),
          const SizedBox(width: 6),
          MyText(
            color: white.withValues(alpha: 0.85),
            text: key,
            multilanguage: true,
            fontsizeNormal: 11,
            fontsizeWeb: 12,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String key) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            color: colorPrimary,
            text: value,
            multilanguage: true,
            fontsizeNormal: 22,
            fontsizeWeb: 22,
            fontweight: FontWeight.w800,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 2),
          MyText(
            color: white.withValues(alpha: 0.45),
            text: key,
            multilanguage: true,
            fontsizeNormal: 10,
            fontsizeWeb: 10,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: white.withValues(alpha: 0.14),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      height: _isDesktop ? _sh : null,
      color: authPanelBgColor,
      child: SingleChildScrollView(
        controller: _isDesktop ? null : _mainScrollController,
        padding: EdgeInsets.symmetric(
          horizontal: _isDesktop ? 48 : 24,
          vertical: _isDesktop ? 0 : 32,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _isDesktop ? _sh : 0),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isDesktop) ...[
                  Center(
                    child: SizedBox(
                      width: 110,
                      height: 44,
                      child: MyImage(
                        fit: BoxFit.contain,
                        imagePath: "appicon.png",
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
                if (_isDesktop)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 24),
                      child: _buildCloseButton(),
                    ),
                  ),
                _buildPageUI(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return InteractiveIcon(
      builder: (isHovered) {
        return InkWell(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          borderRadius: BorderRadius.circular(20),
          focusColor: transparent,
          hoverColor: transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered
                  ? white.withValues(alpha: 0.12)
                  : white.withValues(alpha: 0.06),
              border: Border.all(
                color: white.withValues(alpha: isHovered ? 0.22 : 0.10),
                width: 1,
              ),
            ),
            child: const Icon(Icons.close_rounded, color: white, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildPageUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /* App name + badge — centered */
        Center(
          child: Column(
            children: [
              MyText(
                color: colorPrimary,
                text: Constant.appName,
                multilanguage: false,
                fontsizeNormal: 20,
                fontsizeWeb: 22,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorPrimary.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: MyText(
                  color: colorPrimary,
                  text: "app_tagline",
                  multilanguage: true,
                  fontsizeNormal: 9,
                  fontsizeWeb: 10,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        /* Shield separator */
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.shield_rounded, color: colorPrimary, size: 18),
            ),
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        /* Welcome headline + subtitle */
        MyText(
          color: white,
          text: "welcomeback",
          multilanguage: true,
          fontsizeNormal: 20,
          fontsizeWeb: 22,
          fontweight: FontWeight.w700,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 4),
        MyText(
          color: descTextColor,
          text: "sign_in_subtitle",
          multilanguage: true,
          fontsizeNormal: 12,
          fontsizeWeb: 13,
          fontweight: FontWeight.w400,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 24),
        /* Field label */
        MyText(
          color: descTextColor,
          text: "mobile_number_label",
          multilanguage: true,
          fontsizeNormal: 10,
          fontsizeWeb: 11,
          fontweight: FontWeight.w600,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: white.withValues(alpha: 0.10), width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: IntlPhoneField(
            disableLengthCheck: true,
            controller: numberController,
            textAlignVertical: TextAlignVertical.center,
            autovalidateMode: AutovalidateMode.disabled,
            style: kIsWeb
                ? const TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  )
                : GoogleFonts.inter(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
            showCountryFlag: false,
            showDropdownIcon: false,
            initialCountryCode: Constant.defaultCountryCode,
            dropdownTextStyle: kIsWeb
                ? const TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.inter(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
              border: InputBorder.none,
              hintStyle: kIsWeb
                  ? const TextStyle(
                      color: descTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0,
                    )
                  : GoogleFonts.inter(
                      color: descTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0,
                    ),
              hintText: Locales.string(context, "enter_mobile"),
            ),
            onChanged: (phone) {
              printLog('===> ${phone.completeNumber}');
              mobileNumber = phone.completeNumber;
              printLog('===>mobileNumber $mobileNumber');
            },
            onCountryChanged: (country) {
              printLog('===> ${country.name}');
              printLog('===> ${country.code}');
            },
          ),
        ),
        const SizedBox(height: 20),
        InteractiveIcon(
          builder: (isHovered) {
            return InkWell(
              onTap: () async {
                printLog("Click mobileNumber ==> $mobileNumber");
                if (numberController.text.toString().isEmpty) {
                  Utils.showToast(
                    Locales.string(context, "enter_mobile_toast"),
                  );
                } else {
                  printLog("mobileNumber ==> $mobileNumber");
                  if (!mounted) return;
                  Utils.openWebDialog(
                    context: context,
                    newPage: RoutesConstant.loginOTPPage,
                    oldPage: widget.oldPage ?? "",
                    reqText: mobileNumber ?? "",
                  );
                }
              },
              focusColor: transparent,
              hoverColor: transparent,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isHovered
                      ? colorPrimary.withValues(alpha: 0.88)
                      : colorPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MyText(
                  color: appBgColor,
                  text: "login",
                  multilanguage: true,
                  fontsizeNormal: 15,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: MyText(
                color: white.withValues(alpha: 0.35),
                text: "or",
                multilanguage: true,
                fontsizeNormal: 11,
                fontsizeWeb: 11,
                fontweight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InteractiveIcon(
          builder: (isHovered) {
            return InkWell(
              onTap: () {
                printLog("Clicked on : ====> loginWith Google");
                _gmailLogin();
              },
              focusColor: transparent,
              hoverColor: transparent,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isHovered ? white : white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyImage(
                      width: 18,
                      height: 18,
                      imagePath: "ic_google.png",
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    MyText(
                      color: black,
                      text: "loginwithgoogle",
                      fontsizeNormal: 14,
                      fontsizeWeb: 14,
                      multilanguage: true,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /* Google(Gmail) Login */
  Future<void> _gmailLogin() async {
    UserCredential userCredential;
    try {
      LoadingOverlay().show(context);
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      authProvider.setCustomParameters({
        'prompt': 'select_account',
      }); // force chooser
      authProvider.addScope('email');
      authProvider.addScope('profile');
      userCredential = await _auth.signInWithPopup(authProvider);

      if (userCredential.user == null) {
        LoadingOverlay().hide();
        if (mounted) Utils.showToast(Locales.string(context, "user_not_found"));
        return;
      }
      printLog(
        "_gmailLogin UserName ======> ${userCredential.user?.displayName}",
      );
      printLog("_gmailLogin UserEmail =====> ${userCredential.user?.email}");
      String firebasedid = userCredential.user?.uid ?? "";
      printLog('_gmailLogin firebasedid ===> $firebasedid');

      /* Hide overlay before showing referral dialog */
      LoadingOverlay().hide();
      if (!mounted) return;
      final referralCode = await Utils.showReferralDialog(context);
      if (!mounted) return;
      LoadingOverlay().show(context);
      checkAndNavigate(
        userCredential.user?.email ?? "",
        userCredential.user?.displayName ?? "",
        "2",
        referenceCode: referralCode,
      );
    } on FirebaseAuthException catch (e) {
      printLog('_gmailLogin Firebase Error Code ==> ${e.code.toString()}');
      printLog('_gmailLogin Firebase Error =======> ${e.message.toString()}');
      if (!mounted) return;
      LoadingOverlay().hide();
    }
  }

  Future<void> checkAndNavigate(
    String mail,
    String displayName,
    String type, {
    String? referenceCode,
  }) async {
    email = mail;
    userName = displayName;
    strType = type;
    printLog('checkAndNavigate email ==========>> $email');
    printLog('checkAndNavigate userName =======>> $userName');
    printLog('checkAndNavigate strType ========>> $strType');
    printLog('checkAndNavigate strDeviceType ==>> $strDeviceType');
    printLog('checkAndNavigate strDeviceToken =>> $strDeviceToken');
    printLog('checkAndNavigate referenceCode ==>> $referenceCode');
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    final generalProvider = Provider.of<GeneralProvider>(
      context,
      listen: false,
    );

    await generalProvider.loginWithSocial(
      email,
      userName,
      strType,
      Constant.deviceName,
      strDeviceType,
      strDeviceToken,
      null,
      referenceCode: referenceCode,
    );
    printLog('checkAndNavigate loading ==>> ${generalProvider.loading}');

    if (!generalProvider.loading) {
      if (generalProvider.loginSocialModel.status == 200) {
        printLog('Login Successfull!');
        Utils.saveUserCreds(
          userID: generalProvider.loginSocialModel.result?[0].id.toString(),
          fullName:
              generalProvider.loginSocialModel.result?[0].fullName.toString() ??
              "",
          userName:
              generalProvider.loginSocialModel.result?[0].userName.toString() ??
              "",
          userEmail:
              generalProvider.loginSocialModel.result?[0].email.toString() ??
              "",
          userMobile:
              generalProvider.loginSocialModel.result?[0].mobileNumber
                  .toString() ??
              "",
          userImage:
              generalProvider.loginSocialModel.result?[0].image.toString() ??
              "",
          userPremium:
              generalProvider.loginSocialModel.result?[0].isBuy.toString() ??
              "",
          userType:
              generalProvider.loginSocialModel.result?[0].type.toString() ?? "",
          deviceType: generalProvider.loginSocialModel.result?[0].deviceType
              .toString(),
          deviceToken: generalProvider.loginSocialModel.result?[0].deviceToken
              .toString(),
        );

        // Set UserID for Next
        Constant.userID = generalProvider.loginSocialModel.result?[0].id
            .toString();
        printLog('Constant userID ==>> ${Constant.userID}');

        await Utils.setUserMode(false);
        homeProvider.homeNotifyProvider();
        if (!mounted) return;
        await profileProvider.getProfile(context);
        await sectionDataProvider.getSectionBanner("0", "1");
        await sectionDataProvider.getSectionList("0", "1", 1);
        // Hide Progress Dialog
        LoadingOverlay().hide();
        if (!mounted) return;
        if (context.canPop()) {
          printLog("=====================REMOVE=====================");
          context.pop();
        }
        context.pushReplacementNamed(RoutesConstant.homePage);
      } else {
        // Hide Progress Dialog
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showToast(generalProvider.loginSocialModel.message ?? "");
      }
    }
  }
}
