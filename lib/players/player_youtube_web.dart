import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../main.dart';
import '../model/playermodel.dart';
import '../players/orientationmanager.dart';
import '../provider/connectivityprovider.dart';
import '../provider/playerprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';

class PlayerYoutubeWeb extends StatefulWidget {
  final PlayerModel playerModel;
  const PlayerYoutubeWeb({super.key, required this.playerModel});

  @override
  State<PlayerYoutubeWeb> createState() => PlayerYoutubeWebState();
}

class PlayerYoutubeWebState extends State<PlayerYoutubeWeb>
    with RouteAware, WidgetsBindingObserver {
  YoutubePlayerController? controller;
  bool fullScreen = false;
  late PlayerProvider playerProvider;
  late ConnectivityProvider connectivityProvider;
  int? playerCPosition;

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
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    OrientationManager.forceLandscape();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerInit();
    });
  }

  @override
  void didChangeDependencies() {
    printLog("========= didChangeDependencies =========");
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPop() {
    printLog("========= didPop =========");
    super.didPop();
  }

  @override
  void didPopNext() {
    printLog("========= didPopNext =========");
    if (controller == null) {
      _playerInit();
    }
    super.didPopNext();
  }

  @override
  void didPush() {
    printLog("========= didPush =========");
    super.didPush();
  }

  @override
  void didPushNext() {
    printLog("========= didPushNext =========");
    super.didPushNext();
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

    controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    printLog("videoUrl :===> ${widget.playerModel.videoUrl}");

    String? videoId = "";
    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      videoId = YoutubePlayerController.convertUrlToId(
        widget.playerModel.videoUrl ?? "",
      );
    } else {
      videoId = YoutubePlayerController.convertUrlToId(
        widget.playerModel.trailerUrl ?? "",
      );
    }
    printLog("videoId :====> $videoId");
    controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );

    Future.delayed(const Duration(seconds: 1)).then((value) {
      if (!mounted) return;
      controller?.playVideo();
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await onBackPressed(didPop);
      },
      child: Scaffold(body: SafeArea(child: _buildPlayerUI())),
    );
  }

  Widget _buildPlayerUI() {
    return Stack(
      children: [
        if (controller == null)
          Utils.pageLoader()
        else
          YoutubePlayerScaffold(
            backgroundColor: appBgColor,
            controller: controller!,
            autoFullScreen: true,
            defaultOrientations: const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            builder: (context, player) {
              return Scaffold(
                body: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return player;
                    },
                  ),
                ),
              );
            },
          ),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    controller?.close();
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
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
    double? currentPos;
    currentPos = await controller?.currentTime;
    playerCPosition = (currentPos ?? 0).toInt();
    printLog("onBackPressed playerCPosition :===> $playerCPosition");
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
