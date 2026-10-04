import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';

import '../players/orientationmanager.dart';
import '../model/playermodel.dart';
import '../provider/connectivityprovider.dart';
import '../provider/playerprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../web_js/js_helper.dart';

class PlayerVdoCipher extends StatefulWidget {
  final PlayerModel playerModel;
  const PlayerVdoCipher({super.key, required this.playerModel});

  @override
  State<PlayerVdoCipher> createState() => PlayerVdoCipherState();
}

class PlayerVdoCipherState extends State<PlayerVdoCipher>
    with RouteAware, WidgetsBindingObserver {
  final JSHelper _jsHelper = JSHelper();
  EmbedInfo? vdoEmbedInfo;
  late PlayerProvider playerProvider;
  late ConnectivityProvider connectivityProvider;
  int? playerCPosition, videoDuration;

  VdoPlayerController? _controller;
  VdoPlayerValue? vdoPlayerValue;
  final double aspectRatio = 16 / 9;
  final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);
  Duration? duration;

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
        dynamic isSubscribed = await Utils.openSubscription(
          context: context,
          oldPage: "",
        );
        printLog("isSubscribed =========> $isSubscribed");
        if (!mounted) return;
        if (isSubscribed != null && isSubscribed == false) {
          return;
        }
      }
    }
    /* ************** */

    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      printLog(
        "_playerInit otp ===========> ${widget.playerModel.cipherMediaDetails?.otp}",
      );
      printLog(
        "_playerInit playbackInfo ==> ${widget.playerModel.cipherMediaDetails?.playbackInfo}",
      );
      vdoEmbedInfo = EmbedInfo.streaming(
        otp: widget.playerModel.cipherMediaDetails?.otp ?? "",
        playbackInfo: widget.playerModel.cipherMediaDetails?.playbackInfo ?? "",
        embedInfoOptions: EmbedInfoOptions(
          autoplay: true,
          resumePosition: Duration(
            milliseconds: widget.playerModel.stopTime ?? 0,
          ),
        ),
      );
    }
    printLog("vdoEmbedInfo mediaId ===> ${vdoEmbedInfo?.mediaId}");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });

    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      /* Add Video view */
      playerProvider.addVideoView(
        widget.playerModel.videoId.toString(),
        widget.playerModel.videoType.toString(),
        widget.playerModel.subVideoType.toString(),
        widget.playerModel.episodeId.toString(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    } else {
      _jsHelper.callBrowserFullscreen(false);
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
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: _buildPlayerUI(),
      ),
    );
  }

  AppBar? buildWebAppBar() {
    if (kIsWeb) {
      return AppBar(
        backgroundColor: black,
        elevation: 0,
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        centerTitle: true,
        leading: IconButton(
          autofocus: true,
          focusColor: white.withValues(alpha: 0.5),
          onPressed: () {
            onBackPressed(false);
          },
          icon: const Icon(Icons.arrow_back, color: white),
        ),
      );
    } else {
      return null;
    }
  }

  Widget _buildPlayerUI() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: _getPlayerWidth(),
            height: _getPlayerHeight(),
            alignment: Alignment.center,
            child: (vdoEmbedInfo != null)
                ? VdoPlayer(
                    embedInfo: vdoEmbedInfo!,
                    aspectRatio: aspectRatio,
                    onError: _onVdoError,
                    onFullscreenChange: _onFullscreenChange,
                    onPlayerCreated: _onPlayerCreated,
                    controls: true,
                    onPictureInPictureModeChanged:
                        _onPictureInPictureModeChanged,
                  )
                : SizedBox(height: 70, width: 70, child: Utils.pageLoader()),
          ),
        ),
        if (!kIsWeb)
          Positioned(
            top: 15,
            left: 15,
            child: SafeArea(
              child: InkWell(
                onTap: () {
                  if (MediaQuery.of(context).size.width >
                      MediaQuery.of(context).size.height) {
                    OrientationManager.forcePortrait();
                  } else {
                    onBackPressed(false);
                  }
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

  void _onVdoError(VdoError vdoError) {
    if (kDebugMode) {
      print("Oops, the system encountered a problem: ${vdoError.message}");
    }
  }

  void _onPlayerCreated(VdoPlayerController? controller) {
    if (kIsWeb) {
      _jsHelper.callBrowserFullscreen(true);
    }
    setState(() {
      _controller = controller;
      _onEventChange(_controller);
    });
    _onFullscreenChange(true);
  }

  void _onPictureInPictureModeChanged(bool isInPictureInPictureMode) {}

  void _onEventChange(VdoPlayerController? controller) {
    controller?.addListener(() {
      vdoPlayerValue = controller.value;
      playerCPosition = controller.value.position.inMilliseconds;
      videoDuration = controller.value.duration.inMilliseconds;
    });
  }

  void _onFullscreenChange(bool isFullscreen) {
    if (isFullscreen) {
      OrientationManager.forceLandscape();
      if (kIsWeb) {
        _jsHelper.callBrowserFullscreen(true);
      }
    } else {
      if (!kIsWeb) {
        OrientationManager.forcePortrait();
      } else {
        _jsHelper.callBrowserFullscreen(false);
      }
    }
    setState(() {
      _isFullScreen.value = isFullscreen;
    });
  }

  double _getPlayerWidth() {
    return MediaQuery.of(context).size.width;
  }

  double _getPlayerHeight() {
    return _isFullScreen.value
        ? MediaQuery.of(context).size.height
        : _getHeightForWidth(MediaQuery.of(context).size.width);
  }

  double _getHeightForWidth(double width) {
    if (kIsWeb) {
      return width / aspectRatio;
    } else {
      return width;
    }
  }

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    } else {
      _jsHelper.callBrowserFullscreen(false);
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
