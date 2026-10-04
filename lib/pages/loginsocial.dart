import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../pages/otpverify.dart';
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

class LoginSocial extends StatefulWidget {
  const LoginSocial({super.key});

  @override
  State<LoginSocial> createState() => LoginSocialState();
}

class LoginSocialState extends State<LoginSocial> {
  late GeneralProvider generalProvider;
  SharedPre sharedPre = SharedPre();

  final numberController = TextEditingController();
  String? mobileNumber,
      email,
      userName,
      strType,
      strDeviceType,
      strDeviceToken,
      strPrivacyAndTNC;
  File? mProfileImg;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  bool initialized = false;
  String? webServerClientId;
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    _getDeviceToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getDeviceToken() async {
    try {
      webServerClientId = await sharedPre.read(Constant.googleClientIdKey);
      printLog("_getDeviceToken webServerClientId ===> $webServerClientId");
      if (Platform.isAndroid) {
        strDeviceType = "1";
      } else {
        strDeviceType = "2";
      }
      strDeviceToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      printLog("_getDeviceToken Exception ===> $e");
    }
    printLog("_getDeviceToken strDeviceToken ===> $strDeviceToken");
    printLog("_getDeviceToken strDeviceType ====> $strDeviceType");
  }

  Future<void> _getData() async {
    String? privacyUrl, termsConditionUrl;
    await generalProvider.getPages();
    if (!generalProvider.loading) {
      if (generalProvider.pagesModel.status == 200 &&
          generalProvider.pagesModel.result != null) {
        if ((generalProvider.pagesModel.result?.length ?? 0) > 0) {
          for (
            var i = 0;
            i < (generalProvider.pagesModel.result?.length ?? 0);
            i++
          ) {
            if ((generalProvider.pagesModel.result?[i].pageName ?? "")
                .toLowerCase()
                .contains("privacy")) {
              privacyUrl = generalProvider.pagesModel.result?[i].url;
            }
            if ((generalProvider.pagesModel.result?[i].pageName ?? "")
                .toLowerCase()
                .contains("terms")) {
              termsConditionUrl = generalProvider.pagesModel.result?[i].url;
            }
          }
        }
      }
    }
    printLog('privacyUrl ==> $privacyUrl');
    printLog('termsConditionUrl ==> $termsConditionUrl');

    strPrivacyAndTNC = await Utils.getPrivacyTandCText(
      privacyUrl ?? "",
      termsConditionUrl ?? "",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    numberController.dispose();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                margin: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 170,
                      height: 60,
                      alignment: Alignment.centerLeft,
                      child: MyImage(
                        fit: BoxFit.fill,
                        imagePath: "appicon.png",
                      ),
                    ),
                    const SizedBox(height: 25),
                    MyText(
                      color: titleTextColor,
                      text: "welcomeback",
                      fontsizeNormal: 20,
                      fontsizeWeb: 25,
                      multilanguage: true,
                      fontweight: FontWeight.bold,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                    const SizedBox(height: 7),
                    MyText(
                      color: descTextColor,
                      text: "login_with_mobile_note",
                      fontsizeNormal: 14,
                      fontsizeWeb: 15,
                      multilanguage: true,
                      fontweight: FontWeight.w500,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                    const SizedBox(height: 30),

                    /* Enter Mobile Number */
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorPrimary, width: 0.7),
                        color: edtShadowColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                      ),
                      child: IntlPhoneField(
                        disableLengthCheck: true,
                        textAlignVertical: TextAlignVertical.center,
                        autovalidateMode: AutovalidateMode.disabled,
                        controller: numberController,
                        style: const TextStyle(fontSize: 16, color: white),
                        showCountryFlag: false,
                        showDropdownIcon: false,
                        initialCountryCode: Constant.defaultCountryCode,
                        dropdownTextStyle: GoogleFonts.inter(
                          color: white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          hintStyle: GoogleFonts.inter(
                            color: descTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: Locales.string(context, "enter_mobile"),
                        ),
                        onChanged: (phone) {
                          printLog('===> ${phone.completeNumber}');
                          printLog('===> ${numberController.text}');
                          mobileNumber = phone.completeNumber;
                          printLog('===>mobileNumber $mobileNumber');
                        },
                        onCountryChanged: (country) {
                          printLog('===> ${country.name}');
                          printLog('===> ${country.code}');
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    /* Login Button */
                    InkWell(
                      onTap: () {
                        printLog("Click mobileNumber ==> $mobileNumber");
                        if (numberController.text.toString().isEmpty) {
                          Utils.showSnackbar(
                            context,
                            "info",
                            "login_with_mobile_note",
                            true,
                          );
                        } else {
                          printLog("mobileNumber ==> $mobileNumber");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OTPVerify(mobileNumber ?? ""),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
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
                          color: white,
                          text: "login",
                          multilanguage: true,
                          fontsizeNormal: 17,
                          fontsizeWeb: 19,
                          fontweight: FontWeight.w700,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    /* Privacy & TermsCondition link */
                    if (strPrivacyAndTNC != null)
                      Utils.htmlTexts(strPrivacyAndTNC),
                    const SizedBox(height: 10),

                    /* Or */
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 80, height: 1, color: colorAccent),
                        const SizedBox(width: 15),
                        MyText(
                          color: descTextColor,
                          text: "or",
                          multilanguage: true,
                          fontsizeNormal: 14,
                          fontsizeWeb: 16,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(width: 15),
                        Container(width: 80, height: 1, color: colorAccent),
                      ],
                    ),
                    const SizedBox(height: 25),

                    /* Google Login Button */
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 52,
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () {
                          printLog("Clicked on : ====> loginWith Google");
                          _gmailLogin();
                        },
                        borderRadius: BorderRadius.circular(26),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MyImage(
                              width: 30,
                              height: 30,
                              imagePath: "ic_google.png",
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 30),
                            MyText(
                              color: black,
                              text: "loginwithgoogle",
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
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
                    ),

                    /* Apple Login Button */
                    if (Platform.isIOS)
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 52,
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: () {
                            printLog("Clicked on : ====> loginWith Apple");
                            signInWithApple();
                          },
                          borderRadius: BorderRadius.circular(26),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MyImage(
                                width: 30,
                                height: 30,
                                imagePath: "ic_apple.png",
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 30),
                              MyText(
                                color: black,
                                text: "loginwithapple",
                                fontsizeNormal: 14,
                                fontsizeWeb: 16,
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
                      ),

                    /* Facebook Login Button */
                    // Container(
                    //   width: MediaQuery.of(context).size.width,
                    //   height: 52,
                    //   padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                    //   decoration: BoxDecoration(
                    //     color: white,
                    //     borderRadius: BorderRadius.circular(26),
                    //   ),
                    //   alignment: Alignment.center,
                    //   child: InkWell(
                    //     onTap: () {
                    //       printLog("Clicked on : ====> loginWith Facebook");
                    //       facebookLogin();
                    //     },
                    //     borderRadius: BorderRadius.circular(26),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         MyImage(
                    //           width: 30,
                    //           height: 30,
                    //           imagePath: "ic_facebook.png",
                    //           fit: BoxFit.contain,
                    //         ),
                    //         const SizedBox(width: 30),
                    //         MyText(
                    //           color: black,
                    //           text: "loginwithfacebook",
                    //           fontsizeNormal: 14,
                    //           fontsizeWeb: 16,
                    //           multilanguage: true,
                    //           fontweight: FontWeight.w600,
                    //           maxline: 1,
                    //           overflow: TextOverflow.ellipsis,
                    //           textalign: TextAlign.center,
                    //           fontstyle: FontStyle.normal,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  Utils.exitPage(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  child: MyImage(
                    fit: BoxFit.contain,
                    imagePath: "ic_close.png",
                    color: defaultIconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* Google Login */
  Future<void> _initGoogleSignIn() async {
    try {
      await googleSignIn.initialize(
        clientId: Platform.isIOS ? null : webServerClientId,
        serverClientId: Platform.isIOS ? null : webServerClientId,
      );
      initialized = true;
    } catch (e) {
      printLog("_initGoogleSignIn GoogleSignIn Error ===> $e");
      initialized = false;
      return;
    }
  }

  Future<void> _gmailLogin() async {
    try {
      if (!initialized) {
        await _initGoogleSignIn();
      }
      GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      if (googleUser.authentication.idToken == null) return;

      GoogleSignInAccount user = googleUser;

      printLog('_gmailLogin ===> id : ${user.id}');
      printLog('_gmailLogin ===> email : ${user.email}');
      printLog('_gmailLogin ===> displayName : ${user.displayName}');
      printLog('_gmailLogin ===> photoUrl : ${user.photoUrl}');

      if (!mounted) return;
      LoadingOverlay().show(context);

      UserCredential userCredential;
      final GoogleSignInAuthentication googleAuth = user.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
      assert(await userCredential.user?.getIdToken() != null);
      printLog("_gmailLogin UserName ======> ${user.displayName}");
      printLog("_gmailLogin UserEmail =====> ${user.email}");
      printLog("_gmailLogin UserPhotoUrl ==> ${user.photoUrl}");
      String firebasedid = userCredential.user?.uid ?? "";
      printLog('_gmailLogin firebasedid ===> $firebasedid');

      /* Save PhotoUrl in File */
      mProfileImg = await Utils.saveImageInStorage(user.photoUrl ?? "");
      printLog('_gmailLogin mProfileImg ===> $mProfileImg');

      /* Hide overlay before showing referral dialog */
      LoadingOverlay().hide();
      if (!mounted) return;
      final referralCode = await Utils.showReferralDialog(context);
      if (!mounted) return;
      LoadingOverlay().show(context);
      checkAndNavigate(
        user.email,
        user.displayName ?? "",
        "2",
        referenceCode: referralCode,
      );
    } on FirebaseAuthException catch (e) {
      printLog('_gmailLogin Firebase Error Code ==> ${e.code.toString()}');
      printLog('_gmailLogin Firebase Error =======> ${e.message.toString()}');
      if (!mounted) return;
      LoadingOverlay().hide();
    } on Exception catch (e) {
      printLog('_gmailLogin Exception ==> $e');
      if (!mounted) return;
      LoadingOverlay().hide();
    }
  }

  /* Apple Login */
  Future<void> signInWithApple() async {
    final rawNonce = generateNonce();
    final nonce = Utils.sha256ofString(rawNonce);

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      if (!mounted) return;
      LoadingOverlay().show(context);

      String? displayName;
      final authResult = await _auth.signInWithCredential(oauthCredential);
      final firebaseUser = authResult.user;

      dynamic firebasedId;
      if (appleCredential.givenName != null) {
        displayName =
            '${appleCredential.givenName} ${appleCredential.familyName}';
        userEmail = authResult.user?.email.toString() ?? "";

        await firebaseUser?.updateDisplayName(displayName);

        printLog("===>userEmail $userEmail");
        printLog("===>displayName $displayName");
      } else {
        userEmail = firebaseUser?.email.toString() ?? "";
        firebasedId = firebaseUser?.uid.toString();
        displayName = firebaseUser?.displayName.toString();

        printLog("===>userEmail-else $userEmail");
        printLog("===>displayName-else $displayName");
      }
      printLog("userEmail =====FINAL==> $userEmail");
      printLog("firebasedId ===FINAL==> $firebasedId");
      printLog("displayName ===FINAL==> $displayName");

      /* Hide overlay before showing referral dialog */
      LoadingOverlay().hide();
      if (!mounted) return;
      final referralCode = await Utils.showReferralDialog(context);
      if (!mounted) return;
      LoadingOverlay().show(context);
      checkAndNavigate(
        userEmail,
        ((displayName ?? "").contains("null")) ? "" : (displayName ?? ""),
        "3",
        referenceCode: referralCode,
      );
    } catch (exception) {
      printLog("Apple Login exception =====> $exception");
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
    printLog('checkAndNavigate email ========>> $email');
    printLog('checkAndNavigate userName =====>> $userName');
    printLog('checkAndNavigate strType ======>> $strType');
    printLog('checkAndNavigate mProfileImg ==>> $mProfileImg');
    printLog('checkAndNavigate referenceCode => $referenceCode');

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    final bottombarProvider = Provider.of<BottombarProvider>(
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
      mProfileImg,
      referenceCode: referenceCode,
    );
    printLog('checkAndNavigate loading ==>> ${generalProvider.loading}');

    if (!generalProvider.loading) {
      if (generalProvider.loginSocialModel.status == 200) {
        printLog('Login Successfull!');
        Utils.saveUserCreds(
          userID: generalProvider.loginSocialModel.result?[0].id.toString(),
          fullName: generalProvider.loginSocialModel.result?[0].fullName
              .toString(),
          userName: generalProvider.loginSocialModel.result?[0].userName
              .toString(),
          userEmail: generalProvider.loginSocialModel.result?[0].email
              .toString(),
          userMobile: generalProvider.loginSocialModel.result?[0].mobileNumber
              .toString(),
          userImage: generalProvider.loginSocialModel.result?[0].image
              .toString(),
          userPremium: generalProvider.loginSocialModel.result?[0].isBuy
              .toString(),
          userType: generalProvider.loginSocialModel.result?[0].type.toString(),
          deviceType: generalProvider.loginSocialModel.result?[0].deviceType
              .toString(),
          deviceToken: generalProvider.loginSocialModel.result?[0].deviceToken
              .toString(),
        );

        // Set UserID for Next
        Constant.userID = generalProvider.loginSocialModel.result?[0].id
            .toString();
        printLog('Constant userID ==>> ${Constant.userID}');
        await Future.wait([
          bottombarProvider.setBottomNavIndex(0),
          bottombarProvider.toggleVisibility(true),
          homeProvider.setLoading(true),
          sectionDataProvider.getSectionBanner("0", "1"),
          sectionDataProvider.getSectionList("0", "1", 1),
          /* Initialize Hive */
          Utils.initializeHiveBoxes(),
        ]);

        if (!mounted) return;
        LoadingOverlay().hide();
        if (!mounted) return;
        Utils.redirectToMainPage(context: context);
      } else {
        // Hide Progress Dialog
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(
          context,
          "fail",
          "${generalProvider.loginSocialModel.message}",
          false,
        );
      }
    }
  }
}
