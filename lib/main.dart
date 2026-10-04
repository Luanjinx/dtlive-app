import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/adhelper.dart';
import '../firebase_options.dart';
import '../model/download_item.dart';
import '../pages/contentshowdetails.dart';
import '../pages/contentvideodetails.dart';
import '../pages/splash.dart';
import '../provider/avatarprovider.dart';
import '../provider/bottombarprovider.dart';
import '../provider/connectivityprovider.dart';
import '../provider/myspaceprovider.dart';
import '../provider/mysubscribedplanprovider.dart';
import '../provider/sectionviewallprovider.dart';
import '../provider/subhistoryprovider.dart';
import '../provider/videodownloadprovider.dart';
import '../provider/episodeprovider.dart';
import '../provider/findprovider.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/paymentprovider.dart';
import '../provider/playerprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/purchaselistprovider.dart';
import '../provider/rentstoreprovider.dart';
import '../provider/searchprovider.dart';
import '../provider/sectionbytypeprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/showdetailsprovider.dart';
import '../provider/subscriptionprovider.dart';
import '../provider/videobyidprovider.dart';
import '../provider/videodetailsprovider.dart';
import '../provider/referandearnhistoryprovider.dart';
import '../provider/walletprovider.dart';
import '../provider/viewallprovider.dart';
import '../provider/reviewprovider.dart';
import '../provider/watchlistprovider.dart';
import '../pushservice/pushnotificationservice.dart';
import '../routes/routes_config.dart';
import '../utils/sharedpre.dart';
import '../utils/color.dart';
import '../utils/utils.dart';
import '../utils/constant.dart';
import 'pages/clips.dart';
import 'provider/clipsprovider.dart';
import 'web_js/js_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final RemoteNotification? notification = message.notification;
  // If `onMessage` is triggered with a notification, construct our own
  // local notification to show to users using the created channel.
  if (notification != null) {
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
      GoogleSignIn googleSignIn = GoogleSignIn.instance;
      // Firebase Signout
      String? webServerClientId;
      SharedPre sharedPre = SharedPre();
      try {
        await FirebaseAuth.instance.signOut();

        webServerClientId = await sharedPre.read(Constant.googleClientIdKey);
        printLog("_getDeviceToken webServerClientId ===> $webServerClientId");
        if (kIsWeb) {
          await googleSignIn.initialize();
        } else {
          await googleSignIn.initialize(
            clientId: webServerClientId,
            serverClientId: webServerClientId,
          );
        }

        await googleSignIn.signOut();
      } on Exception catch (e) {
        printLog("_onLogoutDelete Firebase-Gmail Exception =====> $e");
      }
      await Utils.setUserId(null);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  printLog("App Started!!!");

  if (!kIsWeb) {
    await AdHelper().initGoogleMobileAds();

    /* Initialize Hive Start */
    final appDocumentDir = await getApplicationDocumentsDirectory();
    printLog("appDocumentDir Path ==> ${appDocumentDir.path}");
    Hive.init(appDocumentDir.path);
    Hive.registerAdapter(DownloadItemAdapter());
    Hive.registerAdapter(SessionItemAdapter());
    Hive.registerAdapter(EpisodeItemAdapter());
    /* Initialize Hive End */
  } else {
    /* Prevent Right Click */
    final JSHelper jsHelper = JSHelper();
    jsHelper.setupRightClickBlock();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /* Push Notification Set-up */
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  /* Push Notification Set-up */

  await Locales.init([
    'en',
    'af',
    'ar',
    'de',
    'es',
    'fr',
    'gu',
    'hi',
    'id',
    'nl',
    'pt',
    'sq',
    'tr',
    'vi',
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => BottombarProvider()),
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => FindProvider()),
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => MySpaceProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PurchaselistProvider()),
        ChangeNotifierProvider(create: (_) => RentStoreProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => SectionByTypeProvider()),
        ChangeNotifierProvider(create: (_) => SectionDataProvider()),
        ChangeNotifierProvider(create: (_) => ShowDetailsProvider()),
        ChangeNotifierProvider(create: (_) => EpisodeProvider()),
        ChangeNotifierProvider(create: (_) => ClipsProvider()),
        ChangeNotifierProvider(create: (_) => SubHistoryProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => MySubscribedPlanProvider()),
        ChangeNotifierProvider(create: (_) => SectionViewAllProvider()),
        ChangeNotifierProvider(create: (_) => ViewAllProvider()),
        ChangeNotifierProvider(create: (_) => VideoByIDProvider()),
        ChangeNotifierProvider(create: (_) => VideoDetailsProvider()),
        ChangeNotifierProvider(create: (_) => VideoDownloadProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => ReferEarnHistoryProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const MyApp(),
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _router = RoutesConfig().goRouter;
  SharedPre sharedPre = SharedPre();
  late ConnectivityProvider connectivityProvider;
  late ProfileProvider profileProvider;
  late GeneralProvider generalProvider;
  late HomeProvider homeProvider;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    printLog("initState deeplinkDomain ====> ${Constant.deeplinkDomain}");
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    /* Push Notification Set-up */
    PushNotificationService().setupInteractedMessage(context);
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    /* Push Notification Set-up */

    if (!mounted) return;
    getAppVersion();
    _getUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await connectivityProvider.initConnectivity(context);
      await _getDeviceInfo();
      if (!kIsWeb) await _fetchIntro();
      await _getData();
      try {
        await WakelockPlus.enable();
      } on Exception catch (e) {
        printLog("WakelockPlus Exception ====> $e");
      }

      /* Deep Link */
      if (!mounted) return;
      initDeepLinks(context: context);

      if (kIsWeb) {
        final JSHelper jsHelper = JSHelper();
        jsHelper.setupWebVisibility(context);
      }
    });
  }

  Future<void> _getUserData() async {
    Constant.userID = await sharedPre.read('userid');
    Constant.userIsKid = await sharedPre.readBool(Constant.profileUserKey);
    printLog('_getData userID ===========> ${Constant.userID}');
    printLog('_getData userIsKid ========> ${Constant.userIsKid}');
    printLog('_getData currentDeviceId ==> ${Constant.currentDeviceId}');

    if (Constant.userIsKid == null) {
      await Utils.setUserMode(false);
    }
  }

  Future _getData() async {
    await homeProvider.setLoading(true);
    /* *********** Check For Device START *********** */
    if (connectivityProvider.isOnline && Constant.userID != null) {
      await profileProvider.getDeviceSyncList();
      if (profileProvider.deviceSyncModel.result != null &&
          (profileProvider.deviceSyncModel.result?.length ?? 0) > 0) {
        bool? isDeviceContains = profileProvider.deviceSyncModel.result?.any((
          deviceItem,
        ) {
          printLog("_getData deviceList userId ====> ${deviceItem.userId}");
          printLog("_getData deviceList deviceId ==> ${deviceItem.deviceId}");
          return ((deviceItem.deviceId ?? "") == Constant.currentDeviceId);
        });
        printLog("_getData isDeviceContains ====> $isDeviceContains");
        if (isDeviceContains == false) {
          PushNotificationService.onLogoutDelete();
          return;
        }
      }

      if (!mounted) return;
      profileProvider.getProfile(context);
    }
    /* *********** Check For Device END ************* */

    /* Initialize Hive */
    if (!kIsWeb) {
      await Utils.initializeHiveBoxes();
    }
  }

  Future<void> initDeepLinks({required BuildContext context}) async {
    try {
      // Handle links
      _linkSubscription = AppLinks().uriLinkStream.listen((
        Uri initialLink,
      ) async {
        printLog("========================================");
        printLog("initDeepLinks initialLink ====> $initialLink");
        printLog("========================================");

        printLog("initDeepLinks non-app link :===> ${initialLink.host}");
        printLog("initDeepLinks deeplinkDomain :=> ${Constant.deeplinkDomain}");
        if (!kIsWeb) {
          if (initialLink.host == Constant.deeplinkDomain) {
            final uriString = initialLink.path;
            final pathSegments = Uri.parse(uriString).pathSegments;
            printLog("initDeepLinks pathSegments ====> ${pathSegments.length}");

            if (pathSegments.isNotEmpty) {
              /* Get params & open Details */
              String pageType;
              int videoType, typeId, videoId, subVideoType;

              pageType = pathSegments[0]; // video
              videoType = int.parse(pathSegments[1]);
              typeId = int.parse(pathSegments[2]);
              videoId = int.parse(pathSegments[3]);
              subVideoType = (pathSegments.length > 4)
                  ? int.parse(pathSegments[4])
                  : 0;

              printLog("initDeepLinks pageType ======> $pageType");
              printLog("initDeepLinks videoType =====> $videoType");
              printLog("initDeepLinks typeId ========> $typeId");
              printLog("initDeepLinks videoId =======> $videoId");
              printLog("initDeepLinks subVideoType ==> $subVideoType");

              /* Initialize Hive */
              if (!kIsWeb) {
                await Utils.initializeHiveBoxes();
              }
              await Future.delayed(Duration(seconds: 2));
              if (context.mounted) {
                if (navigatorKey.currentContext != null) {
                  final videoDetailsProvider =
                      Provider.of<VideoDetailsProvider>(
                        navigatorKey.currentContext!,
                        listen: false,
                      );
                  final clipsProvider = Provider.of<ClipsProvider>(
                    navigatorKey.currentContext!,
                    listen: false,
                  );
                  final showDetailsProvider = Provider.of<ShowDetailsProvider>(
                    navigatorKey.currentContext!,
                    listen: false,
                  );

                  SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.manual,
                    overlays: SystemUiOverlay.values,
                  );
                  if (videoType == Constant.upcomingContentType ||
                      videoType == Constant.channelContentType ||
                      videoType == Constant.kidsContentType) {
                    if (subVideoType == Constant.movieContentType) {
                      videoDetailsProvider.setLoading(true);
                      if (!(context.mounted)) return;
                      await navigatorKey.currentState?.push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return ContentVideoDetails(
                                  videoId,
                                  subVideoType,
                                  videoType,
                                  typeId,
                                );
                              },
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return child;
                              },
                        ),
                      );
                    } else if (subVideoType == Constant.showContentType) {
                      showDetailsProvider.setLoading(true);
                      if (!(context.mounted)) return;
                      await navigatorKey.currentState?.push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return ContentShowDetails(
                                  videoId,
                                  subVideoType,
                                  videoType,
                                  typeId,
                                );
                              },
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return child;
                              },
                        ),
                      );
                    }
                  } else if (videoType == Constant.shortsContentType) {
                    clipsProvider.setLoading(true);
                    if (!(context.mounted)) return;
                    await navigatorKey.currentState?.push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return Clips(clipId: videoId, openFrom: "");
                        },
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                      ),
                    );
                  } else {
                    if (videoType == Constant.movieContentType) {
                      videoDetailsProvider.setLoading(true);
                      if (!(context.mounted)) return;
                      await navigatorKey.currentState?.push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return ContentVideoDetails(
                                  videoId,
                                  subVideoType,
                                  videoType,
                                  typeId,
                                );
                              },
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return child;
                              },
                        ),
                      );
                    } else if (videoType == Constant.showContentType) {
                      showDetailsProvider.setLoading(true);
                      if (!(context.mounted)) return;
                      await navigatorKey.currentState?.push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return ContentShowDetails(
                                  videoId,
                                  subVideoType,
                                  videoType,
                                  typeId,
                                );
                              },
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return child;
                              },
                        ),
                      );
                    }
                  }
                }
              }
            } else {
              printLog("Invalid URL format");
            }
          } else {
            printLog("URL is not configured for DeepLink.");
          }
        }
      });
    } on PlatformException catch (e) {
      printLog("initDeepLinks Exception ======> $e");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _clearAndDispose();
    super.dispose();
  }

  Future<void> _clearAndDispose() async {
    await WakelockPlus.disable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    printLog('didChangeAppLifecycleState state =====> ${state.name}');
    switch (state) {
      case AppLifecycleState.resumed:
        if (!mounted) return;
        break;
      case AppLifecycleState.paused:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (locale) {
        if (kIsWeb) {
          return _buildForWeb(locale: locale);
        } else {
          return _buildForOther(locale: locale);
        }
      },
    );
  }

  Widget _buildForWeb({required Locale? locale}) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme:
          ThemeData(
            primaryColor: colorPrimary,
            primaryColorDark: colorPrimaryDark,
            primaryColorLight: colorPrimary,
            scaffoldBackgroundColor: appBgColor,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: kIsWeb
                  ? {
                      for (final platform in TargetPlatform.values)
                        platform: const NoTransitionsBuilder(),
                    }
                  : const {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
            ),
          ).copyWith(
            scrollbarTheme: const ScrollbarThemeData().copyWith(
              thumbColor: WidgetStateProperty.all(white),
              trackVisibility: WidgetStateProperty.all(true),
              trackColor: WidgetStateProperty.all(white.withValues(alpha: 0.5)),
            ),
          ),
      title: Constant.appName,
      localizationsDelegates: Locales.delegates,
      supportedLocales: Locales.supportedLocales,
      locale: locale,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
            return locale;
          },
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 360, name: MOBILE),
            const Breakpoint(start: 361, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1000, name: DESKTOP),
            const Breakpoint(start: 1001, end: double.infinity, name: '4K'),
          ],
        );
      },
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
          PointerDeviceKind.trackpad,
        },
      ),
    );
  }

  Widget _buildForOther({required Locale? locale}) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], //HERE
      theme:
          ThemeData(
            primaryColor: colorPrimary,
            primaryColorDark: colorPrimaryDark,
            primaryColorLight: colorPrimary,
            scaffoldBackgroundColor: appBgColor,
          ).copyWith(
            scrollbarTheme: const ScrollbarThemeData().copyWith(
              thumbColor: WidgetStateProperty.all(white),
              trackVisibility: WidgetStateProperty.all(true),
              trackColor: WidgetStateProperty.all(white.withValues(alpha: 0.5)),
            ),
          ),
      title: Constant.appName,
      localizationsDelegates: Locales.delegates,
      supportedLocales: Locales.supportedLocales,
      locale: locale,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
            return locale;
          },
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
      },
      home: const Splash(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
          PointerDeviceKind.trackpad,
        },
      ),
    );
  }

  Future _fetchIntro() async {
    final generalsetting = Provider.of<GeneralProvider>(context, listen: false);
    if (connectivityProvider.isOnline) {
      await generalsetting.getIntroPages();

      if (!mounted) return;
      await generalsetting.getGeneralsetting(context);
      if (generalsetting.generalSettingModel.result != null &&
          (generalsetting.generalSettingModel.result?.length ?? 0) > 0) {
        String? screenRecordStatus = await Utils.configByStatus(
          status: Constant.screenRecordStatus,
        );
        printLog('_fetchIntro screenRecordStatus ==> $screenRecordStatus');
        if (screenRecordStatus == "1") {
          if (!kIsWeb) Utils.preventScreenCapture();
        }
      }
    }
  }

  Future<void> getAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();

    String versionName = info.version;
    String versionCode = info.buildNumber;
    printLog("Version Name: $versionName");
    printLog("Version Code: $versionCode");

    Constant.appVersion = versionName;
  }

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      printLog('_getDeviceInfo Running on : ${webBrowserInfo.platform}');
      printLog('_getDeviceInfo userAgent ======>> ${webBrowserInfo.userAgent}');
      Constant.deviceName = webBrowserInfo.platform ?? '';

      /* <<<<<< Web DeviceId START >>>>>> */
      final cookies = html.document.cookie?.split('; ') ?? [];
      final deviceIdCookie = cookies.firstWhere(
        (cookie) => cookie.startsWith('device_id='),
        orElse: () => '',
      );

      printLog('_getDeviceInfo deviceIdCookie =====>> $deviceIdCookie');
      if (deviceIdCookie.isNotEmpty) {
        printLog(
          '_getDeviceInfo deviceIdCookie =====>> ${deviceIdCookie.split('=')[1]}',
        );
        Constant.currentDeviceId = deviceIdCookie.split('=')[1];
      } else {
        final uuid = const Uuid().v4();
        final generatedDeviceId = Utils.sha256ofString(uuid);
        printLog('_getDeviceInfo uuid ===============>> $uuid');
        printLog('_getDeviceInfo generatedDeviceId ==>> $generatedDeviceId');
        html.document.cookie =
            'device_id=$generatedDeviceId; path=/; max-age=31536000'; // 1 year
        Constant.currentDeviceId = generatedDeviceId;
      }
      /* <<<<<< Web DeviceId END >>>>>> */
    } else {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        Constant.isTV = androidInfo.systemFeatures.contains(
          'android.software.leanback',
        );
        printLog("_getDeviceInfo isTV ==============> ${Constant.isTV}");
        printLog('_getDeviceInfo Running on : ${androidInfo.product}');
        Constant.deviceName = "${androidInfo.brand} ${androidInfo.product}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        printLog('_getDeviceInfo Running on : ${iosInfo.utsname.machine}');
        Constant.deviceName = iosInfo.utsname.machine;
      }

      /* <<<<<< DeviceId START >>>>>> */
      try {
        String consistentUdid = await FlutterUdid.consistentUdid;
        String udid = await FlutterUdid.udid;
        printLog("_getDeviceInfo consistentUdid ======> $consistentUdid");
        printLog("_getDeviceInfo udid ================> $udid");
        Constant.currentDeviceId = consistentUdid;
      } on PlatformException catch (e) {
        printLog("_getDeviceInfo PlatformException ===> $e");
      }
      /* <<<<<< DeviceId END >>>>>> */
    }
    printLog(
      "===========================\nDeviceName => ${Constant.deviceName}\nDeviceId => ${Constant.currentDeviceId}\n===========================",
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    return child!;
  }
}
