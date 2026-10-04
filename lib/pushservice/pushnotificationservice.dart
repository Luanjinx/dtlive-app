import '../main.dart';
import '../pages/loginsocial.dart';
import '../provider/homeprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/constant.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:provider/provider.dart';

class PushNotificationService {
  static GoogleSignIn googleSignIn = GoogleSignIn.instance;

  Future<void> setupInteractedMessage(BuildContext context) async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await Firebase.initializeApp();
    await getAccessToken();
    enableIOSNotifications();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      printLog("===> msg $message");
    });
    if (context.mounted) {
      await registerNotificationListeners(context);
    }
  }

  Future<void> registerNotificationListeners(BuildContext context) async {
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
          printLog("onTokenRefresh ======>>> $fcmToken");
        })
        .onError((err) {
          printLog("onTokenRefresh error ======>>> $err");
        });

    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      final RemoteNotification? notification = message?.notification;
      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.

      if (notification != null && message != null) {
        printLog("notification title =====> ${notification.title}");
        printLog("notification body ======> ${notification.body}");
        printLog("notification message ===> ${message.data}");
        Map<String, dynamic>? notificationData = message.data;
        printLog("notificationData =======> $notificationData");
        String? notifyType = notificationData["type"];
        String? deviceToken = notificationData["deviceToken"];
        String? deviceType = notificationData["deviceType"];
        printLog("notifyType =======> $notifyType");
        printLog("deviceToken ======> $deviceToken");
        printLog("deviceType =======> $deviceType");
        if (notifyType == "logout") {
          onLogoutDelete();
        }
      }
    });
  }

  static Future<void> onLogoutDelete() async {
    late SectionDataProvider sectionDataProvider;
    late ProfileProvider profileProvider;
    late HomeProvider homeProvider;
    if (navigatorKey.currentContext != null) {
      homeProvider = Provider.of<HomeProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      sectionDataProvider = Provider.of<SectionDataProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      profileProvider = Provider.of<ProfileProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      sectionDataProvider.clearProvider();
      profileProvider.clearProvider();
    }
    // Firebase Signout
    String? webServerClientId;
    SharedPre sharedPre = SharedPre();
    try {
      await FirebaseAuth.instance.signOut();

      webServerClientId = await sharedPre.read(Constant.googleClientIdKey);
      printLog("_getDeviceToken webServerClientId ===> $webServerClientId");
      if (kIsWeb) {
        try {
          await googleSignIn.initialize();
        } catch (e) {
          printLog("_initGoogleSignIn GoogleSignIn Error ===> $e");
        }
      } else {
        try {
          await googleSignIn.initialize(
            clientId: webServerClientId,
            serverClientId: webServerClientId,
          );
        } catch (e) {
          printLog("_initGoogleSignIn GoogleSignIn Error ===> $e");
        }
      }

      await googleSignIn.signOut();
    } on Exception catch (e) {
      printLog("_onLogoutDelete Firebase-Gmail Exception =====> $e");
    }
    await Utils.setUserId(null);
    if (navigatorKey.currentContext != null) {
      homeProvider.getSectionType();
      sectionDataProvider.getSectionBanner("0", "1");
      sectionDataProvider.getSectionList("0", "1", 1);
    }

    /* <<<<<<<< Redirect to Login >>>>>>>> */
    if (navigatorKey.currentContext != null) {
      if (kIsWeb) {
        Utils.openWebDialog(
          context: navigatorKey.currentContext!,
          newPage: RoutesConstant.loginSocialPage,
          oldPage: '',
          reqText: '',
        );
      } else {
        /* Initialize Hive */
        await Utils.initializeHiveBoxes();
        navigatorKey.currentState?.push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const LoginSocial();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          ),
        );
      }
    }
    /* <<<<<<<< Redirect to Login >>>>>>>> */
  }

  Future<void> enableIOSNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      printLog('User granted permission');
      await Utils.getFirebaseWebToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      printLog('User granted provisional permission');
    } else {
      printLog('User declined or has not accepted permission');
    }
  }

  static String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  static Future<String> getAccessToken() async {
    final response = await Utils.loadJsonFromAssets(
      'assets/firebase/firebase_service_account.json',
    );
    printLog("getAccessToken response ======> $response");

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(response),
      [firebaseMessagingScope],
    );

    final accessToken = client.credentials.accessToken.data;
    Constant.accessToken = accessToken;
    printLog("getAccessToken accessToken ===> ${Constant.accessToken}");
    return accessToken;
  }
}
