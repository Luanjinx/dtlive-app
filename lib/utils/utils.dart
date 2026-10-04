import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as number;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:hive/hive.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:html/parser.dart' show parse;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screen_protector/screen_protector.dart';

import '../pages/clips.dart';
import '../provider/clipsprovider.dart';
import '../model/download_item.dart';
import '../model/playermodel.dart';
import '../model/qualitymodel.dart';
import '../model/sharemodel.dart';
import '../model/subtitlemodel.dart';
import '../pages/bottombar.dart';
import '../pages/loginsocial.dart';
import '../pages/contentvideodetails.dart';
import '../players/player_vdocipher.dart';
import '../players/player_video.dart';
import '../players/player_vimeo.dart';
import '../players/player_youtube.dart';
import '../pages/contentshowdetails.dart';
import '../players/model/vdociphermodel.dart';
import '../provider/mysubscribedplanprovider.dart';
import '../provider/playerprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/showdetailsprovider.dart';
import '../provider/subscriptionprovider.dart';
import '../provider/videodetailsprovider.dart';
import '../provider/videodownloadprovider.dart';
import '../routes/routes_constant.dart';
import '../subscription/allpayment.dart';
import '../subscription/mypurchaselist.dart';
import '../subscription/mysubscribedplan.dart';
import '../subscription/subscription.dart';
import '../utils/dimens.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../web_js/js_helper.dart';
import '../webpages/webprofileedit.dart';
import '../webservice/apiservices.dart';
import '../webwidget/webdialogs.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/sharedpre.dart';
import 'loadingoverlay.dart';

void printLog(String message) {
  if (kDebugMode) {
    return debugPrint(message);
  }
}

class Utils {
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<String>? getFirebaseWebToken() async {
    String? fcmToken;
    try {
      if (kIsWeb) {
        fcmToken = await FirebaseMessaging.instance.getToken(
          vapidKey: Constant.vapidKeyForWeb,
        );
      }
    } on Exception catch (e) {
      printLog("getFirebaseWebToken Exception ====> $e");
    }
    printLog("getFirebaseWebToken fcmToken ====> $fcmToken");
    return fcmToken ?? "";
  }

  static Future<Map<String, dynamic>> loadJsonFromAssets(
    String filePath,
  ) async {
    String jsonString = await rootBundle.loadString(filePath);
    return jsonDecode(jsonString);
  }

