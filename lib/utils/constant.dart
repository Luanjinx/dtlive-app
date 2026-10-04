import '../model/qualitymodel.dart';
import '../model/subtitlemodel.dart';

class Constant {
  static String baseUrl =
      'https://nexstream.biz.id/api/'; // Replace with your API Path (Get from Admin panel)
  static String apiToken =
      'v25dcFLxPGg0MIGu7jkSDIJQTEEDqcZx'; // Replace with your API Token (Get from Admin panel)

  static String appName = "Javstory";
  static String appPackageName =
      "com.javstory.prjkt"; // This is used for PIP channel
  static String appleAppId = ""; // This is used for Appstore iOS App redirect
  static String appVersion = "";

  /* DeepLink */
  static String deeplinkDomain = Uri.parse(baseUrl).host;

  /* IMA Ad Tags for Player Ads */
  static const String imaAdTags =
      "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=";

  /* Vapid Key to generate Device Token For Web */
  /* Firebase console >> Project Settings >> Cloud Messaging >> Web Configuration >> Copy Key Pair >> Add in Admin's App Setting menu */
  static String? vapidKeyForWeb;
  static String? accessToken;

  /* Default Country Code */
  static const String defaultCountryCode = "US";

  /* Constant for TV check */
  static bool isTV = true;

  /* Device Info */
  static String deviceName = "";
  static String currentDeviceId = "";

  static String? userID;
  static bool? userIsKid;
  static String currencySymbol = "";
  static String currency = "";
  static const String parentLockKey = "PARENT_LOCK_STATUS";
  static const String profileUserKey = "USER_IS_KID";

  static String androidAppShareUrlDesc =
      "Let me recommend you this application\n\n$androidAppUrl";
  static String iosAppShareUrlDesc =
      "Let me recommend you this application\n\n$iosAppUrl";
  static String androidAppUrl = "";
  static String iosAppUrl = "";

  static List<QualityModel> resolutionsUrls = [];
  static List<SubTitleModel> subtitleUrls = [];

  /* Download config */
  static String bgEncryptDecryptTask = 'encrypt_decrypt_task';
  static String hiveDownloadBox = 'DOWNLOADS';
  static String hiveSeasonDownloadBox = 'DOWNLOAD_SEASON';
  static String hiveEpiDownloadBox = 'DOWNLOAD_EPISODE';
  static String videoDownloadPort = 'video_downloader_send_port';
  static String showDownloadPort = 'show_downloader_send_port';
  static String hawkVIDEOList = "myVideoList_";
  static String hawkKIDSVIDEOList = "myKidsVideoList_";
  static String hawkSHOWList = "myShowList_";
  static String hawkSEASONList = "mySeasonList_";
  static String hawkEPISODEList = "myEpisodeList_";
  /* Download config */

  static int fixFourDigit = 1317;
  static int fixSixDigit = 161613;

  /* Durations and Counts ****** */
  static int bannerDuration = 10000; // in milliseconds
  static int animationDuration = 800; // in milliseconds
  static int refreshDuration = 1500; // in milliseconds
  static int minPageContent = 10; // Minimum content fetch per request in API
  /* ****** Durations and Counts */

  /* Show Ad By Type */
  static String rewardAdType = "rewardAd";
  static String interstialAdType = "interstialAd";

  /* Stripe Checkout fields */
  // static const String webDomainURL = 'http://localhost:8080/'; //Localhost
  static const String webDomainURL =
      'https://demo.dramastream.cloud/'; //Normal Web Host
  static String? paymentMode =
      'subscription'; // Set paymentMode as 'payment' for Single Time purchase Packages (Not Recurring Packages)
  static String? publishableKey;
  static String? secretKey;
  static String? packagePriceId;
  static String? successURL;
  static String? cancelURL;
  static bool isStripePaySuccess = false;
  /* Stripe Checkout fields */

  static const String dotText = "•";

  /* *************************************************************************** */
  /* ************ DO NOT TOUCH (Change it according to the backend) ************ */
  /* *************************************************************************** */
  /* Section config START */
  /* 
      Section Type : 
      0-Dynamic, 1-Manually, 2-AI
   */
  static int dynamicContentType = 0;
  static int manualContentType = 1;
  static int aiContentType = 2;
  /* 
      Video Type : 
      1- Movies, 2- TVShow, 3- Category, 4-Language, 5- Upcoming Content, 6- Channel Content, 7- Kids Content, 8- Shorts, 
      101- Continue Watching, 102- Channel List, 103- Rent content
   */
  static int movieContentType = 1;
  static int showContentType = 2;
  static int genresType = 3; //Category Type
  static int languageType = 4;
  static int upcomingContentType = 5;
  static int channelContentType = 6;
  static int kidsContentType = 7;
  static int shortsContentType = 8; //Clips content
  static int continueWatchType = 101;
  static int channelType = 102;
  static int rentContentType = 103;
  /* Section config END */

  /* Video Cipher URL Type Key */
  static String vdocipherPlayType = "vdocipher_id";

  /* Dynamic App Setting Keys (general_setting API) ****** */
  static const String googleClientIdKey = "web_client_id";
  static const String onesignalAppIdKey = "onesignal_app_id";
  static const String playstoreIdKey = "playstore_url";
  static const String appstoreIdKey = "appstore_url";
  static const String vapIdKey = "vapid_key";
  static const String supportMobileKey = "contact";
  static const String supportEmailKey = "email";
  static const String appDescriptionKey = "app_desripation";
  static const String brandImageKey = "powered_by_image";
  static const String trailerAutoPlay = "auto_play_trailer";
  static const String parentControlStatus = "parent_control_status";
  static const String multipleDeviceSync = "multiple_device_sync";
  static const String subscriptionStatus = "subscription_status";
  static const String activeTvStatus = "active_tv_status";
  static const String watchlistStatus = "watchlist_status";
  static const String downloadStatus = "download_status";
  static const String continueWatchingStatus = "continue_watching_status";
  static const String couponStatus = "coupon_status";
  static const String rentStatus = "rent_status";
  static const String introScreenStatus = "on_boarding_screen_status";
  static const String screenRecordStatus = "screen_recording_status";
  static const String playerIMAAdsStatus = "video_player_ima_ads_status";
  static const String admobAdsStatus = "admob_status";
  /* ****** Dynamic App Setting Keys (general_setting API) */
}
