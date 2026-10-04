import 'dart:io';
import '../utils/color.dart'; // [TASK-1]
import '../utils/constant.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'loadingoverlay.dart';

class AdHelper {
  static SharedPre sharePref = SharedPre();
  static bool? isPremiumBuy;

  static InitializationStatus? initializationStatus;

  static String? admobAdsStatus;

  static String? interstitaladid;
  static String? interstitaladidios;
  static String? rewardadid;
  static String? rewardadidios;
  static String? nativeid;
  static String? nativeidios;

  static int? _numInterstitialLoadAttempts = 0;
  static int? maxInterstitialAdclick = 0;
  static int? maxInterstitialAdIOSclick = 0;

  static int? _numRewardAttempts = 0;
  static int? maxRewardAdclick = 0;
  static int? maxRewardAdIOSclick = 0;

  // Map to track buttons that have shown ad once in this session
  static final Map<String, bool> _buttonAdShown = {};

  static var interstitalad = "";
  static var interstitalIos = "";
  static var rewardad = "";
  static var rewardadIos = "";
  static var nativead = "";
  static var nativeadios = "";

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  // Native Ad
  static NativeAd? _nativeAd;
  static int? maxNativeAdClick = 0;
  static int? maxNativeAdIOSclick = 0;
  static bool _isNativeAdLoaded = false; // track if ad is loaded

  static AdRequest request = AdRequest(nonPersonalizedAds: true);

  Future<InitializationStatus?> initGoogleMobileAds() {
    MobileAds.instance
        .initialize()
        .then((value) async {
          printLog("====== Ad Initialize ======");
          initializationStatus = value;
          printLog("Initialization done!!");
          // RequestConfiguration configuration = RequestConfiguration(
          //   testDeviceIds: ['0909832A18BBE70CF5E6BE7486DBB023'],
          // );
          // await MobileAds.instance.updateRequestConfiguration(configuration);
        })
        .onError((error, stackTrace) {
          printLog("Ad Intialize error ====> $error");
          initializationStatus = null;
        });
    return Future.value(initializationStatus);
  }

  static Future<void> getAds(BuildContext context) async {
    isPremiumBuy = await Utils.checkPremiumUser();

    admobAdsStatus = await Utils.configByStatus(
      status: Constant.admobAdsStatus,
    );

    interstitalad = await sharePref.read("interstital_ad") ?? "";
    interstitalIos = await sharePref.read("ios_interstital_ad") ?? "";
    interstitaladid = await sharePref.read("interstital_adid") ?? "";
    interstitaladidios = await sharePref.read("ios_interstital_adid") ?? "";

    rewardad = await sharePref.read("reward_ad") ?? "";
    rewardadIos = await sharePref.read("ios_reward_ad") ?? "";
    rewardadid = await sharePref.read("reward_adid") ?? "";
    rewardadidios = await sharePref.read("ios_reward_adid") ?? "";

    nativead = await sharePref.read("native_ad") ?? "";
    nativeadios = await sharePref.read("ios_native_ad") ?? "";
    nativeid = await sharePref.read("native_adid") ?? "";
    nativeidios = await sharePref.read("ios_native_adid") ?? "";

    String interstialAdClick =
        await sharePref.read("interstital_adclick") ?? "";
    String rewardAdClick = await sharePref.read("reward_adclick") ?? "";
    String interstialAdIOSClick =
        await sharePref.read("ios_interstital_adclick") ?? "";
    String rewardAdIOSClick = await sharePref.read("ios_reward_adclick") ?? "";
    String nativeAdClick = await sharePref.read("native_adclick") ?? "";
    String nativeAdIOSClick = await sharePref.read("ios_native_adclick") ?? "";

    if (interstialAdIOSClick != "") {
      maxInterstitialAdIOSclick = int.parse(interstialAdIOSClick);
    }
    if (rewardAdIOSClick != "") {
      maxRewardAdIOSclick = int.parse(rewardAdIOSClick);
    }
    if (interstialAdClick != "") {
      maxInterstitialAdclick = int.parse(interstialAdClick);
    }
    if (rewardAdClick != "") {
      maxRewardAdclick = int.parse(rewardAdClick);
    }
    if (nativeAdClick != "") {
      maxNativeAdClick = int.parse(nativeAdClick);
    }
    if (nativeAdIOSClick != "") {
      maxNativeAdIOSclick = int.parse(nativeAdIOSClick);
    }
    printLog(
      "==================== AdMob Ads status : $admobAdsStatus ====================",
    );
    printLog("isPremiumBuy : $isPremiumBuy");
    printLog("interstital : $interstitalad");
    printLog("interstitalIos : $interstitalIos");
    printLog("reward : $rewardad");
    printLog("rewardadIos : $rewardadIos");
    printLog("Native Ad iOS: $nativeadios");
    printLog("==================== Ads Click ====================");
    printLog("maxInterstitialAdclick : $maxInterstitialAdclick");
    printLog("maxRewardAdclick : $maxRewardAdclick");
    printLog("maxInterstitialAdIOSclick : $maxInterstitialAdIOSclick");
    printLog("maxRewardAdIOSclick : $maxRewardAdIOSclick");
    printLog("maxNativeAdclick : $maxNativeAdClick");
    printLog("maxNativeAdIOSclick : $maxNativeAdIOSclick");
    printLog(
      "============================================================================",
    );
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return interstitaladid.toString();
    } else if (Platform.isIOS) {
      return interstitaladidios.toString();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return rewardadid.toString();
    } else if (Platform.isIOS) {
      return rewardadidios.toString();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return nativeid.toString();
    } else if (Platform.isIOS) {
      return nativeidios.toString();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /* ********* Native Ad START ********* */
  static ValueNotifier<bool> nativeAdLoadedNotifier = ValueNotifier(false);

  static void loadNativeAd() {
    printLog('===>> loadNativeAd: $nativeAdUnitId');
    if (!((nativead == "1" && Platform.isAndroid) ||
        (nativeadios == "1" && Platform.isIOS))) {
      printLog('loadNativeAd : Native ads is disable');
      if (_nativeAd != null) {
        _nativeAd?.dispose();
      }
      _nativeAd = null;
      return;
    }

    if (nativeAdUnitId.isEmpty || nativeAdUnitId == "null") {
      printLog('🔴 loadNativeAd : Invalid nativeAdUnitId');
      if (_nativeAd != null) {
        _nativeAd?.dispose();
      }
      _nativeAd = null;
      return;
    }

    _isNativeAdLoaded = false;
    nativeAdLoadedNotifier.value = false;

    _nativeAd = NativeAd(
      request: request,
      adUnitId: nativeAdUnitId,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // or 'medium', 'small'
        mainBackgroundColor: white, // [TASK-1]
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: white, // [TASK-1]
          size: 14,
          backgroundColor: infoBG, // [TASK-1]
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: black, // [TASK-1]
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: gray, // [TASK-1]
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          printLog('✅ loadNativeAd : Loaded =====>> $ad');
          _isNativeAdLoaded = true;
          nativeAdLoadedNotifier.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          printLog('❌ loadNativeAd : Loading Error =====>> $error');
          ad.dispose();
          if (_nativeAd != null) {
            _nativeAd?.dispose();
          }
          _nativeAd = null;
          _isNativeAdLoaded = false;
          nativeAdLoadedNotifier.value = false;
        },
      ),
    );

