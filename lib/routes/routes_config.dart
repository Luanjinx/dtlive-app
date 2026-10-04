import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../players/player_youtube_web.dart';
import '../webpages/webclipsepisodes.dart';
import '../model/playermodel.dart';
import '../pages/activetv.dart';
import '../players/player_vdocipher.dart';
import '../provider/homeprovider.dart';
import '../subscription/allpayment.dart';
import '../subscription/contactus.dart';
import '../subscription/mypurchaselist.dart';
import '../players/player_vimeo.dart';
import '../routes/routes_constant.dart';
import '../subscription/mysubscribedplan.dart';
import '../subscription/subscription.dart';
import '../subscription/subscriptionhistory.dart';
import '../webpages/webmyspace.dart';
import '../webpages/webprofile.dart';
import '../webpages/webprofileavatar.dart';
import '../webpages/webprofileedit.dart';
import '../webpages/websearch.dart';
import '../webpages/websectionviewall.dart';
import '../webpages/websettings.dart';
import '../pages/referandearn.dart';
import '../pages/referandearnhistory.dart';
import '../provider/referandearnhistoryprovider.dart';
import '../subscription/wallet.dart';
import '../subscription/wallethistory.dart';
import '../provider/walletprovider.dart';
import '../webpages/webviewall.dart';
import '../main.dart';
import '../players/player_video.dart';
import '../webpages/weberrorpage.dart';
import '../webpages/webhome.dart';
import '../webpages/webcontentvideodetails.dart';
import '../webpages/webrentstore.dart';
import '../webpages/webcontentshowdetails.dart';
import '../webpages/webcontentbyid.dart';
import '../webpages/webmywatchlist.dart';
import '../webpages/webratingreview.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';

