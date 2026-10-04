import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../firebase_options.dart';
import '../model/avatarmodel.dart';
import '../model/castdetailmodel.dart';
import '../model/channelmodel.dart';
import '../model/commentmodel.dart';
import '../model/continuewatchingmodel.dart';
import '../model/couponlistmodel.dart';
import '../model/couponmodel.dart';
import '../model/devicesyncmodel.dart';
import '../model/download_item.dart';
import '../model/historymodel.dart';
import '../model/introscreenmodel.dart';
import '../model/pagesmodel.dart';
import '../model/paymentoptionmodel.dart';
import '../model/paytmmodel.dart';
import '../model/razorpayordermodel.dart';
import '../model/relatedcontentmodel.dart';
import '../model/sectiondetailmodel.dart';
import '../model/clipsmodel.dart';
import '../model/sociallinkmodel.dart';
import '../model/subscriptionmodel.dart';
import '../model/generalsettingmodel.dart';
import '../model/genresmodel.dart';
import '../model/langaugemodel.dart';
import '../model/loginregistermodel.dart';
import '../model/profilemodel.dart';
import '../model/referandearnhistorymodel.dart';
import '../model/wallettransactionmodel.dart';
import '../model/rentmodel.dart';
import '../model/searchmodel.dart';
import '../model/sectionbannermodel.dart';
import '../model/contentdetailmodel.dart' as contentdetails;
import '../model/episodebyseasonmodel.dart' as episode;
import '../model/clipepisodesmodel.dart' as shortsepisode;
import '../model/sectionlistmodel.dart';
import '../model/sectiontypemodel.dart';
import '../model/reviewmodel.dart';
import '../model/successmodel.dart';
import '../model/contentbyidmodel.dart';
import '../model/watchlistmodel.dart';
import '../players/model/vdociphermodel.dart';
import '../provider/videodownloadprovider.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import 'package:flutter_locales/flutter_locales.dart';

import 'dioclient.dart';

class ApiService {
  final Dio dio = DioClient.instance.dio;

  Options optHeaders = Options(
    headers: <String, dynamic>{
      'Content-Type': 'application/json',
      'Api-Token': Constant.apiToken,
    },
  );

  ApiService() {
    if (kDebugMode) {
      final alreadyAdded = dio.interceptors.any((i) => i is PrettyDioLogger);
      if (!alreadyAdded) {
        // dio.interceptors.add(
        //   PrettyDioLogger(
        //     requestHeader: true,
        //     requestBody: true,
        //     responseBody: true,
        //     responseHeader: false,
        //     compact: false,
        //   ),
        // );
      }
    }
  }