    if (_nativeAd != null) {
      _nativeAd?.load();
    }
  }

  static Widget showNativeAd() {
    if (!kIsWeb && _isNativeAdLoaded && _nativeAd != null) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
        height: 120,
        child: AdWidget(ad: _nativeAd!),
      );
    }
    return const SizedBox.shrink();
  }
  /* ********** Native Ad END ********** */

  /* ********* Interstitial Ad START ********* */
  static Future<void> loadInterstitialAd({
    required BuildContext context,
    required VoidCallback callAction,
    bool? loadOnly,
  }) async {
    printLog(
      '===>> loadInterstitialAd : $interstitialAdUnitId ================',
    );

    if (!((interstitalad == "1" && Platform.isAndroid) ||
        (interstitalIos == "1" && Platform.isIOS))) {
      printLog('loadInterstitialAd Ad is Disable.');
      _interstitialAd = null;

      if (loadOnly != true) {
        callAction();
      }
      return;
    }
    if (interstitialAdUnitId == "null" || interstitialAdUnitId.isEmpty) {
      printLog('loadInterstitialAd adUnitId is NULL.');
      _interstitialAd = null;

      if (loadOnly != true) {
        callAction();
      }
      return;
    }
    if (_interstitialAd != null && loadOnly != true) {
      showInterstitialAd(
        context: context,
        callAction: callAction,
        loadOnly: loadOnly,
      );
      return;
    }

    if (loadOnly != true) {
      LoadingOverlay().show(context);
    }
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          printLog('loadInterstitialAd Loaded =====>> $ad');
          LoadingOverlay().hide();
          _interstitialAd = ad;
          if (loadOnly != true) {
            showInterstitialAd(
              context: context,
              callAction: callAction,
              loadOnly: loadOnly,
            );
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          printLog('loadInterstitialAd Loading Error =====>> $error');
          LoadingOverlay().hide();
          _interstitialAd = null;
          if (loadOnly != true) {
            callAction();
          }
        },
      ),
    );
  }

  static Future<void> showInterstitialAd({
    required BuildContext context,
    required VoidCallback callAction,
    bool? loadOnly,
  }) async {
    if (_interstitialAd == null) {
      printLog('<=== InterstitialAd is null ===>');
      if (loadOnly != true) {
        callAction();
      }
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        printLog('✅ InterstitialAd showed full screen.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _numInterstitialLoadAttempts = 0;
        printLog('🟡 InterstitialAd dismissed.');
        if (loadOnly != true) {
          callAction();
        }
        ad.dispose();
        _interstitialAd = null;

        /* Load Ads for Future */
        // loadInterstitialAd(context: context, callAction: () {}, loadOnly: true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        printLog('$ad onAdFailedToShowFullScreenContent: $error');
        printLog('❌ Failed to show InterstitialAd : $error');
        if (loadOnly != true) {
          callAction();
        }
        ad.dispose();
      },
    );
    _interstitialAd?.setImmersiveMode(true);
    await _interstitialAd?.show();
    _interstitialAd = null;
  }
  /* ********** Interstitial Ad END ********** */

  /* ********* Rewarded Ad START ********* */
  static Future<void> loadRewardAd({
    required BuildContext context,
    required VoidCallback callAction,
    bool? loadOnly,
  }) async {
    printLog('===>> loadRewardAd ID : $rewardedAdUnitId ================');

    if (!((rewardad == "1" && Platform.isAndroid) ||
        (rewardadIos == "1" && Platform.isIOS))) {
      _rewardedAd = null;

      if (loadOnly != true) {
        callAction();
      }
      return;
    }

    if (rewardedAdUnitId == "null" || rewardedAdUnitId.isEmpty) {
      _rewardedAd = null;

      if (loadOnly != true) {
        callAction();
      }
      return;
    }

    if (_rewardedAd != null && loadOnly != true) {
      showRewardedAd(
        context: context,
        callAction: callAction,
        loadOnly: loadOnly,
      );
      return;
    }

    if (loadOnly != true) {
      LoadingOverlay().show(context);
    }
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          printLog('loadRewardAd Loaded =====>> $ad');
          LoadingOverlay().hide();
          _rewardedAd = ad;
          if (loadOnly != true) {
            showRewardedAd(
              context: context,
              callAction: callAction,
              loadOnly: loadOnly,
            );
          }
        },
        onAdFailedToLoad: (error) {
          printLog('loadRewardAd Loading Error ===>> $error');
          LoadingOverlay().hide();
          _rewardedAd = null;
          if (loadOnly != true) {
            callAction();
          }
        },
      ),
    );
  }

  static Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback callAction,
    bool? loadOnly,
  }) async {
    if (_rewardedAd == null && loadOnly != true) {
      printLog('<=== RewardedAd is null ===>');
      callAction();
      return;
    }

    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        printLog('✅ RewardedAd showed full screen.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        printLog('🟡 RewardedAd dismissed.');
        if (loadOnly != true) {
          callAction();
        }
        ad.dispose();
        _rewardedAd = null;
        _numRewardAttempts = 0;

        /* Load Ads for Future */
        // loadRewardAd(context: context, callAction: () {}, loadOnly: true);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        printLog('❌ Failed to show RewardedAd : $error');
        if (loadOnly != true) {
          callAction();
        }
        ad.dispose();
        _rewardedAd = null;
      },
    );

    _rewardedAd?.setImmersiveMode(true);
    await _rewardedAd?.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        printLog('🎁 User earned reward: ${reward.amount} ${reward.type}');
        // You can trigger extra logic here if needed
      },
    );

    _rewardedAd = null;
  }
  /* ********** Rewarded Ad END ********** */

  static bool checkInterstialAdAndShow() {
    printLog("loadAttempts ================> $_numInterstitialLoadAttempts");
    printLog("maxInterstitialAdclick ======> $maxInterstitialAdclick");
    printLog("maxInterstitialAdIOSclick ===> $maxInterstitialAdIOSclick");
    if (!kIsWeb) {
      if (Platform.isIOS) {
        if ((_numInterstitialLoadAttempts ?? 0) >=
            (maxInterstitialAdIOSclick ?? 0)) {
          return true;
        } else {
          _numInterstitialLoadAttempts =
              (_numInterstitialLoadAttempts ?? 0) + 1;
          return false;
        }
      } else {
        if ((_numInterstitialLoadAttempts ?? 0) >=
            (maxInterstitialAdclick ?? 0)) {
          return true;
        } else {
          _numInterstitialLoadAttempts =
              (_numInterstitialLoadAttempts ?? 0) + 1;
          return false;
        }
      }
    }
    return false;
  }

  static bool checkRewardAdAndShow() {
    printLog("_numRewardAttempts =======> $_numRewardAttempts");
    printLog("maxRewardAdclick =========> $maxRewardAdclick");
    printLog("maxRewardAdIOSclick ======> $maxRewardAdIOSclick");
    if (!kIsWeb) {
      if (Platform.isIOS) {
        if ((_numRewardAttempts ?? 0) >= (maxRewardAdIOSclick ?? 0)) {
          return true;
        } else {
          _numRewardAttempts = (_numRewardAttempts ?? 0) + 1;
          return false;
        }
      } else {
        if ((_numRewardAttempts ?? 0) >= (maxRewardAdclick ?? 0)) {
          return true;
        } else {
          _numRewardAttempts = (_numRewardAttempts ?? 0) + 1;
          return false;
        }
      }
    }
    return false;
  }

  /* Check For Ads ========================= */
  static void checkAndShowAds({
    required BuildContext context,
    required VoidCallback onAdComplete,
    required String buttonKey,
    required String adType,
    bool alwaysShowAd = false,
    bool showOnByClick = false,
  }) {
    bool showAd = false;
    printLog("checkAndShowAds showOnByClick ===> $showOnByClick");
    printLog("checkAndShowAds alwaysShowAd ====> $alwaysShowAd");

    if (admobAdsStatus != "null" && admobAdsStatus == "0") {
      onAdComplete(); // ad disabled
      return;
    }

    if (isPremiumBuy == true) {
      onAdComplete(); // ad free
      return;
    }

    if (initializationStatus == null) {
      onAdComplete(); // skip ad
      return;
    }

    // First click per session
    if (!_buttonAdShown.containsKey(buttonKey) && !showOnByClick) {
      _buttonAdShown[buttonKey] = true;
      showAd = true;
    }

    // Show ad after number of clicks
    if (showOnByClick) {
      if (adType == Constant.rewardAdType) {
        if (checkRewardAdAndShow()) {
          showAd = true;
        }
      } else if (adType == Constant.interstialAdType) {
        if (checkInterstialAdAndShow()) {
          showAd = true;
        }
      }
    }

    // Show ad every time
    if (alwaysShowAd) {
      showAd = true;
    }

    if (!showAd) {
      onAdComplete(); // skip ad
      return;
    }
    printLog("checkAndShowAds showAd ==========> $showAd");

    if (adType == Constant.rewardAdType) {
      loadRewardAd(
        context: context,
        callAction: () {
          onAdComplete();
        },
      );
    } else if (adType == Constant.interstialAdType) {
      loadInterstitialAd(
        context: context,
        callAction: () {
          onAdComplete();
        },
      );
    }
  }

  /* ========================= Check For Ads */
}