  static Future<void> initializeOneSignal() async {
    if (!kIsWeb) {
      SharedPre sharedPre = SharedPre();
      String? oneSignalAppId = await sharedPre.read(Constant.onesignalAppIdKey);
      printLog("initializeOneSignal AppId ==> $oneSignalAppId");
      if (oneSignalAppId != null && oneSignalAppId != "") {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        // Initialize OneSignal
        OneSignal.initialize(oneSignalAppId);
        OneSignal.Notifications.requestPermission(true);
        OneSignal.Notifications.addPermissionObserver((state) {
          printLog("Has permission ==> $state");
        });
        OneSignal.User.pushSubscription.addObserver((state) {
          printLog(
            "pushSubscription state ==> ${state.current.jsonRepresentation()}",
          );
        });
        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          /// preventDefault to not display the notification
          event.preventDefault();
          // Do async work
          /// notification.display() to display after preventing default
          event.notification.display();
        });
      }
    }
  }

  static Future<VdoCipherModel?>? getVdoCipherOTP({
    required BuildContext context,
    required String videoId,
  }) async {
    printLog('getVdoCipherOTP videoId ==> $videoId');
    VdoCipherModel? cipherMediaDetails;
    LoadingOverlay().show(context); // Stop Loading...
    try {
      cipherMediaDetails = await ApiService().generateCipherOTP(videoId);
      printLog('getVdoCipherOTP message ==> ${cipherMediaDetails.message}');
      if (cipherMediaDetails.status == 200 &&
          cipherMediaDetails.result != null) {
        printLog(
          "getVdoCipherOTP otp ===========> ${cipherMediaDetails.result?.otp}",
        );
        printLog(
          "getVdoCipherOTP playbackInfo ==> ${cipherMediaDetails.result?.playbackInfo}",
        );
      } else {
        printLog(
          "getVdoCipherOTP message =======> ${cipherMediaDetails.result?.message}",
        );
        if (cipherMediaDetails.status == 400) {
          Utils.showToast(cipherMediaDetails.message ?? "");
        } else {
          Utils.showToast(cipherMediaDetails.result?.message ?? "");
        }
      }
      LoadingOverlay().hide(); // Stop Loading...
    } on Exception catch (e) {
      printLog("getVdoCipherOTP Exception ====> $e");
      LoadingOverlay().hide(); // Stop Loading...
    }
    return cipherMediaDetails;
  }

  static void preventScreenCapture() async {
    await ScreenProtector.preventScreenshotOn();
    if (Platform.isIOS) {
      await ScreenProtector.protectDataLeakageWithBlur();
    } else if (Platform.isAndroid) {
      await ScreenProtector.protectDataLeakageOn();
    }
  }

  static Future<void> loadAds(BuildContext context) async {
    if (context.mounted) {
      AdHelper.getAds(context);
    }
  }

  static void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: kIsWeb ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: kIsWeb ? 5 : 2,
      webShowClose: false,
      backgroundColor: white,
      textColor: kIsWeb ? white : black,
      webBgColor: "linear-gradient(to right, #AEEC2B, #78A026)",
      fontSize: kIsWeb ? 20 : 16,
    );
  }

  static Future<String> configByStatus({required String status}) async {
    SharedPre sharedPre = SharedPre();
    String? configValue = "";
    printLog("configByStatus status ========> $status");

    if (status == Constant.trailerAutoPlay) {
      configValue = await sharedPre.read(Constant.trailerAutoPlay);
    } else if (status == Constant.parentControlStatus) {
      configValue = await sharedPre.read(Constant.parentControlStatus);
    } else if (status == Constant.multipleDeviceSync) {
      configValue = await sharedPre.read(Constant.multipleDeviceSync);
    } else if (status == Constant.subscriptionStatus) {
      configValue = await sharedPre.read(Constant.subscriptionStatus);
    } else if (status == Constant.activeTvStatus) {
      configValue = await sharedPre.read(Constant.activeTvStatus);
    } else if (status == Constant.watchlistStatus) {
      configValue = await sharedPre.read(Constant.watchlistStatus);
    } else if (status == Constant.downloadStatus) {
      configValue = await sharedPre.read(Constant.downloadStatus);
    } else if (status == Constant.continueWatchingStatus) {
      configValue = await sharedPre.read(Constant.continueWatchingStatus);
    } else if (status == Constant.couponStatus) {
      configValue = await sharedPre.read(Constant.couponStatus);
    } else if (status == Constant.rentStatus) {
      configValue = await sharedPre.read(Constant.rentStatus);
    } else if (status == Constant.introScreenStatus) {
      configValue = await sharedPre.read(Constant.introScreenStatus);
    } else if (status == Constant.screenRecordStatus) {
      configValue = await sharedPre.read(Constant.screenRecordStatus);
    } else if (status == Constant.playerIMAAdsStatus) {
      configValue = await sharedPre.read(Constant.playerIMAAdsStatus);
    } else if (status == Constant.admobAdsStatus) {
      configValue = await sharedPre.read(Constant.admobAdsStatus);
    } else {
      configValue = "";
    }
    printLog('configByStatus configValue ==> $configValue');
    return configValue ?? "";
  }

  static void exitPage(BuildContext context) {
    final JSHelper jsHelper = JSHelper();
    if (kIsWeb) {
      printLog("========== ON WEB EXIT ==========");
      if (context.canPop()) {
        context.pop();
      } else {
        jsHelper.goBack();
      }
    } else {
      printLog("========== ON MOBILE EXIT ==========");
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  static void exitDialog(BuildContext context) {
    if (kIsWeb) {
      printLog("========== ON WEB EXIT ==========");
      if (context.canPop()) {
        context.pop();
      }
    } else {
      printLog("========== ON MOBILE EXIT ==========");
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  static Future<bool> checkSubsRentLogin({
    required BuildContext context,
    required int isPremium,
    required int isRent,
    required int isBuy,
    required int rentBuy,
    required String producerId,
    required String videoId,
    required String rentPrice,
    required String vTitle,
    required String typeId,
    required String vType,
    required String subVideoType,
    required String rentProductId,
    required String newPage,
    required String oldPage,
    required String reqText,
  }) async {
    if (Constant.userID != null) {
      String? rentStatus = await configByStatus(status: Constant.rentStatus);
      String? subscriptionStatus = await configByStatus(
        status: Constant.subscriptionStatus,
      );
      printLog('checkSubsRentLogin rentStatus ====> $rentStatus');
      printLog('checkSubsRentLogin subs. Status ==> $subscriptionStatus');
      if (isPremium == 1 && isRent == 1) {
        if (subscriptionStatus != "1") {
          return true;
        }
        if (isBuy == 1 || rentBuy == 1) {
          return true;
        } else {
          if (context.mounted) {
            openSubscription(context: context, oldPage: "");
          }
          return false;
        }
      } else if (isPremium == 1) {
        if (subscriptionStatus != "1") {
          return true;
        }
        if (isBuy == 1) {
          return true;
        } else {
          if (context.mounted) {
            openSubscription(context: context, oldPage: "");
          }
          return false;
        }
      } else if (isRent == 1) {
        if (rentStatus != "1") {
          return true;
        }
        if (rentBuy == 1) {
          return true;
        } else {
          if (context.mounted) {
            paymentForRent(
              context: context,
              producerId: producerId,
              videoId: videoId,
              rentPrice: rentPrice,
              vTitle: vTitle,
              typeId: typeId,
              vType: vType,
              subVideoType: subVideoType,
              newPage: newPage,
              oldPage: oldPage,
              reqText: reqText,
              rentProductId: rentProductId,
            );
          }
          return false;
        }
      } else {
        return true;
      }
    } else {
      if (isPremium == 1 || isRent == 1) {
        openLogin(context: context, newPage: "");
        return false;
      } else {
        return true;
      }
    }
  }

  static Future<bool> getTrailerAutoPlay() async {
    SharedPre sharedPref = SharedPre();
    String? autoPlayTrailer = await sharedPref.read("auto_play_trailer") ?? "";
    printLog('getTrailerAutoPlay autoPlayTrailer ==> $autoPlayTrailer');
    if (autoPlayTrailer.toString() != "null" && autoPlayTrailer == "1") {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> redirectToMainPage({
    required BuildContext context,
  }) async {
    if (!context.mounted) return;
    if (kIsWeb) {
      if (context.canPop()) {
        context.pop();
      }
      context.pushReplacementNamed(RoutesConstant.homePage);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const Bottombar()),
        (Route<dynamic> route) => false,
      ).then((value) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const Bottombar(),
            ),
          );
        }
      });
    }
  }

  static Future<dynamic> openSubscription({
    required BuildContext context,
    required String oldPage,
  }) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    dynamic isSubscribe;
    if (profileProvider.profileModel.result != null &&
        (profileProvider.profileModel.result?[0].isBuy ?? 0) == 1) {
      openMySubscription(context: context, oldPage: oldPage);
      return;
    } else {
      await subscriptionProvider.setLoading(true);
      if (!context.mounted) return;
      if (kIsWeb) {
        context.go("/${RoutesConstant.subscriptionPage}", extra: oldPage);
        return isSubscribe;
      }
      isSubscribe = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return Subscription(
              newPage: RoutesConstant.subscriptionPage,
              oldPage: oldPage,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    }
    printLog("openSubscription isSubscribe ====> $isSubscribe");
    return isSubscribe;
  }

  static Future<void> openMySubscription({
    required BuildContext context,
    required String oldPage,
  }) async {
    final mySubscribedPlanProvider = Provider.of<MySubscribedPlanProvider>(
      context,
      listen: false,
    );
    await mySubscribedPlanProvider.setLoading(true);
    if (!context.mounted) return;
    if (kIsWeb) {
      context.go("/${RoutesConstant.mySubscribePlanPage}", extra: oldPage);
    } else {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return MySubscribedPlan(
              newPage: RoutesConstant.mySubscribePlanPage,
              oldPage: oldPage,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    }
  }

  static Future<void> openRentPurchase({
    required BuildContext context,
    required String oldPage,
  }) async {
    if (kIsWeb) {
      if (!context.mounted) return;
      context.go("/${RoutesConstant.rentPurchasePage}", extra: oldPage);
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return MyPurchaselist(
            newPage: RoutesConstant.rentPurchasePage,
            oldPage: oldPage,
            reqText: '',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  /* SHARE feature Dialog ***************** */
  static void openShareDialog({
    required BuildContext context,
    required ShareModel shareModel,
  }) {
    printLog("openShareDialog newPage ======> ${shareModel.newPage}");
    String contentLink = "";
    /* newpage, videoid, videotype, subvideotype, typeid */
    contentLink =
        (shareModel.subVideoType != null && shareModel.subVideoType != 0)
        ? "https://${Constant.deeplinkDomain}/${shareModel.newPage}/${shareModel.videoType}/${shareModel.typeId}/${shareModel.videoId}/${shareModel.subVideoType}"
        : "https://${Constant.deeplinkDomain}/${shareModel.newPage}/${shareModel.videoType}/${shareModel.typeId}/${shareModel.videoId}";

    printLog("contentLink ======> $contentLink");

    /* Share Dialog */
    if (!kIsWeb) {
      showModalBottomSheet(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MyText(
                      text: shareModel.videoTitle ?? "",
                      multilanguage: false,
                      fontsizeNormal: 18,
                      fontsizeWeb: 20,
                      color: titleTextColor,
                      fontstyle: FontStyle.normal,
                      fontweight: FontWeight.w700,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                    ),
                    const SizedBox(height: 12),

                    /* SMS */
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        exitDialog(context);
                        Utils.redirectToUrl(
                          'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${shareModel.videoTitle}. Check it out now on ${Constant.appName}! \n\n$contentLink")}',
                        );
                      },
                      child: buildDialogItems(
                        icon: "ic_sms.png",
                        title: "sms",
                        isMultilang: true,
                      ),
                    ),

                    /* Copy Link */
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        exitDialog(context);
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                "Hey! I'm watching ${shareModel.videoTitle}. Check it out now on ${Constant.appName}! \n\n$contentLink",
                          ),
                        ).then((value) {
                          if (context.mounted) {
                            Utils.showSnackbar(
                              context,
                              "",
                              "link_copied",
                              true,
                            );
                          }
                        });
                      },
                      child: buildDialogItems(
                        icon: "ic_link.png",
                        title: "copy_link",
                        isMultilang: true,
                      ),
                    ),

                    /* More */
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        exitDialog(context);
                        Utils.shareApp(
                          "Hey! I'm watching ${shareModel.videoTitle}. Check it out now on ${Constant.appName}! \n\n$contentLink",
                        );
                      },
                      child: buildDialogItems(
                        icon: "ic_dots_h.png",
                        title: "more",
                        isMultilang: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } else {
      /* For Web only */
      // Utils.shareApp(
      //     "Hey! I'm watching ${shareModel.videoTitle}. Check it out now on ${Constant.appName}! \n\n$contentLink");
      Clipboard.setData(ClipboardData(text: contentLink)).then((value) {
        if (context.mounted) {
          Utils.showSnackbar(context, "", "link_copied", true);
        }
      });
    }
  }

  static Widget buildDialogItems({
    required String icon,
    required String title,
    required bool isMultilang,
  }) {
    return Container(
      height: Dimens.minHtDialogContent,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MyImage(
            width: Dimens.dialogIconSize,
            height: Dimens.dialogIconSize,
            imagePath: icon,
            fit: BoxFit.contain,
            color: defaultIconColor,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: MyText(
              text: title,
              multilanguage: isMultilang,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              color: titleTextColor,
              fontstyle: FontStyle.normal,
              fontweight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
  /* ***************** SHARE feature Dialog */

  /* ========= Open Details ========= */
  static Future<void> openDetails({
    required BuildContext context,
    required int videoId,
    required int subVideoType,
    required int videoType,
    required int typeId,
    required String newPage,
    required String oldPage,
    required String reqText,
  }) async {
    printLog("openDetails videoId ========> $videoId");
    printLog("openDetails subVideoType ===> $subVideoType");
    printLog("openDetails videoType ======> $videoType");
    printLog("openDetails typeId =========> $typeId");

    final videoDetailsProvider = Provider.of<VideoDetailsProvider>(
      context,
      listen: false,
    );
    final showDetailsProvider = Provider.of<ShowDetailsProvider>(
      context,
      listen: false,
    );
    final clipsProvider = Provider.of<ClipsProvider>(context, listen: false);

    /// common extra params for web/TV navigation
    final extraParams = {
      'newpage': oldPage,
      'videotype': videoType.toString(),
      'typeid': typeId.toString(),
      'videoid': videoId.toString(),
      'subvideotype': subVideoType.toString(),
    };

    Future<void> navigateTo(Widget Function() pageBuilder) async {
      if (kIsWeb || Constant.isTV) {
        if (videoType == Constant.shortsContentType) {
          // Details Page Path => /episodes/:videotype/:typeid/:videoid/:subvideotype
          if (subVideoType != 0) {
            context.go(
              "/${RoutesConstant.clipsEpisodesPage}/$videoType/$typeId/$videoId/$subVideoType",
              extra: extraParams,
            );
          } else {
            context.go(
              "/${RoutesConstant.clipsEpisodesPage}/$videoType/$typeId/$videoId",
              extra: extraParams,
            );
          }
        } else {
          // Details Page Path => /details/:videotype/:typeid/:videoid/:subvideotype
          context.go(
            "/${RoutesConstant.contentDetailsPage}/$videoType/$typeId/$videoId/$subVideoType",
            extra: extraParams,
          );
        }
      } else {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => pageBuilder(),
            transitionsBuilder: (_, animation, _, child) => child,
          ),
        );
      }
    }

    if (!(context.mounted)) return;

    switch (videoType) {
      case 5:
      case 6:
      case 7:
        if (subVideoType == Constant.movieContentType) {
          videoDetailsProvider.setLoading(true);
          await navigateTo(
            () => ContentVideoDetails(videoId, subVideoType, videoType, typeId),
          );
        } else if (subVideoType == Constant.showContentType) {
          showDetailsProvider.setLoading(true);
          await navigateTo(
            () => ContentShowDetails(videoId, subVideoType, videoType, typeId),
          );
        }
        break;
      case 8:
        clipsProvider.setLoading(true);
        await navigateTo(() => Clips(clipId: videoId, openFrom: ""));
        break;

      case 1:
        videoDetailsProvider.setLoading(true);
        await navigateTo(
          () => ContentVideoDetails(videoId, subVideoType, videoType, typeId),
        );
        break;

      case 2:
        showDetailsProvider.setLoading(true);
        await navigateTo(
          () => ContentShowDetails(videoId, subVideoType, videoType, typeId),
        );
        break;
    }
  }

  static Future<void> openDetailsWithReplace({
    required BuildContext context,
    required int videoId,
    required int subVideoType,
    required int videoType,
    required int typeId,
    required String newPage,
    required String oldPage,
    required String reqText,
  }) async {
    printLog("openDetailsWithReplace videoId =======> $videoId");
    printLog("openDetailsWithReplace subVideoType ==> $subVideoType");
    printLog("openDetailsWithReplace videoType =====> $videoType");
    printLog("openDetailsWithReplace typeId ========> $typeId");

    final videoDetailsProvider = Provider.of<VideoDetailsProvider>(
      context,
      listen: false,
    );
    final showDetailsProvider = Provider.of<ShowDetailsProvider>(
      context,
      listen: false,
    );
    final clipsProvider = Provider.of<ClipsProvider>(context, listen: false);

    /// common extra params for web/TV navigation
    final extraParams = {
      'newpage': oldPage,
      'videotype': videoType.toString(),
      'typeid': typeId.toString(),
      'videoid': videoId.toString(),
      'subvideotype': subVideoType.toString(),
    };

    Future<void> navigateTo(Widget Function() pageBuilder) async {
      if (kIsWeb || Constant.isTV) {
        if (videoType == Constant.shortsContentType) {
          // Details Page Path => /episodes/:videotype/:typeid/:videoid/:subvideotype
          if (subVideoType != 0) {
            context.go(
              "/${RoutesConstant.clipsEpisodesPage}/$videoType/$typeId/$videoId/$subVideoType",
              extra: extraParams,
            );
          } else {
            context.go(
              "/${RoutesConstant.clipsEpisodesPage}/$videoType/$typeId/$videoId",
              extra: extraParams,
            );
          }
        } else {
          // Details Page Path => /details/:videotype/:typeid/:videoid/:subvideotype
          context.go(
            "/${RoutesConstant.contentDetailsPage}/$videoType/$typeId/$videoId/$subVideoType",
            extra: extraParams,
          );
        }
      } else {
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => pageBuilder(),
            transitionsBuilder: (_, animation, _, child) => child,
          ),
        );
      }
    }

    if (!(context.mounted)) return;

    switch (videoType) {
      case 5:
      case 6:
      case 7:
        if (subVideoType == Constant.movieContentType) {
          videoDetailsProvider.setLoading(true);
          await navigateTo(
            () => ContentVideoDetails(videoId, subVideoType, videoType, typeId),
          );
        } else if (subVideoType == Constant.showContentType) {
          showDetailsProvider.setLoading(true);
          await navigateTo(
            () => ContentShowDetails(videoId, subVideoType, videoType, typeId),
          );
        }
        break;
      case 8:
        clipsProvider.setLoading(true);
        await navigateTo(() => Clips(clipId: videoId, openFrom: ""));
        break;

      case 1:
        videoDetailsProvider.setLoading(true);
        await navigateTo(
          () => ContentVideoDetails(videoId, subVideoType, videoType, typeId),
        );
        break;

      case 2:
        showDetailsProvider.setLoading(true);
        await navigateTo(
          () => ContentShowDetails(videoId, subVideoType, videoType, typeId),
        );
        break;
    }
  }

  /* ========= Open Details ========= */

  static Future<dynamic> paymentForRent({
    required BuildContext context,
    required String? newPage,
    required String? oldPage,
    required String? reqText,
    required String? videoId,
    required String? vTitle,
    required String? vType,
    required String? subVideoType,
    required String? producerId,
    required String? typeId,
    required String? rentPrice,
    required String? rentProductId,
  }) async {
    dynamic isRented;
    if (kIsWeb) {
      context.go(
        "/${RoutesConstant.paymentPage}",
        extra: {
          'newpage': newPage.toString(),
          'paytype': 'Rent',
          'producerid': producerId,
          'itemid': videoId,
          'price': rentPrice,
          'title': vTitle,
          'videotype': vType,
          'subvideotype': subVideoType,
          'typeid': typeId,
          'currency': '',
          'productpackage': rentProductId,
        },
      );
    } else {
      isRented = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return AllPayment(
              payType: 'Rent',
              newPage: RoutesConstant.paymentPage,
              oldPage: newPage.toString(),
              reqText: '',
              producerId: producerId.toString(),
              itemId: videoId.toString(),
              price: rentPrice.toString(),
              itemTitle: vTitle.toString(),
              typeId: typeId.toString(),
              videoType: vType.toString(),
              subVideoType: subVideoType.toString(),
              productPackage: rentProductId,
              currency: '',
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    }
    printLog("paymentForRent isRented ====> $isRented");
    return isRented;
  }

  static Future<dynamic> buildWebAlertDialog(
    BuildContext context,
    String pageName,
    String? reqData,
    String newPage,
  ) async {
    Widget? child;
    if (pageName == "profileedit") {
      child = WebProfileEdit(
        newPage: RoutesConstant.editProfilePage,
        oldPage: newPage,
        reqText: reqData,
      );
    }
    dynamic result = await showDialog<dynamic>(
      context: context,
      useSafeArea: true,
      barrierDismissible: (pageName == "search") ? true : false,
      builder: (BuildContext context) {
        return Dialog(
          alignment: Alignment.topCenter,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          insetPadding: EdgeInsets.fromLTRB(
            (MediaQuery.of(context).size.width > 900) ? 50 : 30,
            (MediaQuery.of(context).size.width > 900) ? 50 : 30,
            (MediaQuery.of(context).size.width > 900) ? 50 : 30,
            (MediaQuery.of(context).size.width > 900) ? 50 : 30,
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          backgroundColor: (pageName == "search") ? transparent : lightBlack,
          child: child,
        );
      },
    );

    printLog("buildWebAlertDialog result ====> $result");
    return result;
  }

  static Future<dynamic> pushWebPage({
    required BuildContext context,
    required Widget newChild,
  }) async {
    printLog("pushWebPage newChild ============> $newChild");
    dynamic result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return newChild;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
    printLog("pushWebPage result =======> $result");
    return result;
  }

  static Future<dynamic> pushReplaceWebPage({
    required BuildContext context,
    required Widget newChild,
  }) async {
    printLog("pushReplaceWebPage newChild ============> $newChild");
    dynamic result = await Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return newChild;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
    printLog("pushReplaceWebPage result =======> $result");
    return result;
  }

  /* ========== Referral Dialog ========== */
  static Future<String?> showReferralDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final result = await showGeneralDialog<String?>(
      context: context,
      barrierDismissible: false,
      barrierColor: black, // [TASK-1]
      pageBuilder: (ctx, anim, secondAnim) {
        final bool isWide = kIsWeb || MediaQuery.of(ctx).size.width > 600;
        return Material(
          color: appBgColor,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 480.0 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back / close button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(null),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: black, // [TASK-1]
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title
                      MyText(
                        color: titleTextColor,
                        text: 'enter_referral_code',
                        multilanguage: true,
                        fontsizeNormal: 26,
                        fontsizeWeb: 28,
                        fontweight: FontWeight.bold,
                        maxline: 2,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 10),
                      // Subtitle
                      MyText(
                        color: descTextColor,
                        text: 'referral_code_subtitle',
                        multilanguage: true,
                        fontsizeNormal: 14,
                        fontsizeWeb: 15,
                        fontweight: FontWeight.w400,
                        maxline: 2,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 30),
                      // Text field
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: titleTextColor),
                        decoration: InputDecoration(
                          hintText: Locales.string(ctx, 'referral_code_hint'),
                          hintStyle: const TextStyle(color: descTextColor),
                          filled: true,
                          fillColor: lightBlack,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: colorPrimary,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: colorPrimary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Next button
                      GestureDetector(
                        onTap: () {
                          final code = controller.text.trim();
                          Navigator.of(ctx).pop(code.isEmpty ? null : code);
                        },
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [colorPrimary, colorPrimaryDark],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: MyText(
                            color: appBgColor,
                            text: 'next',
                            multilanguage: true,
                            fontsizeNormal: 17,
                            fontsizeWeb: 18,
                            fontweight: FontWeight.bold,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.center,
                            fontstyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Skip button
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: MyText(
                            color: titleTextColor,
                            text: 'skip',
                            multilanguage: true,
                            fontsizeNormal: 16,
                            fontsizeWeb: 17,
                            fontweight: FontWeight.bold,
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
          ),
        );
      },
    );
    return result;
  }
  /* ========== Referral Dialog ========== */

  static bool checkLoginUser(BuildContext context) {
    if (Constant.userID != null) {
      return true;
    }
    openLogin(context: context, newPage: RoutesConstant.loginSocialPage);
    return false;
  }

  static Future<dynamic> openLogin({
    required BuildContext context,
    required String newPage,
  }) async {
    printLog("<<<<<<<< OPEN LOGIN >>>>>>>>");
    if ((kIsWeb || Constant.isTV)) {
      if (!context.mounted) return;
      dynamic result = await openWebDialog(
        context: context,
        newPage: RoutesConstant.loginSocialPage,
        oldPage: newPage,
        reqText: '',
      );
      return result;
    }
    if (!context.mounted) return;
    dynamic result = Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginSocial();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
    return result;
  }

  static Future<dynamic> openWebDialog({
    required BuildContext context,
    required String newPage,
    required String oldPage,
    required String reqText,
  }) async {
    dynamic result = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: appBgColor,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (BuildContext context, animation, secondaryAnimation) {
        return WebDialogs(
          dialogType: newPage,
          newPage: newPage,
          oldPage: oldPage,
          reqText: reqText,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        Tween<Offset> tween;
        if (newPage == RoutesConstant.loginSocialPage) {
          tween = Tween(begin: const Offset(0, 1), end: const Offset(0, 0));
        } else {
          tween = Tween(begin: const Offset(0, 0), end: const Offset(0, 0));
        }
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
    return result;
  }

  /* ========= Logout Device ========= */
  static Future<void> logoutFromApp(
    BuildContext context,
    int deviceSyncId,
    int deviceType,
    String deviceToken,
    String deviceId,
  ) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    LoadingOverlay().show(context);
    await profileProvider.logoutDevice(
      deviceSyncId,
      deviceType,
      deviceToken,
      deviceId,
    );
    if (!profileProvider.loadingLogout) {
      if (!context.mounted) return;
      LoadingOverlay().hide();
      if (!context.mounted) return;
      if (profileProvider.deviceLogoutModel.status == 200) {
        if (kIsWeb) {
          showToast(profileProvider.deviceLogoutModel.message ?? "");
        } else {
          showSnackbar(
            context,
            "success",
            "${profileProvider.deviceLogoutModel.message}",
            false,
          );
        }

        /* Send Notification for Logout */
        await ApiService().sendFCMPushNotification(
          "logout",
          deviceToken,
          deviceType,
        );
      } else {
        if (kIsWeb) {
          showToast(profileProvider.deviceLogoutModel.message ?? "");
        } else {
          showSnackbar(
            context,
            "fail",
            "${profileProvider.deviceLogoutModel.message}",
            false,
          );
        }
      }
    }
  }
  /* ========= Logout Device ========= */

  /* ========= Open Player ========= */
  static Future<dynamic> openPlayer({
    required BuildContext context,
    required PlayerModel playerModel,
  }) async {
    dynamic isContinue;
    if (kIsWeb) {
      /* Pod Player & Youtube Player */
      if (!context.mounted) return;
      context.go("/${RoutesConstant.playerPage}", extra: playerModel);
    } else {
      /* Better, Youtube & Vimeo Players */
      if (playerModel.uploadType == "youtube") {
        isContinue = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return PlayerYoutube(playerModel: playerModel);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          ),
        );
      } else if (playerModel.uploadType == "vimeo") {
        isContinue = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return PlayerVimeo(playerModel: playerModel);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          ),
        );
      } else if (playerModel.uploadType == "external") {
        if ((playerModel.videoUrl ?? "").contains('youtube')) {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerYoutube(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        } else if ((playerModel.videoUrl ?? "").contains("vimeo")) {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerVimeo(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        } else {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerVideo(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        }
      } else if (playerModel.uploadType == "live_stream_url") {
        if ((playerModel.videoUrl ?? "").contains('youtube')) {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerYoutube(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        } else if ((playerModel.videoUrl ?? "").contains("vimeo")) {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerVimeo(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        } else {
          isContinue = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return PlayerVideo(playerModel: playerModel);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        }
      } else if (playerModel.uploadType == Constant.vdocipherPlayType &&
          playerModel.cipherMediaDetails != null) {
        isContinue = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return PlayerVdoCipher(playerModel: playerModel);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          ),
        );
      } else {
        isContinue = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return PlayerVideo(playerModel: playerModel);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          ),
        );
      }
    }
    printLog("isContinue ===> $isContinue");
    return isContinue;
  }
  /* ========= Open Player ========= */

  /* ========= Set-up Quality URL START ========= */
  static void setQualityURLs({
    required String video320,
    required String video480,
    required String video720,
    required String video1080,
  }) {
    Map<String, String> qualityUrlList = <String, String>{};
    if (video320 != "") {
      qualityUrlList['320p'] = video320;
    }
    if (video480 != "") {
      qualityUrlList['480p'] = video480;
    }
    if (video720 != "") {
      qualityUrlList['720p'] = video720;
    }
    if (video1080 != "") {
      qualityUrlList['1080p'] = video1080;
    }
    printLog("qualityUrlList ==========> ${qualityUrlList.length}");
    Constant.resolutionsUrls.clear();
    Constant.resolutionsUrls = [];
    Constant.resolutionsUrls = qualityUrlList.entries
        .map((entry) => QualityModel(entry.key, entry.value))
        .toList();
    printLog("resolutionsUrls ==========> ${Constant.resolutionsUrls.length}");
  }
  /* ========= Set-up Quality URL END =========== */

  static void clearQualitySubtitle() {
    Constant.resolutionsUrls.clear();
    Constant.resolutionsUrls = [];
    Constant.subtitleUrls.clear();
    Constant.subtitleUrls = [];
  }

  /* ========= Set-up Subtitle URL START ========= */
  static void setSubtitleURLs({
    required String subtitleUrl1,
    required String subtitleUrl2,
    required String subtitleUrl3,
    required String subtitleLang1,
    required String subtitleLang2,
    required String subtitleLang3,
  }) {
    Map<String, String> subtitleUrlList = <String, String>{};
    if (subtitleUrl1 != "") {
      subtitleUrlList[subtitleLang1] = subtitleUrl1;
    }
    if (subtitleUrl2 != "") {
      subtitleUrlList[subtitleLang2] = subtitleUrl2;
    }
    if (subtitleUrl3 != "") {
      subtitleUrlList[subtitleLang3] = subtitleUrl3;
    }
    printLog("subtitleUrlList========> ${subtitleUrlList.length}");
    Constant.subtitleUrls.clear();
    Constant.subtitleUrls = [];
    Constant.subtitleUrls = subtitleUrlList.entries
        .map((entry) => SubTitleModel(entry.key, entry.value))
        .toList();
    printLog("subtitleUrls ==========> ${Constant.subtitleUrls.length}");
  }
  /* ========= Set-up Subtitle URL END =========== */

  /* Update Required profile data before Payment START ************************/
  static Widget dataUpdateDialog(
    BuildContext context, {
    required bool isNameReq,
    required bool isEmailReq,
    required bool isMobileReq,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController mobileController,
  }) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: Container(
        width: Dimens.isBigScreen(context)
            ? (MediaQuery.of(context).size.width * 0.3)
            : (MediaQuery.of(context).size.width),
        padding: const EdgeInsets.all(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* Title & Subtitle */
            Container(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    color: titleTextColor,
                    text: "update_profile",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 16,
                    fontsizeWeb: 16,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    color: descTextColor,
                    text: "update_profile_desc",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 13,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w500,
                    maxline: 3,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),

            /* Fullname */
            const SizedBox(height: 30),
            if (isNameReq)
              buildTextFormField(
                controller: nameController,
                hintText: "fullname",
                inputType: TextInputType.name,
                readOnly: false,
              ),

            /* Email */
            if (isEmailReq)
              buildTextFormField(
                controller: emailController,
                hintText: "email_address",
                inputType: TextInputType.emailAddress,
                readOnly: false,
              ),

            /* Mobile */
            if (isMobileReq)
              buildTextFormField(
                controller: mobileController,
                hintText: "mobile_number",
                inputType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                readOnly: false,
              ),
            const SizedBox(height: 5),

            /* Cancel & Update Buttons */
            Container(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /* Cancel */
                  InkWell(
                    onTap: () {
                      final profileEditProvider = Provider.of<ProfileProvider>(
                        context,
                        listen: false,
                      );
                      if (!profileEditProvider.loadingUpdate) {
                        if (kIsWeb) {
                          if (context.canPop()) {
                            context.pop(false);
                          }
                        } else {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, false);
                          }
                        }
                      }
                    },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 75),
                      height: 50,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: descTextColor, width: .5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: MyText(
                        color: descTextColor,
                        text: "cancel",
                        multilanguage: true,
                        textalign: TextAlign.center,
                        fontsizeNormal: 16,
                        fontsizeWeb: 16,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.w500,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  /* Submit */
                  Consumer<ProfileProvider>(
                    builder: (context, profileEditProvider, child) {
                      if (profileEditProvider.loadingUpdate) {
                        return Container(
                          width: 100,
                          height: 50,
                          padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                          alignment: Alignment.center,
                          child: pageLoader(),
                        );
                      }
                      return InkWell(
                        onTap: () async {
                          SharedPre sharedPref = SharedPre();
                          final fullName = nameController.text
                              .toString()
                              .trim();
                          final emailAddress = emailController.text
                              .toString()
                              .trim();
                          final mobileNumber = mobileController.text
                              .toString()
                              .trim();

                          printLog(
                            "fullName =======> $fullName ; required ========> $isNameReq",
                          );
                          printLog(
                            "emailAddress ===> $emailAddress ; required ====> $isEmailReq",
                          );
                          printLog(
                            "mobileNumber ===> $mobileNumber ; required ====> $isMobileReq",
                          );
                          if (isNameReq && fullName.isEmpty) {
                            Utils.showToast(
                              Locales.string(context, "enter_name"),
                            );
                          } else if (isEmailReq && emailAddress.isEmpty) {
                            Utils.showToast(
                              Locales.string(context, "enter_email"),
                            );
                          } else if (isMobileReq && mobileNumber.isEmpty) {
                            Utils.showToast(
                              Locales.string(context, "enter_mobile_toast"),
                            );
                          } else if (isEmailReq &&
                              !EmailValidator.validate(emailAddress)) {
                            Utils.showToast(
                              Locales.string(context, "enter_valid_email"),
                            );
                          } else {
                            final profileEditProvider =
                                Provider.of<ProfileProvider>(
                                  context,
                                  listen: false,
                                );
                            profileEditProvider.setUpdateLoading(true);

                            await profileEditProvider.getUpdateDataForPayment(
                              fullName,
                              emailAddress,
                              mobileNumber,
                            );
                            if (!profileEditProvider.loadingUpdate) {
                              profileEditProvider.setUpdateLoading(false);
                              if (profileEditProvider.successModel.status ==
                                  200) {
                                if (isNameReq) {
                                  await sharedPref.save(
                                    'userfullname',
                                    fullName,
                                  );
                                }
                                if (isEmailReq) {
                                  await sharedPref.save(
                                    'useremail',
                                    emailAddress,
                                  );
                                }
                                if (isMobileReq) {
                                  await sharedPref.save(
                                    'usermobile',
                                    mobileNumber,
                                  );
                                }
                                if (context.mounted) {
                                  if (kIsWeb) {
                                    if (context.canPop()) {
                                      context.pop(false);
                                    }
                                  } else {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context, true);
                                    }
                                  }
                                }
                              } else {
                                Utils.showToast(
                                  "${profileEditProvider.successModel.message}",
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 75),
                          height: 50,
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(5),
                            shape: BoxShape.rectangle,
                          ),
                          child: MyText(
                            color: black,
                            text: "submit",
                            textalign: TextAlign.center,
                            fontsizeNormal: 16,
                            fontsizeWeb: 16,
                            multilanguage: true,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w700,
                            fontstyle: FontStyle.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType inputType,
    required bool readOnly,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: kIsWeb ? Dimens.textFieldHeightWeb : Dimens.textFieldHeight,
      ),
      margin: const EdgeInsets.only(bottom: 25),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        textInputAction: TextInputAction.next,
        obscureText: false,
        maxLines: 1,
        readOnly: readOnly,
        cursorColor: colorAccent,
        cursorRadius: const Radius.circular(2),
        decoration: InputDecoration(
          filled: true,
          isDense: false,
          fillColor: transparent,
          focusedBorder: const GradientOutlineInputBorder(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorPrimary, colorPrimary],
            ),
            width: 1,
          ),
          border: GradientOutlineInputBorder(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorPrimary.withValues(alpha: 0.5),
                colorPrimary.withValues(alpha: 0.5),
              ],
            ),
            width: 1,
          ),
          label: MyText(
            multilanguage: true,
            color: titleTextColor,
            text: hintText,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
            fontsizeNormal: 14,
            fontsizeWeb: 16,
            fontweight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
        style: kIsWeb
            ? const TextStyle(
                fontSize: 16,
                color: white,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
              )
            : GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: white,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
      ),
    );
  }
  /* *********************** Update Required profile data before Payment END */

  static void getCurrencySymbol() async {
    SharedPre sharedPref = SharedPre();
    Constant.currencySymbol = await sharedPref.read("currency_code") ?? "";
    printLog('Constant currencySymbol ==> ${Constant.currencySymbol}');
    Constant.currency = await sharedPref.read("currency") ?? "";
    printLog('Constant currency ==> ${Constant.currency}');
  }

  /* For Stripe Web ***************** */
  static Future<void> savePayParams({
    required String payType,
    required String itemId,
    required String price,
    required String itemTitle,
    required String typeId,
    required String videoType,
    required String productPackage,
    required String currency,
    required String paymentId,
  }) async {
    SharedPre sharedPref = SharedPre();
    await sharedPref.save("payType", payType);
    await sharedPref.save("itemId", itemId);
    await sharedPref.save("price", price);
    await sharedPref.save("itemTitle", itemTitle);
    await sharedPref.save("typeId", typeId);
    await sharedPref.save("videoType", videoType);
    await sharedPref.save("productPackage", productPackage);
    await sharedPref.save("currency", currency);
    await sharedPref.save("paymentId", paymentId);
  }

  static Future<void> clearPayParams() async {
    SharedPre sharedPref = SharedPre();
    await sharedPref.remove("payType");
    await sharedPref.remove("itemId");
    await sharedPref.remove("price");
    await sharedPref.remove("itemTitle");
    await sharedPref.remove("typeId");
    await sharedPref.remove("videoType");
    await sharedPref.remove("productPackage");
    await sharedPref.remove("currency");
    await sharedPref.remove("paymentId");
  }
  /* ***************** For Stripe Web */

  static Future<void> saveUserCreds({
    required dynamic userID,
    required userName,
    required fullName,
    required userEmail,
    required userMobile,
    required userImage,
    required userPremium,
    required userType,
    required deviceType,
    required deviceToken,
  }) async {
    SharedPre sharedPref = SharedPre();
    if (userID != null) {
      await sharedPref.save("userid", userID);
      await sharedPref.save("username", userName);
      await sharedPref.save("userfullname", fullName);
      await sharedPref.save("useremail", userEmail);
      await sharedPref.save("usermobile", userMobile);
      await sharedPref.save("userimage", userImage);
      await sharedPref.save("userpremium", userPremium);
      await sharedPref.save("usertype", userType);
      await sharedPref.save("devicetype", deviceType);
      await sharedPref.save("devicetoken", deviceToken);
    } else {
      await sharedPref.remove("userid");
      await sharedPref.remove("username");
      await sharedPref.remove("userfullname");
      await sharedPref.remove("userimage");
      await sharedPref.remove("useremail");
      await sharedPref.remove("usermobile");
      await sharedPref.remove("userpremium");
      await sharedPref.remove("usertype");
      await sharedPref.remove("devicetype");
      await sharedPref.remove("devicetoken");
      await sharedPref.remove("useriskid");
    }
    Constant.userID = await sharedPref.read("userid");
    printLog('setUserId userID ==> ${Constant.userID}');
  }

  static Future<void> saveUserPaymentCreds({
    required dynamic userID,
    required userName,
    required fullName,
    required userEmail,
    required userMobile,
  }) async {
    SharedPre sharedPref = SharedPre();
    if (userID != null) {
      await sharedPref.save("userid", userID);
      await sharedPref.save("username", userName);
      await sharedPref.save("userfullname", fullName);
      await sharedPref.save("useremail", userEmail);
      await sharedPref.save("usermobile", userMobile);
    } else {
      await sharedPref.remove("userid");
      await sharedPref.remove("username");
      await sharedPref.remove("userfullname");
      await sharedPref.remove("userimage");
      await sharedPref.remove("useremail");
      await sharedPref.remove("usermobile");
      await sharedPref.remove("userpremium");
      await sharedPref.remove("usertype");
      await sharedPref.remove("devicetype");
      await sharedPref.remove("devicetoken");
      await sharedPref.remove("useriskid");
    }
    Constant.userID = await sharedPref.read("userid");
    printLog('setUserId userID ==> ${Constant.userID}');
  }

  static Future<bool> checkParentLock() async {
    SharedPre sharedPre = SharedPre();
    bool? isParentLock = await sharedPre.readBool(Constant.parentLockKey);
    printLog('checkParentLock isParentLock ==> $isParentLock');
    return isParentLock ?? false;
  }

  static Future<void> setParentLock(bool parentLockStatus) async {
    printLog('setParentLock parentLockStatus ==> $parentLockStatus');
    SharedPre sharedPre = SharedPre();
    await sharedPre.saveBool(Constant.parentLockKey, parentLockStatus);
    bool? isParentLock = await checkParentLock();
    printLog('setParentLock isParentLock ==> $isParentLock');
  }

  static Future<bool> checkPremiumUser() async {
    SharedPre sharedPre = SharedPre();
    String? isPremiumBuy = await sharedPre.read("userpremium");
    printLog('checkPremiumUser isPremiumBuy ==> $isPremiumBuy');
    if (isPremiumBuy != null && isPremiumBuy == "1") {
      return true;
    } else {
      return false;
    }
  }

  static void updatePremium(String isPremiumBuy) async {
    printLog('updatePremium isPremiumBuy ==> $isPremiumBuy');
    SharedPre sharedPre = SharedPre();
    await sharedPre.save("userpremium", isPremiumBuy);
    String? isPremium = await sharedPre.read("userpremium");
    printLog('updatePremium ===============> $isPremium');
  }

  static Future<void> setUserMode(bool? userIsKid) async {
    SharedPre sharedPref = SharedPre();
    if (userIsKid != null) {
      await sharedPref.saveBool(Constant.profileUserKey, userIsKid);
    } else {
      await sharedPref.remove(Constant.profileUserKey);
    }
    Constant.userIsKid = await sharedPref.readBool(Constant.profileUserKey);
    printLog('setUserMode userIsKid ==> ${Constant.userIsKid}');
  }

  static Future<void> setUserId(dynamic userID) async {
    SharedPre sharedPref = SharedPre();
    if (userID != null) {
      await sharedPref.save("userid", userID);
    } else {
      await sharedPref.remove("userid");
      await sharedPref.remove("username");
      await sharedPref.remove("userfullname");
      await sharedPref.remove("userimage");
      await sharedPref.remove("useremail");
      await sharedPref.remove("usermobile");
      await sharedPref.remove("userpremium");
      await sharedPref.remove("usertype");
      await sharedPref.remove("devicetype");
      await sharedPref.remove("devicetoken");
      await sharedPref.remove("useriskid");
    }
    Constant.userID = await sharedPref.read("userid");
    printLog('setUserId userID ==> ${Constant.userID}');
  }

  static Future<void> setFirstTime(dynamic value) async {
    SharedPre sharedPref = SharedPre();
    await sharedPref.save("seen", value);
    String? seenValue = await sharedPref.read("seen");
    printLog('setFirstTime seen ==> $seenValue');
  }

  static Future<String> getPrivacyTandCText(
    String privacyUrl,
    String termsConditionUrl,
  ) async {
    printLog('privacyUrl ==> $privacyUrl');
    printLog('T&C Url =====> $termsConditionUrl');

    String strPrivacyAndTNC =
        "<p style=color:white; > By continuing , I understand and agree with <a href=$privacyUrl>Privacy Policy</a> and <a href=$termsConditionUrl>Terms and Conditions</a> of ${Constant.appName}. </p>";

    printLog('strPrivacyAndTNC =====> $strPrivacyAndTNC');
    return strPrivacyAndTNC;
  }

  static Future<void> deleteCacheDir() async {
    if (!kIsWeb && Platform.isAndroid) {
      var tempDir = await getTemporaryDirectory();

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  static List<int> getVisibleIndexes({
    required ScrollController controller,
    required double itemWidth,
    required double spacing,
    required int itemCount,
  }) {
    final double scrollOffset = controller.offset;
    final double viewportWidth = controller.position.viewportDimension;

    final int firstVisibleIndex = (scrollOffset / (itemWidth + spacing))
        .floor();
    final int lastVisibleIndex =
        ((scrollOffset + viewportWidth) / (itemWidth + spacing)).ceil();

    // Clamp the values to valid range
    final int start = firstVisibleIndex.clamp(0, itemCount - 1);
    final int end = lastVisibleIndex.clamp(0, itemCount - 1);

    return List.generate(end - start + 1, (i) => start + i);
  }

  static void scrollContentView({
    required BuildContext context,
    required bool forward,
    required ScrollController scrollController,
  }) {
    double scrollAmount = MediaQuery.of(context).size.width / 2;
    if (scrollController.hasClients) {
      if (forward) {
        scrollController.animateTo(
          scrollController.offset + scrollAmount,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        scrollController.animateTo(
          scrollController.offset - scrollAmount,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  static BoxDecoration subscribeGradBorderBG(
    bool isBuy,
    double radius,
    double border,
  ) {
    if (isBuy) {
      return BoxDecoration(
        border: GradientBoxBorder(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[colorPrimary, colorPrimary],
          ),
          width: border,
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[complimentryColor, colorAccent],
        ),
        borderRadius: BorderRadius.circular(radius),
        shape: BoxShape.rectangle,
      );
    }
    return BoxDecoration(
      border: GradientBoxBorder(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            colorPrimary,
            colorPrimaryDark,
            colorAccent,
            complimentryColor,
          ],
        ),
        width: border,
      ),
      color: black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradientBGWithCenter(
    Color colorStart,
    Color colorCenter,
    Color colorEnd,
    double radius,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[colorStart, colorCenter, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradientBGTTB(
    Color colorStart,
    Color colorCenter,
    Color colorEnd,
    double radius,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colorStart, colorCenter, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static Widget buildGradLine() {
    return Container(
      height: 0.5,
      decoration: Utils.setGradTTBBGWithBorder(
        colorPrimaryDark.withValues(alpha: 0.4),
        colorPrimary.withValues(alpha: 0.4),
        transparent,
        0,
        0,
      ),
    );
  }

  static BoxDecoration setBackground(Color color, double radius) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setBGWithBorder(
    Color color,
    Color borderColor,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: border),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradLTRBorderWithBG(
    Color colorStart,
    Color colorEnd,
    Color bgColor,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      border: GradientBoxBorder(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[colorStart, colorEnd],
        ),
        width: border,
      ),
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradTTBBorderWithBG(
    Color colorTop,
    Color colorBottom,
    Color bgColor,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      border: GradientBoxBorder(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[colorTop, colorBottom],
        ),
        width: border,
      ),
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradTTBBorderAndGradBG(
    Color colorTop,
    Color colorBottom,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colorTop, colorBottom],
      ),
      border: GradientBoxBorder(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[colorTop, colorBottom],
        ),
        width: border,
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradLTRBGWithBorder(
    Color colorStart,
    Color colorEnd,
    Color borderColor,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      border: Border.all(color: borderColor, width: border),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[colorStart, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradTTBBGWithBorder(
    Color colorStart,
    Color colorEnd,
    Color borderColor,
    double radius,
    double border,
  ) {
    return BoxDecoration(
      border: Border.all(color: borderColor, width: border),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colorStart, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradBGWithCenter(
    Color colorStart,
    Color colorCenter,
    Color colorEnd,
    double radius,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[colorStart, colorCenter, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradTTBBGWithCenter(
    Color colorTop,
    Color colorCenter,
    Color colorBottom,
    double radius,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colorTop, colorCenter, colorBottom],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static BoxDecoration setGradTTBWithCenter(
    Color colorStart,
    Color colorCenter,
    Color colorEnd,
    double radius,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colorStart, colorCenter, colorEnd],
      ),
      borderRadius: BorderRadius.circular(radius),
      shape: BoxShape.rectangle,
    );
  }

  static Widget buildCloseBtn(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      focusColor: gray.withValues(alpha: 0.5),
      onTap: () {
        Utils.exitPage(context);
      },
      child: Container(
        padding: const EdgeInsets.all(5.0),
        child: SimpleShadow(
          color: colorPrimaryDark,
          sigma: 1,
          child: MyImage(
            height: 18,
            width: 18,
            imagePath: "ic_close.png",
            fit: BoxFit.contain,
            color: white,
          ),
        ),
      ),
    );
  }

  static Widget buildBackBtnDesign(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: MyImage(
        height: 17,
        width: 17,
        imagePath: "back.png",
        fit: BoxFit.contain,
        color: white,
      ),
    );
  }

  static Widget buildRentPremiumTAG({
    required BuildContext context,
    required int isPremium,
    required int isRent,
    required int rentPrice,
  }) {
    if (isPremium == 1 && isRent == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(
              minHeight: kIsWeb ? 10 : 15,
              minWidth: kIsWeb ? 25 : 30,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(
              kIsWeb ? 8 : 5,
              3,
              kIsWeb ? 8 : 5,
              3,
            ),
            decoration: BoxDecoration(
              color: complimentryColor,
              border: Border.all(color: white, width: 0.7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: MyText(
              color: titleTextColor,
              text: "Premium",
              textalign: TextAlign.center,
              fontsizeNormal: 8,
              fontsizeWeb: 12,
              fontweight: FontWeight.w600,
              maxline: 1,
              multilanguage: false,
              overflow: TextOverflow.ellipsis,
              fontstyle: FontStyle.normal,
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: kIsWeb ? 10 : 15,
              minWidth: kIsWeb ? 25 : 30,
            ),
            margin: const EdgeInsets.only(top: 5),
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(
              kIsWeb ? 8 : 5,
              3,
              kIsWeb ? 8 : 5,
              3,
            ),
            decoration: BoxDecoration(
              color: colorAccent,
              border: Border.all(color: white, width: 0.7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: MyText(
              color: titleTextColor,
              text: "Rent : ${Constant.currencySymbol}$rentPrice",
              textalign: TextAlign.center,
              fontsizeNormal: 8,
              fontsizeWeb: 12,
              fontweight: FontWeight.w600,
              maxline: 1,
              multilanguage: false,
              overflow: TextOverflow.ellipsis,
              fontstyle: FontStyle.normal,
            ),
          ),
        ],
      );
    } else if (isPremium == 1 || isRent == 1) {
      return Container(
        constraints: const BoxConstraints(
          minHeight: kIsWeb ? 10 : 15,
          minWidth: kIsWeb ? 25 : 30,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(
          kIsWeb ? 8 : 5,
          3,
          kIsWeb ? 8 : 5,
          3,
        ),
        decoration: BoxDecoration(
          color: (isRent == 1) ? colorAccent : complimentryColor,
          border: Border.all(color: white, width: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
        ),
        child: MyText(
          color: titleTextColor,
          text: (isRent == 1)
              ? "Rent : ${Constant.currencySymbol}$rentPrice"
              : "Premium",
          textalign: TextAlign.center,
          fontsizeNormal: 8,
          fontsizeWeb: 12,
          fontweight: FontWeight.w600,
          maxline: 1,
          multilanguage: false,
          overflow: TextOverflow.ellipsis,
          fontstyle: FontStyle.normal,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  static List<StaggeredGridTile> buildGroupedTiles({
    required int dataCount,
    required Widget Function({required int position}) contentItem,
  }) {
    List<StaggeredGridTile> tiles = [];

    for (int i = 0; i < dataCount;) {
      // Pattern: Big (i), Small stacked (i+1, i+2)
      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 4,
            mainAxisCellCount: 6,
            child: contentItem(position: i++),
          ),
        );
      }

      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }

      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }

      // Pattern: Row of 3 small (i+3, i+4, i+5)
      for (int j = 0; j < 3 && i < dataCount; j++) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }

      // Pattern: Small (i), Big (i+1), Small (i+2)
      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }

      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 4,
            mainAxisCellCount: 6,
            child: contentItem(position: i++),
          ),
        );
      }

      if (i < dataCount) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }

      // Row of 3 small again
      for (int j = 0; j < 3 && i < dataCount; j++) {
        tiles.add(
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 3,
            child: contentItem(position: i++),
          ),
        );
      }
    }

    return tiles;
  }

  static AppBar myAppBar(
    BuildContext context,
    String appBarTitle,
    bool multilanguage,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: appBgColor,
      centerTitle: true,
      title: MyText(
        color: colorPrimary,
        text: appBarTitle,
        multilanguage: multilanguage,
        fontsizeNormal: 16,
        fontsizeWeb: 18,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        fontweight: FontWeight.bold,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  static AppBar myAppBarWithBack(
    BuildContext context,
    String appBarTitle,
    bool multilanguage,
  ) {
    return AppBar(
      elevation: 5,
      backgroundColor: appBgColor,
      centerTitle: true,
      leading: IconButton(
        autofocus: true,
        focusColor: white.withValues(alpha: 0.5),
        onPressed: () {
          Utils.exitPage(context);
        },
        icon: MyImage(
          imagePath: "back.png",
          fit: BoxFit.contain,
          height: 17,
          width: 17,
          color: white,
        ),
      ),
      title: MyText(
        text: appBarTitle,
        multilanguage: multilanguage,
        fontsizeNormal: 16,
        fontsizeWeb: 18,
        fontstyle: FontStyle.normal,
        fontweight: FontWeight.bold,
        textalign: TextAlign.center,
        color: colorPrimary,
      ),
    );
  }

  static AppBar myAppBarWithOnlyActions(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: appBgColor,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          autofocus: true,
          focusColor: white.withValues(alpha: 0.4),
          onPressed: () {
            exitPage(context);
          },
          icon: MyImage(
            imagePath: "ic_close.png",
            fit: BoxFit.contain,
            height: 17,
            width: 17,
            color: titleTextColor,
          ),
        ),
      ],
    );
  }

  static Widget pageLoader() {
    return const Align(
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: colorPrimary, strokeWidth: 2.5),
    );
  }

  static Widget pageLoaderWithStroke({required double strokeWidth}) {
    return Align(
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(colorPrimary),
        strokeWidth: strokeWidth,
      ),
    );
  }

  static Widget progressWithPercentage(dynamic progress) {
    return Align(
      alignment: Alignment.center,
      child: CircularPercentIndicator(
        radius: 35,
        lineWidth: 2.0,
        percent: progress,
        progressColor: complimentryColor,
      ),
    );
  }

  static void showSnackbar(
    BuildContext context,
    String showFor,
    String message,
    bool multilanguage,
  ) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.fixed,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: transparent,
      elevation: 0,
      padding: EdgeInsets.only(
        left: kIsWeb
            ? (Dimens.isBigScreen(context)
                  ? (MediaQuery.of(context).size.width * 0.3)
                  : 16)
            : 16,
        right: kIsWeb
            ? (Dimens.isBigScreen(context)
                  ? (MediaQuery.of(context).size.width * 0.3)
                  : 16)
            : 16,
        bottom: 16,
      ),
      content: Container(
        constraints: const BoxConstraints(minHeight: 60),
        alignment: Alignment.center,
        decoration: Utils.setBackground(
          showFor == "fail"
              ? failureBG
              : showFor == "warning"
              ? warningBG
              : showFor == "info"
              ? infoBG
              : showFor == "success"
              ? successBG
              : complimentryColor,
          4,
        ),
        padding: const EdgeInsets.all(15),
        child: MyText(
          text: message,
          multilanguage: multilanguage,
          fontstyle: FontStyle.normal,
          fontsizeNormal: 14,
          fontsizeWeb: 16,
          maxline: 5,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          color: white,
          textalign: TextAlign.center,
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static String withSuffix(int number) {
    var shortForm = "";
    if (number < 1000) {
      shortForm = number.toString();
    } else if (number >= 1000 && number < 1000000) {
      shortForm = "${(number / 1000).toStringAsFixed(1)}K";
    } else if (number >= 1000000 && number < 1000000000) {
      shortForm = "${(number / 1000000).toStringAsFixed(1)}M";
    } else if (number >= 1000000000 && number < 1000000000000) {
      shortForm = "${(number / 1000000000).toStringAsFixed(1)}B";
    }
    return shortForm;
  }

  static String convertHalfStopToVLine(String strText) {
    return strText.replaceAll(',', ' |');
  }

  static String convertToColonText(int timeInMilli) {
    String convTime = "";

    try {
      if (timeInMilli > 0) {
        int seconds = ((timeInMilli / 1000) % 60).toInt();
        int minutes = ((timeInMilli / (1000 * 60)) % 60).toInt();
        int hours = ((timeInMilli / (1000 * 60 * 60)) % 24).toInt();

        if (hours >= 1) {
          if (minutes > 0 && seconds > 0) {
            convTime = "$hours : $minutes : $seconds hr";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "$hours : $minutes : 00 hr";
          } else if (minutes == 0 && seconds > 0) {
            convTime = "$hours : 00 : $seconds hr";
          } else if (minutes == 0 && seconds == 0) {
            convTime = "$hours : 00 hr";
          }
        } else if (minutes > 0) {
          if (seconds > 0) {
            convTime = "$minutes : $seconds min";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "$minutes : 00 min";
          }
        } else if (seconds > 0) {
          convTime = "00 : $seconds sec";
        }
      } else {
        convTime = "0";
      }
    } catch (e) {
      printLog("ConvTimeE Exception ==> $e");
    }
    return convTime;
  }

  static String convertTimeToText(int timeInMilli) {
    String convTime = "";

    try {
      if (timeInMilli > 0) {
        double seconds = ((timeInMilli / 1000) % 60);
        double minutes = ((timeInMilli / (1000 * 60)) % 60);
        double hours = ((timeInMilli / (1000 * 60 * 60)) % 24);

        if (hours >= 1) {
          if (minutes > 0 && seconds > 0) {
            convTime =
                "${hours.toInt()} hr ${minutes.toInt()} min ${seconds.toInt()} sec";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "${hours.toInt()} hr ${minutes.toInt()} min";
          } else if (minutes == 0 && seconds > 0) {
            convTime = "${hours.toInt()} hr ${seconds.toInt()} sec";
          } else if (minutes == 0 && seconds == 0) {
            convTime = "${hours.toInt()} hr";
          }
        } else if (minutes > 0) {
          if (seconds > 0) {
            convTime = "${minutes.toInt()} min ${seconds.toInt()} sec";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "${minutes.toInt()} min";
          }
        } else if (seconds > 0) {
          convTime = "${seconds.toInt()} sec";
        }
      } else {
        convTime = "0";
      }
    } catch (e) {
      printLog("ConvTimeE Exception ==> $e");
    }
    return convTime;
  }

  static String remainTimeInMin(int remainWatch) {
    String convTime = "";

    try {
      printLog("remainTimeInMin ==> ${(remainWatch / 1000)}");
      if (remainWatch > 0) {
        double seconds = ((remainWatch / 1000) % 60);
        double minutes = ((remainWatch / (1000 * 60)) % 60);
        double hours = ((remainWatch / (1000 * 60 * 60)) % 24);

        if (hours >= 1) {
          if (minutes > 0 && seconds > 0) {
            convTime =
                "${hours.toInt()} hr ${minutes.toInt()} min ${seconds.toInt()} sec";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "${hours.toInt()} hr ${minutes.toInt()} min";
          } else if (minutes == 0 && seconds > 0) {
            convTime = "${hours.toInt()} hr ${seconds.toInt()} sec";
          } else if (minutes == 0 && seconds == 0) {
            convTime = "${hours.toInt()} hr";
          }
        } else if (minutes > 0) {
          if (seconds > 0) {
            convTime = "${minutes.toInt()} min ${seconds.toInt()} sec";
          } else if (minutes > 0 && seconds == 0) {
            convTime = "${minutes.toInt()} min";
          }
        } else if (seconds > 0) {
          convTime = "${seconds.toInt()} sec";
        }
      } else {
        convTime = "0";
      }
    } catch (e) {
      printLog("remainTimeInMin Exception ==> $e");
    }
    return convTime;
  }

  static String remainTimeInDays(String dateString) {
    String convTime = "";

    try {
      DateTime mExpireDate = DateTime.parse(dateString);
      DateTime mCurrentDate = DateTime.now();
      if (mExpireDate.isAfter(mCurrentDate)) {
        Duration difference;
        difference = mExpireDate.difference(mCurrentDate);
        convTime = difference.inDays.toString();
      } else {
        convTime = "0";
      }
    } catch (e) {
      printLog("remainTimeInDays Exception ==> $e");
      convTime = "";
    }
    return convTime;
  }

  static String convertInMin(int remainWatch) {
    String convTime = "";

    try {
      if (remainWatch > 0) {
        double minutes = ((remainWatch / (1000 * 60)) % 60);
        double seconds = ((remainWatch / 1000) % 60);
        if (minutes >= 0 && minutes < 1) {
          convTime = "${seconds.toInt()} sec";
        } else if (minutes >= 1 && minutes < 10) {
          convTime = "0${minutes.toInt()} min";
        } else {
          convTime = "${minutes.toInt()} min";
        }
      } else {
        convTime = "00 min";
      }
    } catch (e) {
      printLog("convertInMin Exception ==> $e");
    }
    return convTime;
  }

  static String convertToStar(String mobileOREmail) {
    String finalSecureString = "";

    try {
      if (mobileOREmail.contains('+') && !mobileOREmail.contains(' ')) {
        finalSecureString = mobileOREmail.replaceRange(
          5,
          (mobileOREmail.length - 1),
          "********",
        );
      } else if (mobileOREmail.contains('+') && mobileOREmail.contains(' ')) {
        finalSecureString = mobileOREmail.replaceRange(
          mobileOREmail.indexOf(" ") + 2,
          (mobileOREmail.length - 1),
          "********",
        );
      } else if (mobileOREmail.contains('@')) {
        finalSecureString = mobileOREmail.replaceRange(
          1,
          mobileOREmail.indexOf("@") - 2,
          "********",
        );
      } else {
        finalSecureString = mobileOREmail.replaceRange(1, 9, "********");
      }
    } catch (e) {
      printLog("convertToStar Exception ==> $e");
      finalSecureString = "-";
    }
    return finalSecureString;
  }

  static double getPercentage(int totalValue, int usedValue) {
    double percentage = 0.0;
    try {
      if (totalValue != 0) {
        percentage = ((usedValue / totalValue).clamp(0.0, 1.0) * 100);
      } else {
        percentage = 0.0;
      }
    } catch (e) {
      printLog("getPercentage Exception ==> $e");
      percentage = 0.0;
    }
    percentage = (percentage.round() / 100);
    return percentage;
  }

  //Convert Html to simple String
  static String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    final String parsedString = parse(
      document.body!.text,
    ).documentElement!.text;

    return parsedString;
  }

  static Future<String> getFileUrl(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/$fileName";
  }

  static Future<File?> saveImageInStorage(dynamic imgUrl) async {
    try {
      var response = await http.get(Uri.parse(imgUrl));
      Directory? documentDirectory;
      if (Platform.isAndroid) {
        documentDirectory = await getExternalStorageDirectory();
      } else {
        documentDirectory = await getApplicationDocumentsDirectory();
      }
      File file = File(
        path.join(
          documentDirectory?.path ?? "",
          '${DateTime.now().millisecondsSinceEpoch.toString()}.png',
        ),
      );
      file.writeAsBytesSync(response.bodyBytes);
      // This is a sync operation on a real
      // app you'd probably prefer to use writeAsByte and handle its Future
      return file;
    } catch (e) {
      printLog("saveImageInStorage Exception ===> $e");
      return null;
    }
  }

  static Html htmlTexts(dynamic strText) {
    return Html(
      data: strText,
      style: {
        "body": Style(
          color: descTextColor,
          fontSize: FontSize(15),
          fontWeight: FontWeight.w500,
        ),
        "link": Style(
          color: colorPrimaryDark,
          fontSize: FontSize(15),
          fontWeight: FontWeight.w500,
        ),
      },
      onLinkTap: (url, _, _) async {
        if (await canLaunchUrl(Uri.parse(url!))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
        } else {
          throw 'Could not launch $url';
        }
      },
      shrinkWrap: false,
    );
  }

  static Future<void> redirectToUrl(String url) async {
    printLog("_launchUrl url ===> $url");
    if (await canLaunchUrl(Uri.parse(url.toString()))) {
      await launchUrl(
        Uri.parse(url.toString()),
        mode: LaunchMode.platformDefault,
      );
    } else {
      throw "Could not launch $url";
    }
  }

  static Future<void> redirectToStore() async {
    final appId = Platform.isAndroid
        ? Constant.appPackageName
        : Constant.iosAppUrl;
    final url = Uri.parse(
      Platform.isAndroid ? "market://details?id=$appId" : appId,
    );
    printLog("_launchUrl url ===> $url");
    if (await canLaunchUrl(Uri.parse(url.toString()))) {
      await launchUrl(
        Uri.parse(url.toString()),
        mode: LaunchMode.platformDefault,
      );
    } else {
      throw "Could not launch $url";
    }
  }

  static Future<void> shareApp(dynamic shareMessage) async {
    try {
      SharePlus.instance.share(
        ShareParams(text: shareMessage, subject: Constant.appName),
      );
    } catch (e) {
      printLog("shareApp Exception ===> $e");
      return;
    }
  }

  static Future<void> referCode({
    required String referralCode,
    required BuildContext context,
  }) async {
    try {
      final String appStoreLink = (!kIsWeb)
          ? (Platform.isAndroid ? Constant.androidAppUrl : Constant.iosAppUrl)
          : "";

      String hook = "Unlock premium movies and shows on ${Constant.appName}!";
      String steps = kIsWeb
          ? "Step 1️⃣: Use my Referral Code: $referralCode"
          : "Step 1️⃣: Download the app: $appStoreLink\nStep 2️⃣: Use my Referral Code: $referralCode";

      final shareMessage =
          '''
🎬 *$hook*

Don't miss out! Use my invite to get:
🎁 *Invite your friend to install the app using given link below*
🍿 *They sign up using your referral code.*
🔥 *Earn reward for each successful registration.*

$steps

Let's watch together! 🍿✨
''';

      // 4. Using SharePlus with standardized parameters
      // Note: Ensure you are using the latest version of share_plus
      if (kIsWeb) {
        printLog("referCode WEB");
        Clipboard.setData(ClipboardData(text: shareMessage));
        Utils.showToast(Locales.string(context, "copied_success"));
      } else {
        printLog("referCode OTHER");
        SharePlus.instance.share(
          ShareParams(
            text: shareMessage,
            subject: "Watch movies with me on ${Constant.appName}",
          ),
        );
      }
    } catch (e) {
      printLog("referCode Exception :=> $e");
    }
  }

  /* ***************** generate Unique OrderID START ***************** */
  static String generateRandomOrderID() {
    int getRandomNumber;
    String? finalOID;
    printLog("fixFourDigit =>>> ${Constant.fixFourDigit}");
    printLog("fixSixDigit =>>> ${Constant.fixSixDigit}");

    number.Random r = number.Random();
    int ran5thDigit = r.nextInt(9);
    printLog("Random ran5thDigit =>>> $ran5thDigit");

    int randomNumber = number.Random().nextInt(9999999);
    printLog("Random randomNumber =>>> $randomNumber");
    if (randomNumber < 0) {
      randomNumber = -randomNumber;
    }
    getRandomNumber = randomNumber;
    printLog("getRandomNumber =>>> $getRandomNumber");

    finalOID =
        "${Constant.fixFourDigit.toInt()}"
        "$ran5thDigit"
        "${Constant.fixSixDigit.toInt()}"
        "$getRandomNumber";
    printLog("finalOID =>>> $finalOID");

    return finalOID;
  }
  /* ***************** generate Unique OrderID END ***************** */

  /* ***************** Download ***************** */

  static Future<String> prepareSaveDir() async {
    String localPath = (await _getSavedDir())!;
    printLog("localPath ------------> $localPath");
    final savedDir = Directory(localPath);
    printLog("savedDir -------------> $savedDir");
    printLog("is exists ? ----------> ${savedDir.existsSync()}");
    if (!(await savedDir.exists())) {
      await savedDir.create(recursive: true);
    }
    return localPath;
  }

  static Future<String?> _getSavedDir() async {
    String? externalStorageDirPath;

    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      try {
        externalStorageDirPath = "${directory?.absolute.path}/downloads/";
      } catch (err, st) {
        printLog('failed to get downloads path: $err, $st');
        externalStorageDirPath = "${directory?.absolute.path}/downloads/";
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    printLog("externalStorageDirPath ------------> $externalStorageDirPath");
    return externalStorageDirPath;
  }

  static Future<String> prepareShowSaveDir(
    String showName,
    String seasonName,
  ) async {
    printLog("showName -------------> $showName");
    printLog("seasonName -------------> $seasonName");
    String localPath = (await _getShowSavedDir(showName, seasonName))!;
    final savedDir = Directory(localPath);
    printLog("savedDir -------------> $savedDir");
    printLog("savedDir path --------> ${savedDir.path}");
    if (!savedDir.existsSync()) {
      await savedDir.create(recursive: true);
    }
    return localPath;
  }

  static Future<String?> _getShowSavedDir(
    String showName,
    String seasonName,
  ) async {
    String? externalStorageDirPath;

    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath =
            "${directory?.path}/downloads/${showName.toLowerCase()}/${seasonName.toLowerCase()}";
      } catch (err, st) {
        printLog('failed to get downloads path: $err, $st');
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath =
            "${directory?.path}/downloads/${showName.toLowerCase()}/${seasonName.toLowerCase()}";
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          "${(await getApplicationDocumentsDirectory()).absolute.path}/downloads/${showName.toLowerCase()}/${seasonName.toLowerCase()}";
    }
    return externalStorageDirPath;
  }

  static Future<void> initializeHiveBoxes() async {
    printLog("initializeHiveBoxes userId =====> ${Constant.userID}");
    printLog("initializeHiveBoxes userIsKid ==> ${Constant.userIsKid}");
    if (kIsWeb) return;
    if (Constant.userID == null) {
      try {
        await Hive.deleteBoxFromDisk(Constant.hiveDownloadBox);
        await Hive.deleteBoxFromDisk(Constant.hiveSeasonDownloadBox);
        await Hive.deleteBoxFromDisk(Constant.hiveEpiDownloadBox);
      } on Exception catch (e) {
        printLog("initializeHiveBoxes Exception ==> $e");
      }
    }

    printLog("hiveDownloadBox =========> ${Constant.hiveDownloadBox}");
    printLog("hiveSeasonDownloadBox ===> ${Constant.hiveSeasonDownloadBox}");
    printLog("hiveEpiDownloadBox ======> ${Constant.hiveEpiDownloadBox}");
    if (Constant.userID != null) {
      if (Constant.userIsKid == true) {
        bool? isDownloadBoxExists = await Hive.boxExists(
          '${Constant.hiveDownloadBox}_${Constant.userID}_KID',
        );
        bool? isSeasonBoxExists = await Hive.boxExists(
          '${Constant.hiveSeasonDownloadBox}_${Constant.userID}_KID',
        );
        bool? isEpisodeBoxExists = await Hive.boxExists(
          '${Constant.hiveEpiDownloadBox}_${Constant.userID}_KID',
        );

        printLog("isDownloadBoxExists ===KID===> $isDownloadBoxExists");
        printLog("isSeasonBoxExists ====KID====> $isSeasonBoxExists");
        printLog("isEpisodeBoxExists ====KID===> $isEpisodeBoxExists");
        await Hive.openBox<DownloadItem>(
          '${Constant.hiveDownloadBox}_${Constant.userID}_KID',
        );
        await Hive.openBox<SessionItem>(
          '${Constant.hiveSeasonDownloadBox}_${Constant.userID}_KID',
        );
        await Hive.openBox<EpisodeItem>(
          '${Constant.hiveEpiDownloadBox}_${Constant.userID}_KID',
        );
      } else {
        bool? isDownloadBoxExists = await Hive.boxExists(
          '${Constant.hiveDownloadBox}_${Constant.userID}',
        );
        bool? isSeasonBoxExists = await Hive.boxExists(
          '${Constant.hiveSeasonDownloadBox}_${Constant.userID}',
        );
        bool? isEpisodeBoxExists = await Hive.boxExists(
          '${Constant.hiveEpiDownloadBox}_${Constant.userID}',
        );

        printLog("isDownloadBoxExists ========> $isDownloadBoxExists");
        printLog("isSeasonBoxExists ==========> $isSeasonBoxExists");
        printLog("isEpisodeBoxExists =========> $isEpisodeBoxExists");
        await Hive.openBox<DownloadItem>(
          '${Constant.hiveDownloadBox}_${Constant.userID}',
        );
        await Hive.openBox<SessionItem>(
          '${Constant.hiveSeasonDownloadBox}_${Constant.userID}',
        );
        await Hive.openBox<EpisodeItem>(
          '${Constant.hiveEpiDownloadBox}_${Constant.userID}',
        );
      }
    } else {
      await Hive.openBox<DownloadItem>(Constant.hiveDownloadBox);
      await Hive.openBox<SessionItem>(Constant.hiveSeasonDownloadBox);
      await Hive.openBox<EpisodeItem>(Constant.hiveEpiDownloadBox);
    }
  }

  static String generateRandomKey(int len) {
    final random = Random.secure();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(
      len,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String convertToHex(String input) {
    return utf8
        .encode(input)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Future<dynamic> encryptUsingFFMPEG(List<dynamic> args) async {
    // return null;

    File inputFile = args[0] as File;
    String generateKey = args[1] as String;
    String generateIVKey = args[2] as String;
    printLog("encryptUsingFFMPEG generateKey =====> $generateKey");
    printLog("encryptUsingFFMPEG generateIVKey ===> $generateIVKey");

    // Get the ProgressProvider
    final downloadProvider = Provider.of<VideoDownloadProvider>(
      args[3],
      listen: false,
    );

    final Completer<File?> completer = Completer<File?>();

    // Create a temporary file for the encrypted output
    File tempFile = File(
      (inputFile.path.replaceAll(".mp4", "aes.mp4")).toString(),
    );
    printLog("encryptUsingFFMPEG tempFile ===> $tempFile");

    try {
      /* DURATION FETCHING */
      // Get the duration of the input file
      String durationCommand = '-i ${inputFile.path} -hide_banner';
      final durationSession = await FFmpegKit.execute(durationCommand);
      final durationLog = await durationSession.getOutput();
      // Check if the log output is not null and has the expected format
      double totalDuration = 0;
      if (durationLog != null) {
        // Extract duration from the log output
        final durationMatch = RegExp(
          r'Duration:\s+(\d{2}):(\d{2}):(\d{2})\.(\d{2})',
        ).firstMatch(durationLog);
        // Calculate total duration in seconds
        if (durationMatch != null) {
          final hours = int.parse(durationMatch.group(1)!);
          final minutes = int.parse(durationMatch.group(2)!);
          final seconds = double.parse(durationMatch.group(3)!);
          totalDuration = hours * 3600 + minutes * 60 + seconds;
          printLog(
            'encryptUsingFFMPEG Encryption totalDuration ====> $totalDuration',
          ); // Duration in seconds
        } else {
          printLog('Could not find duration in log output');
        }
      } else {
        printLog('No output from duration command');
      }
      /* DURATION FETCHING */
      // FFmpeg command for AES-256-CBC encryption
      String command =
          '-i ${inputFile.path} -c:v copy -c:a copy -encryption_scheme cenc-aes-ctr -encryption_key $generateKey -encryption_kid $generateIVKey ${tempFile.path}';
      downloadProvider.setEncryptProgress(0.0);
      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          printLog('encryptUsingFFMPEG returnCode : $returnCode');
          if (ReturnCode.isSuccess(returnCode)) {
            // SUCCESS
            printLog('encryptUsingFFMPEG Successful tempFile : $tempFile');
            // Replace the original file with the encrypted temporary file
            await inputFile.delete();
            await tempFile.rename(inputFile.path);
            printLog('encryptUsingFFMPEG Successful inputFile : $inputFile');
            downloadProvider.setEncryptProgress(1.0);
            completer.complete(inputFile);
          } else {
            // ERROR
            printLog('encryptUsingFFMPEG Failed!!!');
            downloadProvider.setEncryptProgress(0.0);
            completer.complete(null);
          }
        },
        (log) {
          printLog('encryptUsingFFMPEG getMessage : ${log.getMessage()}');
        },
        (progress) async {
          // Update the progress provider here
          if (totalDuration > 0) {
            // Update the progress provider here
            printLog(
              'encryptUsingFFMPEG Decryption progressTime =====> ${progress.getTime()}',
            );
            printLog(
              'encryptUsingFFMPEG Decryption totalDuration ====> $totalDuration',
            );
            // Assuming progress.getTime() returns milliseconds
            final progressTimeInSeconds = (progress.getTime() / 1000.0)
                .roundToDouble(); // Convert to seconds
            printLog(
              'encryptUsingFFMPEG Decryption progressTimeInSeconds ====> $progressTimeInSeconds',
            );
            double percentage = progressTimeInSeconds / totalDuration;
            downloadProvider.setEncryptProgress(
              percentage.clamp(0.0, 1.0),
            ); // Clamp to 0-1
          }
        },
      );
    } catch (e) {
      printLog('encryptUsingFFMPEG Error during encryption: $e');
      downloadProvider.setEncryptProgress(0.0);
      completer.complete(null);
    }
    return completer.future;
  }

  static Future<File?> decryptUsingFFMPEG(List<dynamic> args) async {
    // return null;

    File inFile = args[0] as File;
    String generateKey = args[1] as String;
    String generateIVKey = args[2] as String;

    // Get the ProgressProvider
    final playerProvider = Provider.of<PlayerProvider>(args[3], listen: false);

    printLog("decryptUsingFFMPEG generateKey =====> $generateKey");
    printLog("decryptUsingFFMPEG generateIVKey ===> $generateIVKey");
    await deleteCacheDir();

    // Create a temporary decrypted file
    final tempDir = await getTemporaryDirectory();
    File decryptedFile = File('${tempDir.path}/${path.basename(inFile.path)}');
    printLog('decryptUsingFFMPEG inFile ==========> $inFile');
    printLog('decryptUsingFFMPEG decryptedFile ===> $decryptedFile');

    final Completer<File?> completer = Completer<File?>();
    try {
      // Check if the encrypted file exists
      bool isInFileExists = await inFile.exists();
      if (!isInFileExists) {
        printLog("decryptUsingFFMPEG Encrypted file does not exist.");
        completer.complete(null);
        return completer.future;
      }

      /* DURATION FETCHING */
      // Get the duration of the input file
      String durationCommand = '-i ${inFile.path} -hide_banner';
      final durationSession = await FFmpegKit.execute(durationCommand);
      final durationLog = await durationSession.getOutput();
      // Check if the log output is not null and has the expected format
      double totalDuration = 0;
      if (durationLog != null) {
        // Extract duration from the log output
        final durationMatch = RegExp(
          r'Duration:\s+(\d{2}):(\d{2}):(\d{2})\.(\d{2})',
        ).firstMatch(durationLog);
        // Calculate total duration in seconds
        if (durationMatch != null) {
          final hours = int.parse(durationMatch.group(1)!);
          final minutes = int.parse(durationMatch.group(2)!);
          final seconds = double.parse(durationMatch.group(3)!);
          totalDuration = hours * 3600 + minutes * 60 + seconds;
          printLog(
            'decryptUsingFFMPEG Decryption totalDuration ====> $totalDuration',
          ); // Duration in seconds
        } else {
          printLog('Could not find duration in log output');
        }
      } else {
        printLog('No output from duration command');
      }
      /* DURATION FETCHING */
      // FFmpeg command for decryption
      String command =
          '-decryption_key $generateKey -i ${inFile.path} -c:v copy -c:a copy ${decryptedFile.path}';
      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          printLog('decryptUsingFFMPEG returnCode : $returnCode');
          if (ReturnCode.isSuccess(returnCode)) {
            // SUCCESS
            printLog(
              'decryptUsingFFMPEG Decryption successful decryptedFile : $decryptedFile',
            );
            completer.complete(decryptedFile);
            playerProvider.setDecryptProgress(1.0);
          } else {
            // ERROR
            printLog('decryptUsingFFMPEG Decryption failed!!!');
            completer.complete(null);
            playerProvider.setDecryptProgress(0.0);
          }
        },
        (log) {
          printLog('decryptUsingFFMPEG getMessage : ${log.getMessage()}');
        },
        (progress) async {
          if (totalDuration > 0) {
            // Update the progress provider here
            printLog(
              'decryptUsingFFMPEG Decryption progressTime =====> ${progress.getTime()}',
            );
            printLog(
              'decryptUsingFFMPEG Decryption totalDuration ====> $totalDuration',
            );
            // Assuming progress.getTime() returns milliseconds
            final progressTimeInSeconds = (progress.getTime() / 1000.0)
                .roundToDouble(); // Convert to seconds
            printLog(
              'decryptUsingFFMPEG Decryption progressTimeInSeconds ====> $progressTimeInSeconds',
            );
            double percentage = progressTimeInSeconds / totalDuration;
            playerProvider.setDecryptProgress(
              percentage.clamp(0.0, 1.0),
            ); // Clamp to 0-1
          }
        },
      );
      printLog('decryptUsingFFMPEG decryptedFile ===> $decryptedFile');
    } catch (e) {
      printLog('decryptUsingFFMPEG Error during decryption: $e');
      completer.complete(null);
      playerProvider.setDecryptProgress(0.0);
    }
    return completer.future;
  }

  /* ***************** Download ***************** */

  /* ── Wallet ──────────────────────────────────────────────── */

  static void openWalletTopup({
    required BuildContext context,
    required String amount,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AllPayment(
            payType: 'wallet_topup',
            newPage: 'wallet',
            oldPage: 'wallet',
            reqText: '',
            producerId: '',
            itemId: 'wallet',
            price: amount,
            itemTitle: 'Wallet Topup',
            typeId: '',
            videoType: '',
            subVideoType: '',
            productPackage: '',
            currency: Constant.currency,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String formatReviewDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  static String getStarLabel(int rating, BuildContext context) {
    switch (rating) {
      case 1:
        return Locales.string(context, 'star_label_1');
      case 2:
        return Locales.string(context, 'star_label_2');
      case 3:
        return Locales.string(context, 'star_label_3');
      case 4:
        return Locales.string(context, 'star_label_4');
      case 5:
        return Locales.string(context, 'star_label_5');
      default:
        return Locales.string(context, 'tap_a_star_to_rate');
    }
  }
}
