import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/generalsettingmodel.dart' as settings;
import '../model/introscreenmodel.dart';
import '../model/loginregistermodel.dart';
import '../model/pagesmodel.dart';
import '../model/sociallinkmodel.dart';
import '../utils/constant.dart';
import '../utils/sharedpre.dart';
import '../webservice/apiservices.dart';
import '../utils/utils.dart';

class GeneralProvider extends ChangeNotifier {
  settings.GeneralSettingModel generalSettingModel =
      settings.GeneralSettingModel();
  PagesModel pagesModel = PagesModel();
  IntroScreenModel introScreenModel = IntroScreenModel();
  SocialLinkModel socialLinkModel = SocialLinkModel();
  LoginRegisterModel loginSocialModel = LoginRegisterModel();
  LoginRegisterModel loginOTPModel = LoginRegisterModel();
  LoginRegisterModel loginNormalModel = LoginRegisterModel();
  LoginRegisterModel loginTVModel = LoginRegisterModel();

  bool loading = false, loadingOTP = false;
  String? appDescription;

  SharedPre sharedPre = SharedPre();

  Future<void> getGeneralsetting(BuildContext context) async {
    loading = true;
    if (generalSettingModel.result != null &&
        (generalSettingModel.result?.length ?? 0) > 0) {
      loading = false;
      notifyListeners();
    }
    try {
      generalSettingModel = await ApiService().genaralSetting();
      printLog('getGeneralsetting status ==> ${generalSettingModel.status}');
      if (generalSettingModel.status == 200) {
        if (generalSettingModel.result != null) {
          /* Insert in local db */
          await Future.forEach<settings.Result>(
            generalSettingModel.result ?? [],
            (generalSettingItem) async {
              await sharedPre.save(
                generalSettingItem.key.toString(),
                generalSettingItem.value.toString(),
              );
            },
          );

          appDescription =
              await sharedPre.read(Constant.appDescriptionKey) ?? "";
          Constant.androidAppUrl =
              await sharedPre.read(Constant.playstoreIdKey) ?? "";
          Constant.iosAppUrl =
              await sharedPre.read(Constant.appstoreIdKey) ?? "";
          Constant.vapidKeyForWeb =
              await sharedPre.read(Constant.vapIdKey) ?? "";
          printLog("getGeneralsetting appDescription ==> $appDescription");
          printLog("androidAppUrl =======> ${Constant.androidAppUrl}");
          printLog("iosAppUrl ===========> ${Constant.iosAppUrl}");
          printLog(
            "getGeneralsetting vapidKeyForWeb ==> ${Constant.vapidKeyForWeb}",
          );
          /* Get Ads Init */
          if (!kIsWeb) {
            await Utils.initializeOneSignal();
            if (context.mounted) {
              Utils.loadAds(context);
            }
          }
        }
      }
    } on Exception catch (e) {
      printLog('getGeneralsetting Exception ==> $e');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getPages() async {
    loading = true;
    try {
      if (pagesModel.result != null && (pagesModel.result?.length ?? 0) > 0) {
        loading = false;
        notifyListeners();
      }
      pagesModel = await ApiService().getPages();
    } on Exception catch (e) {
      printLog("getPages Exception :==> $e");
    }
    printLog("getPages status :==> ${pagesModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> getIntroPages() async {
    loading = true;
    try {
      if (introScreenModel.result == null &&
          (introScreenModel.result?.length ?? 0) == 0) {
        introScreenModel = await ApiService().getOnboardingScreen();
      }
    } on Exception catch (e) {
      printLog("getIntroPages Exception :==> $e");
    }
    printLog("getIntroPages status :==> ${introScreenModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> getSocialLinks() async {
    loading = true;
    try {
      if (socialLinkModel.result != null &&
          (socialLinkModel.result?.length ?? 0) > 0) {
        loading = false;
        notifyListeners();
      }
      socialLinkModel = await ApiService().getSocialLink();
    } on Exception catch (e) {
      printLog("getSocialLinks Exception :==> $e");
    }
    printLog("getSocialLinks status :==> ${socialLinkModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginWithSocial(
    dynamic email,
    name,
    type,
    deviceName,
    deviceType,
    deviceToken,
    profileImg, {
    String? referenceCode,
  }) async {
    printLog("loginWithSocial email :========> $email");
    printLog("loginWithSocial name :=========> $name");
    printLog("loginWithSocial type :=========> $type");
    printLog("loginWithSocial deviceName :===> $deviceName");
    printLog("loginWithSocial deviceType :===> $deviceType");
    printLog("loginWithSocial deviceToken :==> $deviceToken");
    printLog("loginWithSocial profileImg :===> ${profileImg?.path}");
    printLog("loginWithSocial referenceCode :=> $referenceCode");

    loading = true;
    loginSocialModel = await ApiService().loginWithSocial(
      email,
      name,
      type,
      deviceName,
      deviceType,
      deviceToken,
      profileImg,
      referenceCode: referenceCode,
    );
    printLog("loginWithSocial status :===> ${loginSocialModel.status}");
    printLog("loginWithSocial message :==> ${loginSocialModel.message}");
    loading = false;
    notifyListeners();
  }

  Future setLoadingOTP(bool loading) async {
    loadingOTP = loading;
    notifyListeners();
  }

  Future<void> loginWithOTP(
    dynamic mobile,
    deviceName,
    deviceType,
    deviceToken, {
    String? referenceCode,
  }) async {
    printLog("loginWithOTP mobile :=======> $mobile");
    printLog("loginWithOTP deviceName :===> $deviceName");
    printLog("loginWithOTP deviceType :===> $deviceType");
    printLog("loginWithOTP deviceToken :==> $deviceToken");
    printLog("loginWithOTP referenceCode :=> $referenceCode");

    loading = true;
    loginOTPModel = await ApiService().loginWithOTP(
      mobile,
      deviceName,
      deviceType,
      deviceToken,
      referenceCode: referenceCode,
    );
    printLog("loginWithOTP status :===> ${loginOTPModel.status}");
    printLog("loginWithOTP message :==> ${loginOTPModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginNormal(
    dynamic email,
    password,
    deviceName,
    deviceType,
    deviceToken,
  ) async {
    printLog("loginNormal email :========> $email");
    printLog("loginNormal password :=====> $password");
    printLog("loginNormal deviceName :===> $deviceName");
    printLog("loginNormal deviceType :===> $deviceType");
    printLog("loginNormal deviceToken :==> $deviceToken");

    loading = true;
    loginNormalModel = await ApiService().loginWithEmailPW(
      email,
      password,
      deviceName,
      deviceType,
      deviceToken,
    );
    printLog("loginNormal status :===> ${loginNormalModel.status}");
    printLog("loginNormal message :==> ${loginNormalModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginWithTV(dynamic strOTP) async {
    printLog("loginWithTV strOTP :==> $strOTP");

    loading = true;
    loginTVModel = await ApiService().tvLogin(strOTP);
    printLog("loginWithTV status :===> ${loginTVModel.status}");
    printLog("loginWithTV message :==> ${loginTVModel.message}");
    loading = false;
    notifyListeners();
  }
}
