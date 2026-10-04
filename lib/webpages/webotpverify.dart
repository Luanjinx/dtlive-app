import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../web_js/js_helper.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/webfooter.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

import '../routes/routes_constant.dart';

class WebOTPVerify extends StatefulWidget {
  final String? mobileNumber, newPage, oldPage;
  final dynamic reqText;
  const WebOTPVerify(
    this.mobileNumber, {
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebOTPVerify> createState() => _WebOTPVerifyState();
}

class _WebOTPVerifyState extends State<WebOTPVerify> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPre sharePref = SharedPre();
  late GeneralProvider generalProvider;
  final numberController = TextEditingController();
  final pinPutController = TextEditingController();
  late final FocusNode pinPutFocusNode;
  ScrollController scollController = ScrollController();
  String? verificationId, finalOTP, strDeviceType = "3", strDeviceToken;
  int? forceResendingToken;
  bool codeResended = false;
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

  double _pinCellSize(int count, double gap) {
    final double available = _formWidth() - 64 - (gap * (count - 1));
    return (available / count).clamp(44.0, 68.0);
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
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    pinPutFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeSend(false);
    });
    _getDeviceToken();
  }

  Future<void> _getDeviceToken() async {
    String? token = await Utils.getFirebaseWebToken();
    strDeviceToken = token;
    strDeviceType = "3";
    printLog("_getDeviceToken strDeviceToken ===> $strDeviceToken");
    printLog("_getDeviceToken strDeviceType ====> $strDeviceType");
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    numberController.dispose();
    pinPutFocusNode.dispose();
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
            Utils.exitDialog(context);
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
    final double cell = _pinCellSize(6, 8);
    return Consumer<GeneralProvider>(
      builder: (context, gp, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /* App name + badge */
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
                  child: Container(
                    height: 1,
                    color: white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.shield_rounded,
                    color: colorPrimary,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MyText(
              color: white,
              text: "verifyphonenumber",
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
              text: "code_sent_desc",
              fontsizeNormal: 12,
              fontsizeWeb: 13,
              fontweight: FontWeight.w400,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              multilanguage: true,
              fontstyle: FontStyle.normal,
            ),
            if ((widget.mobileNumber ?? "").isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorPrimary.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: MyText(
                  color: colorPrimary,
                  text: widget.mobileNumber ?? "",
                  fontsizeNormal: 13,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  multilanguage: false,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
            const SizedBox(height: 24),
            MyText(
              color: descTextColor,
              text: "otp_number_label",
              multilanguage: true,
              fontsizeNormal: 10,
              fontsizeWeb: 11,
              fontweight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
            const SizedBox(height: 10),
            if (gp.loadingOTP)
              SizedBox(
                height: cell,
                child: Center(child: Utils.pageLoader()),
              )
            else
              Pinput(
                length: 6,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                controller: pinPutController,
                focusNode: pinPutFocusNode,
                mainAxisAlignment: MainAxisAlignment.center,
                separatorBuilder: (i) => const SizedBox(width: 8),
                defaultPinTheme: PinTheme(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    color: white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                  textStyle: TextStyle(
                    color: white,
                    fontSize: cell * 0.36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    color: colorPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorPrimary, width: 1.5),
                  ),
                  textStyle: TextStyle(
                    color: white,
                    fontSize: cell * 0.36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    color: colorPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorPrimary.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  textStyle: TextStyle(
                    color: white,
                    fontSize: cell * 0.36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            if (!gp.loadingOTP)
              InteractiveIcon(
                builder: (isHovered) {
                  return InkWell(
                    onTap: () async {
                      if (pinPutController.text.isEmpty) {
                        Utils.showToast(
                          Locales.string(context, "enter_otp_toast"),
                        );
                      } else {
                        _checkOTPAndLogin();
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
                        text: "confirm",
                        fontsizeNormal: 15,
                        fontsizeWeb: 15,
                        multilanguage: true,
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
            if (!gp.loadingOTP) ...[
              const SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () {
                    if (!codeResended) codeSend(true);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: codeResended
                              ? descTextColor
                              : white.withValues(alpha: 0.60),
                        ),
                        const SizedBox(width: 6),
                        MyText(
                          color: codeResended
                              ? descTextColor
                              : white.withValues(alpha: 0.60),
                          text: "resend",
                          multilanguage: true,
                          fontsizeNormal: 13,
                          fontsizeWeb: 13,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> codeSend(bool isResend) async {
    codeResended = isResend;
    await generalProvider.setLoadingOTP(true);
    if (!mounted) return;
    await phoneSignIn(
      phoneNumber: widget.mobileNumber.toString(),
      isResend: isResend,
    );
  }

  Future<void> phoneSignIn({
    required String phoneNumber,
    required bool isResend,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: _onVerificationCompleted,
      verificationFailed: _onVerificationFailed,
      codeSent: _onCodeSent,
      codeAutoRetrievalTimeout: _onCodeTimeout,
    );
  }

  Future<void> _onVerificationCompleted(
    PhoneAuthCredential authCredential,
  ) async {
    printLog("verification completed ${authCredential.smsCode}");
    await generalProvider.setLoadingOTP(false);
    if (!mounted) return;
    setState(() {
      finalOTP = authCredential.smsCode ?? "";
      pinPutController.text = authCredential.smsCode ?? "";
      printLog("finalOTP =====> $finalOTP");
    });
  }

  Future<void> _onVerificationFailed(FirebaseAuthException exception) async {
    if (exception.code == 'invalid-phone-number') {
      printLog("The phone number entered is invalid!");
      await generalProvider.setLoadingOTP(false);
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "invalid_phone_number"));
    }
  }

  Future<void> _onCodeSent(
    String verificationId,
    int? forceResendingToken,
  ) async {
    this.verificationId = verificationId;
    this.forceResendingToken = forceResendingToken;
    await generalProvider.setLoadingOTP(false);
    if (!mounted) return;
    printLog("resendingToken =======> ${forceResendingToken.toString()}");
    printLog("code sent");
  }

  Future<Null> _onCodeTimeout(String timeout) async {
    await generalProvider.setLoadingOTP(false);
    if (!mounted) return;
    codeResended = false;
    return null;
  }

  Future<void> _checkOTPAndLogin() async {
    await generalProvider.setLoadingOTP(false);
    if (!mounted) return;
    bool error = false;
    UserCredential? userCredential;

    printLog("_checkOTPAndLogin verificationId =====> $verificationId");
    printLog("_checkOTPAndLogin smsCode =====> ${pinPutController.text}");
    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential? phoneAuthCredential = PhoneAuthProvider.credential(
      verificationId: verificationId ?? "",
      smsCode: pinPutController.text.toString(),
    );

    if (!mounted) return;
    LoadingOverlay().show(context);
    printLog(
      "phoneAuthCredential.smsCode        =====> ${phoneAuthCredential.smsCode}",
    );
    printLog(
      "phoneAuthCredential.verificationId =====> ${phoneAuthCredential.verificationId}",
    );
    try {
      userCredential = await _auth.signInWithCredential(phoneAuthCredential);
      printLog(
        "_checkOTPAndLogin userCredential =====> ${userCredential.user?.phoneNumber ?? ""}",
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      LoadingOverlay().hide();
      printLog("_checkOTPAndLogin error Code =====> ${e.code}");
      if (e.code == 'invalid-verification-code' ||
          e.code == 'invalid-verification-id') {
        if (!mounted) return;
        Utils.showToast(Locales.string(context, "enter_valid_otp"));
        pinPutFocusNode.requestFocus();
        return;
      } else if (e.code == 'session-expired') {
        if (!mounted) return;
        Utils.showToast(
          "Your OTP login session is expired, continue with other logins.",
        );
        return;
      } else {
        error = true;
      }
    }
    printLog(
      "Firebase Verification Completed & phoneNumber => ${userCredential?.user?.phoneNumber} and isError => $error",
    );
    if (!error && userCredential != null) {
      LoadingOverlay().hide();
      if (!mounted) return;
      final referralCode = await Utils.showReferralDialog(context);
      if (!mounted) return;
      LoadingOverlay().show(context);
      _login(widget.mobileNumber.toString(), referenceCode: referralCode);
    } else {
      if (!mounted) return;
      LoadingOverlay().hide();
      Utils.showToast(Locales.string(context, "otp_login_fail"));
    }
  }

  Future<void> _login(String mobile, {String? referenceCode}) async {
    printLog("_login mobile ==========> $mobile");
    printLog('_login strDeviceType ==>> $strDeviceType');
    printLog('_login strDeviceToken =>> $strDeviceToken');
    printLog('_login referenceCode ==>> $referenceCode');
    JSHelper().hideRecaptcha();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );

    await generalProvider.loginWithOTP(
      mobile,
      Constant.deviceName,
      strDeviceType,
      strDeviceToken,
      referenceCode: referenceCode,
    );

    if (!generalProvider.loading) {
      if (generalProvider.loginOTPModel.status == 200) {
        printLog(
          'loginOTPModel ==>> ${generalProvider.loginOTPModel.toString()}',
        );
        printLog('Login Successfull!');
        Utils.saveUserCreds(
          userID: generalProvider.loginOTPModel.result?[0].id.toString(),
          fullName:
              generalProvider.loginOTPModel.result?[0].fullName.toString() ??
              "",
          userName:
              generalProvider.loginOTPModel.result?[0].userName.toString() ??
              "",
          userEmail:
              generalProvider.loginOTPModel.result?[0].email.toString() ?? "",
          userMobile:
              generalProvider.loginOTPModel.result?[0].mobileNumber
                  .toString() ??
              "",
          userImage:
              generalProvider.loginOTPModel.result?[0].image.toString() ?? "",
          userPremium:
              generalProvider.loginOTPModel.result?[0].isBuy.toString() ?? "",
          userType:
              generalProvider.loginOTPModel.result?[0].type.toString() ?? "",
          deviceType: generalProvider.loginOTPModel.result?[0].deviceType
              .toString(),
          deviceToken: generalProvider.loginOTPModel.result?[0].deviceToken
              .toString(),
        );

        // Set UserID for Next
        Constant.userID = generalProvider.loginOTPModel.result?[0].id
            .toString();
        printLog('Constant userID ==>> ${Constant.userID}');

        await Utils.setUserMode(false);
        homeProvider.homeNotifyProvider();
        if (!mounted) return;
        await profileProvider.getProfile(context);
        await sectionDataProvider.getSectionBanner("0", "1");
        await sectionDataProvider.getSectionList("0", "1", 1);
        // Hide Progress Dialog
        if (!mounted) return;
        LoadingOverlay().hide();
        if (!mounted) return;
        Utils.exitDialog(context);
        Utils.exitDialog(context);
        context.pushReplacementNamed(RoutesConstant.homePage);
      } else {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showToast(generalProvider.loginOTPModel.message ?? "");
      }
    }
  }
}