class SmartBannerAd extends StatefulWidget {
  final bool? isSpacing;
  final double? bottomSpace, topSpace;
  const SmartBannerAd({
    super.key,
    this.isSpacing,
    this.bottomSpace,
    this.topSpace,
  });

  @override
  State<SmartBannerAd> createState() => _SmartBannerAdState();
}

class _SmartBannerAdState extends State<SmartBannerAd> {
  SharedPre sharePref = SharedPre();

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool? isPremiumBuy;
  String? admobAdsStatus;
  String? banneradid;
  String? banneradidios;
  var bannerad = "";
  var banneradIos = "";

  Future<void> getAds(BuildContext context) async {
    admobAdsStatus = await Utils.configByStatus(
      status: Constant.admobAdsStatus,
    );
    isPremiumBuy = await Utils.checkPremiumUser();

    bannerad = await sharePref.read("banner_ad") ?? "";
    banneradIos = await sharePref.read("ios_banner_ad") ?? "";
    banneradid = await sharePref.read("banner_adid") ?? "";
    banneradidios = await sharePref.read("ios_banner_adid") ?? "";
    printLog("================= SmartBannerAd status =================");
    printLog("admobAdsStatus : $admobAdsStatus");
    printLog("banner : $bannerad");
    printLog("banneradIos : $banneradIos");
    printLog("========================================================");
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      printLog("banner Android===>$banneradidios");
      return banneradid.toString();
    } else if (Platform.isIOS) {
      printLog("banner Unit ID IOS===>$banneradidios");
      return banneradidios.toString();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  @override
  void initState() {
    super.initState();
    getAds(context).then((_) => _loadAd());
  }

  void _loadAd() {
    if (isPremiumBuy == true) {
      _bannerAd = null;
      return;
    }
    if (admobAdsStatus != "null" && admobAdsStatus == "0") {
      _bannerAd = null;
      return;
    }
    if (bannerAdUnitId == "null" || bannerAdUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          printLog('BannerAd Loaded Successfully');
        },
        onAdFailedToLoad: (ad, error) {
          printLog('BannerAd Failed to Load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Padding(
        padding: (widget.isSpacing == true)
            ? EdgeInsets.only(
                bottom: widget.bottomSpace ?? 0,
                top: widget.topSpace ?? 0,
              )
            : EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AdSize.banner.height.toDouble(),
              width: AdSize.banner.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