class RoutesConfig {
  GoRouter goRouter = GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,
    observers: [routeObserver], //HERE
    routes: [
      /* Initial route by Platform */
      GoRoute(
        path: '/',
        name: RoutesConstant.homePage,
        builder: (context, state) {
          return const WebHome(
            newPage: RoutesConstant.homePage,
            oldPage: RoutesConstant.homePage,
            reqText: '',
          );
        },
      ),

      /* Search */
      GoRoute(
        name: RoutesConstant.searchPage,
        path: '/${RoutesConstant.searchPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          printLog("searchPage extra ====> ${state.extra}");
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("searchPage newPage ==> $newPage");

          homeProvider.getSectionType();

          return WebSearch(
            newPage: RoutesConstant.searchPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Rent */
      GoRoute(
        name: RoutesConstant.storePage,
        path: '/${RoutesConstant.storePage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =====> $newPage");
          homeProvider.getSectionType();
          return WebRentStore(
            newPage: RoutesConstant.storePage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Watchlist */
      GoRoute(
        name: RoutesConstant.myWatchlistPage,
        path: '/${RoutesConstant.myWatchlistPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =====> $newPage");
          homeProvider.getSectionType();
          return WebMyWatchlist(
            newPage: RoutesConstant.myWatchlistPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Clip's Episodes */
      GoRoute(
        path:
            '/${RoutesConstant.clipsEpisodesPage}/:videotype/:typeid/:videoid/:subvideotype',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          final videoTypeStr = state.pathParameters['videotype'];
          final typeIdStr = state.pathParameters['typeid'];
          final videoIdStr = state.pathParameters['videoid'];
          final subVideoTypeStr = state.pathParameters['subvideotype'];

          final int videoType = int.tryParse(videoTypeStr ?? "0") ?? 0;
          final int typeId = int.tryParse(typeIdStr ?? "0") ?? 0;
          final int videoId = int.tryParse(videoIdStr ?? "0") ?? 0;
          final int subVideoType = int.tryParse(subVideoTypeStr ?? "0") ?? 0;

          String newPage = "";
          if (state.extra is Map<String, dynamic>) {
            newPage = (state.extra as Map<String, dynamic>)['newpage'] ?? "";
          }

          homeProvider.getSectionType();

          return WebClipsEpisodes(
            newPage: RoutesConstant.clipsEpisodesPage,
            oldPage: newPage,
            reqText: "",
            videoId: videoId,
            videoType: videoType,
            typeId: typeId,
            subVideoType: subVideoType,
          );
        },
      ),
      GoRoute(
        path:
            '/${RoutesConstant.clipsEpisodesPage}/:videotype/:typeid/:videoid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          final videoTypeStr = state.pathParameters['videotype'];
          final typeIdStr = state.pathParameters['typeid'];
          final videoIdStr = state.pathParameters['videoid'];

          final int videoType = int.tryParse(videoTypeStr ?? "0") ?? 0;
          final int typeId = int.tryParse(typeIdStr ?? "0") ?? 0;
          final int videoId = int.tryParse(videoIdStr ?? "0") ?? 0;

          String newPage = "";
          if (state.extra is Map<String, dynamic>) {
            newPage = (state.extra as Map<String, dynamic>)['newpage'] ?? "";
          }

          homeProvider.getSectionType();

          return WebClipsEpisodes(
            newPage: RoutesConstant.clipsEpisodesPage,
            oldPage: newPage,
            reqText: "",
            videoId: videoId,
            videoType: videoType,
            typeId: typeId,
            subVideoType: 0,
          );
        },
      ),

      /* Video/Show Details */
      GoRoute(
        path:
            '/${RoutesConstant.contentDetailsPage}/:videotype/:typeid/:videoid/:subvideotype',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          final videoTypeStr = state.pathParameters['videotype'];
          final typeIdStr = state.pathParameters['typeid'];
          final videoIdStr = state.pathParameters['videoid'];
          final subVideoTypeStr = state.pathParameters['subvideotype'];

          final int videoType = int.tryParse(videoTypeStr ?? "0") ?? 0;
          final int typeId = int.tryParse(typeIdStr ?? "0") ?? 0;
          final int videoId = int.tryParse(videoIdStr ?? "0") ?? 0;
          final int subVideoType = int.tryParse(subVideoTypeStr ?? "0") ?? 0;

          String newPage = "";
          if (state.extra is Map<String, dynamic>) {
            newPage = (state.extra as Map<String, dynamic>)['newpage'] ?? "";
          }

          homeProvider.getSectionType();

          final bool isShowDetails =
              (videoType == Constant.upcomingContentType ||
                  videoType == Constant.channelContentType ||
                  videoType == Constant.kidsContentType)
              ? subVideoType == Constant.showContentType
              : videoType == Constant.showContentType;

          return isShowDetails
              ? WebContentShowDetails(
                  videoId,
                  subVideoType,
                  videoType,
                  typeId,
                  newPage: RoutesConstant.contentDetailsPage,
                  oldPage: newPage,
                  reqText: "deeplink",
                  key: ValueKey("$videoId$videoType$typeId$subVideoType"),
                )
              : WebContentVideoDetails(
                  videoId,
                  subVideoType,
                  videoType,
                  typeId,
                  newPage: RoutesConstant.contentDetailsPage,
                  oldPage: newPage,
                  reqText: "deeplink",
                  key: ValueKey("$videoId$videoType$typeId$subVideoType"),
                );
        },
      ),
      GoRoute(
        path:
            '/${RoutesConstant.contentDetailsPage}/:videotype/:typeid/:videoid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          final videoTypeStr = state.pathParameters['videotype'];
          final typeIdStr = state.pathParameters['typeid'];
          final videoIdStr = state.pathParameters['videoid'];

          final int videoType = int.tryParse(videoTypeStr ?? "0") ?? 0;
          final int typeId = int.tryParse(typeIdStr ?? "0") ?? 0;
          final int videoId = int.tryParse(videoIdStr ?? "0") ?? 0;

          String newPage = "";
          if (state.extra is Map<String, dynamic>) {
            newPage = (state.extra as Map<String, dynamic>)['newpage'] ?? "";
          }

          homeProvider.getSectionType();

          final bool isShowDetails = (videoType == Constant.showContentType);

          return isShowDetails
              ? WebContentShowDetails(
                  videoId,
                  0,
                  videoType,
                  typeId,
                  newPage: RoutesConstant.contentDetailsPage,
                  oldPage: newPage,
                  reqText: "deeplink",
                  key: ValueKey("$videoId$videoType$typeId"),
                )
              : WebContentVideoDetails(
                  videoId,
                  0,
                  videoType,
                  typeId,
                  newPage: RoutesConstant.contentDetailsPage,
                  oldPage: newPage,
                  reqText: "deeplink",
                  key: ValueKey("$videoId$videoType$typeId"),
                );
        },
      ),

      /* Section ViewAll */
      GoRoute(
        path:
            '/${RoutesConstant.sectionDetailsPage}/:itemid/:videotype/:screenlayout',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? videoType, itemID, screenLayout, appBarTitle;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          videoType = state.pathParameters['videotype'];
          screenLayout = state.pathParameters['screenlayout'];
          printLog("sectionDetails videoId =======> $itemID");
          printLog("sectionDetails screenLayout ==> $screenLayout");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("sectionDetails newPage =======> $newPage");
          printLog("sectionDetails screenLayout ==> $screenLayout");
          printLog("sectionDetails appBarTitle ===> $appBarTitle");

          if (itemID != null && videoType != null) {
            homeProvider.getSectionType();
            return WebSectionViewAll(
              sectionId: int.parse(itemID),
              videoType: int.parse(videoType),
              appBarTitle: appBarTitle ?? "",
              screenLayout: screenLayout ?? "",
              newPage: RoutesConstant.sectionDetailsPage,
              oldPage: newPage,
              reqText: itemID,
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Video By Category */
      GoRoute(
        path: '/${RoutesConstant.videoByCatPage}/:itemid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, layoutType, appBarTitle;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          printLog("videoByCatPage itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            layoutType = extraData['layouttype'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("videoByCatPage newPage =======> $newPage");
          printLog("videoByCatPage screenLayout ==> $layoutType");
          printLog("videoByCatPage appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebVideosByID(
              int.parse(itemID),
              appBarTitle ?? "",
              RoutesConstant.videoByCatPage,
              newPage: RoutesConstant.videoByCatPage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Video By Language */
      GoRoute(
        path: '/${RoutesConstant.videoByLanguagePage}/:itemid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, layoutType, appBarTitle;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          printLog("videoByLanguage itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            layoutType = extraData['layouttype'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("videoByLanguage newPage =======> $newPage");
          printLog("videoByLanguage screenLayout ==> $layoutType");
          printLog("videoByLanguage appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebVideosByID(
              int.parse(itemID),
              appBarTitle ?? "",
              RoutesConstant.videoByLanguagePage,
              newPage: RoutesConstant.videoByLanguagePage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Video By Channel */
      GoRoute(
        path: '/${RoutesConstant.videoByChannelPage}/:itemid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, layoutType, appBarTitle;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          printLog("videoByChannel itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            layoutType = extraData['layouttype'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("videoByChannel newPage =======> $newPage");
          printLog("videoByChannel screenLayout ==> $layoutType");
          printLog("videoByChannel appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebVideosByID(
              int.parse(itemID),
              appBarTitle ?? "",
              RoutesConstant.videoByChannelPage,
              newPage: RoutesConstant.videoByChannelPage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Video By Cast */
      GoRoute(
        path: '/${RoutesConstant.videoByCastPage}/:itemid',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, layoutType, appBarTitle;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          printLog("videoByCast itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            layoutType = extraData['layouttype'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("videoByCast newPage =======> $newPage");
          printLog("videoByCast screenLayout ==> $layoutType");
          printLog("videoByCast appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebVideosByID(
              int.parse(itemID),
              appBarTitle ?? "",
              RoutesConstant.videoByCastPage,
              newPage: RoutesConstant.videoByCastPage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* View All */
      GoRoute(
        path:
            '/${RoutesConstant.relatedContentPage}/:itemid/:typeid/:videotype/:subvideotype',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, appBarTitle, subVideoType, videoType, typeId;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          subVideoType = state.pathParameters['subvideotype'];
          videoType = state.pathParameters['videotype'];
          typeId = state.pathParameters['typeid'];
          printLog("relatedContent itemID =======> $itemID");
          printLog("relatedContent subVideoType =======> $subVideoType");
          printLog("relatedContent itemID =======> $itemID");
          printLog("relatedContent itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("relatedContent newPage =======> $newPage");
          printLog("relatedContent appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebViewAll(
              appBarTitle: RoutesConstant.relatedContentPage,
              videoId: int.parse(itemID),
              subVideoType: int.parse(subVideoType ?? "0"),
              videoType: int.parse(videoType ?? "0"),
              typeId: int.parse(typeId ?? "0"),
              newPage: RoutesConstant.relatedContentPage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),
      GoRoute(
        path:
            '/${RoutesConstant.relatedContentPage}/:itemid/:typeid/:videotype',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          String newPage = "";
          String? itemID, appBarTitle, videoType, typeId;
          // Extract parameters from URL, not `state.extra`
          itemID = state.pathParameters['itemid'];
          videoType = state.pathParameters['videotype'];
          typeId = state.pathParameters['typeid'];
          printLog("relatedContent itemID =======> $itemID");
          printLog("relatedContent itemID =======> $itemID");
          printLog("relatedContent itemID =======> $itemID");

          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            appBarTitle = extraData['title'] as String;
          }
          printLog("relatedContent newPage =======> $newPage");
          printLog("relatedContent appBarTitle ===> $appBarTitle");

          if (itemID != null) {
            homeProvider.getSectionType();
            return WebViewAll(
              appBarTitle: RoutesConstant.relatedContentPage,
              videoId: int.parse(itemID),
              subVideoType: 0,
              videoType: int.parse(videoType ?? "0"),
              typeId: int.parse(typeId ?? "0"),
              newPage: RoutesConstant.relatedContentPage,
              oldPage: newPage,
              reqText: '',
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Continue Watching (ViewAll) */
      GoRoute(
        name: RoutesConstant.continueWatchPage,
        path: '/${RoutesConstant.continueWatchPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          Map<String, dynamic> extraData = {};
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
          }
          printLog("newPage =====> $newPage");
          homeProvider.getSectionType();
          return WebViewAll(
            appBarTitle: RoutesConstant.continueWatchPage,
            videoId: 0,
            subVideoType: 0,
            videoType: 0,
            typeId: 0,
            newPage: RoutesConstant.continueWatchPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Players */
      GoRoute(
        name: RoutesConstant.playerPage,
        path: '/${RoutesConstant.playerPage}',
        builder: (context, state) {
          String newPage = "";
          PlayerModel playerModel;
          if (state.extra != null && state.extra is PlayerModel) {
            playerModel = state.extra as PlayerModel;
            printLog("newPage =====> $newPage");
            if (playerModel.uploadType == "youtube") {
              return PlayerYoutubeWeb(playerModel: playerModel);
            } else if (playerModel.uploadType == "external") {
              if ((playerModel.videoUrl ?? "").contains('youtube')) {
                return PlayerYoutubeWeb(playerModel: playerModel);
              } else if ((playerModel.videoUrl ?? "").contains("vimeo")) {
                return PlayerVimeo(playerModel: playerModel);
              } else {
                return PlayerVideo(playerModel: playerModel);
              }
            } else if (playerModel.uploadType == "live_stream_url") {
              if ((playerModel.videoUrl ?? "").contains('youtube')) {
                return PlayerYoutubeWeb(playerModel: playerModel);
              } else if ((playerModel.videoUrl ?? "").contains("vimeo")) {
                return PlayerVimeo(playerModel: playerModel);
              } else {
                return PlayerVideo(playerModel: playerModel);
              }
            } else if (playerModel.uploadType == "vimeo") {
              return PlayerVimeo(playerModel: playerModel);
            } else if (playerModel.uploadType == Constant.vdocipherPlayType) {
              return PlayerVdoCipher(playerModel: playerModel);
            } else {
              return PlayerVideo(playerModel: playerModel);
            }
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Login */
      // GoRoute(
      //   name: RoutesConstant.loginSocialPage,
      //   path: '/${RoutesConstant.loginSocialPage}',
      //   builder: (context, state) {
      //     String newPage = "";
      //     if (state.extra != null && state.extra is String) {
      //       newPage = state.extra as String;
      //       printLog("newPage =====> $newPage");
      //       if (kIsWeb || Constant.isTV) {
      //         return WebLoginSocial(
      //           newPage: RoutesConstant.loginSocialPage,
      //           oldPage: newPage,
      //           reqText: '',
      //         );
      //       }
      //       return const LoginSocial();
      //     } else {
      // return WebErrorPage(
      //   (state.error != null)
      //       ? (state.error!)
      //       : Exception(Locales.string(context, "page_not_found")),
      // );
      //     }
      //   },
      // ),
      /* Login OTP */
      // GoRoute(
      //   name: RoutesConstant.loginOTPPage,
      //   path: '/${RoutesConstant.loginOTPPage}',
      //   builder: (context, state) {
      //     String newPage = "", mobileNumber = "";
      //     Map<String, dynamic> extraData = {};
      //     if (state.extra != null && state.extra is Map<String, dynamic>) {
      //       extraData = state.extra as Map<String, dynamic>;
      //       newPage = extraData['newpage'] as String;
      //       mobileNumber = extraData['mobile'] as String;
      //       printLog("newPage =======> $newPage");
      //       printLog("mobileNumber ==> $mobileNumber");
      //       if (kIsWeb || Constant.isTV) {
      //         return WebOTPVerify(
      //           mobileNumber,
      //           newPage: RoutesConstant.loginOTPPage,
      //           oldPage: newPage,
      //           reqText: '',
      //         );
      //       }
      //       return OTPVerify(mobileNumber);
      //     } else {
      // return WebErrorPage(
      //   (state.error != null)
      //       ? (state.error!)
      //       : Exception(Locales.string(context, "page_not_found")),
      // );
      //     }
      //   },
      // ),

      /* Avatar */
      GoRoute(
        name: RoutesConstant.avatarPage,
        path: '/${RoutesConstant.avatarPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return WebProfileAvatar(
            newPage: RoutesConstant.avatarPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Profile */
      GoRoute(
        name: RoutesConstant.myProfilePage,
        path: '/${RoutesConstant.myProfilePage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return WebProfile(
            newPage: RoutesConstant.myProfilePage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* My Sapce */
      GoRoute(
        name: RoutesConstant.mySpacePage,
        path: '/${RoutesConstant.mySpacePage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return WebMySpace(
            newPage: RoutesConstant.mySpacePage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Settings */
      GoRoute(
        name: RoutesConstant.settingsPage,
        path: '/${RoutesConstant.settingsPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return WebSettings(
            newPage: RoutesConstant.settingsPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Edit Profile */
      GoRoute(
        name: RoutesConstant.editProfilePage,
        path: '/${RoutesConstant.editProfilePage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return WebProfileEdit(
            newPage: RoutesConstant.editProfilePage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Active TV */
      GoRoute(
        name: RoutesConstant.activeTVPage,
        path: '/${RoutesConstant.activeTVPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return ActiveTV(
            newPage: RoutesConstant.activeTVPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Subscription */
      GoRoute(
        name: RoutesConstant.subscriptionPage,
        path: '/${RoutesConstant.subscriptionPage}',
        builder: (context, state) {
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          return Subscription(
            newPage: RoutesConstant.subscriptionPage,
            oldPage: newPage,
          );
        },
      ),

      /* My Subscription */
      GoRoute(
        name: RoutesConstant.mySubscribePlanPage,
        path: '/${RoutesConstant.mySubscribePlanPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();

          return MySubscribedPlan(
            newPage: RoutesConstant.mySubscribePlanPage,
            oldPage: newPage,
          );
        },
      ),

      /* Contact Us */
      GoRoute(
        name: RoutesConstant.contactUsPage,
        path: '/${RoutesConstant.contactUsPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return ContactUs(
            newPage: RoutesConstant.contactUsPage,
            oldPage: newPage,
          );
        },
      ),

      /* All Payments Page */
      GoRoute(
        name: RoutesConstant.paymentPage,
        path: '/${RoutesConstant.paymentPage}',
        builder: (context, state) {
          String newPage = "";
          Map<String, dynamic> extraData = {};
          final String? payType,
              producerId,
              itemId,
              price,
              itemTitle,
              typeId,
              videoType,
              subVideoType,
              productPackage,
              currency;
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            extraData = state.extra as Map<String, dynamic>;
            newPage = extraData['newpage'] as String;
            itemId = extraData['itemid'] as String;
            producerId = extraData['producerid'] as String;
            payType = extraData['paytype'] as String;
            price = extraData['price'] as String;
            itemTitle = extraData['title'] as String;
            typeId = extraData['typeid'] as String;
            videoType = extraData['videotype'] as String;
            subVideoType = extraData['subvideotype'] as String;
            productPackage = extraData['productpackage'] as String;
            currency = extraData['currency'] as String;

            printLog("newPage =====> $newPage");
            return AllPayment(
              newPage: RoutesConstant.paymentPage,
              oldPage: newPage,
              reqText: '',
              payType: payType,
              producerId: producerId,
              itemId: itemId,
              price: price,
              itemTitle: itemTitle,
              typeId: typeId,
              videoType: videoType,
              subVideoType: subVideoType,
              productPackage: productPackage,
              currency: currency,
            );
          } else {
            return WebErrorPage(
              (state.error != null)
                  ? (state.error!)
                  : Exception(Locales.string(context, "page_not_found")),
            );
          }
        },
      ),

      /* Subscription History */
      GoRoute(
        name: RoutesConstant.subsHistoryPage,
        path: '/${RoutesConstant.subsHistoryPage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return SubscriptionHistory(
            newPage: RoutesConstant.subsHistoryPage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Rent Purchases */
      GoRoute(
        name: RoutesConstant.rentPurchasePage,
        path: '/${RoutesConstant.rentPurchasePage}',
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );
          String newPage = "";
          if (state.extra != null && state.extra is String) {
            newPage = state.extra as String;
          }
          printLog("newPage =======> $newPage");
          homeProvider.getSectionType();
          return MyPurchaselist(
            newPage: RoutesConstant.rentPurchasePage,
            oldPage: newPage,
            reqText: '',
          );
        },
      ),

      /* Refer & Earn */
      GoRoute(
        name: RoutesConstant.referEarnPage,
        path: '/${RoutesConstant.referEarnPage}',
        builder: (context, state) {
          Provider.of<HomeProvider>(context, listen: false).getSectionType();
          return const ReferEarn();
        },
      ),

      /* Refer & Earn History */
      GoRoute(
        name: RoutesConstant.referEarnHistoryPage,
        path: '/${RoutesConstant.referEarnHistoryPage}',
        builder: (context, state) {
          Provider.of<HomeProvider>(context, listen: false).getSectionType();
          Provider.of<ReferEarnHistoryProvider>(
            context,
            listen: false,
          ).clearProvider();
          return const ReferEarnHistory();
        },
      ),

      /* Wallet */
      GoRoute(
        name: RoutesConstant.walletPage,
        path: '/${RoutesConstant.walletPage}',
        builder: (context, state) {
          Provider.of<HomeProvider>(context, listen: false).getSectionType();
          return const Wallet();
        },
      ),

      /* Wallet History */
      GoRoute(
        name: RoutesConstant.walletHistoryPage,
        path: '/${RoutesConstant.walletHistoryPage}',
        builder: (context, state) {
          Provider.of<HomeProvider>(context, listen: false).getSectionType();
          Provider.of<WalletProvider>(
            context,
            listen: false,
          ).clearTransactions();
          return const WalletHistory();
        },
      ),

      /* Rating & Review */
      GoRoute(
        path:
            '/${RoutesConstant.ratingReviewPage}/:videotype/:subvideotype/:videoid',
        name: RoutesConstant.ratingReviewPage,
        builder: (context, state) {
          final homeProvider = Provider.of<HomeProvider>(
            context,
            listen: false,
          );

          final videoTypeStr = state.pathParameters['videotype'];
          final subVideoTypeStr = state.pathParameters['subvideotype'];
          final videoIdStr = state.pathParameters['videoid'];
          final int videoType = int.tryParse(videoTypeStr ?? "0") ?? 0;
          final int subVideoType = int.tryParse(subVideoTypeStr ?? "0") ?? 0;
          final int videoId = int.tryParse(videoIdStr ?? "0") ?? 0;

          String newPage = "";
          String title = "";
          String poster = "";
          String contentType = "movie";
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            newPage = extra['newpage'] ?? "";
            title = extra['title'] ?? "";
            poster = extra['poster'] ?? "";
            contentType = extra['contenttype'] ?? "movie";
          }

          homeProvider.getSectionType();

          return WebRatingReview(
            newPage: RoutesConstant.ratingReviewPage,
            oldPage: newPage,
            reqText: '',
            videoId: videoId,
            videoType: videoType,
            subVideoType: subVideoType,
            videoTitle: title,
            posterUrl: poster,
            contentType: contentType,
          );
        },
      ),

      /* Payment Success */
      GoRoute(
        name: RoutesConstant.paymentSuccessPage,
        path: '/${RoutesConstant.paymentSuccessPage}',
        builder: (context, state) {
          return const SuccessPage();
        },
      ),

      /* Payment Cancel */
      GoRoute(
        name: RoutesConstant.paymentCancelPage,
        path: '/${RoutesConstant.paymentCancelPage}',
        builder: (context, state) {
          return const CancelPage();
        },
      ),
    ],
    errorBuilder: (context, state) {
      return WebErrorPage(
        (state.error != null)
            ? (state.error!)
            : Exception(Locales.string(context, "page_not_found")),
      );
    },
    debugLogDiagnostics: true,
  );
}