  /* VideoCipher OTP generation START ************* */
  Future<VdoCipherModel> generateCipherOTP(dynamic videoId) async {
    VdoCipherModel dataModel;
    String apiName = "get_vdocipher_otp";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {'vdocipher_id': videoId},
    );
    dataModel = VdoCipherModel.fromJson(response.data);
    return dataModel;
  }
  /* *************** VideoCipher OTP generation END */

  /* Send FCM PushNotification START ************* */
  Future sendFCMPushNotification(
    dynamic notifyType,
    toUserDeviceToken,
    toUserDeviceType,
  ) async {
    printLog("notifyTyoe ===> $notifyType");
    printLog("deviceToken ==> $toUserDeviceToken");
    printLog("deviceType ===> $toUserDeviceType");
    printLog("projectId ===> ${DefaultFirebaseOptions.android.projectId}");
    try {
      var params = {
        "message": {
          "token": toUserDeviceToken.toString(),
          "notification": {
            "title": "You are going to logout from this device.",
            "body": notifyType,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "type": notifyType.toString(),
            "deviceToken": toUserDeviceToken.toString(),
            "deviceType": toUserDeviceType.toString(),
          },
          "android": {"priority": "high"},
          "apns": {
            "payload": {
              "aps": {"category": Constant.appName},
            },
          },
          "webpush": {"fcm_options": {}},
        },
      };
      var url =
          'https://fcm.googleapis.com/v1/projects/${DefaultFirebaseOptions.android.projectId}/messages:send';
      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${Constant.accessToken}",
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(params),
      );

      if (response.statusCode == 200) {
        printLog("Send Notification");
        Map<String, dynamic> map = jsonDecode(response.body);
        printLog("fcm.google map :=====> $map");
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        printLog("fcm.google error :=====> $error");
      }
    } on Exception catch (e) {
      printLog("Send FCM Exception ====> $e");
    }
  }
  /* *************** Send FCM PushNotification END */

  // general_setting API
  Future<GeneralSettingModel> genaralSetting() async {
    GeneralSettingModel dataModel;
    String apiName = "general_setting";
    Response response = await dio.post(apiName, options: optHeaders);
    dataModel = GeneralSettingModel.fromJson(response.data);
    return dataModel;
  }

  // get_onboarding_screen API
  Future<IntroScreenModel> getOnboardingScreen() async {
    IntroScreenModel dataModel;
    String apiName = "get_onboarding_screen";
    Response response = await dio.post(apiName, options: optHeaders);
    dataModel = IntroScreenModel.fromJson(response.data);
    return dataModel;
  }

  // get_pages API
  Future<PagesModel> getPages() async {
    PagesModel dataModel;
    String apiName = "get_pages";
    Response response = await dio.post(apiName, options: optHeaders);
    dataModel = PagesModel.fromJson(response.data);
    return dataModel;
  }

  // get_social_link API
  Future<SocialLinkModel> getSocialLink() async {
    SocialLinkModel dataModel;
    String apiName = "get_social_link";
    Response response = await dio.post(apiName, options: optHeaders);
    dataModel = SocialLinkModel.fromJson(response.data);
    return dataModel;
  }

  /* type => 1-OTP, 2-Google, 3-Apple, 4-Normal */
  /* device_type => 1-Android, 2-Apple */
  // login API
  Future<LoginRegisterModel> loginWithEmailPW(
    dynamic email,
    password,
    deviceName,
    deviceType,
    deviceToken,
  ) async {
    printLog("email :========> $email");
    printLog("password :=====> $password");
    printLog("deviceName :===> $deviceName");
    printLog("deviceType :===> $deviceType");
    printLog("deviceToken :==> $deviceToken");
    printLog("deviceId :=====> ${Constant.currentDeviceId}");

    LoginRegisterModel dataModel;
    String apiName = "login";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: FormData.fromMap({
        'type': "4",
        'email': email,
        'password': password,
        'device_name': deviceName,
        'device_type': deviceType,
        'device_token': deviceToken,
        'device_id': Constant.currentDeviceId,
      }),
    );

    dataModel = LoginRegisterModel.fromJson(response.data);
    return dataModel;
  }

  /* type => 1-OTP, 2-Google, 3-Apple, 4-Normal */
  /* device_type => 1-Android, 2-Apple */
  // login API
  Future<LoginRegisterModel> loginWithSocial(
    dynamic email,
    name,
    type,
    deviceName,
    deviceType,
    deviceToken,
    profileImg, {
    String? referenceCode,
  }) async {
    printLog("email :=========> $email");
    printLog("name :==========> $name");
    printLog("type :==========> $type");
    printLog("deviceName :====> $deviceName");
    printLog("deviceType :====> $deviceType");
    printLog("deviceToken :===> $deviceToken");
    printLog("referenceCode :=> $referenceCode");
    printLog("profileImg :====> $profileImg");
    printLog("deviceId :======> ${Constant.currentDeviceId}");

    MultipartFile? imageFile;

    if (profileImg != null) {
      if (kIsWeb && profileImg is Uint8List) {
        imageFile = MultipartFile.fromBytes(profileImg);
      } else if (profileImg is File) {
        imageFile = await MultipartFile.fromFile(
          profileImg.path,
          filename: profileImg.path.split('/').last,
        );
      }
    }

    LoginRegisterModel dataModel;
    String apiName = "login";
    Response response = await dio.post(
      apiName,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Api-Token': Constant.apiToken,
        },
      ),
      data: FormData.fromMap({
        'type': type,
        'email': email,
        'full_name': name,
        'device_name': deviceName,
        'device_type': deviceType,
        'device_token': deviceToken,
        'device_id': Constant.currentDeviceId,
        'image': ?imageFile,
        if (referenceCode != null && referenceCode.isNotEmpty)
          'reference_code': referenceCode,
      }),
    );

    dataModel = LoginRegisterModel.fromJson(response.data);
    return dataModel;
  }

  /* type => 1-OTP, 2-Google, 3-Apple, 4-Normal */
  /* device_type => 1-Android, 2-Apple */
  // login API
  Future<LoginRegisterModel> loginWithOTP(
    dynamic mobile,
    deviceName,
    deviceType,
    deviceToken, {
    String? referenceCode,
  }) async {
    printLog("mobile :========> $mobile");
    printLog("deviceName :====> $deviceName");
    printLog("deviceType :====> $deviceType");
    printLog("deviceToken :===> $deviceToken");
    printLog("referenceCode :=> $referenceCode");
    printLog("deviceId :======> ${Constant.currentDeviceId}");

    LoginRegisterModel dataModel;
    String apiName = "login";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'type': '1',
        'mobile_number': mobile,
        'device_name': deviceName,
        'device_type': deviceType,
        'device_token': deviceToken,
        'device_id': Constant.currentDeviceId,
        if (referenceCode != null && referenceCode.isNotEmpty)
          'reference_code': referenceCode,
      },
    );

    dataModel = LoginRegisterModel.fromJson(response.data);
    return dataModel;
  }

  // tv_login API
  Future<LoginRegisterModel> tvLogin(dynamic uniqueCode) async {
    printLog("tvLogin userID :======> ${Constant.userID}");
    printLog("tvLogin uniqueCode :==> $uniqueCode");

    LoginRegisterModel dataModel;
    String apiName = "tv_login";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'unique_code': uniqueCode,
      },
    );

    dataModel = LoginRegisterModel.fromJson(response.data);
    return dataModel;
  }

  // get_refer_earn_history API
  Future<ReferEarnHistoryModel> getReferEarnHistory(dynamic pageNo) async {
    printLog("getReferEarnHistory pageNo :==> $pageNo");

    ReferEarnHistoryModel dataModel;
    String apiName = "get_refer_earn_history";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'min_content': Constant.minPageContent,
        'page_no': pageNo,
      },
    );

    dataModel = ReferEarnHistoryModel.fromJson(response.data);
    return dataModel;
  }

  // get_profile API
  Future<ProfileModel> profile() async {
    printLog("profile userID :==> ${Constant.userID}");

    ProfileModel dataModel;
    String apiName = "get_profile";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {'user_id': (Constant.userID == null) ? 0 : Constant.userID},
    );

    dataModel = ProfileModel.fromJson(response.data);
    return dataModel;
  }

  // update_profile API
  Future<SuccessModel> updateProfile(
    dynamic name,
    email,
    mobileNumber,
    pickedImage,
    avatarId,
  ) async {
    printLog("updateProfile userID :=======> ${Constant.userID}");
    printLog("updateProfile name :=========> $name");
    printLog("updateProfile email :=========> $email");
    printLog("updateProfile mobileNo :=====> $mobileNumber");
    printLog("updateProfile pickedImage :==> $pickedImage");
    printLog("updateProfile avatarId :=====> $avatarId");

    MultipartFile? imageFile;

    if (pickedImage != null) {
      if (kIsWeb && pickedImage is Uint8List) {
        imageFile = MultipartFile.fromBytes(pickedImage);
      } else if (pickedImage is File) {
        imageFile = await MultipartFile.fromFile(
          pickedImage.path,
          filename: pickedImage.path.split('/').last,
        );
      }
    }

    SuccessModel dataModel;
    String apiName = "update_profile";
    Response response = await dio.post(
      apiName,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Api-Token': Constant.apiToken,
        },
      ),
      data: FormData.fromMap({
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'full_name': name,
        if (email != null && email != "" && !email.toString().contains("null"))
          'email': email,
        if (mobileNumber != null &&
            mobileNumber != "" &&
            !mobileNumber.toString().contains("null"))
          'mobile_number': mobileNumber,
        if (avatarId != null || pickedImage != null)
          'image_type': (avatarId != null) ? 2 : 1,
        'image': (avatarId != null) ? avatarId : imageFile,
      }),
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // update_profile API
  Future<SuccessModel> updateDataForPayment(
    dynamic fullName,
    email,
    mobileNumber,
  ) async {
    printLog("updateDataForPayment userID :====> ${Constant.userID}");
    printLog("updateDataForPayment fullName :==> $fullName");
    printLog("updateDataForPayment email :=====> $email");
    printLog("updateProfile mobileNumber :=====> $mobileNumber");

    SuccessModel dataModel;
    String apiName = "update_profile";
    Response response = await dio.post(
      apiName,
      data: FormData.fromMap({
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'full_name': fullName,
        'email': email,
        'mobile_number': mobileNumber,
      }),
      options: optHeaders,
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // update_profile API
  Future<SuccessModel> updatePCPassword(dynamic password) async {
    printLog("updatePCPassword userID :====> ${Constant.userID}");
    printLog("updatePCPassword password :==> $password");

    SuccessModel dataModel;
    String apiName = "update_profile";
    Response response = await dio.post(
      apiName,
      data: FormData.fromMap({
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'parent_control_password': password,
      }),
      options: optHeaders,
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // update_profile API
  Future<SuccessModel> updatePCStatus(dynamic pcStatus) async {
    printLog("updatePCStatus userID :====> ${Constant.userID}");
    printLog("updatePCStatus pcStatus :==> $pcStatus");

    SuccessModel dataModel;
    String apiName = "update_profile";
    Response response = await dio.post(
      apiName,
      data: FormData.fromMap({
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'parent_control_status': pcStatus,
      }),
      options: optHeaders,
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // parent_control_check_password API
  Future<SuccessModel> parentControlCheckPassword(dynamic password) async {
    printLog("parentControlCheckPassword userID :====> ${Constant.userID}");
    printLog("parentControlCheckPassword password :==> $password");

    SuccessModel dataModel;
    String apiName = "parent_control_check_password";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'password': password,
      },
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // get_device_sync_list API
  Future<DeviceSyncModel> getDeviceSyncList() async {
    printLog("getDeviceSyncList userID :==> ${Constant.userID}");

    DeviceSyncModel dataModel;
    String apiName = "get_device_sync_list";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {'user_id': (Constant.userID == null) ? 0 : Constant.userID},
    );

    dataModel = DeviceSyncModel.fromJson(response.data);
    return dataModel;
  }

  // logout_device_sync API
  Future<SuccessModel> logoutDeviceSync(
    dynamic deviceSyncId,
    deviceType,
    deviceToken,
    deviceId,
  ) async {
    printLog("logoutDeviceSync userID :=======> ${Constant.userID}");
    printLog("logoutDeviceSync deviceSyncId :=> $deviceSyncId");
    printLog("logoutDeviceSync deviceType :===> $deviceType");
    printLog("logoutDeviceSync deviceToken :==> $deviceToken");
    printLog("logoutDeviceSync deviceId :=====> $deviceId");

    SuccessModel dataModel;
    String apiName = "logout_device_sync";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'device_sync_id': deviceSyncId,
        'device_type': deviceType,
        'device_token': deviceToken,
        'device_id': deviceId,
      },
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // add_remove_device_watching API
  Future<DeviceSyncModel> addRemoveDeviceWatching(dynamic type) async {
    printLog("addRemoveDeviceWatching userID :=====> ${Constant.userID}");
    printLog(
      "addRemoveDeviceWatching deviceId :===> ${Constant.currentDeviceId}",
    );
    printLog("addRemoveDeviceWatching type :=======> $type");

    DeviceSyncModel dataModel;
    String apiName = "add_remove_device_watching";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type': type,
        'device_id': Constant.currentDeviceId,
      },
    );

    dataModel = DeviceSyncModel.fromJson(response.data);
    return dataModel;
  }

  // add_remove_kids_mode API
  Future<SuccessModel> addRemoveKidsMode(dynamic type) async {
    printLog("addRemoveKidsMode userID :=====> ${Constant.userID}");
    printLog("addRemoveKidsMode deviceId :===> ${Constant.currentDeviceId}");
    printLog("addRemoveKidsMode type :=======> $type");

    SuccessModel dataModel;
    String apiName = "add_remove_kids_mode";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'kids_mode': type,
        'device_id': Constant.currentDeviceId,
      },
    );

    dataModel = SuccessModel.fromJson(response.data);
    return dataModel;
  }

  // get_avatar API
  Future<AvatarModel> getAvatar() async {
    AvatarModel dataModel;
    String apiName = "get_avatar";
    Response response = await dio.post(apiName, options: optHeaders, data: {});
    dataModel = AvatarModel.fromJson(response.data);
    return dataModel;
  }

  /* type => 1-movies, 2-news, 3-sport, 4-tv show */
  // get_type API
  Future<SectionTypeModel> sectionType() async {
    SectionTypeModel dataModel;
    String sectionType = "get_type";
    Response response = await dio.post(
      sectionType,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
      },
    );
    dataModel = SectionTypeModel.fromJson(response.data);
    return dataModel;
  }

  // get_banner API
  Future<SectionBannerModel> sectionBanner(dynamic typeId, isHomeScreen) async {
    printLog('sectionBanner typeId ========>>> $typeId');
    printLog('sectionBanner isHomeScreen ==>>> $isHomeScreen');
    SectionBannerModel dataModel;
    String sectionBanner = "get_banner";
    Response response = await dio.post(
      sectionBanner,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type_id': typeId,
        'is_home_screen': isHomeScreen,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    dataModel = SectionBannerModel.fromJson(response.data);
    return dataModel;
  }

  // section_list API
  /* ****** Below video_type only for Sections ****** */
  //1-Video, 2-Show, 3-Category, 4-Language, 5-Channel List,
  //6-Upcoming Content, 7-Channel Content, 8-Continue Watching,
  //9-Kids Content
  /* ************************************************ */
  Future<SectionListModel> sectionList(
    dynamic typeId,
    isHomeScreen,
    pageNo,
  ) async {
    printLog('sectionList typeId ========>>> $typeId');
    printLog('sectionList isHomeScreen ==>>> $isHomeScreen');
    printLog('sectionList pageNo ========>>> $pageNo');
    SectionListModel dataModel;
    String apiName = "section_list";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type_id': typeId,
        'is_home_screen': isHomeScreen,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = SectionListModel.fromJson(response.data);
    return dataModel;
  }

  // section_detail API
  Future<SectionDetailModel> sectionDetails(dynamic sectionId, pageNo) async {
    SectionDetailModel dataModel;
    String apiName = "section_detail";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'section_id': sectionId,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = SectionDetailModel.fromJson(response.data);
    return dataModel;
  }

  // content_detail API
  Future<contentdetails.ContentDetailModel> contentDetails(
    dynamic typeId,
    videoType,
    videoId,
    subVideoType,
  ) async {
    contentdetails.ContentDetailModel dataModel;
    String apiName = "content_detail";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type_id': typeId,
        'video_type': videoType,
        'video_id': videoId,
        'sub_video_type': subVideoType,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    dataModel = contentdetails.ContentDetailModel.fromJson(response.data);
    return dataModel;
  }

  // get_releted_content API
  Future<RelatedContentModel> relatedContent(
    dynamic typeId,
    videoType,
    videoId,
    subVideoType,
    pageNo,
  ) async {
    RelatedContentModel dataModel;
    String apiName = "get_releted_content";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type_id': typeId,
        'video_type': videoType,
        'video_id': videoId,
        'sub_video_type': subVideoType,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = RelatedContentModel.fromJson(response.data);
    return dataModel;
  }

  // get_shorts_list API
  Future<ClipsModel> getShortsList(dynamic shortsId, pageNo) async {
    ClipsModel dataModel;
    String apiName = "get_shorts_list";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        if (shortsId != null && shortsId != 0) 'shorts_id': shortsId,
        'page_no': pageNo,
      },
    );
    dataModel = ClipsModel.fromJson(response.data);
    return dataModel;
  }

  // get_continue_watching API
  Future<ContinueWatchingModel> getContinueWatching(dynamic pageNo) async {
    ContinueWatchingModel dataModel;
    String apiName = "get_continue_watching";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = ContinueWatchingModel.fromJson(response.data);
    return dataModel;
  }

  // get_comment API
  Future<CommentModel> getComment(
    dynamic videoId,
    videoType,
    subVideoType,
    pageNo,
  ) async {
    printLog('getComment videoId =======>>> $videoId');
    printLog('getComment videoType =====>>> $videoType');
    printLog('getComment subVideoType ==>>> $subVideoType');

    CommentModel commentModel;
    String apiName = "get_comment";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_id': videoId,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'page_no': pageNo,
      },
      options: optHeaders,
    );

    commentModel = CommentModel.fromJson(response.data);
    return commentModel;
  }

  // get_replay_comment API
  Future<CommentModel> getReplyComment(dynamic commentId, pageNo) async {
    printLog('getReplyComment commentId ==>>> $commentId');

    CommentModel commentModel;
    String apiName = "get_replay_comment";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'comment_id': commentId,
        'page_no': pageNo,
      },
      options: optHeaders,
    );

    commentModel = CommentModel.fromJson(response.data);
    return commentModel;
  }

  // add_comment API
  // NOTE : Comment feature work for Clip content only, not for Clip's Episodes
  Future<SuccessModel> addComment(
    dynamic comment,
    mainCommentId,
    contentId,
    videoType,
    subVideoType,
  ) async {
    printLog("addComment comment :======> $comment");
    printLog("addComment mainCommentId => $mainCommentId");
    printLog("addComment contentId :====> $contentId");
    printLog("addComment videoType :====> $videoType");
    printLog("addComment subVideoType :=> $subVideoType");

    SuccessModel successModel;
    String apiName = "add_comment";
    Response response = await dio.post(
      apiName,
      data: {
        if (mainCommentId != null && mainCommentId != 0)
          'comment_id': mainCommentId, //For reply comment
        'video_id': contentId,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'comment': comment,
      },
      options: optHeaders,
    );

    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // edit_comment API
  Future<SuccessModel> editComment(dynamic comment, commentId) async {
    printLog("editComment comment :===> $comment");
    printLog("editComment commentId :=> $commentId");

    SuccessModel successModel;
    String apiName = "edit_comment";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'comment': comment,
        'comment_id': commentId,
      },
      options: optHeaders,
    );

    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // delete_comment API
  Future<SuccessModel> deleteComment(dynamic commentId) async {
    printLog("deleteComment commentId :==> $commentId");

    SuccessModel successModel;
    String apiName = "delete_comment";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'comment_id': commentId,
      },
      options: optHeaders,
    );

    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // get_reviews API
  Future<ReviewPageResultModel> getReview(
    dynamic videoId,
    videoType,
    subVideoType,
    pageNo,
  ) async {
    printLog('getReview videoId ====>>> $videoId');
    printLog('getReview videoType ==>>> $videoType');
    printLog('getReview subVideoType ==>>> $subVideoType');
    printLog('getReview pageNo =====>>> $pageNo');

    String apiName = "get_reviews";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_id': videoId,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'page_no': pageNo,
        'min_content': Constant.minPageContent,
      },
      options: optHeaders,
    );

    return ReviewPageResultModel.fromJson(response.data);
  }

  // add_review API
  Future<SuccessModel> addReview(
    dynamic videoId,
    videoType,
    subVideoType,
    rating,
    reviewText,
  ) async {
    printLog('addReview videoId ====>>> $videoId');
    printLog('addReview videoType ==>>> $videoType');
    printLog('addReview subVideoType ==>>> $subVideoType');
    printLog('addReview rating =====>>> $rating');

    SuccessModel successModel;
    String apiName = "add_review";
    Response response = await dio.post(
      apiName,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_id': videoId,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'rating': rating,
        'review_text': reviewText,
      },
      options: optHeaders,
    );

    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // video_view API
  Future<SuccessModel> videoView(
    dynamic videoId,
    videoType,
    subVideoType,
    episodeId,
  ) async {
    printLog('videoView videoId ====>>> $videoId');
    printLog('videoView videoType ==>>> $videoType');
    printLog('videoView episodeId ==>>> $episodeId');
    SuccessModel successModel;
    String apiName = "add_video_view";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_id': videoId,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'episode_id': episodeId,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // add_remove_bookmark API
  Future<SuccessModel> addRemoveBookmark(
    dynamic subVideoType,
    videoType,
    videoId,
  ) async {
    printLog("addRemoveBookmark userID ==========> ${Constant.userID}");
    SuccessModel successModel;
    String sectionList = "add_remove_bookmark";
    Response response = await dio.post(
      sectionList,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'sub_video_type': subVideoType,
        'video_type': videoType,
        'video_id': videoId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // add_remove_like API
  Future<SuccessModel> addRemoveLike(
    dynamic subVideoType,
    videoType,
    videoId,
  ) async {
    printLog("addRemoveLike userID ==========> ${Constant.userID}");
    SuccessModel successModel;
    String sectionList = "add_remove_like";
    Response response = await dio.post(
      sectionList,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'sub_video_type': subVideoType,
        'video_type': videoType,
        'video_id': videoId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // add_continue_watching API
  Future<SuccessModel> addContinueWatching(
    dynamic videoId,
    episodeId,
    videoType,
    subVideoType,
    stopTime,
  ) async {
    SuccessModel successModel;
    String continueWatching = "add_continue_watching";
    Response response = await dio.post(
      continueWatching,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_id': videoId,
        if (episodeId != null && episodeId != 0) 'episode_id': episodeId,
        'video_type': videoType,
        'stop_time': stopTime,
        'sub_video_type': subVideoType,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // remove_continue_watching API
  Future<SuccessModel> removeContinueWatching(
    dynamic videoId,
    videoType,
    subVideoType,
  ) async {
    SuccessModel successModel;
    String removeContinueWatching = "remove_continue_watching";
    Response response = await dio.post(
      removeContinueWatching,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'video_type': videoType,
        'sub_video_type': subVideoType,
        'video_id': videoId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // get_video_by_season_id API
  Future<episode.EpisodeBySeasonModel> episodeBySeason(
    dynamic seasonId,
    showId,
    pageNo,
  ) async {
    episode.EpisodeBySeasonModel dataModel;
    String apiName = "get_video_by_season_id";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'season_id': seasonId,
        'show_id': showId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = episode.EpisodeBySeasonModel.fromJson(response.data);
    return dataModel;
  }

  // get_shorts_episode API
  Future<shortsepisode.ClipEpisodesModel> shortsEpisodeBySeason(
    dynamic seasonId,
    shortsId,
    pageNo,
  ) async {
    shortsepisode.ClipEpisodesModel dataModel;
    String apiName = "get_shorts_episode";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'season_id': seasonId,
        'shorts_id': shortsId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    dataModel = shortsepisode.ClipEpisodesModel.fromJson(response.data);
    return dataModel;
  }

  // cast_detail API
  Future<CastDetailModel> getCastDetails(dynamic castId) async {
    CastDetailModel castDetailModel;
    String castDetails = "cast_detail";
    Response response = await dio.post(
      castDetails,
      options: optHeaders,
      data: {'cast_id': castId},
    );
    castDetailModel = CastDetailModel.fromJson(response.data);
    return castDetailModel;
  }

  // get_category API
  Future<GenresModel> genres() async {
    GenresModel genresModel;
    String genres = "get_category";
    Response response = await dio.post(genres, options: optHeaders);
    genresModel = GenresModel.fromJson(response.data);
    return genresModel;
  }

  // get_language API
  Future<LangaugeModel> language() async {
    LangaugeModel langaugeModel;
    String language = "get_language";
    Response response = await dio.post(language, options: optHeaders);
    langaugeModel = LangaugeModel.fromJson(response.data);
    return langaugeModel;
  }

  // get_channel API
  Future<ChannelModel> channel() async {
    ChannelModel channelModel;
    String language = "get_channel";
    Response response = await dio.post(language, options: optHeaders);
    channelModel = ChannelModel.fromJson(response.data);
    return channelModel;
  }

  // search_content API
  Future<SearchModel> searchContent(dynamic searchText, pageNo) async {
    printLog('searchContent searchText ==>>> $searchText');
    SearchModel searchModel;
    String search = "search_content";
    Response response = await dio.post(
      search,
      options: optHeaders,
      data: {
        'name': searchText,
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    searchModel = SearchModel.fromJson(response.data);
    return searchModel;
  }

  // rent_content_list API
  // type : 1-Video, 2-Show
  Future<RentModel> rentContentList(dynamic contentType, pageNo) async {
    RentModel rentModel;
    String rentList = "rent_content_list";
    Response response = await dio.post(
      rentList,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'type': contentType,
        'page_no': pageNo,
      },
    );
    rentModel = RentModel.fromJson(response.data);
    return rentModel;
  }

  // user_rent_content_list API
  Future<RentModel> userRentContentList(dynamic pageNo) async {
    RentModel rentModel;
    String rentList = "user_rent_content_list";
    Response response = await dio.post(
      rentList,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'page_no': pageNo,
      },
    );
    rentModel = RentModel.fromJson(response.data);
    return rentModel;
  }

  // content_by_category API
  Future<ContentByIdModel> contentByCategory(dynamic categoryID, pageNo) async {
    printLog('contentByCategory categoryID ==>>> $categoryID');
    printLog('contentByCategory pageNo ======>>> $pageNo');
    ContentByIdModel videoByIdModel;
    String apiName = "content_by_category";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'category_id': categoryID,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    videoByIdModel = ContentByIdModel.fromJson(response.data);
    return videoByIdModel;
  }

  // content_by_language API
  Future<ContentByIdModel> contentByLanguage(dynamic languageID, pageNo) async {
    printLog('contentByLanguage languageID ==>>> $languageID');
    printLog('contentByLanguage pageNo ======>>> $pageNo');
    ContentByIdModel videoByIdModel;
    String apiName = "content_by_language";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'language_id': languageID,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    videoByIdModel = ContentByIdModel.fromJson(response.data);
    return videoByIdModel;
  }

  // content_by_channel API
  Future<ContentByIdModel> contentByChannel(dynamic channelID, pageNo) async {
    printLog('contentByChannel channelID ==>>> $channelID');
    printLog('contentByChannel pageNo =====>>> $pageNo');
    ContentByIdModel videoByIdModel;
    String apiName = "content_by_channel";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'channel_id': channelID,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    videoByIdModel = ContentByIdModel.fromJson(response.data);
    return videoByIdModel;
  }

  // content_by_cast API
  Future<ContentByIdModel> contentByCast(dynamic castID, pageNo) async {
    printLog('contentByCast castID =====>>> $castID');
    printLog('contentByCast pageNo =====>>> $pageNo');
    ContentByIdModel videoByIdModel;
    String apiName = "content_by_cast";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'cast_id': castID,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );
    videoByIdModel = ContentByIdModel.fromJson(response.data);
    return videoByIdModel;
  }

  // get_package API
  Future<SubscriptionModel> subscriptionPackage() async {
    printLog('subscriptionPackage userID ==>>> ${Constant.userID}');
    SubscriptionModel subscriptionModel;
    String getPackage = "get_package";
    Response response = await dio.post(
      getPackage,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
      },
    );
    subscriptionModel = SubscriptionModel.fromJson(response.data);
    return subscriptionModel;
  }

  // get_bookmark_video API
  Future<WatchlistModel> watchlist(dynamic pageNo) async {
    printLog("watchlist userID :====> ${Constant.userID}");
    printLog("watchlist deviceID :==> ${Constant.currentDeviceId}");
    printLog("watchlist pageNo :====> $pageNo");

    WatchlistModel watchlistModel;
    String getBookmarkVideo = "get_bookmark_video";
    printLog("getBookmarkVideo API :==> $getBookmarkVideo");
    Response response = await dio.post(
      getBookmarkVideo,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'is_kids_profile': (Constant.userIsKid == true) ? 1 : 0,
        'page_no': pageNo,
      },
    );

    watchlistModel = WatchlistModel.fromJson(response.data);
    return watchlistModel;
  }

  // get_payment_option API
  Future<PaymentOptionModel> getPaymentOption() async {
    PaymentOptionModel paymentOptionModel;
    String paymentOption = "get_payment_option";
    printLog("paymentOption API :==> $paymentOption");
    Response response = await dio.post(paymentOption, options: optHeaders);

    paymentOptionModel = PaymentOptionModel.fromJson(response.data);
    return paymentOptionModel;
  }

  // apply_coupon API
  Future<CouponModel> applyPackageCoupon(dynamic couponCode, packageId) async {
    CouponModel couponModel;
    String applyCoupon = "apply_coupon";
    printLog("applyPackageCoupon API :==> $applyCoupon");
    Response response = await dio.post(
      applyCoupon,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'apply_coupon_type': "1",
        'code': couponCode,
        'package_id': packageId,
      },
    );

    couponModel = CouponModel.fromJson(response.data);
    return couponModel;
  }

  // apply_coupon API
  Future<CouponModel> applyRentCoupon(
    dynamic couponCode,
    videoId,
    typeId,
    videoType,
    price,
  ) async {
    CouponModel couponModel;
    String applyCoupon = "apply_coupon";
    printLog("applyRentCoupon API :==> $applyCoupon");
    Response response = await dio.post(
      applyCoupon,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'apply_coupon_type': "2",
        'code': couponCode,
        'video_id': videoId,
        'type_id': typeId,
        'video_type': videoType,
        'price': price,
      },
    );

    couponModel = CouponModel.fromJson(response.data);
    return couponModel;
  }

  // get_coupon_list API
  Future<CouponListModel> getCouponList(dynamic type, pageNo) async {
    printLog('getCouponList type :=======> $type');
    printLog('getCouponList pageNo :=====> $pageNo');
    CouponListModel dataModel;
    String apiName = "get_coupon_list";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'type': type,
        'page_no': pageNo,
        'min_content': Constant.minPageContent,
      },
    );
    dataModel = CouponListModel.fromJson(response.data);
    return dataModel;
  }

  // get_payment_token API
  Future<PayTmModel> getPaytmToken(
    dynamic merchantID,
    orderId,
    custmoreID,
    channelID,
    txnAmount,
    website,
    callbackURL,
    industryTypeID,
  ) async {
    PayTmModel payTmModel;
    String paytmToken = "get_payment_token";
    printLog("paytmToken API :==> $paytmToken");
    Response response = await dio.post(
      paytmToken,
      options: optHeaders,
      data: {
        'MID': merchantID,
        'order_id': orderId,
        'CUST_ID': custmoreID,
        'CHANNEL_ID': channelID,
        'TXN_AMOUNT': txnAmount,
        'WEBSITE': website,
        'CALLBACK_URL': callbackURL,
        'INDUSTRY_TYPE_ID': industryTypeID,
      },
    );

    payTmModel = PayTmModel.fromJson(response.data);
    return payTmModel;
  }

  /* Create Razorpay Order START ************* */
  Future<RazorpayOrderModel> createRazorpayOrder(dynamic orderPrice) async {
    printLog("createRazorpayOrder orderPrice ==> $orderPrice");
    RazorpayOrderModel dataModel;
    String apiName = "create_razorpay_order";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {'price': orderPrice},
    );
    dataModel = RazorpayOrderModel.fromJson(response.data);
    return dataModel;
  }
  /* *************** Create Razorpay Order END */

  // update_transaction_status API
  Future<SuccessModel> updateTransaction(
    dynamic type, // 1-Package Transaction, 2-Rent Transaction
    transId,
    transStatus, // 1-Processing, 2-Success, 3-Failed
  ) async {
    printLog('updateTransaction userID =======>>> ${Constant.userID}');
    printLog('updateTransaction type =========>>> $type');
    printLog('updateTransaction transId ======>>> $transId');
    printLog('updateTransaction transStatus ==>>> $transStatus');
    SuccessModel successModel;
    String transaction = "update_transaction_status";
    Response response = await dio.post(
      transaction,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'type': type,
        'transaction_id': transId,
        'transaction_status': transStatus,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // add_transaction API
  Future<SuccessModel> addTransaction(
    dynamic packageId,
    description,
    amount,
    paymentId,
    couponCode, {
    int paymentType = 0, // 0 = Online, 1 = Wallet
  }) async {
    printLog('addTransaction userID ========>>> ${Constant.userID}');
    printLog('addTransaction packageId =====>>> $packageId');
    printLog('addTransaction description ===>>> $description');
    printLog('addTransaction amount ========>>> $amount');
    printLog('addTransaction paymentId =====>>> $paymentId');
    printLog('addTransaction couponCode ====>>> $couponCode');
    printLog('addTransaction paymentType ===>>> $paymentType');
    SuccessModel successModel;
    String transaction = "add_transaction";
    Response response = await dio.post(
      transaction,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'package_id': packageId,
        'description': description,
        'price': amount,
        'transaction_id': paymentId,
        'payment_type': paymentType,
        if (couponCode != null && couponCode != "") 'coupon_code': couponCode,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // add_rent_transaction API
  Future<SuccessModel> addRentTransaction(
    dynamic producerId,
    videoId,
    price,
    typeId,
    videoType,
    subVideoType,
    transactionId,
    description,
    couponCode, {
    int paymentType = 0, // 0 = Online, 1 = Wallet
  }) async {
    printLog('addRentTransaction userID ========>>> ${Constant.userID}');
    printLog('addRentTransaction producerId ====>>> $producerId');
    printLog('addRentTransaction videoId =======>>> $videoId');
    printLog('addRentTransaction price =========>>> $price');
    printLog('addRentTransaction typeId ========>>> $typeId');
    printLog('addRentTransaction videoType =====>>> $videoType');
    printLog('addRentTransaction subVideoType ==>>> $subVideoType');
    printLog('addRentTransaction transactionId =>>> $transactionId');
    printLog('addRentTransaction description ===>>> $description');
    printLog('addRentTransaction couponCode ====>>> $couponCode');
    SuccessModel successModel;
    String rentTransaction = "add_rent_transaction";
    Response response = await dio.post(
      rentTransaction,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'producer_id': producerId,
        'video_id': videoId,
        'price': price,
        'type_id': typeId,
        'sub_video_type': subVideoType,
        'video_type': videoType,
        'transaction_id': transactionId,
        'description': description,
        'payment_type': paymentType,
        if (couponCode != null && couponCode != "") 'coupon_code': couponCode,
      },
    );
    successModel = SuccessModel.fromJson(response.data);
    return successModel;
  }

  // get_transaction_list API
  Future<HistoryModel> subscriptionList(dynamic pageNo) async {
    HistoryModel dataModel;
    String apiName = "get_transaction_list";
    Response response = await dio.post(
      apiName,
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'device_id': Constant.currentDeviceId,
        'page_no': pageNo,
      },
    );
    dataModel = HistoryModel.fromJson(response.data);
    return dataModel;
  }

  /* ========================== Wallet ========================== */
  // add_wallet_amount API
  Future<AddWalletAmountModel> addWalletAmount(
    dynamic userId,
    dynamic amount,
    dynamic transactionId,
  ) async {
    printLog('addWalletAmount userId ========>>> $userId');
    printLog('addWalletAmount amount ========>>> $amount');
    printLog('addWalletAmount transactionId =>>> $transactionId');
    Response response = await dio.post(
      "add_wallet_amount",
      options: optHeaders,
      data: {
        'user_id': userId ?? (Constant.userID ?? 0),
        'amount': amount,
        'transaction_id': transactionId,
      },
    );
    return AddWalletAmountModel.fromJson(response.data);
  }

  // get_wallet_transaction API
  Future<WalletTransactionModel> getWalletTransactions(dynamic pageNo) async {
    printLog('getWalletTransactions pageNo :==> $pageNo');
    Response response = await dio.post(
      "get_wallet_transaction",
      options: optHeaders,
      data: {
        'user_id': (Constant.userID == null) ? 0 : Constant.userID,
        'min_content': Constant.minPageContent,
        'page_no': pageNo,
      },
    );
    return WalletTransactionModel.fromJson(response.data);
  }

  /* ========================== Wallet ========================== */
}

/* ========================== Download Videos ========================== */
Future<void> prepareVideoDownload(
  BuildContext context,
  contentdetails.Result? contentDetails,
) async {
  contentdetails.Result? sectionDetails = contentDetails;
  printLog('videoExtension ============> ${sectionDetails?.videoExtension}');
  final downloadProvider = Provider.of<VideoDownloadProvider>(
    context,
    listen: false,
  );
  downloadProvider.setCurrentDownload(sectionDetails?.id ?? 0);

  Dio dio = Dio();

  /* Hive */
  Box<DownloadItem> dowonloadBox;
  if (Constant.userIsKid == true) {
    dowonloadBox = Hive.box<DownloadItem>(
      '${Constant.hiveDownloadBox}_${Constant.userID}_KID',
    );
  } else {
    dowonloadBox = Hive.box<DownloadItem>(
      '${Constant.hiveDownloadBox}_${Constant.userID}',
    );
  }

  DateTime now = DateTime.now();
  String timeStamp = now.millisecondsSinceEpoch.abs().toString();

  /* Prepare Target Video File START ************* */
  File? mTargetFile;
  String? localPath;
  String? mFileName = (Constant.userIsKid == true)
      ? ('${(sectionDetails?.name ?? "").replaceAll(" ", "")}'
            '${(sectionDetails?.id ?? 0)}${(Constant.userID)}_KID')
      : ('${(sectionDetails?.name ?? "").replaceAll(" ", "")}'
            '${(sectionDetails?.id ?? 0)}${(Constant.userID)}');
  try {
    localPath = await Utils.prepareSaveDir();
    printLog("localPath ====> $localPath");
    mTargetFile = File(
      path.join(
        localPath,
        '$mFileName.${(sectionDetails?.videoExtension ?? "mp4")}',
      ),
    );
    // This is a sync operation on a real
    // app you'd probably prefer to use writeAsByte and handle its Future
  } catch (e) {
    printLog("saveVideoStorage Exception ===> $e");
  }
  printLog("mFileName ========> $mFileName");
  printLog("mTargetFile ========> ${mTargetFile?.absolute.path ?? ""}");
  /* *************** Prepare Target Video File END */

  /* Prepare Target Image Files START ************* */
  File? mTargetPortImageFile, mTargetLandImageFile;
  String? mPortImageFileName = 'port_$timeStamp';
  String? mLandImageFileName = 'land_$timeStamp';
  if (localPath != null) {
    try {
      mTargetPortImageFile = File(
        path.join(localPath, '$mPortImageFileName.png'),
      );
      mTargetLandImageFile = File(
        path.join(localPath, '$mLandImageFileName.png'),
      );
    } catch (e) {
      printLog("saveVideoStorage Exception ===> $e");
    }
  } else {
    return;
  }
  printLog("mPortImageFileName ========> $mPortImageFileName");
  printLog(
    "mTargetPortImageFile ======> ${mTargetPortImageFile?.absolute.path ?? ""}",
  );
  printLog("mLandImageFileName ========> $mLandImageFileName");
  printLog(
    "mTargetLandImageFile ======> ${mTargetLandImageFile?.absolute.path ?? ""}",
  );
  /* *************** Prepare Target Image Files END */

  try {
    if (context.mounted) {
      Utils.showToast(Locales.string(context, "download_started"));
    }

    /* Potrait Image Download */
    dio.download(
      sectionDetails?.thumbnail ?? "",
      path.join(localPath, '$mPortImageFileName.png'),
      onReceiveProgress: (received, total) {},
    );

    /* Landscape Image Download */
    dio.download(
      sectionDetails?.landscape ?? "",
      path.join(localPath, '$mLandImageFileName.png'),
      onReceiveProgress: (received, total) {},
    );

    /* Video Download */
    await dio.download(
      sectionDetails?.video320 ?? "",
      mTargetFile?.path,
      onReceiveProgress: (received, total) async {
        if (total != -1) {
          downloadProvider.setDownloadProgress(
            (received / total * 100).round(),
            sectionDetails?.id ?? 0,
          );
        }
      },
    );

    /* Encrypt Video File START ************** */
    String generateKey = Utils.convertToHex(
      Utils.generateRandomKey(32).padRight(16, '0').substring(0, 16),
    );
    String generateIVKey = Utils.convertToHex(
      Utils.generateRandomKey(16).padRight(16, '0').substring(0, 16),
    );
    printLog("generateKey =======> $generateKey");
    printLog("generateIVKey =====> $generateIVKey");
    dynamic encryptedFile = await Utils.encryptUsingFFMPEG([
      mTargetFile,
      generateKey,
      generateIVKey,
      context,
    ]);
    printLog("encryptedFile =====> $encryptedFile");
    /* ***************** Encrypt Video File END */

    DownloadItem downloadedItem = DownloadItem(
      id: sectionDetails?.id,
      securityKey: generateKey,
      securityIVKey: generateIVKey,
      name: sectionDetails?.name,
      description: sectionDetails?.description,
      videoUrl: sectionDetails?.video320,
      savedDir: localPath,
      savedFile: mTargetFile?.path ?? "",
      videoType: sectionDetails?.videoType,
      subVideoType: sectionDetails?.subVideoType,
      typeId: sectionDetails?.typeId,
      isPremium: sectionDetails?.isPremium,
      isBuy: sectionDetails?.isBuy,
      isRent: sectionDetails?.isRent,
      rentBuy: sectionDetails?.rentBuy,
      rentPrice: sectionDetails?.price,
      isDownload: 1,
      videoUploadType: sectionDetails?.videoUploadType,
      trailerUploadType: sectionDetails?.trailerType,
      trailerUrl: sectionDetails?.trailerUrl,
      videoDuration: sectionDetails?.videoDuration,
      stopTime: sectionDetails?.stopTime ?? 0,
      releaseYear: sectionDetails?.releaseDate,
      thumbnailImg: mTargetPortImageFile?.path,
      landscapeImg: mTargetLandImageFile?.path,
      session: [],
    );

    /* Insert in Hive */
    dowonloadBox.add(downloadedItem);

    downloadProvider.setDownloadProgress(-1, 0);
    downloadProvider.setCurrentDownload(null);
    downloadProvider.setLoading(false);
    if (context.mounted) {
      Utils.showToast(Locales.string(context, "download_completed"));
    }
  } catch (e) {
    if (context.mounted) {
      Utils.showToast(Locales.string(context, "download_failed"));
    }
  }
}
/* ========================== Download Videos ========================== */

/* ========================== Download Shows ========================== */
Future<void> prepareShowDownload(
  BuildContext context, {
  required contentdetails.Result? contentDetails,
  required int? seasonPos,
  required int? episodePos,
  required episode.Result? episodeDetails,
}) async {
  contentdetails.Result? sectionDetails = contentDetails;
  int seasonPosition = seasonPos ?? 0;
  int epiPos = episodePos ?? 0;
  episode.Result? epiDetails = episodeDetails;

  final downloadProvider = Provider.of<VideoDownloadProvider>(
    context,
    listen: false,
  );
  downloadProvider.setCurrentDownload(epiDetails?.id ?? 0);

  Dio dio = Dio();

  /* Hive */
  Box<DownloadItem> dowonloadBox;
  Box<SessionItem> dowonloadSeasonBox;
  Box<EpisodeItem> dowonloadEpiBox;
  if (Constant.userIsKid == true) {
    dowonloadBox = Hive.box<DownloadItem>(
      '${Constant.hiveDownloadBox}_${Constant.userID}_KID',
    );
    dowonloadSeasonBox = Hive.box<SessionItem>(
      '${Constant.hiveSeasonDownloadBox}_${Constant.userID}_KID',
    );
    dowonloadEpiBox = Hive.box<EpisodeItem>(
      '${Constant.hiveEpiDownloadBox}_${Constant.userID}_KID',
    );
  } else {
    dowonloadBox = Hive.box<DownloadItem>(
      '${Constant.hiveDownloadBox}_${Constant.userID}',
    );
    dowonloadSeasonBox = Hive.box<SessionItem>(
      '${Constant.hiveSeasonDownloadBox}_${Constant.userID}',
    );
    dowonloadEpiBox = Hive.box<EpisodeItem>(
      '${Constant.hiveEpiDownloadBox}_${Constant.userID}',
    );
  }
  if (!dowonloadBox.isOpen) {
    return;
  }

  DateTime now = DateTime.now();
  String timeStamp = now.millisecondsSinceEpoch.abs().toString();

  /* Prepare Target Video File START ************* */
  File? mTargetFile;
  String? localPath;
  try {
    localPath = await Utils.prepareShowSaveDir(
      (sectionDetails?.name ?? "").replaceAll(RegExp('\\W+'), ''),
      (sectionDetails?.season?[seasonPosition].name ?? "").replaceAll(
        RegExp('\\W+'),
        '',
      ),
    );
    printLog("localPath ====> $localPath");
    String? mFileName;
    if (Constant.userIsKid == true) {
      mFileName =
          '${(sectionDetails?.season?[seasonPosition].name ?? "").replaceAll(RegExp('\\W+'), '')}'
          '_Ep${(epiPos + 1)}_${episodeDetails?.id}${(Constant.userID)}_KID';
    } else {
      mFileName =
          '${(sectionDetails?.season?[seasonPosition].name ?? "").replaceAll(RegExp('\\W+'), '')}'
          '_Ep${(epiPos + 1)}_${episodeDetails?.id}${(Constant.userID)}';
    }
    printLog("mFileName ======> $mFileName");

    mTargetFile = File(
      path.join(
        localPath,
        '$mFileName.${episodeDetails?.videoExtension != '' ? (episodeDetails?.videoExtension ?? 'mp4') : 'mp4'}',
      ),
    );
  } catch (e) {
    printLog("saveShowStorage Exception ===> $e");
  }
  printLog("mTargetFile ====> ${mTargetFile?.absolute.path ?? ""}");
  /* *************** Prepare Target Video File END */

  /* Prepare Target Image Files START ************* */
  File? mShowPortImageFile,
      mShowLandImageFile,
      mEpiPortImageFile,
      mEpiLandImageFile;
  String? mShowPortImgFileName = 'port_$timeStamp';
  String? mShowLandImgFileName = 'land_$timeStamp';
  String? mEpiPortImgFileName = 'port_epi_$timeStamp';
  String? mEpiLandImgFileName = 'land_epi_$timeStamp';
  if (localPath != null) {
    try {
      mShowPortImageFile = File(
        path.join(localPath, '$mShowPortImgFileName.png'),
      );
      mShowLandImageFile = File(
        path.join(localPath, '$mShowLandImgFileName.png'),
      );
      mEpiPortImageFile = File(
        path.join(localPath, '$mEpiPortImgFileName.png'),
      );
      mEpiLandImageFile = File(
        path.join(localPath, '$mEpiLandImgFileName.png'),
      );
    } catch (e) {
      printLog("saveShowStorage Exception ===> $e");
    }
  } else {
    return;
  }
  printLog("mPortImageFileName ======> $mShowPortImgFileName");
  printLog(
    "mTargetPortImageFile ====> ${mShowPortImageFile?.absolute.path ?? ""}",
  );
  printLog("mLandImageFileName ======> $mShowLandImgFileName");
  printLog(
    "mTargetLandImageFile ====> ${mShowLandImageFile?.absolute.path ?? ""}",
  );
  printLog("mEpiPortImgFileName =====> $mEpiPortImgFileName");
  printLog(
    "mEpiPortImageFile =======> ${mEpiPortImageFile?.absolute.path ?? ""}",
  );
  printLog("mEpiLandImgFileName =====> $mEpiLandImgFileName");
  printLog(
    "mEpiLandImageFile =======> ${mEpiLandImageFile?.absolute.path ?? ""}",
  );
  /* *************** Prepare Target Image Files END */

  try {
    if (!context.mounted) return;
    Utils.showToast(Locales.string(context, "download_started"));

    /* Save Video/Show */
    List<DownloadItem> myDownloadList = [];
    DownloadItem downloadedItem = DownloadItem(
      id: sectionDetails?.id,
      securityKey: "",
      securityIVKey: null,
      name: sectionDetails?.name,
      description: sectionDetails?.description,
      videoUrl: "",
      savedDir: localPath,
      savedFile: "",
      videoType: sectionDetails?.videoType,
      subVideoType: sectionDetails?.subVideoType,
      typeId: sectionDetails?.typeId,
      isPremium: sectionDetails?.isPremium,
      isBuy: sectionDetails?.isBuy,
      isRent: sectionDetails?.isRent,
      rentBuy: sectionDetails?.rentBuy,
      rentPrice: sectionDetails?.price,
      isDownload: 1,
      videoUploadType: sectionDetails?.videoUploadType,
      trailerUploadType: sectionDetails?.trailerType,
      trailerUrl: sectionDetails?.trailerUrl,
      videoDuration: sectionDetails?.videoDuration,
      stopTime: sectionDetails?.stopTime ?? 0,
      releaseYear: sectionDetails?.releaseDate,
      thumbnailImg: mShowPortImageFile?.path,
      landscapeImg: mShowLandImageFile?.path,
      session: null,
    );
    /* Check in Download Box */
    myDownloadList = dowonloadBox.values.where((myDowonloadItem) {
      return (myDowonloadItem.id == sectionDetails?.id);
    }).toList();

    if (myDownloadList.isEmpty) {
      /* Potrait Image Download */
      dio.download(
        sectionDetails?.thumbnail ?? "",
        path.join(localPath, '$mShowPortImgFileName.png'),
        onReceiveProgress: (received, total) {},
      );

      /* Landscape Image Download */
      dio.download(
        sectionDetails?.landscape ?? "",
        path.join(localPath, '$mShowLandImgFileName.png'),
        onReceiveProgress: (received, total) {},
      );
    }

    /* Potrait Episode Image Download */
    dio.download(
      epiDetails?.thumbnail ?? "",
      path.join(localPath, '$mEpiPortImgFileName.png'),
      onReceiveProgress: (received, total) {},
    );

    /* Landscape Episode Image Download */
    dio.download(
      epiDetails?.landscape ?? "",
      path.join(localPath, '$mEpiLandImgFileName.png'),
      onReceiveProgress: (received, total) {},
    );

    /* Video Download */
    await dio.download(
      epiDetails?.video320 ?? "",
      mTargetFile?.path,
      onReceiveProgress: (received, total) async {
        if (total != -1) {
          downloadProvider.setDownloadProgress(
            (received / total * 100).round(),
            epiDetails?.id ?? 0,
          );
        }
      },
    );

    /* Encrypt Episode File START ************** */
    String generateKey = Utils.convertToHex(
      Utils.generateRandomKey(32).padRight(16, '0').substring(0, 16),
    );
    String generateIVKey = Utils.convertToHex(
      Utils.generateRandomKey(16).padRight(16, '0').substring(0, 16),
    );
    printLog("generateKey =======> $generateKey");
    printLog("generateIVKey =====> $generateIVKey");

    dynamic encryptedFile = await Utils.encryptUsingFFMPEG([
      mTargetFile,
      generateKey,
      generateIVKey,
      context,
    ]);
    printLog("encryptedFile =======> $encryptedFile");
    /* ***************** Encrypt Episode File END */

    /* Check In Downloaded Items START **************** */
    List<SessionItem> mySavedSeasonList = [];
    List<EpisodeItem> mySavedEpiList = [];

    /* Save Episode */
    EpisodeItem episodeItem = EpisodeItem(
      id: episodeDetails?.id,
      securityKey: generateKey,
      securityIVKey: generateIVKey,
      showId: sectionDetails?.id,
      sessionId: sectionDetails?.season?[seasonPosition].id,
      thumbnail: mEpiPortImageFile?.path,
      landscape: mEpiLandImageFile?.path,
      videoUploadType: episodeDetails?.videoUploadType,
      typeId: sectionDetails?.typeId,
      videoType: sectionDetails?.videoType,
      subVideoType: sectionDetails?.subVideoType,
      stopTime: episodeDetails?.stopTime,
      videoExtension: episodeDetails?.videoExtension != ''
          ? (episodeDetails?.videoExtension ?? 'mp4')
          : 'mp4',
      videoDuration: episodeDetails?.videoDuration,
      isPremium: episodeDetails?.isPremium,
      name: sectionDetails?.name,
      description: episodeDetails?.name,
      status: episodeDetails?.status,
      video320: episodeDetails?.video320,
      video480: episodeDetails?.video480,
      video720: episodeDetails?.video720,
      video1080: episodeDetails?.video1080,
      savedDir: localPath,
      savedFile: mTargetFile?.path ?? "",
      subtitleType: episodeDetails?.subtitleType,
      subtitle1: episodeDetails?.subtitle1,
      subtitle2: episodeDetails?.subtitle2,
      subtitle3: episodeDetails?.subtitle3,
      subtitleLang1: episodeDetails?.subtitleLang1,
      subtitleLang2: episodeDetails?.subtitleLang2,
      subtitleLang3: episodeDetails?.subtitleLang3,
      isDownloaded: 1,
      isBookmark: sectionDetails?.isBookmark,
      rentBuy: sectionDetails?.rentBuy,
      isRent: sectionDetails?.isRent,
      rentPrice: sectionDetails?.price,
      isBuy: episodeDetails?.isBuy,
      categoryName: sectionDetails?.categoryName,
    );

    /* Save Season */
    SessionItem sessionItem = SessionItem(
      id: sectionDetails?.season?[seasonPosition].id,
      showId: sectionDetails?.id,
      sessionPosition: seasonPosition,
      name: sectionDetails?.season?[seasonPosition].name,
      status: sectionDetails?.season?[seasonPosition].status,
      isDownload: 1,
      episode: null,
    );

    /* Check in Season Box */
    mySavedSeasonList = dowonloadSeasonBox.values.where((mySeasonItem) {
      return (mySeasonItem.showId == sectionDetails?.id &&
          mySeasonItem.id == sectionDetails?.season?[seasonPosition].id);
    }).toList();
    /* Check in Episode Box */
    mySavedEpiList = dowonloadEpiBox.values.where((myEpiItem) {
      return (myEpiItem.showId == sectionDetails?.id &&
          myEpiItem.id == episodeDetails?.id &&
          myEpiItem.sessionId == sectionDetails?.season?[seasonPosition].id);
    }).toList();
    printLog("myDownloadList =======> ${myDownloadList.length}");
    printLog("mySavedSeasonList ====> ${mySavedSeasonList.length}");
    printLog("mySavedEpiList =======> ${mySavedEpiList.length}");
    /* ****************** Check In Downloaded Items END */

    /* Insert in Hive */
    if (mySavedEpiList.isEmpty) {
      dowonloadEpiBox.add(episodeItem);
    }
    if (mySavedSeasonList.isEmpty) {
      dowonloadSeasonBox.add(sessionItem);
    }
    if (myDownloadList.isEmpty) {
      dowonloadBox.add(downloadedItem);
    }

    downloadProvider.setDownloadProgress(-1, 0);
    downloadProvider.setCurrentDownload(null);
    downloadProvider.setLoading(false);
    if (context.mounted) {
      Utils.showToast(Locales.string(context, "download_completed"));
    }
  } catch (e) {
    if (!context.mounted) return;
    Utils.showToast(Locales.string(context, "download_failed"));
  }
}
/* ========================== Download Shows ========================== */