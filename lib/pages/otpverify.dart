import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../provider/bottombarprovider.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';

class OTPVerify extends StatefulWidget {
  final String mobileNumber;
  const OTPVerify(this.mobileNumber, {super.key});

  @override
  State<OTPVerify> createState() => OTPVerifyState();
}

class OTPVerifyState extends State<OTPVerify> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPre sharePref = SharedPre();
  late GeneralProvider generalProvider;
  final numberController = TextEditingController();
  final pinPutController = TextEditingController();
  late final FocusNode pinPutFocusNode;
  ScrollController scollController = ScrollController();
  String? verificationId, strDeviceType, strDeviceToken;
  int? forceResendingToken;
  bool codeResended = false;

  @override
  void initState() {
    super.initState();
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    pinPutFocusNode = FocusNode();
    _getDeviceToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeSend(false);
    });
  }

  Future<void> _getDeviceToken() async {
    try {
      if (Platform.isAndroid) {
        strDeviceType = "1";
      } else {
        strDeviceType = "2";
      }
      strDeviceToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      printLog("_getDeviceToken Exception ===> $e");
    }
    printLog("===>strDeviceToken $strDeviceToken");
    printLog("===>strDeviceType $strDeviceType");
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    numberController.dispose();
    pinPutFocusNode.dispose();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          margin: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Utils.exitPage(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: MyImage(
                        fit: BoxFit.fill,
                        imagePath: "backwith_bg.png",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyText(
                  color: titleTextColor,
                  text: "verifyphonenumber",
                  fontsizeNormal: 22,
                  multilanguage: true,
                  fontweight: FontWeight.bold,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 8),
                MyText(
                  color: descTextColor,
                  text: "code_sent_desc",
                  fontsizeNormal: 15,
                  fontweight: FontWeight.w500,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  multilanguage: true,
                  fontstyle: FontStyle.normal,
                ),
                MyText(
                  color: descTextColor,
                  text: widget.mobileNumber,
                  fontsizeNormal: 15,
                  fontweight: FontWeight.w500,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  multilanguage: false,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 40),

                /* Enter Received OTP */
                if (generalProvider.loadingOTP)
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(3),
                    child: Utils.pageLoader(),
                  )
                else
                  Pinput(
                    length: 6,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    controller: pinPutController,
                    focusNode: pinPutFocusNode,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: titleTextColor,
                        fontSize: 16,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),

                /* Confirm Button */
                if (!generalProvider.loadingOTP)
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      printLog(
                        "Clicked sms Code =====> ${pinPutController.text}",
                      );
                      if (pinPutController.text.toString().isEmpty) {
                        Utils.showSnackbar(
                          context,
                          "info",
                          "enterreceivedotp",
                          true,
                        );
                      } else {
                        if (verificationId == null || verificationId == "") {
                          Utils.showSnackbar(
                            context,
                            "info",
                            "otp_not_working",
                            true,
                          );
                          return;
                        }
                        LoadingOverlay().show(context);
                        _checkOTPAndLogin();
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 52,
                      decoration: Utils.setGradLTRBGWithBorder(
                        colorPrimary,
                        colorPrimaryDark,
                        transparent,
                        30,
                        0,
                      ),
                      alignment: Alignment.center,
                      child: MyText(
                        color: titleTextColor,
                        text: "confirm",
                        fontsizeNormal: 17,
                        multilanguage: true,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                if (!generalProvider.loadingOTP) const SizedBox(height: 40),

                /* Resend */
                if (!generalProvider.loadingOTP)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (!codeResended) {
                        codeSend(true);
                      }
                    },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 70),
                      padding: const EdgeInsets.all(5),
                      child: MyText(
                        color: titleTextColor,
                        text: "resend",
                        multilanguage: true,
                        fontsizeNormal: 16,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> codeSend(bool isResend) async {
    printLog("codeSend mobileNumber ==1==> ${widget.mobileNumber.toString()}");
    codeResended = isResend;
    await generalProvider.setLoadingOTP(true);
    if (!mounted) return;
    await phoneSignIn(phoneNumber: widget.mobileNumber.toString());
  }

  Future<void> phoneSignIn({required String phoneNumber}) async {
    await _auth.verifyPhoneNumber(
      timeout: const Duration(seconds: 60),
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: _onVerificationCompleted,
      verificationFailed: _onVerificationFailed,
      codeSent: _onCodeSent,
      codeAutoRetrievalTimeout: _onCodeTimeout,
    );
  }

  Future<void> _onVerificationCompleted(
    PhoneAuthCredential authCredential,
  ) async {
    printLog("verification completed ======> ${authCredential.smsCode}");
    await generalProvider.setLoadingOTP(false);
    if (!mounted) return;
    setState(() {
      pinPutController.text = authCredential.smsCode ?? "";
    });
  }

  Future<void> _onVerificationFailed(FirebaseAuthException exception) async {
    printLog("_onVerificationFailed exception ======> ${exception.code}");
    if (exception.code == 'invalid-phone-number') {
      printLog("The phone number entered is invalid!");
      await generalProvider.setLoadingOTP(false);
      if (!mounted) return;
      Utils.showSnackbar(context, "fail", "invalidphonenumber", true);
    }
  }

  Future<void> _onCodeSent(
    String verificationId,
    int? forceResendingToken,
  ) async {
    this.verificationId = verificationId;
    this.forceResendingToken = forceResendingToken;
    await generalProvider.setLoadingOTP(false);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    printLog("verificationId =======> $verificationId");
    printLog("resendingToken =======> ${forceResendingToken.toString()}");
    printLog("code sent");
  }

  Future<Null> _onCodeTimeout(String verificationId) async {
    printLog("_onCodeTimeout verificationId =======> $verificationId");
    this.verificationId = verificationId;
    await generalProvider.setLoadingOTP(false);
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
      printLog("_checkOTPAndLogin error Code =====> ${e.code}");
      if (e.code == 'invalid-verification-code' ||
          e.code == 'invalid-verification-id') {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(context, "info", "otp_invalid", true);
        pinPutFocusNode.requestFocus();
        return;
      } else if (e.code == 'session-expired') {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(context, "fail", "otp_session_expired", true);
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
      LoadingOverlay().hide();
      if (!mounted) return;
      Utils.showSnackbar(context, "fail", "otp_login_fail", true);
    }
  }

  Future<void> _login(String mobile, {String? referenceCode}) async {
    printLog("click on Submit mobile => $mobile");
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final bottombarProvider = Provider.of<BottombarProvider>(
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
          fullName: generalProvider.loginOTPModel.result?[0].fullName
              .toString(),
          userName: generalProvider.loginOTPModel.result?[0].userName
              .toString(),
          userEmail: generalProvider.loginOTPModel.result?[0].email.toString(),
          userMobile: generalProvider.loginOTPModel.result?[0].mobileNumber
              .toString(),
          userImage: generalProvider.loginOTPModel.result?[0].image.toString(),
          userPremium: generalProvider.loginOTPModel.result?[0].isBuy
              .toString(),
          userType: generalProvider.loginOTPModel.result?[0].type.toString(),
          deviceType: generalProvider.loginOTPModel.result?[0].deviceType
              .toString(),
          deviceToken: generalProvider.loginOTPModel.result?[0].deviceToken
              .toString(),
        );

        // Set UserID for Next
        Constant.userID = generalProvider.loginOTPModel.result?[0].id
            .toString();
        printLog('Constant userID ==>> ${Constant.userID}');

        await homeProvider.setLoading(true);
        await bottombarProvider.setBottomNavIndex(0);
        await bottombarProvider.toggleVisibility(true);
        await sectionDataProvider.getSectionBanner("0", "1");
        await sectionDataProvider.getSectionList("0", "1", 1);
        /* Initialize Hive */
        await Utils.initializeHiveBoxes();

        if (!mounted) return;
        LoadingOverlay().hide();
        if (!mounted) return;
        Utils.redirectToMainPage(context: context);
      } else {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(
          context,
          "fail",
          "${generalProvider.loginOTPModel.message}",
          false,
        );
      }
    }
  }
}
