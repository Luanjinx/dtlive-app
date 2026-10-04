import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';

import '../model/playermodel.dart';
import '../players/orientationmanager.dart';
import '../provider/connectivityprovider.dart';
import '../provider/playerprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';

class PlayerVimeo extends StatefulWidget {
  final PlayerModel playerModel;
  const PlayerVimeo({super.key, required this.playerModel});

  @override
  State<PlayerVimeo> createState() => PlayerVimeoState();
}

class PlayerVimeoState extends State<PlayerVimeo>
    with RouteAware, WidgetsBindingObserver {
  String? vimeoVideoId;
  late PlayerProvider playerProvider;
  late ConnectivityProvider connectivityProvider;
  int? playerCPosition, videoDuration;

  bool isVideoLoading = true;

  /// Controller of the WebView
  InAppWebViewController? webViewController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    printLog('didChangeAppLifecycleState state =====> ${state.name}');
    switch (state) {
      case AppLifecycleState.resumed:
        if (connectivityProvider.isOnline &&
            (widget.playerModel.playType == "Video" ||
                widget.playerModel.playType == "Show") &&
            Constant.userID != null &&
            widget.playerModel.isPremium == 1) {
          playerProvider.addRemoveDevice(1);
        }
        break;
      case AppLifecycleState.paused:
        if (connectivityProvider.isOnline &&
            (widget.playerModel.playType == "Video" ||
                widget.playerModel.playType == "Show") &&
            Constant.userID != null &&
            widget.playerModel.isPremium == 1) {
          playerProvider.addRemoveDevice(2);
        }
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    super.initState();
    OrientationManager.forceLandscape();
    _playerInit();
  }

  Future<void> _playerInit() async {
    WidgetsFlutterBinding.ensureInitialized();

    /* ******* Check Device Sync ******* */
    if (connectivityProvider.isOnline &&
        (widget.playerModel.playType == "Video" ||
            widget.playerModel.playType == "Show") &&
        Constant.userID != null &&
        widget.playerModel.isPremium == 1) {
      await playerProvider.addRemoveDevice(1);
      if (!playerProvider.isDeviceAdded) {
        if (!mounted) return;
        dynamic isNotWatching = await Utils.openWebDialog(
          context: context,
          newPage: RoutesConstant.cannotWatchPage,
          oldPage: "",
          reqText: "",
        );
        printLog("isNotWatching =========> $isNotWatching");
        if (!mounted) return;
        if (isNotWatching != null && isNotWatching == false) {
          Utils.exitPage(context);
          return;
        }
      }
    }
    /* ************** */

    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      vimeoVideoId = widget.playerModel.videoUrl;
    } else {
      vimeoVideoId = widget.playerModel.trailerUrl;
    }
    if ((vimeoVideoId ?? "").contains("vimeo.com") ||
        (vimeoVideoId ?? "").contains("vimeo")) {
      vimeoVideoId = extractVimeoId(vimeoVideoId ?? "");
    }
    printLog("vimeo VideoId ===> $vimeoVideoId");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });

    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      /* Add Video view */
      await playerProvider.addVideoView(
        widget.playerModel.videoId.toString(),
        widget.playerModel.videoType.toString(),
        widget.playerModel.subVideoType.toString(),
        widget.playerModel.episodeId.toString(),
      );
    }
  }

  String? extractVimeoId(String url) {
    final regExp = RegExp(
      r'(?:vimeo\.com/(?:video/)?|player\.vimeo\.com/video/)(\d+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    webViewController?.dispose();
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await onBackPressed(didPop);
      },
      child: Scaffold(
        backgroundColor: black,
        body: SafeArea(child: _buildPlayerUI()),
      ),
    );
  }

  Widget _buildPlayerUI() {
    return Stack(
      children: [
        VimeoVideoPlayer(
          videoId: vimeoVideoId ?? "",
          isAutoPlay: true,
          onInAppWebViewCreated: (controller) {
            webViewController = controller;
          },
          onInAppWebViewLoadStart: (controller, url) {
            setState(() {
              isVideoLoading = true;
            });
          },
          onInAppWebViewLoadStop: (controller, url) {
            setState(() {
              isVideoLoading = false;
            });
          },
        ),
        if (isVideoLoading) const Center(child: CircularProgressIndicator()),
        if (!kIsWeb)
          Positioned(
            top: 15,
            left: 15,
            child: SafeArea(
              child: InkWell(
                onTap: () {
                  onBackPressed(false);
                },
                focusColor: gray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                child: Utils.buildBackBtnDesign(context),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    printLog("onBackPressed playerCPosition :===> $playerCPosition");
    printLog("onBackPressed videoDuration :===> $videoDuration");
    printLog("onBackPressed playType :===> ${widget.playerModel.playType}");

    /* Remove Device from Watch START ********* */
    if (connectivityProvider.isOnline &&
        (widget.playerModel.playType == "Video" ||
            widget.playerModel.playType == "Show") &&
        Constant.userID != null &&
        widget.playerModel.isPremium == 1) {
      playerProvider.addRemoveDevice(2);
    }
    /* *********** Remove Device from Watch END */

    if ((widget.playerModel.playType == "Video" ||
            widget.playerModel.playType == "Show") &&
        Constant.userID != null) {
      if ((playerCPosition ?? 0) > 0) {
        /* Add to Continue */
        if (connectivityProvider.isOnline) {
          await playerProvider.addToContinue(
            "${widget.playerModel.videoId}",
            "${widget.playerModel.episodeId}",
            "${widget.playerModel.videoType}",
            "${widget.playerModel.subVideoType}",
            "$playerCPosition",
          );
        }
        if (!mounted) return;
        Utils.exitPage(context);
      } else {
        if (!mounted) return;
        Utils.exitPage(context);
      }
    } else {
      if (!mounted) return;
      Utils.exitPage(context);
    }
  }
}
