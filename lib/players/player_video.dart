import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_locales/flutter_locales.dart';

import '../main.dart';
import '../web_js/js_helper.dart';
import '../players/orientationmanager.dart';
import '../provider/connectivityprovider.dart';
import '../provider/playerprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../widget/myfileimage.dart'; // [TASK-3]
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../model/playermodel.dart';
import 'model/optionitem.dart';
import 'model/subtitlemodel.dart';
import 'model/subtitlemodel.dart' as mysubtitle;
import 'model/vdociphermodel.dart';

String duration2String(Duration? dur, {showLive = '🔴 Live'}) {
  Duration duration = dur ?? const Duration();
  if (duration.inSeconds <= 0) {
    return showLive;
  } else {
    return duration.toString().split('.').first.padLeft(8, "0");
  }
}

class PlayerVideo extends StatefulWidget {
  final PlayerModel playerModel;

  const PlayerVideo({super.key, required this.playerModel});

  @override
  State<PlayerVideo> createState() => _PlayerVideoState();
}

class _PlayerVideoState extends State<PlayerVideo>
    with RouteAware, WidgetsBindingObserver, TickerProviderStateMixin {
  // [NEW] multi-ticker for controls + enter/exit
  // FIX-B1
  final JSHelper _jsHelper = JSHelper();
  late PlayerProvider playerProvider;
  late ConnectivityProvider connectivityProvider;

  final _pipChannel = MethodChannel('${Constant.appPackageName}/pip');

  late VideoPlayerController _videoPlayerController;
  bool _isControllerReady =
      false; // [FIX] guards all controller access before init
  bool _showControls = true;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;
  int? playerCPosition, videoTotalDuration;
  Timer? _durationTimer;
  Duration? videoCPosition, videoTDuration;
  int _doubleTapCountForward = 0;
  int _doubleTapCountBackward = 0;
  Timer? _doubleTapTimer;

  int _lastListenerPositionMs = -1;
  bool _isQualitySwitching = false;

  // Controls show/hide animation
  late AnimationController _controlsAnimController;
  late Animation<double> _controlsFadeAnim;

  // [NEW] FEATURE-9: Enter/exit animation
  late AnimationController _enterExitAnim;
  late Animation<double> _enterFade;
  late Animation<double> _enterScale;

  // [NEW] FEATURE-1: Long-press speed boost
  bool _isLongPressSpeed = false;
  double _speedBeforeLongPress = 1.0;

  // [NEW] FEATURE-2: Lock screen
  bool _isScreenLocked = false;

  bool _isMouseOverPlayer = false; // [WEB-1] tracks mouse hover state on web
  bool _isWebFullscreen = false; // [WEB-2] tracks browser fullscreen state
  bool _isWebCursorVisible =
      true; // [FIX-CUR] dedicated cursor flag — decoupled from _showControls

  // [NEW] FEATURE-4: Scrub preview
  bool _isScrubbing = false;
  double _scrubValue = 0.0;

  SubtitleController? subtitleController;

  /* Volume/Brightness START */
  late final VolumeController? _volumeController;
  /* Volume/Brightness END */

  /* Next Episode Pop-up START */
  bool _showNextEpisodePopup = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  static const int nextEpisodeThresholdMs = 60000; // 60 seconds
  static const int safeStartDelayMs = 3000;

  bool _hasShownNextEpisodePopup = false;
  int _initialPositionMs = 0;
  double _popupOpacity = 1.0;
  double _countdownProgress = 1.0; // 1.0 = full bar, 0.0 = empty
  /* Next Episode Pop-up END */

  /* IMA Ads START */
  String? imaAdsFeatureStatus;
  AdsLoader? _adsLoader;
  AdsManager? _adsManager;
  AppLifecycleState _lastLifecycleState = AppLifecycleState.resumed;
  bool _isAdActuallyPlaying = false;
  bool _shouldShowContentVideo = false;
  // Guard: prevents duplicate _resumeContent() calls per ad break.
  bool _contentResumeHandled = false;
  // Drives ContentProgressProvider so mid-roll cue points advance correctly.
  Timer? _contentProgressTimer;
  ContentProgressProvider? _contentProgressProvider;
  AdDisplayContainer? _adDisplayContainer;

  /// Returns true when IMA ads should be shown for this session.
  /// Ads are mobile-only, feature-flag-gated, and skipped for purchased/rented content.
  bool _shouldShowAds() {
    if (kIsWeb) return false;
    if (imaAdsFeatureStatus != "1") return false;
    if (widget.playerModel.isBuy == 1 || widget.playerModel.rentBuy == 1) {
      return false;
    }
    return true;
  }

  Future<void> _requestAds(AdDisplayContainer container) {
    return _adsLoader?.requestAds(
          AdsRequest(
            adTagUrl: Constant.imaAdTags,
            contentProgressProvider: _contentProgressProvider,
          ),
        ) ??
        Future.value();
  }

  /// Starts a 200ms timer that feeds the current playback position into
  /// [ContentProgressProvider] so the IMA SDK can trigger mid-roll cue points.
  void _startContentProgressUpdates() {
    _contentProgressTimer?.cancel();
    if (_contentProgressProvider == null) return;
    _contentProgressTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      if (!mounted) return;
      if (_isAdActuallyPlaying) return;
      if (!_isControllerReady) return; // [FIX] check flag first
      if (!_videoPlayerController.value.isInitialized) return;
      final pos = _videoPlayerController.value.position;
      final dur = _videoPlayerController.value.duration;
      if (dur > Duration.zero) {
        _contentProgressProvider?.setProgress(progress: pos, duration: dur);
      }
    });
  }

  void _stopContentProgressUpdates() {
    _contentProgressTimer?.cancel();
    _contentProgressTimer = null;
  }

  void _setupAdsManager(AdsManager manager) {
    manager.setAdsManagerDelegate(
      AdsManagerDelegate(
        onAdEvent: (AdEvent event) async {
          if (!mounted || _adsManager == null) return;
          printLog("IMA Event: ${event.type}");
          switch (event.type) {
            case AdEventType.loaded:
              // Ad data arrived — reset resume guard and start playback.
              _contentResumeHandled = false;
              await _adsManager?.start();

            case AdEventType.contentPauseRequested:
              // IMA wants content paused (pre-roll, mid-roll, post-roll).
              _stopContentProgressUpdates();
              await _videoPlayerController.pause();
              _isAdActuallyPlaying = true;
              _shouldShowContentVideo = false;
              playerProvider.notifyProvider();

            case AdEventType.started:
              // Individual ad started playing.
              // Ensure content audio is silent even if already paused.
              if (_videoPlayerController.value.isPlaying) {
                await _videoPlayerController.pause();
              }

            case AdEventType.contentResumeRequested:
              // IMA wants content to resume — this is the single correct trigger.
              if (_contentResumeHandled) return;
              _contentResumeHandled = true;
              _isAdActuallyPlaying = false;
              playerProvider.notifyProvider();
              await _resumeContent();

            case AdEventType.allAdsCompleted:
              // All ad pods exhausted — release manager to avoid leaks.
              _adsManager?.destroy();
              _adsManager = null;

            case _:
              break;
          }
        },
        onAdErrorEvent: (AdErrorEvent event) {
          printLog("IMA Error: ${event.error.message}");
          _isAdActuallyPlaying = false;
          if (!_contentResumeHandled) {
            _contentResumeHandled = true;
            _resumeContent();
          }
        },
      ),
    );
    manager.init(settings: AdsRenderingSettings());
  }

  Future<void> _resumeContent() async {
    if (!mounted) return;
    _isAdActuallyPlaying = false;
    _shouldShowContentVideo = true;
    playerProvider.notifyProvider();

    if (_isControllerReady && _videoPlayerController.value.isInitialized) {
      // [FIX]
      await _videoPlayerController.play();
      startDurationTimer();
      // Restart progress updates so future mid-roll cue points advance.
      _startContentProgressUpdates();
      if (!kIsWeb) _updateVideoState(isPlaying: true);
    }
  }
  /* IMA Ads END */

  /// Send video state to Android for PIP player
  void _updateVideoState({required bool isPlaying}) {
    if (!_isControllerReady) return; // [FIX]
    final cPosition = _videoPlayerController.value.position.inSeconds;
    printLog("_updateVideoState cPosition : $cPosition");
    try {
      _pipChannel.invokeMethod('updateVideoState', {
        "isPlaying": isPlaying,
        "videoUrl": widget.playerModel.videoUrl ?? "",
        "position": cPosition,
      });
    } on PlatformException catch (e) {
      printLog("_updateVideoState Failed : ${e.message}");
    }
  }

  void _updateVideoProgress() {
    if (!_isControllerReady) return; // [FIX]
    final cPosition = _videoPlayerController.value.position.inSeconds;
    try {
      _pipChannel.invokeMethod('videoProgress', {"position": cPosition});
    } on PlatformException catch (e) {
      printLog("_updateVideoProgress Failed : ${e.message}");
    }
  }

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
        if (!kIsWeb && _isAdActuallyPlaying) {
          _adsManager?.resume();
        }
      case AppLifecycleState.inactive:
        // Android Activity.onPause — only pause ad if we were in foreground.
        if (!kIsWeb &&
            _isAdActuallyPlaying &&
            _lastLifecycleState == AppLifecycleState.resumed) {
          _adsManager?.pause();
        }
      case AppLifecycleState.hidden:
      // if (connectivityProvider.isOnline &&
      //         (widget.playerModel.playType == "Video" ||
      //             widget.playerModel.playType == "Show") &&
      //         Constant.userID !=
      //             null /* &&
      //     (widget.playerModel.isPremium == 1) */
      //     ) {
      //   // playerProvider.addRemoveDevice(2);
      //   enterPipMode(widget.playerModel.videoUrl ?? "");
      // }
      case AppLifecycleState.paused:
        if (connectivityProvider.isOnline &&
            (widget.playerModel.playType == "Video" ||
                widget.playerModel.playType == "Show") &&
            Constant.userID != null &&
            widget.playerModel.isPremium == 1) {
          playerProvider.addRemoveDevice(2);
        }
      case AppLifecycleState.detached:
    }
    _lastLifecycleState = state;
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

  @override
  void initState() {
    super.initState();
    printLog("initState videoUrl ======> ${widget.playerModel.videoUrl}");
    printLog("initState uploadType ====> ${widget.playerModel.uploadType}");
    printLog("initState stopTime ======> ${widget.playerModel.stopTime}");
    // Store the starting resume position (stopTime)
    _initialPositionMs = widget.playerModel.stopTime ?? 0;

    // Controls show/hide animation — start visible
    _controlsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _controlsFadeAnim = CurvedAnimation(
      parent: _controlsAnimController,
      curve: Curves.easeInOut,
    );

    // [NEW] FEATURE-9: Enter animation — scale+fade in on open
    _enterExitAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _enterFade = CurvedAnimation(parent: _enterExitAnim, curve: Curves.easeOut);
    _enterScale = Tween<double>(
      begin: 1.05,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterExitAnim, curve: Curves.easeOut));
    _enterExitAnim.forward(); // [NEW] kick off enter animation

    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    _volumeController = kIsWeb ? null : VolumeController.instance;

    // Required for didChangeAppLifecycleState (ad pause/resume on background).
    WidgetsBinding.instance.addObserver(this);

    // [FIX] _setVideoURL() moved inside addPostFrameCallback and awaited
    // DO NOT call _setVideoURL() here — it is async and must be awaited
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Step 1: Force landscape first, wait for system to apply it
      if (!kIsWeb) {
        OrientationManager.forceLandscape();
        await Future.delayed(const Duration(milliseconds: 80));
      }
      // Step 2: [FIX] Await controller init BEFORE anything else touches it
      await _setVideoURL();
      if (!mounted) return;
      _isControllerReady = true; // [FIX] controller now safely assigned

      // Step 3: Fetch ads config
      imaAdsFeatureStatus = await Utils.configByStatus(
        status: Constant.playerIMAAdsStatus,
      );
      printLog('_getData imaAdsFeatureStatus =======> $imaAdsFeatureStatus');
      _shouldShowContentVideo = false;
      _isAdActuallyPlaying = false;

      // Step 4: Init ads + player (controller guaranteed assigned)
      _initIMAAds();
    });
    if (kIsWeb) {
      // [WEB-4] Web: start with controls hidden — hover will show them
      _showControls = false;
      _controlsAnimController.value = 0.0;
      // [FIX-CUR] _isWebCursorVisible stays true (initialized above)
      // Never hide cursor before user has even interacted with player
    } else {
      // Mobile: start with controls visible, then auto-hide
      _startHideTimer();
    }
  }

  Future<void> _initIMAAds() async {
    final showAds = _shouldShowAds();
    _contentProgressProvider = showAds ? ContentProgressProvider() : null;
    _adDisplayContainer = showAds
        ? AdDisplayContainer(
            onContainerAdded: (AdDisplayContainer container) {
              // Guard: avoid "Already Initialized" crash on hot-restart / re-entry.
              if (_adsLoader != null) {
                printLog("IMA: AdsLoader already exists, re-requesting ads");
                _requestAds(container);
                return;
              }

              _adsLoader = AdsLoader(
                container: container,
                onAdsLoaded: (OnAdsLoadedData data) {
                  printLog('IMA: Ad loaded');
                  _adsManager = data.manager;
                  _setupAdsManager(data.manager);
                },
                onAdsLoadError: (AdsLoadErrorData data) {
                  printLog('IMA: Load error — ${data.error.message}');
                  _adsManager = null;
                  if (!_contentResumeHandled) {
                    _contentResumeHandled = true;
                    _resumeContent();
                  }
                },
              );

              _requestAds(container);
            },
          )
        : null;

    _playerInit();
  }

  Future<void> _playerInit() async {
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

    /* Subtitles & Quality */
    printLog("sSubTitleUrls Length =======> ${Constant.subtitleUrls.length}");
    if (widget.playerModel.playType == "Video" ||
        widget.playerModel.playType == "Show") {
      if (Constant.resolutionsUrls.isNotEmpty) {
        playerProvider.setCurrentQuality(
          Constant.resolutionsUrls[0].qualityName,
        );
      }
    } else {
      Constant.resolutionsUrls.clear();
    }
    /* ************** */

    /* Volume Change */
    if (!kIsWeb) {
      _volumeController?.getVolume().then((v) {
        playerProvider.volumeLevel = v;
        playerProvider.lastVolumeLevel = playerProvider.volumeLevel;
      });
      _volumeController?.isMuted().then((isMuted) {
        playerProvider.isVolMuted = isMuted;
      });

      /* Brightness Change */
      ScreenBrightness().application.then((b) {
        playerProvider.brightnessLevel = b;
      });
    }
    playerProvider.notifyProvider();

    initializePlayer();

    if (connectivityProvider.isOnline &&
        (widget.playerModel.playType == "Video" ||
            widget.playerModel.playType == "Show")) {
      /* Add Video view */
      playerProvider.addVideoView(
        widget.playerModel.videoId.toString(),
        widget.playerModel.videoType.toString(),
        widget.playerModel.subVideoType.toString(),
        widget.playerModel.episodeId.toString(),
      );
    }
  }

  Future<void> _setVideoURL() async {
    if (!kIsWeb && widget.playerModel.playType == "Download") {
      dynamic tempFile;

      /* Decrypt & Play START ******************** */
      tempFile = await Utils.decryptUsingFFMPEG([
        File(widget.playerModel.videoUrl ?? ""),
        widget.playerModel.securityKey ?? "",
        widget.playerModel.securityIVKey,
        context,
      ]);
      printLog("_playerInit tempFile ======> $tempFile");
      if (tempFile != null) {
        _videoPlayerController = VideoPlayerController.file(
          File(tempFile?.path ?? ""),
        );
      } else {
        printLog("_playerInit decrypt Failed, playing original file URL");
        _videoPlayerController = VideoPlayerController.file(
          File(widget.playerModel.videoUrl ?? ""),
        );
      }
      /* ********************** Decrypt & Play END */
    } else {
      if (widget.playerModel.playType == "Video" ||
          widget.playerModel.playType == "Show") {
        if (Constant.resolutionsUrls.isNotEmpty) {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(Constant.resolutionsUrls[0].qualityUrl),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
              allowBackgroundPlayback: false,
            ),
          );
        } else {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.playerModel.videoUrl ?? ""),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
              allowBackgroundPlayback: false,
            ),
          );
        }
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.playerModel.trailerUrl ?? ""),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }
    }
  }

  Future<void> initializePlayer() async {
    await Future.wait([_videoPlayerController.initialize()]).then((
      value,
    ) async {
      if (mounted) {
        printLog(
          "initializePlayer stopTime :===> ${widget.playerModel.stopTime}",
        );

        /* Subtitle Loads — fire in background, don't block video start */
        unawaited(_loadSubtitleInBackground());

        if (widget.playerModel.stopTime != null &&
            (widget.playerModel.stopTime ?? 0) > 0) {
          await _videoPlayerController.seekTo(
            Duration(milliseconds: widget.playerModel.stopTime ?? 0),
          );
        }

        // [WEB-2] Browser fullscreen is now controlled by dedicated button only
        if (_isAdActuallyPlaying) {
          printLog("IMA: Ad started before video init — keeping video paused.");
          await _videoPlayerController.pause();
          _shouldShowContentVideo = false;
        } else {
          if (_shouldShowAds()) {
            // Ads enabled: hold video paused until contentResumeRequested fires.
            printLog("IMA: Video ready, waiting for pre-roll ad...");
            await _videoPlayerController.pause();
            _shouldShowContentVideo = false;
          } else {
            // No ads: start content immediately and begin progress reporting.
            await _resumeContent();
          }
        }
        if (!mounted) return;
        playerProvider.notifyProvider();
        _startHideTimer();
        startDurationTimer();
      }
    });

    _videoPlayerController.addListener(
      _onVideoListener,
    ); // [OPT] named method for clean removal

    /* Handle PIP */
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == "pipClosed") {
        int? position = call.arguments;
        if (position != null) {
          playerCPosition = position;
          playerProvider.notifyProvider();

          printLog("pipClosed playerCPosition :=====> $playerCPosition");
          // Resume video from last position
          await _videoPlayerController.seekTo(
            Duration(seconds: playerCPosition ?? 0),
          );
          playPausePlayer(true);
        }
      }
    });
  }

  // [OPT] OPT-2: Named listener for clean addListener/removeListener pairing
  void _onVideoListener() {
    if (!mounted) return;
    final posMs = _videoPlayerController.value.position.inMilliseconds;
    final durMs = _videoPlayerController.value.duration.inMilliseconds;
    playerCPosition = posMs;
    videoTotalDuration = durMs;
    // Throttle: run expensive checks only every 500ms of playback change
    if ((posMs - _lastListenerPositionMs).abs() < 500) return;
    _lastListenerPositionMs = posMs;
    _checkNextEpisodeTrigger(posMs, durMs);
  }

  Future<void> playPausePlayer(bool isPlay) async {
    if (!mounted) return;
    if (!isPlay) {
      await _videoPlayerController.pause();
    } else {
      await _videoPlayerController.play();
    }
    playerProvider.notifyProvider();
    _startHideTimer();
  }

  /* Player Duration Monitor START *************** */
  Future<void> _durationMonitor() async {
    if (!_isControllerReady) return; // [FIX]
    // monitor cast events
    var dur = _videoPlayerController.value.duration,
        pos = _videoPlayerController.value.position;
    if (!mounted) return;
    if (videoTDuration == null ||
        (videoTDuration?.inSeconds != dur.inSeconds)) {
      videoTDuration = dur;
    }
    if (videoCPosition == null ||
        (videoCPosition?.inSeconds != pos.inSeconds)) {
      videoCPosition = pos;
    }
    if (!kIsWeb) {
      _updateVideoProgress();
    }
    playerProvider.notifyProvider();
  }

  void resetDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void startDurationTimer() {
    if (_durationTimer?.isActive ?? false) {
      return;
    }
    resetDurationTimer();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationMonitor();
      if (!mounted) return;
      playerProvider.setSubtitlePosition(_videoPlayerController.value.position);
      printLog(
        "startDurationTimer _subtitlesPosition :===> ${playerProvider.subtitlesPosition}",
      );
    });
  }
  /* ***************** Player Duration Monitor END */

  Future<void> _loadSubtitleInBackground() async {
    if (Constant.subtitleUrls.isEmpty) return;
    try {
      playerProvider.setCurrentSubtitle(Constant.subtitleUrls[0].subtitleLang);
      final response = await http.get(
        Uri.parse(Constant.subtitleUrls[0].subtitleUrl),
      );
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        subtitleController = SubtitleController.string(
          body,
          format: SubtitleFormat.srt,
        );
        playerProvider.setSubtitles(
          subtitleController!.subtitles.map((e) {
            return mysubtitle.Subtitle(
              index: e.number,
              start: Duration(milliseconds: e.start),
              end: Duration(milliseconds: e.end),
              text: e.text,
            );
          }).toList(),
        );
        if (mounted) playerProvider.notifyProvider();
      }
    } catch (e) {
      printLog("_loadSubtitleInBackground error: $e");
    }
  }

  @override
  void dispose() {
    _controlsAnimController.dispose();
    _enterExitAnim.dispose(); // [NEW] FEATURE-9
    WidgetsBinding.instance.removeObserver(this);
    _stopContentProgressUpdates();
    if (!kIsWeb) {
      if (_isControllerReady) _updateVideoState(isPlaying: false); // [FIX]
      _adsManager?.pause();
      _adsManager?.destroy();
      _adsManager = null;
      OrientationManager.forcePortrait();
    } else {
      _jsHelper.callBrowserFullscreen(false);
    }
    _adsLoader = null;
    _countdownTimer?.cancel();
    _durationTimer?.cancel();
    _hideTimer?.cancel();
    _doubleTapTimer?.cancel();
    if (_isControllerReady) {
      // [FIX] only access if assigned
      _videoPlayerController.removeListener(_onVideoListener);
      _videoPlayerController.dispose();
    }
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    int totalSeconds = _countdownSeconds;

    _countdownProgress = 1.0; // full bar
    if (!mounted) return;
    playerProvider.notifyProvider();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds <= 1) {
        _countdownTimer?.cancel();
        _playNextEpisode();
      } else {
        _countdownSeconds--;
        _countdownProgress = _countdownSeconds / totalSeconds;
        playerProvider.notifyProvider();
      }
    });
  }

  void _cancelNextEpisode() {
    if (!mounted) return;
    _countdownTimer?.cancel(); // Stop countdown timer
    _showNextEpisodePopup = false; // Hide popup
    _hasShownNextEpisodePopup = true; // Prevent re-trigger during same playback
    playerProvider.notifyProvider();
  }

  // [NEW] FEATURE-7: Rewritten to use shared _jumpToEpisode + smooth fade transition
  Future<void> _playNextEpisode() async {
    if (!mounted) return;
    setState(() => _popupOpacity = 0.0);
    await Future.delayed(
      const Duration(milliseconds: 250),
    ); // fade-out animation only
    if (!mounted) return;

    final nextIndex = (widget.playerModel.currentEpiPos ?? 0) + 1;
    final list = widget.playerModel.episodeList;
    if (list == null || nextIndex >= list.length) {
      await onBackPressed(false);
      return;
    }
    await _jumpToEpisode(nextIndex);
  }

  // [NEW] FEATURE-6 + FEATURE-7: Shared jump-to-episode logic (used by panel + countdown)
  Future<void> _jumpToEpisode(int index) async {
    if (!mounted) return;
    final list = widget.playerModel.episodeList;
    if (list == null || index >= list.length) return;

    final ep = list[index];

    /* VdoCipher OTP */
    VdoCipherModel? vdocipherDetails;
    if ((ep.videoUploadType ?? "") == Constant.vdocipherPlayType &&
        widget.playerModel.playType != "Trailer") {
      if (!mounted) return;
      vdocipherDetails = await Utils.getVdoCipherOTP(
        context: context,
        videoId: ep.video320 ?? "",
      );
      if (kDebugMode) {
        printLog(
          "_jumpToEpisode vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
        );
      }
    }
    /* VdoCipher OTP */

    final playerModel = PlayerModel(
      playType: widget.playerModel.playType,
      isLive: false,
      videoId: widget.playerModel.videoId ?? 0,
      videoTitle: widget.playerModel.videoTitle ?? "",
      videoType: widget.playerModel.videoType ?? 0,
      subVideoType: 0,
      typeId: widget.playerModel.typeId ?? 0,
      episodeId: ep.id ?? 0,
      videoUrl: ep.video320 ?? "",
      cipherMediaDetails: (vdocipherDetails?.result != null)
          ? vdocipherDetails!.result
          : null,
      trailerUrl: widget.playerModel.trailerUrl ?? "",
      uploadType: widget.playerModel.uploadType ?? "",
      videoThumb: ep.landscape ?? "",
      stopTime: 0, // [FIX] FIX-2: always 0 for any new episode jump
      isPremium: widget.playerModel.isPremium ?? 0,
      isBuy: widget.playerModel.isBuy ?? 0,
      isRent: widget.playerModel.isRent ?? 0,
      rentBuy: widget.playerModel.rentBuy ?? 0,
      securityKey: widget.playerModel.securityKey ?? "",
      securityIVKey: widget.playerModel.securityIVKey ?? "",
      currentEpiPos: index,
      episodeList: list,
    );

    if (!mounted || !context.mounted) return;
    if (kIsWeb) {
      context.pushReplacement(
        "/${RoutesConstant.playerPage}",
        extra: playerModel,
      );
    } else {
      // [NEW] FEATURE-7: FadeTransition instead of MaterialPageRoute
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PlayerVideo(playerModel: playerModel),
          transitionsBuilder: (context, anim, secondaryAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  // [NEW] FEATURE-6: Episode switcher panel
  void _showEpisodePanel() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: white.withValues(alpha: 0.24), // [IMP-4]
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  MyText(
                    // [TASK-2]
                    color: white,
                    text: "episodes",
                    multilanguage: true,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: white.withValues(alpha: 0.54), // [IMP-4]
                      size: 20,
                    ),
                    onPressed: () => Utils.exitDialog(context),
                  ),
                ],
              ),
            ),
            Divider(color: white.withValues(alpha: 0.12), height: 1), // [IMP-4]
            LimitedBox(
              maxHeight: 320,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.playerModel.episodeList?.length ?? 0,
                itemBuilder: (_, i) {
                  final ep = widget.playerModel.episodeList![i];
                  final isCurrent =
                      i == (widget.playerModel.currentEpiPos ?? 0);
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: MyNetworkImage(
                        imageUrl: ep.landscape ?? "",
                        width: 72,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: MyText(
                      color: isCurrent ? colorAccent : white, // [IMP-4]
                      text: ep.name ?? ep.description ?? "Episode ${i + 1}",
                      multilanguage: false,
                      textalign: TextAlign.start,
                      fontsizeNormal: 13,
                      fontsizeWeb: 14,
                      fontweight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                    subtitle: isCurrent
                        ? MyText(
                            // [TASK-2]
                            color: colorAccent,
                            text: "now_playing",
                            multilanguage: true,
                            fontsizeNormal: 11,
                            fontsizeWeb: 12,
                            fontweight: FontWeight.w400,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                          )
                        : null,
                    trailing: isCurrent
                        ? Icon(
                            Icons.play_arrow_rounded,
                            color: colorAccent, // [IMP-4]
                            size: 20,
                          )
                        : null,
                    onTap: isCurrent
                        ? null
                        : () {
                            Utils.exitDialog(context);
                            _jumpToEpisode(i);
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    ).then((_) {
      if (_videoPlayerController.value.isPlaying) _startHideTimer();
    });
  }

  void _resetDoubleTapCount() {
    _doubleTapCountForward = 0;
    _doubleTapCountBackward = 0;
    _doubleTapTimer?.cancel();
  }

  Future<void> _handleDoubleTap(bool isForward) async {
    if (isForward) {
      _doubleTapCountForward++;
      final seconds = 10 * _doubleTapCountForward;
      _videoPlayerController.seekTo(
        _videoPlayerController.value.position + Duration(seconds: seconds),
      );
      await playerProvider.showSeekPopupTexts("+$seconds", isForward);
    } else {
      _doubleTapCountBackward++;
      final seconds = 10 * _doubleTapCountBackward;
      _videoPlayerController.seekTo(
        _videoPlayerController.value.position - Duration(seconds: seconds),
      );
      await playerProvider.showSeekPopupTexts("-$seconds", isForward);
    }

    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(Duration(seconds: 1), () {
      _resetDoubleTapCount();
    });
  }

  Future<void> _toggleControls() async {
    // FIX-B2
    if (!_shouldShowContentVideo) return;
    if (!mounted) return;
    if (_showControls) {
      _hideControls();
    } else {
      _showControlsAnimated();
    }
  }

  void _showControlsAnimated() {
    if (!mounted) return;
    _showControls = true;
    _isWebCursorVisible =
        true; // [FIX-CUR] always show cursor when showing controls
    _controlsAnimController.forward();
    // [WEB-4] On web: only start hide timer if mouse has left the player
    if (!kIsWeb || !_isMouseOverPlayer) {
      _startHideTimer();
    }
    playerProvider.notifyProvider();
  }

  void _hideControls() {
    _controlsAnimController.reverse().then((_) {
      if (mounted) {
        _showControls = false;
        // [FIX-CUR] Hide cursor only after animation fully done AND mouse is not over player
        if (kIsWeb && !_isMouseOverPlayer) {
          _isWebCursorVisible = false;
        }
        playerProvider.notifyProvider();
      }
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    if (!mounted) return;
    _showControlsAnimated();
    _startHideTimer(); // [OPT] OPT-1: always restart countdown after cancel
  }

  // [WEB-2] Toggle browser fullscreen independently of BoxFit state
  void _toggleWebFullscreen() {
    if (!kIsWeb) return;
    _isWebFullscreen = !_isWebFullscreen;
    _jsHelper.callBrowserFullscreen(_isWebFullscreen);
    if (mounted) setState(() {});
    _startHideTimer();
  }

  Future<void> _startHideTimer() async {
    // FIX-C2
    _hideTimer?.cancel();
    // [WEB-1] On web: never auto-hide while mouse is over player
    if (kIsWeb && _isMouseOverPlayer) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      // FIX-C2: Only auto-hide when video is actually playing
      if (mounted &&
          _isControllerReady &&
          _videoPlayerController.value.isPlaying) {
        // [WEB-1] On web: double-check mouse is not over player before hiding
        if (kIsWeb && _isMouseOverPlayer) return;
        _hideControls();
      }
    });
  }

  void _checkNextEpisodeTrigger(int posMs, int durMs) {
    if (!_videoPlayerController.value.isInitialized) return;
    if (widget.playerModel.episodeList == null ||
        (widget.playerModel.episodeList?.length ?? 0) == 0) {
      return;
    }
    if (!_videoPlayerController.value.isPlaying) return;
    if (_hasShownNextEpisodePopup) return;
    if (durMs <= 0 || posMs <= 0) return;

    int remainingMs = durMs - posMs;
    if (remainingMs <= nextEpisodeThresholdMs && remainingMs > 0) {
      if (_initialPositionMs >= (durMs - nextEpisodeThresholdMs)) {
        if (posMs - _initialPositionMs < safeStartDelayMs) return;
      }
      int remainingSec = (remainingMs / 1000).floor();
      _countdownSeconds = remainingSec < 5 ? remainingSec : 5;
      if (!mounted) return;
      _showNextEpisodePopup = true;
      _hasShownNextEpisodePopup = true;
      _startCountdown();
      playerProvider.notifyProvider();
    }
  }

  Future<void> _seekBackward() async {
    _cancelAndRestartTimer();
    await _handleDoubleTap(false);
  }

  Future<void> _seekForward() async {
    _cancelAndRestartTimer();
    await _handleDoubleTap(true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, Size size) async {
    if (kIsWeb) return;
    final dx = details.globalPosition.dx;
    final dy = details.delta.dy;

    if (dx < size.width / 2) {
      // Left side: Brightness
      playerProvider.brightnessLevel -= dy * 0.005;
      playerProvider.brightnessLevel = playerProvider.brightnessLevel.clamp(
        0.0,
        1.0,
      );
      ScreenBrightness().setApplicationScreenBrightness(
        playerProvider.brightnessLevel,
      );
      playerProvider.showBrightnessBar = true;
    } else {
      // Right side: Volume
      playerProvider.volumeLevel -= dy * 0.005;
      playerProvider.volumeLevel = playerProvider.volumeLevel.clamp(0.0, 1.0);
      _volumeController?.setVolume(playerProvider.volumeLevel);
      playerProvider.showVolumeBar = true;
      await _volumeController?.setMute(playerProvider.volumeLevel <= 0);
      playerProvider.isVolMuted = (_volumeController != null)
          ? (await _volumeController.isMuted())
          : false;
    }
    playerProvider.notifyProvider();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _hideVolumeAndBrightnessBars();
  }

  void _onVerticalDragCancel() {
    _hideVolumeAndBrightnessBars();
  }

  void _hideVolumeAndBrightnessBars() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        playerProvider.showVolumeBar = false;
        playerProvider.showBrightnessBar = false;
        playerProvider.notifyProvider();
      }
    });
  }

  Future<void> updateMuteStatus(bool isMute) async {
    if (kIsWeb) return;
    if (isMute) {
      playerProvider.lastVolumeLevel = playerProvider.volumeLevel;
      playerProvider.volumeLevel = 0.0;
    } else {
      playerProvider.volumeLevel = playerProvider.lastVolumeLevel;
    }
    await _volumeController?.setMute(isMute);
    if (Platform.isIOS) {
      // On iOS, the system does not update the mute status immediately
      // You need to wait for the system to update the mute status
      await Future.delayed(Duration(milliseconds: 50));
    }
    playerProvider.isVolMuted = (_volumeController != null)
        ? (await _volumeController.isMuted())
        : false;
    playerProvider.notifyProvider();
  }

  /* Quality START ********************************** */
  void updateQualityUrl({
    required String qualityName,
    required String qualityUrl,
  }) async {
    printLog("updateQualityUrl qualityUrl =====NEW===> $qualityUrl");
    printLog("updateQualityUrl qualityName ====NEW===> $qualityName");
    printLog(
      "updateQualityUrl currentQuality =======> ${playerProvider.currentQuality}",
    );
    if (playerProvider.currentQuality == qualityName) return;

    setState(() => _isQualitySwitching = true);
    playerCPosition = (_videoPlayerController.value.position).inMilliseconds;
    final wasPlaying = _videoPlayerController.value.isPlaying;

    final newController = VideoPlayerController.networkUrl(
      Uri.parse(qualityUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    await newController.initialize();
    await newController.seekTo(Duration(milliseconds: playerCPosition ?? 0));

    if (!mounted) return;
    await _videoPlayerController.pause();
    _videoPlayerController.removeListener(
      _onVideoListener,
    ); // [OPT] remove before dispose
    await _videoPlayerController.dispose();

    _videoPlayerController = newController;
    _videoPlayerController.addListener(
      _onVideoListener,
    ); // [OPT] re-attach named listener

    if (wasPlaying) {
      await _videoPlayerController.play();
      startDurationTimer();
      _startContentProgressUpdates();
    }

    playerProvider.setCurrentQuality(qualityName);
    if (mounted) setState(() => _isQualitySwitching = false);
    playerProvider.notifyProvider();
  }
  /* ************************************ Quality END */

  /* Subtitle START ********************************** */
  Future<void> updateSubtitleUrl({required String subtitleUrl}) async {
    printLog("updateSubtitleUrl subtitleUrl ============> $subtitleUrl");
    printLog(
      "updateSubtitleUrl currentSubtitle ========> ${playerProvider.currentSubtitle}",
    );
    if (subtitleController != null) {
      /* Subtitle Loads START */
      String? body;
      playerProvider.setCurrentSubtitle(playerProvider.currentSubtitle);

      body = utf8.decode((await http.get(Uri.parse(subtitleUrl))).bodyBytes);
      subtitleController = null;
      subtitleController = SubtitleController.string(
        body,
        format: SubtitleFormat.srt,
      );

      if (body != "") {
        _videoPlayerController.setClosedCaptionFile(
          Future.value(SubRipCaptionFile(body)),
        );
      }

      playerProvider.setSubtitles(
        subtitleController!.subtitles.map((e) {
          printLog("updateSubtitleUrl setSubtitles number ==> ${e.number}");
          printLog("updateSubtitleUrl setSubtitles start ===> ${e.start}");
          printLog("updateSubtitleUrl setSubtitles end =====> ${e.end}");
          return mysubtitle.Subtitle(
            index: e.number,
            start: Duration(milliseconds: e.start),
            end: Duration(milliseconds: e.end),
            text: e.text,
          );
        }).toList(),
      );

      if (!mounted) return;
      playerProvider.setSubtitlePosition(_videoPlayerController.value.position);
      printLog(
        "updateSubtitleUrl _subtitlesPosition :===> ${playerProvider.subtitlesPosition}",
      );
      /* Subtitle Loads END */
      if (!mounted) return;
      await playerProvider.setSubtitleState(true);
    }
  }
  /* ************************************ Subtitle END */

  @override
  Widget build(BuildContext context) {
    // [NEW] FEATURE-9: Wrap in enter/exit animation
    return FadeTransition(
      opacity: _enterFade,
      child: ScaleTransition(
        scale: _enterScale,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            await onBackPressed(didPop);
          },
          child: Focus(
            autofocus: kIsWeb, // [WEB-2] auto-focus only on web for key events
            onKeyEvent:
                kIsWeb // [WEB-2]
                ? (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    // Space = play/pause
                    if (event.logicalKey == LogicalKeyboardKey.space) {
                      if (!_isControllerReady || !_shouldShowContentVideo) {
                        return KeyEventResult.ignored;
                      }
                      _videoPlayerController.value.isPlaying
                          ? _videoPlayerController.pause()
                          : _videoPlayerController.play();
                      playerProvider.notifyProvider();
                      return KeyEventResult.handled;
                    }
                    // F = toggle fullscreen
                    if (event.logicalKey == LogicalKeyboardKey.keyF) {
                      _toggleWebFullscreen();
                      return KeyEventResult.handled;
                    }
                    // ArrowLeft = seek backward 10s
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      if (!_isControllerReady || !_shouldShowContentVideo) {
                        return KeyEventResult.ignored;
                      }
                      _seekBackward();
                      return KeyEventResult.handled;
                    }
                    // ArrowRight = seek forward 10s
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      if (!_isControllerReady || !_shouldShowContentVideo) {
                        return KeyEventResult.ignored;
                      }
                      _seekForward();
                      return KeyEventResult.handled;
                    }
                    // Escape = exit fullscreen if in fullscreen
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      if (_isWebFullscreen) {
                        _isWebFullscreen = false;
                        _jsHelper.callBrowserFullscreen(false);
                        if (mounted) setState(() {});
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  }
                : null,
            child: MouseRegion(
              cursor: kIsWeb
                  ? (_isWebCursorVisible // [FIX-CUR] use dedicated flag, NOT _showControls
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.none)
                  : MouseCursor.defer,
              onEnter:
                  kIsWeb // [WEB-1]
                  ? (event) {
                      if (_isScreenLocked) return;
                      _isMouseOverPlayer = true; // [WEB-1]
                      _isWebCursorVisible =
                          true; // [FIX-CUR] cursor ON immediately on enter
                      _hideTimer?.cancel(); // [WEB-1] cancel any pending hide
                      _showControlsAnimated(); // [WEB-1] show controls immediately
                    }
                  : (event) {
                      if (!_isScreenLocked) _cancelAndRestartTimer();
                    },
              onHover:
                  kIsWeb // [WEB-1] continuous movement — keep controls visible
                  ? (event) {
                      if (_isScreenLocked) return;
                      // [FIX-CUR] Set cursor visible directly — no setState, no notifyProvider
                      // This avoids 60fps rebuilds from mouse movement
                      if (!_isWebCursorVisible) {
                        _isWebCursorVisible = true;
                        if (mounted) setState(() {});
                      }
                      // Show controls only if currently hidden (not on every move)
                      if (!_showControls) _showControlsAnimated();
                      _hideTimer
                          ?.cancel(); // [WEB-1] reset any pending hide on movement
                    }
                  : null,
              onExit:
                  kIsWeb // [WEB-1]
                  ? (event) {
                      if (_isScreenLocked) return;
                      _isMouseOverPlayer = false; // [WEB-1]
                      _isWebCursorVisible =
                          true; // [FIX-CUR] always restore cursor on exit
                      // Only start hide timer when mouse leaves AND video is playing
                      if (_isControllerReady &&
                          _videoPlayerController.value.isPlaying) {
                        _startHideTimer(); // [WEB-1] short delay then hide
                      }
                      // If paused: keep controls visible after mouse leaves
                    }
                  : (event) {
                      if (!_isScreenLocked) _startHideTimer();
                    },
              child: GestureDetector(
                onTap: _isScreenLocked
                    ? null
                    : kIsWeb // [WEB-1]
                    ? () async {
                        // Web: single tap = play/pause (controls always via hover)
                        if (!_isControllerReady || !_shouldShowContentVideo) {
                          return;
                        }
                        if (_isAdActuallyPlaying) return;
                        _videoPlayerController.value.isPlaying
                            ? await _videoPlayerController.pause()
                            : await _videoPlayerController.play();
                        if (!mounted) return;
                        playerProvider.notifyProvider();
                        if (_videoPlayerController.value.isPlaying) {
                          if (!_isMouseOverPlayer) _startHideTimer();
                        } else {
                          _hideTimer?.cancel();
                          _showControlsAnimated(); // [WEB-1] keep visible when paused
                        }
                      }
                    : _toggleControls, // mobile: tap = toggle controls
                onVerticalDragEnd: _isScreenLocked ? null : _onVerticalDragEnd,
                onVerticalDragCancel: _isScreenLocked
                    ? null
                    : _onVerticalDragCancel,
                onVerticalDragUpdate: _isScreenLocked
                    ? null
                    : (details) => _onVerticalDragUpdate(
                        details,
                        MediaQuery.of(context).size,
                      ),
                onDoubleTapDown: _isScreenLocked
                    ? null
                    : (details) async {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final dx = details.globalPosition.dx;
                        final isFinished =
                            (_videoPlayerController.value.position >=
                                _videoPlayerController.value.duration) &&
                            _videoPlayerController.value.duration.inSeconds > 0;
                        if (widget.playerModel.isLive == true ||
                            !_shouldShowContentVideo ||
                            isFinished) {
                          return;
                        }
                        if (dx < screenWidth / 2) {
                          _handleDoubleTap(false);
                        } else {
                          _handleDoubleTap(true);
                        }
                      },
                // [NEW] FEATURE-1: Long-press speed boost
                onLongPressStart: _isScreenLocked
                    ? null
                    : (details) {
                        if (!_shouldShowContentVideo || _isAdActuallyPlaying) {
                          return;
                        }
                        if (widget.playerModel.isLive == true) return;
                        _speedBeforeLongPress = _playbackSpeed;
                        _isLongPressSpeed = true;
                        _videoPlayerController.setPlaybackSpeed(2.0);
                        _hideTimer?.cancel();
                        if (mounted) playerProvider.notifyProvider();
                      },
                onLongPressEnd: _isScreenLocked
                    ? null
                    : (details) {
                        if (!_isLongPressSpeed) return;
                        _isLongPressSpeed = false;
                        _videoPlayerController.setPlaybackSpeed(
                          _speedBeforeLongPress,
                        );
                        if (mounted) {
                          playerProvider.notifyProvider();
                          if (_videoPlayerController.value.isPlaying) {
                            _startHideTimer();
                          }
                        }
                      },
                child: Scaffold(
                  backgroundColor: black, // [IMP-4]
                  body: Consumer<PlayerProvider>(
                    builder: (context, playerProvider, child) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Always renders player/loading — fills full screen
                          _setBuildPlayer(),

                          // Ad container overlaid on top
                          if (_shouldShowAds() && _adDisplayContainer != null)
                            Visibility(
                              visible: _isAdActuallyPlaying,
                              maintainState: true,
                              child: _adDisplayContainer!,
                            ),

                          // Initial spinner when neither ad nor content is ready
                          if (!_isAdActuallyPlaying &&
                              !_shouldShowContentVideo &&
                              (!_isControllerReady || // [FIX]
                                  !_videoPlayerController.value.isInitialized))
                            Center(child: Utils.pageLoader()),

                          // [NEW] FEATURE-2: Lock screen overlay — absorbs all input when locked
                          if (_isScreenLocked) _buildLockOverlay(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ), // [WEB-2] Focus close
        ),
      ),
    );
  }

  // [NEW] FEATURE-2: Lock screen overlay widget
  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {}), // absorb taps; show lock icon
        child: Container(
          color: transparent, // [IMP-4]
          child: SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isScreenLocked = false);
                    _showControlsAnimated();
                    _startHideTimer();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: black.withValues(alpha: 0.54), // [IMP-4]
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorAccent,
                        width: 1.5,
                      ), // [IMP-4]
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: colorAccent, // [IMP-4]
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setBuildPlayer() {
    Widget child;

    // [FIX] MUST check _isControllerReady FIRST — late field not assigned yet
    if (!_isControllerReady) {
      child = _buildLoadingView(key: const ValueKey('loading-init'));
    } else if (!_shouldShowContentVideo &&
        !_videoPlayerController.value.isInitialized) {
      child = _buildLoadingView(key: const ValueKey('loading-wait'));
    } else if (_shouldShowContentVideo &&
        _videoPlayerController.value.isInitialized) {
      child = _buildPlayer(key: const ValueKey('video-player'));
    } else if (!_shouldShowContentVideo &&
        _videoPlayerController.value.isInitialized) {
      // Ad is playing — show black fill (ad container is above this in the Stack)
      child = Container(
        key: const ValueKey('ad-placeholder'),
        color: black, // [IMP-4]
      );
    } else {
      child = _buildLoadingView(key: const ValueKey('loading-init2')); // [FIX]
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }

  Widget _buildPlayer({Key? key}) {
    // FIX-A4
    final bool isFinished =
        (_videoPlayerController.value.position >=
            _videoPlayerController.value.duration) &&
        _videoPlayerController.value.duration.inSeconds > 0;
    printLog("cSubtitleList ======> ${playerProvider.cSubtitleList}");

    return Stack(
      // FIX-A4
      key: key,
      fit: StackFit.expand,
      children: [
        // Video surface
        Center(
          child: SizedBox.expand(
            child: FittedBox(
              fit: playerProvider.currentFit,
              child: SizedBox(
                width: _videoPlayerController.value.size.width,
                height: _videoPlayerController.value.size.height,
                child: AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController),
                ),
              ),
            ),
          ),
        ),

        // Quality-switch overlay
        if (_isQualitySwitching)
          Container(
            color: black.withValues(alpha: 0.75), // [IMP-4]
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: white, // [IMP-4]
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 12),
                  MyText(
                    // [TASK-2]
                    color: white,
                    text: "switching_quality",
                    multilanguage: true,
                    fontsizeNormal: 13,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w400,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
          ),

        // Brightness/Volume side bars — AnimatedOpacity handles visibility
        if (!kIsWeb)
          _buildSideBar(
            "brightness",
            playerProvider.brightnessLevel,
            Alignment.centerLeft,
            Icons.brightness_6,
          ),
        if (!kIsWeb)
          _buildSideBar(
            "volume",
            playerProvider.volumeLevel,
            Alignment.centerRight,
            playerProvider.isVolMuted ? Icons.volume_off : Icons.volume_up,
          ),

        // Controls overlay (animated)
        _buildControlsOverlay(isFinished: isFinished),

        // [IMP-2] Buffering spinner — always shown when buffering, pixel-aligned
        // with play/pause button (68×68), visible even when controls are hidden
        if (_isControllerReady &&
            _videoPlayerController.value.isBuffering &&
            !isFinished)
          Center(
            child: SizedBox(
              width: 68, // [IMP-2]
              height: 68, // [IMP-2]
              child: CircularProgressIndicator(
                color: white, // [IMP-4]
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round, // [IMP-2]
              ),
            ),
          ),

        // Seek popup
        _buildSeekPopup(),

        // [NEW] FEATURE-1: Long-press 2× speed indicator
        if (_isLongPressSpeed)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: black.withValues(alpha: 0.65), // [IMP-4]
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: white.withValues(alpha: 0.24), // [IMP-4]
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fast_forward_rounded,
                    color: white, // [IMP-4]
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    // [TASK-2]
                    color: white,
                    text: "2× Speed",
                    multilanguage: false,
                    fontsizeNormal: 13,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
          ),

        // Next episode countdown
        if (_showNextEpisodePopup &&
            widget.playerModel.episodeList != null &&
            (widget.playerModel.episodeList?.length ?? 0) > 0)
          Positioned(bottom: 24, right: 20, child: _buildCountdownWidget()),
      ],
    );
  }

  Widget _buildControlsOverlay({required bool isFinished}) {
    // FIX-B3
    return FadeTransition(
      opacity: _controlsFadeAnim,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 130,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [black, transparent], // [IMP-4]
                  ),
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [black, transparent], // [IMP-4]
                  ),
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _buildTopBar(),
            ),
          ),

          // Center controls (play/pause + seek)
          if (!isFinished || widget.playerModel.isLive == true)
            Center(
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _buildCenterControls(isFinished: isFinished),
              ),
            ),

          // Subtitle (shifts bottom position when controls visible)
          if (playerProvider.subtitleOn &&
              playerProvider.cSubtitleList != null &&
              widget.playerModel.isLive == false)
            Positioned(
              bottom: _showControls ? 90 : 20,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Center(
                  child: _buildSubtitles(playerProvider.cSubtitleList!),
                ),
              ),
            ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _buildBottomBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls({required bool isFinished}) {
    // FIX-B4
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.playerModel.isLive == false)
          _buildSeekButton(isForward: false),
        const SizedBox(width: 32),
        _buildPlayPauseButton(isFinished: isFinished),
        const SizedBox(width: 32),
        if (widget.playerModel.isLive == false)
          _buildSeekButton(isForward: true),
      ],
    );
  }

  Widget _buildPlayPauseButton({required bool isFinished}) {
    final bool isPlaying = _videoPlayerController.value.isPlaying;
    final bool isBuffering =
        _videoPlayerController.value.isBuffering; // [IMP-2]
    return GestureDetector(
      onTap:
          isBuffering // [IMP-2] disable tap while buffering
          ? null
          : () async {
              if (isFinished) {
                await _videoPlayerController.seekTo(Duration.zero);
                await _videoPlayerController.play();
              } else {
                _videoPlayerController.value.isPlaying
                    ? await _videoPlayerController.pause()
                    : await _videoPlayerController.play();
              }
              if (!mounted) return;
              playerProvider.notifyProvider();
              if (_videoPlayerController.value.isPlaying) {
                _startHideTimer();
              } else {
                _hideTimer?.cancel();
                _showControlsAnimated();
              }
            },
      child: AnimatedOpacity(
        opacity: isBuffering
            ? 0.0
            : 1.0, // [IMP-2] hide button when spinner visible
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white.withValues(alpha: 0.15), // [IMP-4]
            border: Border.all(
              color: white.withValues(alpha: 0.35), // [IMP-4]
              width: 1.5,
            ),
          ),
          child: Icon(
            isFinished
                ? Icons.replay_rounded
                : isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: white, // [IMP-4]
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildSeekButton({required bool isForward}) {
    // FIX-B4
    return GestureDetector(
      onTap: isForward ? _seekForward : _seekBackward,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: white.withValues(alpha: 0.08), // [IMP-4]
        ),
        child: Icon(
          isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
          color: white, // [IMP-4]
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // FIX-B5
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: white, // [IMP-4]
                size: 20,
              ),
              onPressed: () => onBackPressed(false),
              tooltip: 'Back',
            ),
            Expanded(
              child: Row(
                children: [
                  if (widget.playerModel.isLive == true)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: redColor, // [IMP-4]
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: MyText(
                        // [TASK-2]
                        color: white,
                        text: "● LIVE",
                        multilanguage: false,
                        fontsizeNormal: 11,
                        fontsizeWeb: 11,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  Expanded(
                    child: MyText(
                      color: white, // [IMP-4]
                      text: widget.playerModel.videoTitle ?? "",
                      multilanguage: false,
                      textalign: TextAlign.start,
                      fontsizeNormal: 15,
                      fontsizeWeb: 17,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            // [NEW] FEATURE-6: Episodes panel button — show type only
            if (widget.playerModel.playType == "Show" &&
                (widget.playerModel.episodeList?.length ?? 0) > 1)
              Tooltip(
                message: 'Episodes',
                child: IconButton(
                  icon: Icon(
                    Icons.playlist_play_rounded,
                    color: white, // [IMP-4]
                    size: 24,
                  ),
                  onPressed: _showEpisodePanel,
                ),
              ),
            // [NEW] FEATURE-2: Lock screen button
            Tooltip(
              message: _isScreenLocked ? 'Unlock' : 'Lock screen',
              child: IconButton(
                icon: Icon(
                  _isScreenLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  color: _isScreenLocked ? colorAccent : white, // [IMP-4]
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isScreenLocked = !_isScreenLocked);
                  if (_isScreenLocked) {
                    _hideTimer?.cancel();
                    _hideControls();
                  } else {
                    _showControlsAnimated();
                    _startHideTimer();
                  }
                },
              ),
            ),
            if (widget.playerModel.isLive == false &&
                Constant.subtitleUrls.isNotEmpty)
              _buildSubtitleToggle(),
            if (widget.playerModel.isLive == false) _buildOptionsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    // FIX-B6
    final position = _videoPlayerController.value.position;
    final duration = _videoPlayerController.value.duration;
    final dur = duration.inMilliseconds;
    final pos = position.inMilliseconds;

    final double sliderValue = (dur > 0) ? (pos / dur).clamp(0.0, 1.0) : 0.0;
    final buffered = _videoPlayerController.value.buffered;
    final double bufferedValue = (dur > 0 && buffered.isNotEmpty)
        ? (buffered.last.end.inMilliseconds / dur).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [IMP-3] Scrub preview pill — LayoutBuilder for accurate thumb position
            if (_isScrubbing)
              LayoutBuilder(
                builder: (context, constraints) {
                  const double sliderPadding =
                      24.0; // Flutter default thumb overlay
                  final double usableWidth =
                      constraints.maxWidth - sliderPadding * 2;
                  final double thumbX =
                      sliderPadding + (usableWidth * _scrubValue);
                  const double pillWidth = 90.0;
                  final double pillLeft = (thumbX - pillWidth / 2).clamp(
                    0.0,
                    constraints.maxWidth - pillWidth,
                  );

                  final previewDuration = Duration(
                    milliseconds: (dur * _scrubValue).toInt(),
                  );
                  final remaining =
                      Duration(milliseconds: dur) - previewDuration;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Vertical stem line from pill to thumb
                      Positioned(
                        left: thumbX - 1,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          height: 12,
                          color: white.withValues(alpha: 0.60), // [IMP-4]
                        ),
                      ),
                      // Time pill
                      Positioned(
                        left: pillLeft,
                        bottom: 10,
                        child: Container(
                          width: pillWidth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: black.withValues(alpha: 0.85), // [IMP-4]
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: white.withValues(alpha: 0.20), // [IMP-4]
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MyText(
                                color: white,
                                text: duration2String(previewDuration),
                                textalign: TextAlign.center,
                                fontsizeNormal: 13,
                                fontsizeWeb: 13,
                                fontweight: FontWeight.w700,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              MyText(
                                color: white.withValues(alpha: 0.60),
                                text: "-${duration2String(remaining)}",
                                textalign: TextAlign.center,
                                fontsizeNormal: 10,
                                fontsizeWeb: 10,
                                fontweight: FontWeight.w400,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // Custom slider with buffered track
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14.0,
                ),
                activeTrackColor: white, // [IMP-4]
                inactiveTrackColor: white.withValues(alpha: 0.2), // [IMP-4]
                thumbColor: white, // [IMP-4]
                overlayColor: white.withValues(alpha: 0.2), // [IMP-4]
                secondaryActiveTrackColor: white.withValues(
                  alpha: 0.4,
                ), // [IMP-4]
              ),
              child: Slider(
                value: _isScrubbing
                    ? _scrubValue
                    : sliderValue, // [NEW] FEATURE-4
                secondaryTrackValue: bufferedValue,
                min: 0.0,
                max: 1.0,
                onChangeStart: (value) {
                  _hideTimer?.cancel();
                  setState(() {
                    _isScrubbing = true; // [IMP-3]
                    _scrubValue = value;
                  });
                },
                onChanged: (value) {
                  if (dur <= 0) return;
                  setState(
                    () => _scrubValue = value,
                  ); // [IMP-3] update preview ONLY — no seekTo
                  // Do NOT call seekTo() here — seek only on release
                },
                onChangeEnd: (value) {
                  if (dur > 0) {
                    final seekTo = Duration(
                      milliseconds: (dur * value).toInt(),
                    );
                    _videoPlayerController.seekTo(
                      seekTo,
                    ); // [IMP-3] seek on release
                    playerProvider.notifyProvider();
                  }
                  setState(() => _isScrubbing = false); // [IMP-3]
                  if (_videoPlayerController.value.isPlaying) {
                    _startHideTimer();
                  }
                },
              ),
            ),

            // Controls row
            Row(
              children: [
                // Play/Pause inline in bottom bar
                IconButton(
                  icon: Icon(
                    _videoPlayerController.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: white, // [IMP-4]
                    size: 24,
                  ),
                  onPressed: () async {
                    _videoPlayerController.value.isPlaying
                        ? await _videoPlayerController.pause()
                        : await _videoPlayerController.play();
                    if (!mounted) return;
                    playerProvider.notifyProvider();
                    // FIX-C3: Stay visible when paused
                    if (_videoPlayerController.value.isPlaying) {
                      _startHideTimer();
                    } else {
                      _hideTimer?.cancel();
                      _showControlsAnimated();
                    }
                  },
                  tooltip: 'Play/Pause',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 6),

                // Position time
                if (widget.playerModel.isLive == false)
                  MyText(
                    color: white,
                    text: duration2String(position),
                    multilanguage: false,
                    fontsizeNormal: 12,
                    fontsizeWeb: 12,
                    fontweight: FontWeight.w500,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),

                if (widget.playerModel.isLive == true)
                  MyText(
                    color: white,
                    text: duration2String(Duration.zero),
                    multilanguage: false,
                    fontsizeNormal: 12,
                    fontsizeWeb: 12,
                    fontweight: FontWeight.w400,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),

                const Spacer(),

                // Total duration
                if (widget.playerModel.isLive == false)
                  MyText(
                    color: white.withValues(alpha: 0.7),
                    text: duration2String(duration),
                    multilanguage: false,
                    fontsizeNormal: 12,
                    fontsizeWeb: 12,
                    fontweight: FontWeight.w500,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),

                const SizedBox(width: 4),

                // Fit toggle
                Tooltip(
                  message:
                      kIsWeb // [WEB-3]
                      ? (playerProvider.currentFit == BoxFit.contain
                            ? 'Zoom to Fill'
                            : 'Fit to Screen')
                      : 'Change Fit',
                  child: IconButton(
                    icon: Icon(
                      kIsWeb
                          // [WEB-3] Web: 2 icons — contain vs cover
                          ? (playerProvider.currentFit == BoxFit.contain
                                ? Icons.crop_free_rounded
                                : Icons.crop_rounded)
                          // [WEB-3] Mobile: 3 icons — contain / cover / fill
                          : (playerProvider.currentFit == BoxFit.contain
                                ? Icons.fit_screen_outlined
                                : playerProvider.currentFit == BoxFit.cover
                                ? Icons.crop_rounded
                                : Icons.fullscreen_rounded),
                      color: white, // [IMP-4]
                      size: 22,
                    ),
                    onPressed: () async {
                      BoxFit nextFit;
                      if (kIsWeb) {
                        // [WEB-3] Web fit cycle: contain ↔ cover (2 states only)
                        // Fullscreen is handled by dedicated button (CHANGE 2)
                        nextFit = (playerProvider.currentFit == BoxFit.contain)
                            ? BoxFit.cover
                            : BoxFit.contain;
                      } else {
                        // [WEB-3] Mobile fit cycle: contain → cover → fill → contain (3 states)
                        if (playerProvider.currentFit == BoxFit.contain) {
                          nextFit = BoxFit.cover;
                        } else if (playerProvider.currentFit == BoxFit.cover) {
                          nextFit = BoxFit.fill;
                        } else {
                          nextFit = BoxFit.contain;
                        }
                      }
                      await playerProvider.changeBoxFit(nextFit);
                      _startHideTimer();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),

                // Speed button
                if (widget.playerModel.isLive == false)
                  Tooltip(
                    message: 'Playback Speed',
                    child: _buildSpeedButton(),
                  ),

                // [WEB-2] Web-only fullscreen toggle button
                if (kIsWeb)
                  Tooltip(
                    message: _isWebFullscreen
                        ? 'Exit Fullscreen'
                        : 'Fullscreen',
                    child: IconButton(
                      icon: Icon(
                        _isWebFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: white,
                        size: 24,
                      ),
                      onPressed: _toggleWebFullscreen,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // [NEW] UI-6: Half-screen gradient ripple seek popup (Netflix style)
  Widget _buildSeekPopup() {
    if (!playerProvider.showSeekPopup) return const SizedBox.shrink();
    final isForward = playerProvider.isForwardSeek;
    return Positioned(
      top: 0,
      bottom: 0,
      left: isForward ? null : 0,
      right: isForward ? 0 : null,
      width: MediaQuery.of(context).size.width * 0.45,
      child: AnimatedOpacity(
        opacity: playerProvider.showSeekPopup ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
              end: isForward ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                white.withValues(alpha: 0.12), // [IMP-4]
                transparent, // [IMP-4]
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: isForward ? const Radius.circular(80) : Radius.zero,
              bottomLeft: isForward ? const Radius.circular(80) : Radius.zero,
              topRight: isForward ? Radius.zero : const Radius.circular(80),
              bottomRight: isForward ? Radius.zero : const Radius.circular(80),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
                color: white, // [IMP-4]
                size: 36,
              ),
              const SizedBox(height: 6),
              MyText(
                color: white,
                text: playerProvider.seekPopupText ?? "",
                multilanguage: false,
                fontsizeNormal: 16,
                fontsizeWeb: 16,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSpeedButton() {
    // FIX-B6
    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();
        final chosenSpeed = await showCupertinoModalPopup<double>(
          context: context,
          semanticsDismissible: true,
          builder: (context) => _PlaybackSpeedDialog(
            speeds: [0.5, 1.0, 1.5, 2.0],
            selected: _playbackSpeed,
          ),
        );
        if (chosenSpeed != null) {
          await _videoPlayerController.setPlaybackSpeed(chosenSpeed);
          _playbackSpeed = chosenSpeed;
          if (mounted) playerProvider.notifyProvider();
        }
        if (_videoPlayerController.value.isPlaying) _startHideTimer();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: white.withValues(alpha: 0.38),
            width: 1,
          ), // [IMP-4]
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          '${_playbackSpeed == _playbackSpeed.truncateToDouble() ? _playbackSpeed.toInt() : _playbackSpeed}x',
          style: const TextStyle(
            color: white, // [IMP-4]
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleToggle() {
    //if don't have subtitle hiden button
    if (Constant.subtitleUrls.isEmpty) {
      return const SizedBox();
    }
    return Tooltip(
      message: 'Subtitles ON/OFF',
      child: GestureDetector(
        onTap: _subtitleToggle,
        child: Container(
          height: 47.0,
          color: transparent, // [IMP-4]
          margin: const EdgeInsets.only(right: 10.0),
          padding: const EdgeInsets.only(left: 6.0, right: 6.0),
          child: Icon(
            playerProvider.subtitleOn ? Icons.subtitles : Icons.subtitles_off,
            color: white, // [IMP-4]
            size: 25.0,
          ),
        ),
      ),
    );
  }

  Future<void> _subtitleToggle() async {
    if (!mounted) return;
    await playerProvider.setSubtitleState(!playerProvider.subtitleOn);
  }

  Widget _buildSubtitles(Subtitles subtitles) {
    if (!playerProvider.subtitleOn) {
      return const SizedBox();
    }
    if (playerProvider.subtitlesPosition == null) {
      return const SizedBox();
    }
    printLog(
      "_subtitleToggle _subtitlesPosition ====> ${playerProvider.subtitlesPosition?.inMilliseconds}",
    );
    final currentSubtitle = subtitles.getByPosition(
      playerProvider.subtitlesPosition!,
    );
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }
    printLog("_subtitleToggle currentSubtitle ====> $currentSubtitle");
    return Container(
      margin: EdgeInsets.fromLTRB(10, 15, 10, 15),
      padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
      decoration: BoxDecoration(
        color: black.withValues(alpha: 0.59), // [IMP-4]
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: MyText(
        color: white, // [IMP-4]
        text: currentSubtitle.first?.text.toString() ?? "",
        multilanguage: false,
        textalign: TextAlign.center,
        fontsizeNormal: 18,
        fontsizeWeb: 20,
        fontweight: FontWeight.w600,
        maxline: 2,
        overflow: TextOverflow.ellipsis,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  Widget _buildLoadingView({Key? key}) {
    final thumb = widget.playerModel.videoThumb ?? "";
    final isDownload = widget.playerModel.playType == "Download"; // [IMP-1]
    return Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        // Thumbnail background — local file for downloads, network for streaming
        if (thumb.isNotEmpty)
          isDownload // [IMP-1]
              ? MyFileImage(
                  // [TASK-3]
                  imagePath: thumb,
                  fit: BoxFit.cover,
                )
              : MyNetworkImage(imageUrl: thumb, fit: BoxFit.cover), // [IMP-1]
        // Dark scrim
        ColoredBox(color: black.withValues(alpha: 0.65)), // [IMP-1] [IMP-4]
        // Single loading indicator — centered
        Center(child: _buildLoading()),
        // Back button always accessible
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: white, // [IMP-4]
                size: 20,
              ),
              onPressed: () => onBackPressed(false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final isDownload = widget.playerModel.playType == "Download"; // [IMP-1]
        final progress = playerProvider.progress; // [IMP-1]
        return Column(
          mainAxisSize: MainAxisSize.min, // [IMP-1]
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // [IMP-1] Single spinner: circular for download, pageLoader for streaming
            if (isDownload) // [IMP-1]
              SizedBox(
                height: 70,
                width: 70,
                child: Utils.progressWithPercentage(
                  progress,
                ), // [IMP-1] only this for downloads
              )
            else
              SizedBox(
                height: 70,
                width: 70,
                child: Utils.pageLoader(), // [IMP-1] only this for streaming
              ),

            // Decrypt progress text — downloads only, when actively decrypting
            if (isDownload && progress > 0) ...[
              // [IMP-1]
              const SizedBox(height: 16),
              MyText(
                color: titleTextColor,
                text:
                    "${Locales.string(context, "loading")} ${(progress * 100).toStringAsFixed(1)}%", // [IMP-1]
                textalign: TextAlign.center,
                fontsizeNormal: 14,
                fontweight: FontWeight.w600,
                fontsizeWeb: 16,
                multilanguage: false,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
            ],

            // "Preparing..." label for download when progress == 0
            if (isDownload && progress == 0) ...[
              // [IMP-1]
              const SizedBox(height: 16),
              MyText(
                color: white.withValues(alpha: 0.70), // [IMP-1] [IMP-4]
                text: "Preparing video...",
                textalign: TextAlign.center,
                fontsizeNormal: 13,
                fontweight: FontWeight.w500,
                fontsizeWeb: 14,
                multilanguage: false,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
            ],
          ],
        );
      },
    );
  }

  // [NEW] UI-8: Netflix-style dark card countdown widget
  Widget _buildCountdownWidget() {
    final nextIndex = (widget.playerModel.currentEpiPos ?? 0) + 1;
    final list = widget.playerModel.episodeList;
    if (list == null || nextIndex >= list.length) {
      return const SizedBox.shrink(); // [FIX] FIX-3
    }
    final nextEp = list[nextIndex];

    return AnimatedOpacity(
      opacity: _popupOpacity,
      duration: const Duration(milliseconds: 350),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: secondaryBgColor, // [IMP-4]
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: white.withValues(alpha: 0.12), // [IMP-4]
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: black.withValues(alpha: 0.60), // [IMP-4]
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              // [TASK-2]
              color: white.withValues(alpha: 0.54),
              text: "NEXT EPISODE",
              multilanguage: false,
              fontsizeNormal: 10,
              fontsizeWeb: 11,
              fontweight: FontWeight.w700,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: MyNetworkImage(
                    imageUrl: nextEp.landscape ?? "",
                    width: 88,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MyText(
                    color: white, // [IMP-4]
                    text: nextEp.name ?? nextEp.description ?? "",
                    multilanguage: false,
                    textalign: TextAlign.start,
                    fontsizeNormal: 13,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w600,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _countdownProgress,
                color: redColor, // [IMP-4]
                backgroundColor: white.withValues(alpha: 0.12), // [IMP-4]
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MyText(
                  color: white.withValues(alpha: 0.60),
                  text: Locales.string(context, 'playing_in_sec').replaceAll('{0}', '$_countdownSeconds'),
                  multilanguage: false,
                  fontsizeNormal: 11,
                  fontsizeWeb: 11,
                  fontweight: FontWeight.w400,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _playNextEpisode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: white, // [IMP-4]
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      // [TASK-2]
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: black, // [IMP-4]
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          // [TASK-2]
                          color: black,
                          text: "watch_now",
                          multilanguage: true,
                          fontsizeNormal: 12,
                          fontsizeWeb: 13,
                          fontweight: FontWeight.w700,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cancelNextEpisode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: white.withValues(alpha: 0.30),
                      ), // [IMP-4]
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: MyText(
                      // [TASK-2]
                      color: white.withValues(alpha: 0.70),
                      text: "cancel",
                      multilanguage: true,
                      fontsizeNormal: 12,
                      fontsizeWeb: 13,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildOptionsButton() {
    final options = <OptionItem>[];
    OptionItem qualityItem = OptionItem(
      onTap: (context) {
        Utils.exitDialog(context);
        qualityDialog();
      },
      iconData: Icons.video_collection_rounded,
      title: 'Quality',
    );
    OptionItem subtitlesItem = OptionItem(
      onTap: (context) {
        Utils.exitDialog(context);
        subtitleDialog();
      },
      iconData: Icons.video_collection_rounded,
      title: 'Subtitles',
    );

    if (Constant.resolutionsUrls.isNotEmpty) options.add(qualityItem);
    if (Constant.subtitleUrls.isNotEmpty) options.add(subtitlesItem);

    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();
        await showCupertinoModalPopup<OptionItem>(
          context: context,
          semanticsDismissible: true,
          builder: (context) => CupertinoOptionsDialog(
            options: options,
            cancelButtonText: "Cancel",
          ),
        );
        if (_videoPlayerController.value.isPlaying) {
          _startHideTimer();
        }
      },
      child: Tooltip(
        message: 'Quality/Subtitles change',
        child: Container(
          height: 47.0,
          color: transparent, // [IMP-4]
          padding: const EdgeInsets.only(left: 4.0, right: 8.0),
          margin: const EdgeInsets.only(right: 6.0),
          child: Icon(Icons.more_vert, color: white, size: 23), // [IMP-4]
        ),
      ),
    );
  }

  Future<void> subtitleDialog() async {
    await showCupertinoModalPopup<void>(
      context: context,
      semanticsDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return CupertinoActionSheet(
          actions: Constant.subtitleUrls
              .map(
                (option) => CupertinoActionSheetAction(
                  onPressed: () async {
                    playerProvider.setCurrentSubtitle(option.subtitleLang);
                    updateSubtitleUrl(subtitleUrl: option.subtitleUrl);
                    if (!context.mounted) return;
                    Utils.exitDialog(context);
                  },
                  child: Text(
                    option.subtitleLang,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontStyle: FontStyle.normal,
                      color:
                          (playerProvider.currentSubtitle ==
                              option.subtitleLang)
                          ? black
                          : black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Utils.exitDialog(context),
            isDestructiveAction: true,
            child: Text(
              "Cancel",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontStyle: FontStyle.normal,
                color: redColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    ).then((value) {
      printLog("============= SUBTITLE =============");
      if (!mounted) return;
      playerProvider.notifyProvider();
    });
  }

  Future<void> qualityDialog() async {
    await showCupertinoModalPopup<void>(
      context: context,
      semanticsDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return CupertinoActionSheet(
          actions: Constant.resolutionsUrls
              .map(
                (option) => CupertinoActionSheetAction(
                  onPressed: () async {
                    updateQualityUrl(
                      qualityName: option.qualityName,
                      qualityUrl: option.qualityUrl,
                    );
                    if (!context.mounted) return;
                    Utils.exitDialog(context);
                  },
                  child: Text(
                    option.qualityName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontStyle: FontStyle.normal,
                      color:
                          (playerProvider.currentQuality == option.qualityName)
                          ? black
                          : black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Utils.exitDialog(context),
            isDestructiveAction: true,
            child: Text(
              "Cancel",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontStyle: FontStyle.normal,
                color: redColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    ).then((value) {
      printLog("============= QUALITY =============");
      if (!mounted) return;
      playerProvider.notifyProvider();
    });
  }

  /* Brightness/Volume START ********************************** */
  Widget _buildSideBar(
    // FIX-B8
    String btnType,
    double value,
    Alignment alignment,
    IconData icon,
  ) {
    final isVolume = btnType == "volume";
    return AnimatedOpacity(
      opacity:
          (isVolume
              ? playerProvider.showVolumeBar
              : playerProvider.showBrightnessBar)
          ? 1.0
          : 0.0,
      duration: const Duration(milliseconds: 200),
      child: SafeArea(
        child: Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            width: 44,
            height: 160,
            decoration: BoxDecoration(
              color: black.withValues(alpha: 0.60), // [IMP-4]
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: white.withValues(alpha: 0.15), // [IMP-4]
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: isVolume
                      ? () async => updateMuteStatus(!playerProvider.isVolMuted)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(icon, color: white, size: 18), // [IMP-4]
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        color: white, // [IMP-4]
                        backgroundColor: white.withValues(
                          alpha: 0.24,
                        ), // [IMP-4]
                        minHeight: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  /* ************************************ Brightness/Volume END */

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    // [NEW] FEATURE-9: Animate out before dismissing
    await _enterExitAnim.reverse();
    if (!mounted) return;
    if (!kIsWeb) {
      OrientationManager.forcePortrait();
    } else {
      _isWebFullscreen = false; // [WEB-2] Reset fullscreen state on exit
      _jsHelper.callBrowserFullscreen(false);
    }
    if (kDebugMode) {
      printLog("onBackPressed playerCPosition :===> $playerCPosition");
    }
    printLog("onBackPressed videoDuration :===> $videoTotalDuration");
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

class CupertinoOptionsDialog extends StatefulWidget {
  const CupertinoOptionsDialog({
    super.key,
    required this.options,
    this.cancelButtonText,
  });

  final List<OptionItem> options;
  final String? cancelButtonText;

  @override
  State<CupertinoOptionsDialog> createState() => _CupertinoOptionsDialogState();
}

class _CupertinoOptionsDialogState extends State<CupertinoOptionsDialog> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CupertinoActionSheet(
        actions: widget.options
            .map(
              (option) => CupertinoActionSheetAction(
                onPressed: () => option.onTap(context),
                child: Text(option.title),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Utils.exitDialog(context),
          isDestructiveAction: true,
          child: Text(widget.cancelButtonText ?? 'Cancel'),
        ),
      ),
    );
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    required List<double> speeds,
    required double selected,
  }) : _speeds = speeds,
       _selected = selected;

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoActionSheet(
      actions: _speeds
          .map(
            (e) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop(e);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (e == _selected)
                    Icon(Icons.check, size: 20.0, color: selectedColor),
                  MyText(
                    color: white,
                    text: e.toString(),
                    multilanguage: false,
                    fontsizeNormal: 14,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w500,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class CenterSeekButtonNew extends StatelessWidget {
  const CenterSeekButtonNew({
    super.key,
    required this.iconName,
    this.iconColor,
    required this.show,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.iconSize = 26,
    this.onPressed,
  });

  final String iconName;
  final bool show;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final Duration fadeDuration;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: transparent, // [TASK-1]
      child: Center(
        child: UnconstrainedBox(
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: fadeDuration,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.all(3),
                child: MyImage(
                  imagePath: "$iconName.png",
                  height: 45,
                  width: 45,
                  color: white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      padding: const EdgeInsets.all(16.0),
      color: colorPrimary,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(icon, color: black),
    );
  }
}

enum AppState { idle, connected, mediaLoaded, error }

class MyWebVTTCaptionFile extends ClosedCaptionFile {
  MyWebVTTCaptionFile(this.captions);

  @override
  List<Caption> captions = [];
}
