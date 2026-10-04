import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../model/commentmodel.dart' as comments;
import '../model/sharemodel.dart';
import '../model/clipepisodesmodel.dart' as shortsepisode;
import '../model/contentdetailmodel.dart' as details;
import '../provider/clipsprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/constant.dart';
import '../utils/loadingoverlay.dart';
import '../widget/mynetworkimg.dart';
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../widget/centerplaybutton.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

String duration2String(Duration? dur) {
  final duration = dur ?? Duration.zero;
  if (duration.inSeconds <= 0) return "00:00";
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

class ClipsEpisodes extends StatefulWidget {
  final int videoId, subVideoType, videoType, typeId;
  const ClipsEpisodes({
    required this.videoId,
    required this.subVideoType,
    required this.videoType,
    required this.typeId,
    super.key,
  });

  @override
  State<ClipsEpisodes> createState() => _ClipsEpisodesState();
}

class _ClipsEpisodesState extends State<ClipsEpisodes> {
  late ClipsProvider clipsProvider;

  final PageController _pageController = PageController();
  Map<int, VideoPlayerController> _controllers = {};
  late ValueNotifier<int> _current;
  final int _preloadCount = 4;
  Timer? _debounce;
  Timer? _autoplayDelayTimer;

  @override
  void initState() {
    super.initState();
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);
    _current = ValueNotifier<int>(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future _getData() async {
    await clipsProvider.getShortsDetails(
      widget.typeId,
      widget.videoType,
      widget.videoId,
      widget.subVideoType,
      forceRefresh: true,
    );

    if (clipsProvider.contentDetailModel.result != null &&
        (clipsProvider.contentDetailModel.result?.length ?? 0) > 0 &&
        clipsProvider.contentDetailModel.result?[0].season != null &&
        (clipsProvider.contentDetailModel.result?[0].season?.length ?? 0) > 0) {
      await _getAllEpisodes(0);
      _preLoadEpisodes();
    }

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future _getAllEpisodes(int seasonPos) async {
    printLog("_getAllEpisodes seasonPos ======> $seasonPos");
    await clipsProvider.setSeason(seasonPos);
    await clipsProvider.getEpisodesBySeason(
      widget.videoId,
      clipsProvider.contentDetailModel.result?[0].season?[seasonPos].id ?? 0,
      1,
      forceRefresh: true,
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _preLoadEpisodes() async {
    printLog(
      "_preLoadEpisodes shortFilmEpisodeModel ====> ${clipsProvider.shortFilmEpisodeModel.result?.length}",
    );
    if (clipsProvider.shortFilmEpisodeModel.result != null &&
        (clipsProvider.shortFilmEpisodeModel.result?.length ?? 0) > 0) {
      _prepare(0);
      for (int i = 1; i <= _preloadCount; i++) {
        _prepare(i);
      }
    }
  }

  Future<void> _prepare(int index) async {
    if (index < 0 ||
        index >= (clipsProvider.shortFilmEpisodeModel.result?.length ?? 0)) {
      return;
    }
    if (_controllers.containsKey(index)) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(
        clipsProvider.shortFilmEpisodeModel.result?[index].video320 ?? "",
      ),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    _controllers[index] = controller;

    unawaited(() async {
      try {
        await controller.initialize();
        controller.setLooping(true);

        if (_current.value == index) {
          if (_checkPremium(index)) {
            await controller.pause();
          } else {
            // Poster delay: show thumbnail before autoplay
            await Future.delayed(const Duration(milliseconds: 1000));
            if (mounted && _current.value == index) {
              await controller.play();
            }
          }
          Future.delayed(Duration.zero).then((value) {
            if (!mounted) return;
            setState(() {});
          });
        } else {
          await controller.seekTo(Duration.zero);
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 150));
          await controller.pause();
        }
      } catch (e, s) {
        printLog("_prepare Video error at index = $index : $e\n$s");
      }
    }());
  }

  void _onPageChanged(int index) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: transparent,
        systemNavigationBarColor: secondaryBgColor,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _autoplayDelayTimer?.cancel();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      _current.value = index;

      for (final entry in _controllers.entries) {
        final i = entry.key;
        final c = entry.value;
        if (!c.value.isInitialized) continue;

        if (i == index) {
          if (_checkPremium(index)) {
            c.pause();
          } else {
            // Poster delay before autoplay on page scroll
            _autoplayDelayTimer?.cancel();
            _autoplayDelayTimer = Timer(const Duration(milliseconds: 1000), () {
              if (mounted && _current.value == index) {
                c.play();
              }
            });
          }
        } else {
          c.pause();
          unawaited(c.seekTo(Duration.zero));
        }
      }

      // Preload neighbors
      for (int off = -_preloadCount; off <= _preloadCount; off++) {
        if (off == 0) continue;
        _prepare(index + off);
      }

      // Dispose far controllers
      _controllers.keys
          .where((i) => (i - index).abs() > _preloadCount)
          .toList()
          .forEach((i) {
            _controllers[i]?.dispose();
            _controllers.remove(i);
          });
    });
  }

  bool _checkPremium(int index) {
    return clipsProvider.shortFilmEpisodeModel.result?[index].isPremium == 1 &&
        clipsProvider.shortFilmEpisodeModel.result?[index].isBuy != 1;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autoplayDelayTimer?.cancel();
    _current.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: ValueListenableBuilder<int>(
        valueListenable: _current,
        builder: (context, current, _) {
          if (clipsProvider.isEpiLoading && !clipsProvider.loadMore) {
            return ShimmerUtils.buildClipsEpisodeShimmer(context);
          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: clipsProvider.shortFilmEpisodeModel.result?.length ?? 0,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final controller = _controllers[index];
              if (controller == null || !controller.value.isInitialized) {
                return ShimmerUtils.buildClipsEpisodeShimmer(context);
              }
              return Consumer<ClipsProvider>(
                builder: (context, clipsProvider, child) {
                  return _EpisodePlayer(
                    controller: controller,
                    isCurrent: (current == index),
                    vIndex: index,
                    pageController: _pageController,
                    clipVideoId: widget.videoId,
                    clipVideoType: widget.videoType,
                    clipSubVideoType: widget.subVideoType,
                    seasonList:
                        clipsProvider.contentDetailModel.result?[0].season ??
                        [],
                    episodeList:
                        clipsProvider.shortFilmEpisodeModel.result ?? [],
                    onVideoEnd: () {
                      printLog("ShortsPlayer Auto-scroll triggered for $index");
                      if (index + 1 <
                          (clipsProvider.shortFilmEpisodeModel.result?.length ??
                              0)) {
                        _pageController.animateToPage(
                          index + 1,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    onSeasonChange: (int mCurrentPage) async {
                      printLog(
                        "onSeasonChange mCurrentPage =====> $mCurrentPage",
                      );
                      _onSeasonChange(
                        mCurrentPage: mCurrentPage,
                        vController: controller,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onSeasonChange({
    required int mCurrentPage,
    required VideoPlayerController vController,
  }) async {
    if (clipsProvider.seasonPos == mCurrentPage) return;
    printLog(
      "onSeasonChange SeasonID ====> ${(clipsProvider.contentDetailModel.result?[0].season?[mCurrentPage].id ?? 0)}",
    );
    LoadingOverlay().show(context);
    if (vController.value.isPlaying) {
      vController.pause();
    }
    clipsProvider.setEpiLoading(true);
    await clipsProvider.setSeason(mCurrentPage);
    printLog("onSeasonChange seasonPos =2=> ${clipsProvider.seasonPos}");
    await clipsProvider.getEpisodesBySeason(
      clipsProvider.contentDetailModel.result?[0].id ?? 0,
      clipsProvider.contentDetailModel.result?[0].season?[mCurrentPage].id ?? 0,
      1,
      forceRefresh: true,
    );
    _controllers.clear();
    _controllers = {};
    _current = ValueNotifier<int>(0);
    _pageController.jumpToPage(0);
    await _preLoadEpisodes();
    LoadingOverlay().hide();
    if (!mounted) return;
    Utils.exitPage(context);
    printLog("onSeasonChange CHANGED!!!");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }
}

// ─────────────────────────────────────────────────
// Single episode reel widget
// ─────────────────────────────────────────────────
class _EpisodePlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final PageController pageController;
  final bool isCurrent;
  final int vIndex;
  final int clipVideoId;
  final int clipVideoType;
  final int clipSubVideoType;
  final List<details.Season> seasonList;
  final List<shortsepisode.Result> episodeList;
  final VoidCallback? onVideoEnd;
  final void Function(int index) onSeasonChange;

  const _EpisodePlayer({
    required this.controller,
    required this.pageController,
    required this.isCurrent,
    required this.vIndex,
    required this.clipVideoId,
    required this.clipVideoType,
    required this.clipSubVideoType,
    required this.seasonList,
    required this.episodeList,
    this.onVideoEnd,
    required this.onSeasonChange,
  });

  @override
  State<_EpisodePlayer> createState() => _EpisodePlayerState();
}

class _EpisodePlayerState extends State<_EpisodePlayer>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late ClipsProvider clipsProvider;

  Timer? _hideTimer;
  bool _showPlayPause = true;
  bool _showControls = true;
  bool _isVideoStarted = false;
  bool _hasSignalledEnd = false;

  int _speedIndex = 1;
  final List<double> _playbackSpeeds = [0.5, 1.0, 1.5, 2.0];

  // Mute state per index
  final ValueNotifier<Map<int, bool?>> _muteStatesNotifier = ValueNotifier({});

  // Comment controllers
  TextEditingController commentController = TextEditingController();
  TextEditingController editCommentController = TextEditingController();
  ScrollController commentScrollController = ScrollController();
  ScrollController repliesScrollController = ScrollController();

  Future<void> toggleMute(int index) async {
    final currentStates = Map<int, bool>.from(_muteStatesNotifier.value);
    currentStates[index] = !(currentStates[index] ?? false);
    _muteStatesNotifier.value = currentStates;
    final isMuted = currentStates[index] ?? false;
    widget.controller.setVolume(isMuted ? 0.0 : 1.0);
  }

  void _changeSpeed() {
    setState(() {
      _speedIndex = (_speedIndex + 1) % _playbackSpeeds.length;
    });
    widget.controller.setPlaybackSpeed(_playbackSpeeds[_speedIndex]);
  }

  Future<void> _togglePlayPause() async {
    _showPlayPause = !_showPlayPause;
    _isVideoStarted = (widget.controller.value.isPlaying);
    if (!mounted) return;
    if (_showPlayPause) _startHideTimer();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleControls() async {
    _showControls = !_showControls;
    if (!mounted) return;
    setState(() {});
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    if (!mounted) return;
    _showPlayPause = true;
    _isVideoStarted = (widget.controller.value.isPlaying);
  }

  Future<void> _startHideTimer() async {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () async {
      _showPlayPause = false;
      _showControls = false;
      _isVideoStarted = (widget.controller.value.isPlaying);
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onTapPlayerArea() {
    setState(() {
      _showControls = !_showControls;
      _showPlayPause = _showControls;
    });
    if (_showControls) _startHideTimer();
  }

  @override
  void initState() {
    super.initState();
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);
    widget.controller.addListener(_videoListener);
    commentScrollController.addListener(_commentScrollListener);
    repliesScrollController.addListener(_repliesScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Utils.deleteCacheDir();
      _togglePlayPause();
      _addViewAPI();
    });
  }

  Future<void> _addViewAPI() async {
    clipsProvider.addViewCount(
      clipsProvider.contentDetailModel.result?[0].id ?? 0,
      clipsProvider.contentDetailModel.result?[0].videoType ?? 0,
      widget.episodeList[widget.vIndex].id ?? 0,
    );
  }

  Future<void> _commentScrollListener() async {
    if (!commentScrollController.hasClients) return;
    if (commentScrollController.offset >=
            commentScrollController.position.maxScrollExtent &&
        !commentScrollController.position.outOfRange &&
        (clipsProvider.isCommentMorePage ?? false)) {
      clipsProvider.setCommentLoadMore(true);
      await clipsProvider.getComments(
        widget.clipVideoId,
        widget.clipVideoType,
        widget.clipSubVideoType,
        (clipsProvider.currentCommentPage ?? 0) + 1,
      );
    }
  }

  Future<void> _repliesScrollListener() async {
    if (!repliesScrollController.hasClients) return;
    if (repliesScrollController.offset >=
            repliesScrollController.position.maxScrollExtent &&
        !repliesScrollController.position.outOfRange &&
        (clipsProvider.isReplyMorePage ?? false)) {
      clipsProvider.setReplyLoadMore(true);
      await clipsProvider.getReplyComments(
        (clipsProvider
                .commentList?[clipsProvider.selectedCommentIndex ?? 0]
                .id ??
            0),
        (clipsProvider.currentReplyPage ?? 0) + 1,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _EpisodePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_videoListener);
      widget.controller.addListener(_videoListener);
      _hasSignalledEnd = false;
    }
  }

  void _videoListener() {
    final c = widget.controller;
    if (!c.value.isInitialized) return;

    final pos = c.value.position;
    final dur = c.value.duration;
    if (dur.inMilliseconds == 0) return;

    final tolerance = const Duration(milliseconds: 200);

    if (widget.isCurrent && !_hasSignalledEnd && pos >= dur - tolerance) {
      _hasSignalledEnd = true;

      final total = clipsProvider.shortFilmEpisodeModel.result?.length ?? 0;
      final nextIndex = widget.vIndex + 1;
      printLog(
        "ShortsPlayer: end detected index=${widget.vIndex} totalEpi=$total nextIndex=$nextIndex",
      );

      if (nextIndex < total) {
        if (!clipsProvider.isDialogOpen) {
          widget.onVideoEnd?.call();
        }
      } else {
        c.pause();
        _showControls = true;
        _isVideoStarted = (widget.controller.value.isPlaying);
        if (!mounted) return;
        setState(() {});
        printLog("Reached last video, playback stopped.");
      }
      return;
    }

    if (pos < dur - tolerance && _hasSignalledEnd) {
      _hasSignalledEnd = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (widget.controller.value.isPlaying) widget.controller.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _hideTimer?.cancel();
    widget.controller.removeListener(_videoListener);
    commentController.dispose();
    editCommentController.dispose();
    commentScrollController.dispose();
    repliesScrollController.dispose();
    _muteStatesNotifier.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!clipsProvider.isDialogOpen) {
      if (_checkPremium()) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    }
  }

  @override
  void didPushNext() {
    if (!clipsProvider.isDialogOpen) {
      widget.controller.pause();
    }
  }

  bool _checkPremium() {
    return widget.episodeList[widget.vIndex].isPremium == 1 &&
        widget.episodeList[widget.vIndex].isBuy != 1;
  }

  bool _isFreeORBuy() {
    return widget.episodeList[widget.vIndex].isPremium == 0 ||
        widget.episodeList[widget.vIndex].isBuy == 1;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vCont = widget.controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 0: Video / premium poster ──────────────────
        if (_checkPremium())
          _buildSubscribeView(index: widget.vIndex)
        else
          GestureDetector(
            onTap: _onTapPlayerArea,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: vCont,
              builder: (context, cValue, _) {
                return SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: cValue.size.width,
                      height: cValue.size.height,
                      child: VideoPlayer(vCont),
                    ),
                  ),
                );
              },
            ),
          ),

        // ── Layer 3: Center play/pause ────────────────────────
        if (_isFreeORBuy())
          AnimatedOpacity(
            opacity: _showPlayPause ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showPlayPause,
              child: Center(child: _buildHitArea()),
            ),
          ),

        // ── Layer 4: Controls (top bar + gradients + content + right rail) ─
        AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Top gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [black.withValues(alpha: 0.70), transparent],
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
                  height: 320,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            black,
                            black.withValues(alpha: 0.80),
                            black.withValues(alpha: 0.40),
                            transparent,
                          ],
                          stops: [0.0, 0.30, 0.60, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top AppBar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: _buildAppBar()),
                ),

                // Bottom: episode details + progress bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEpisodeDetails(index: widget.vIndex),
                        const SizedBox(height: 10),
                        if (_isFreeORBuy())
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: vCont,
                              builder: (context, val, _) {
                                final dur = val.duration.inMilliseconds;
                                final pos = val.position.inMilliseconds;
                                final prog = dur > 0 ? pos / dur : 0.0;
                                return SizedBox(
                                  height: 5,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 4,
                                        pressedElevation: 0,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 0,
                                          ),
                                      trackShape:
                                          const RoundedRectSliderTrackShape(),
                                      minThumbSeparation: 0,
                                      showValueIndicator:
                                          ShowValueIndicator.never,
                                    ),
                                    child: Slider(
                                      value: prog.clamp(0, 1),
                                      onChanged: (v) =>
                                          vCont.seekTo(val.duration * v),
                                      activeColor: colorPrimary,
                                      inactiveColor: white.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Right-side feature rail
                Positioned(
                  right: 0,
                  bottom: 70,
                  child: _buildFeatureBtns(widget.vIndex),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Subscribe / premium view ────────────────────────────

  Widget _buildSubscribeView({required int index}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: MyNetworkImage(
                  imageUrl: widget.episodeList[widget.vIndex].thumbnail ?? "",
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: Utils.setBackground(
                  black.withValues(alpha: 0.6),
                  0,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyImage(imagePath: 'ic_lock.png', height: 30, width: 30),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      await Utils.openSubscription(
                        context: context,
                        oldPage: "",
                      );
                    },
                    child: FittedBox(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                        decoration: Utils.setGradTTBBGWithBorder(
                          colorPrimaryDark,
                          colorPrimary,
                          transparent,
                          30,
                          0,
                        ),
                        alignment: Alignment.center,
                        child: MyText(
                          color: white,
                          text: "subscribe_now",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 14,
                          fontweight: FontWeight.w600,
                          fontsizeWeb: 15,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
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

  // ── Top AppBar ──────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Utils.exitPage(context),
            child: Container(
              height: 40,
              width: 40,
              padding: const EdgeInsets.all(12),
              child: SimpleShadow(
                color: black.withValues(alpha: 0.5),
                sigma: 2,
                child: MyImage(
                  imagePath: "back.png",
                  fit: BoxFit.contain,
                  color: white,
                ),
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _toggleControls,
            child: Container(
              height: 40,
              width: 40,
              padding: const EdgeInsets.all(3),
              alignment: Alignment.center,
              decoration: Utils.setBackground(
                descTextColor.withValues(alpha: 0.75),
                25,
              ),
              child: SimpleShadow(
                color: black.withValues(alpha: 0.5),
                sigma: 2,
                child: MyImage(
                  height: 22,
                  width: 22,
                  imagePath: "ic_screen_default.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Center play/pause hit area ──────────────────────────

  Widget _buildHitArea() {
    final c = widget.controller;
    final bool isFinished =
        (c.value.position >= c.value.duration) &&
        c.value.duration.inSeconds > 0;
    _isVideoStarted = (c.value.isPlaying);
    return Container(
      height: 70,
      width: 70,
      color: transparent,
      child: Tooltip(
        message: 'Play/Pause',
        child: CenterPlayButton(
          backgroundColor: black.withValues(alpha: 0.26),
          iconColor: white,
          isFinished: isFinished,
          isPlaying: _isVideoStarted,
          show: _showPlayPause,
          onPressed: () async {
            if (_checkPremium()) return;
            _isVideoStarted ? c.pause() : c.play();
            if (!mounted) return;
            setState(() {});
            if (c.value.isPlaying == false) {
              _cancelAndRestartTimer();
            } else {
              _startHideTimer();
            }
          },
        ),
      ),
    );
  }

  // ── Episode details (bottom-left) ──────────────────────

  Widget _buildEpisodeDetails({required int index}) {
    final title =
        clipsProvider.contentDetailModel.result?[0].name ??
        widget.episodeList[index].name ??
        '';
    final seasonNum = (clipsProvider.seasonPos) + 1;
    final epNum = index + 1;
    final desc = widget.episodeList[index].description ?? '';

    return Padding(
      // Right padding to avoid overlap with feature rail
      padding: const EdgeInsets.fromLTRB(14, 0, 72, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            MyText(
              color: titleTextColor,
              text: title,
              fontsizeNormal: 20,
              fontsizeWeb: 22,
              fontweight: FontWeight.w800,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              isShadowText: true,
            ),
          const SizedBox(height: 4),
          MyText(
            color: colorPrimary,
            text: 'S$seasonNum  •  E$epNum',
            fontsizeNormal: 13,
            fontsizeWeb: 14,
            fontweight: FontWeight.w600,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            isShadowText: true,
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            MyText(
              color: descTextColor,
              text: desc,
              fontsizeNormal: 12,
              fontsizeWeb: 13,
              fontweight: FontWeight.w400,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              isShadowText: true,
            ),
          ],
        ],
      ),
    );
  }

  // ── Right-side feature rail ─────────────────────────────

  Widget _buildFeatureBtns(int index) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(right: 12),
          constraints: const BoxConstraints(minWidth: 45),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Share
              _buildFeatureIcon(
                iconName: 'ic_send',
                index: index,
                count: "share",
                isTitle: true,
                onClick: () async {
                  ShareModel shareModel = ShareModel(
                    newPage: RoutesConstant.clipsEpisodesPage,
                    videoTitle:
                        clipsProvider.contentDetailModel.result?[0].name ?? "",
                    videoId:
                        clipsProvider.contentDetailModel.result?[0].id ?? 0,
                    videoType:
                        clipsProvider.contentDetailModel.result?[0].videoType ??
                        0,
                    subVideoType:
                        clipsProvider
                            .contentDetailModel
                            .result?[0]
                            .subVideoType ??
                        0,
                    typeId:
                        clipsProvider.contentDetailModel.result?[0].typeId ?? 0,
                  );
                  Utils.openShareDialog(
                    context: context,
                    shareModel: shareModel,
                  );
                },
              ),

              // Episodes
              _buildFeatureIcon(
                iconName: "ic_episodes",
                index: index,
                isTitle: true,
                count: "episodes",
                onClick: () async {
                  clipsProvider.setDialogState(true);
                  _showAllEpisodeDialog();
                },
              ),

              // Comments
              _buildFeatureIcon(
                iconName: "ic_comment",
                index: index,
                isTitle: true,
                count: "comments",
                onClick: () => _handleComment(),
              ),

              // Mute/Unmute
              ValueListenableBuilder<Map<int, bool?>>(
                valueListenable: _muteStatesNotifier,
                builder: (_, states, _) {
                  final isMuted = states[index] ?? false;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () => toggleMute(index),
                          child: Center(
                            child: SimpleShadow(
                              color: black.withValues(alpha: 0.5),
                              sigma: 2,
                              child: Icon(
                                isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: titleTextColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      MyText(
                        color: titleTextColor,
                        text: isMuted ? "unmute" : "mute",
                        multilanguage: true,
                        fontsizeNormal: 12,
                        fontsizeWeb: 14,
                        fontweight: FontWeight.w500,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                        isShadowText: true,
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),

              // Duration timestamp
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: widget.controller,
                builder: (_, val, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText(
                      color: titleTextColor,
                      text: duration2String(val.position),
                      fontsizeNormal: 11,
                      fontsizeWeb: 12,
                      fontweight: FontWeight.w500,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      isShadowText: true,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcon({
    required String iconName,
    required int index,
    required String count,
    required bool isTitle,
    required Function() onClick,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 35,
          height: 35,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: onClick,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(3),
                child: SimpleShadow(
                  color: black.withValues(alpha: 0.5),
                  sigma: 2,
                  child: MyImage(
                    imagePath: "$iconName.png",
                    fit: BoxFit.contain,
                    color: (iconName == "ic_heartfill")
                        ? colorPrimary
                        : titleTextColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (count.isNotEmpty && !isTitle)
          MyText(
            color: titleTextColor,
            text: Utils.withSuffix(int.tryParse(count) ?? 0),
            fontsizeNormal: 12,
            fontsizeWeb: 14,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
            isShadowText: true,
          )
        else if (isTitle)
          MyText(
            color: titleTextColor,
            text: count,
            multilanguage: true,
            fontsizeNormal: 12,
            fontsizeWeb: 14,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
            isShadowText: true,
          ),
        const SizedBox(height: 15),
      ],
    );
  }

  // ── Speed button (preserved, not shown in current UI) ──
  // ignore: unused_element
  Widget _buildBottomBar() {
    final c = widget.controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MyText(
                color: white,
                text: duration2String(value.position),
                textalign: TextAlign.center,
                fontsizeNormal: 14,
                fontsizeWeb: 16,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                isShadowText: true,
              ),
              MyText(
                color: white,
                text: " / ",
                textalign: TextAlign.center,
                fontsizeNormal: 15,
                fontsizeWeb: 17,
                fontweight: FontWeight.w600,
                maxline: 2,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                isShadowText: true,
              ),
              MyText(
                color: white,
                text: duration2String(value.duration),
                textalign: TextAlign.center,
                fontsizeNormal: 14,
                fontsizeWeb: 16,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                isShadowText: true,
              ),
              const Spacer(),
              Tooltip(message: 'Playback Speed', child: _buildSpeedButton()),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  GestureDetector _buildSpeedButton() {
    return GestureDetector(
      onTap: _changeSpeed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MyText(
            color: white,
            text: "${_playbackSpeeds[_speedIndex]}x",
            textalign: TextAlign.center,
            fontsizeNormal: 14,
            fontsizeWeb: 16,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
          Container(
            height: 47.0,
            color: transparent,
            padding: const EdgeInsets.only(left: 6, right: 8),
            margin: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.speed, color: white, size: 25),
          ),
        ],
      ),
    );
  }

  // ── Episodes dialog ─────────────────────────────────────

  void _showAllEpisodeDialog() {
    // Pause current video before opening dialog
    final wasPlaying = widget.controller.value.isPlaying;
    if (wasPlaying) widget.controller.pause();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appBgColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return _buildEpiDialogItems();
      },
    ).whenComplete(() {
      clipsProvider.setDialogState(false);
      // Resume video if it was playing before dialog opened
      if (wasPlaying && !_checkPremium()) {
        widget.controller.play();
      }
      if (!mounted) return;
      setState(() {});
    });
  }

  Widget _buildEpiDialogItems() {
    final seasonNum = (clipsProvider.seasonPos) + 1;
    return Container(
      color: appBgColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: MyText(
                    color: titleTextColor,
                    text: "episodes",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 22,
                    fontweight: FontWeight.w700,
                    fontsizeWeb: 24,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
                InkWell(
                  onTap: () => Utils.exitDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: secondaryBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.close, color: white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Season selector
          _buildSeasonBtn(),

          // Separator
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 0.5,
            decoration: Utils.setBackground(
              descTextColor.withValues(alpha: 0.4),
              0,
            ),
          ),

          // 3-column episode grid
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: widget.episodeList.length,
                itemBuilder: (context, position) {
                  final isNowPlaying = widget.vIndex == position;
                  final isPremiumLocked =
                      widget.episodeList[position].isPremium == 1 &&
                      widget.episodeList[position].isBuy != 1;
                  final epLabel = 'S$seasonNum E${position + 1}';

                  return GestureDetector(
                    onTap: () {
                      Utils.exitDialog(context);
                      widget.pageController.jumpToPage(position);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail
                          MyNetworkImage(
                            imageUrl:
                                widget.episodeList[position].thumbnail ?? "",
                            fit: BoxFit.cover,
                          ),

                          // Dim non-current episodes
                          if (!isNowPlaying)
                            Container(
                              decoration: BoxDecoration(
                                color: black.withValues(alpha: 0.35),
                              ),
                            ),

                          // Bottom-left: play icon + S1 E1 label
                          Positioned(
                            left: 6,
                            bottom: 6,
                            right: 4,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: white,
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: MyText(
                                    color: white,
                                    text: epLabel,
                                    fontsizeNormal: 11,
                                    fontsizeWeb: 12,
                                    fontweight: FontWeight.w600,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textalign: TextAlign.start,
                                    isShadowText: true,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // "NOW PLAYING" badge
                          if (isNowPlaying)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorPrimary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: MyText(
                                  color: black,
                                  text: "NOW PLAYING",
                                  fontsizeNormal: 8,
                                  fontsizeWeb: 9,
                                  fontweight: FontWeight.w700,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textalign: TextAlign.center,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                          // Premium lock icon
                          if (isPremiumLocked)
                            Center(
                              child: Container(
                                height: 30,
                                width: 30,
                                alignment: Alignment.center,
                                child: MyImage(
                                  imagePath: "ic_lock.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonBtn() {
    return Consumer<ClipsProvider>(
      builder: (context, clipsProvider, child) {
        if (clipsProvider.contentDetailModel.result?[0].season != null &&
            (clipsProvider.contentDetailModel.result?[0].season?.length ?? 0) >
                0) {
          return Container(
            height: 50,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 35 : 12,
              Dimens.isBigScreen(context) ? 10 : 8,
              Dimens.isBigScreen(context) ? 35 : 12,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 10,
                itemCount:
                    clipsProvider
                        .contentDetailModel
                        .result?[0]
                        .season
                        ?.length ??
                    0,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              widget.onSeasonChange(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              alignment: Alignment.center,
                              child: MyText(
                                color: (index == clipsProvider.seasonPos)
                                    ? titleTextColor
                                    : descTextColor,
                                text:
                                    clipsProvider
                                        .contentDetailModel
                                        .result?[0]
                                        .season?[index]
                                        .name ??
                                    "-",
                                fontsizeNormal: 13,
                                fontsizeWeb: 15,
                                fontstyle: FontStyle.normal,
                                fontweight: FontWeight.w600,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.start,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 2,
                        constraints: const BoxConstraints(minWidth: 50),
                        decoration: Utils.setBackground(
                          (index == clipsProvider.seasonPos)
                              ? colorPrimary
                              : transparent,
                          2,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  // ── Comments ────────────────────────────────────────────

  void _handleComment() {
    if (!mounted) return;
    if (Utils.checkLoginUser(context)) {
      clipsProvider.setDialogState(true);
      clipsProvider.resetCommentData();
      clipsProvider.getComments(
        widget.clipVideoId,
        widget.clipVideoType,
        widget.clipSubVideoType,
        1,
      );
      openCommentSheet();
    }
  }

  void openCommentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: transparent,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: transparent,
          resizeToAvoidBottomInset: true,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<ClipsProvider>(
              builder: (context, cp, _) => _buildCommentDialog(),
            ),
          ),
        );
      },
    ).whenComplete(() {
      clipsProvider.setDialogState(false);
      clipsProvider.setDialogType(
        position: 0,
        dialogType: comments.CommentDialogEnum.comments,
      );
    });
  }

  Widget _buildCommentDialog() {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.6,
        constraints: const BoxConstraints(minHeight: 0),
        decoration: BoxDecoration(
          color: secondaryBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentHeader(),
              Utils.buildGradLine(),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 0,
                    maxHeight: MediaQuery.of(context).size.height,
                  ),
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        (clipsProvider.currentDialogPage ==
                            comments.CommentDialogEnum.comments)
                        ? _buildCommentList()
                        : _buildReplyList(
                            commentIndex:
                                clipsProvider.selectedCommentIndex ?? 0,
                          ),
                  ),
                ),
              ),
              if (clipsProvider.loadCommentMore || clipsProvider.loadReplyMore)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Utils.pageLoader(),
                )
              else
                const SizedBox.shrink(),
              Utils.buildGradLine(),
              // Comment input
              Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height,
                ),
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 25),
                alignment: Alignment.center,
                decoration: Utils.setBGWithBorder(
                  transparent,
                  titleTextColor,
                  5,
                  0.7,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: commentController,
                        maxLines: 1,
                        scrollPhysics: const AlwaysScrollableScrollPhysics(),
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: transparent,
                          border: InputBorder.none,
                          hintText: Locales.string(context, "comment_hint"),
                          hintStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            color: descTextColor,
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                        ),
                        obscureText: false,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          color: titleTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () async {
                          if (!clipsProvider.sending) {
                            await clipsProvider.addComments(
                              commentController.text.toString(),
                              (clipsProvider.currentDialogPage ==
                                      comments.CommentDialogEnum.comments)
                                  ? 0
                                  : (clipsProvider
                                            .commentList?[clipsProvider
                                                    .selectedCommentIndex ??
                                                0]
                                            .id ??
                                        0),
                              widget.clipVideoId,
                              widget.clipVideoType,
                              widget.clipSubVideoType,
                            );
                            commentController.clear();
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.all(4),
                          child: Consumer<ClipsProvider>(
                            builder: (context, cp, _) {
                              if (!cp.sending) {
                                return MyImage(
                                  height: 15,
                                  width: 15,
                                  fit: BoxFit.contain,
                                  imagePath: "ic_send.png",
                                  color: titleTextColor,
                                );
                              } else {
                                return Utils.pageLoaderWithStroke(
                                  strokeWidth: 2,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentHeader() {
    final isReplies =
        clipsProvider.currentDialogPage == comments.CommentDialogEnum.replies;
    final int count = isReplies
        ? (clipsProvider
                  .commentList?[clipsProvider.selectedCommentIndex ?? 0]
                  .totalReply ??
              0)
        : (clipsProvider.contentDetailModel.result?[0].totalComment ?? 0);
    final String label = isReplies
        ? (count > 1 ? "replies" : "reply")
        : (count > 1 ? "comments" : "comment");

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isReplies)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  clipsProvider.setDialogType(
                    position: 0,
                    dialogType: comments.CommentDialogEnum.comments,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MyImage(
                    width: 18,
                    height: 18,
                    imagePath: "back.png",
                    fit: BoxFit.contain,
                    color: titleTextColor,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: isReplies ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MyText(
                    color: titleTextColor,
                    text: Utils.withSuffix(count),
                    fontsizeNormal: 15,
                    fontsizeWeb: 17,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    isShadowText: true,
                  ),
                  const SizedBox(width: 5),
                  MyText(
                    color: white,
                    multilanguage: true,
                    text: label,
                    fontsizeNormal: 15,
                    fontsizeWeb: 17,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    isShadowText: true,
                  ),
                ],
              ),
            ),
          ),
          if (!isReplies)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  clipsProvider.resetCommentData();
                  Utils.exitPage(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MyImage(
                    width: 15,
                    height: 15,
                    imagePath: "ic_close.png",
                    fit: BoxFit.contain,
                    color: titleTextColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    if (clipsProvider.loadingComment && !clipsProvider.loadCommentMore) {
      return Center(child: Utils.pageLoader());
    }
    if ((clipsProvider.commentList?.length ?? 0) > 0) {
      return SingleChildScrollView(
        controller: commentScrollController,
        child: AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          crossAxisSpacing: 0,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          mainAxisSpacing: 20,
          itemCount: clipsProvider.commentList?.length ?? 0,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, position) => _buildCommentItem(position: position),
        ),
      );
    }
    return const NoData(title: '', subTitle: '');
  }

  Widget _buildCommentItem({required int position}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(minHeight: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.zero,
            width: 35,
            height: 35,
            decoration: Utils.setGradTTBBorderWithBG(
              white,
              white,
              transparent,
              20,
              1,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: MyNetworkImage(
                width: 35,
                height: 35,
                imageUrl: clipsProvider.commentList?[position].userImage ?? "",
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: titleTextColor,
                  text: clipsProvider.commentList?[position].userName ?? "",
                  fontsizeNormal: 13,
                  fontsizeWeb: 14,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.bold,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
                const SizedBox(height: 5),
                MyText(
                  color: titleTextColor,
                  text: clipsProvider.commentList?[position].comment ?? "",
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.normal,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Reply button
                    InkWell(
                      onTap: () {
                        clipsProvider.getReplyComments(
                          clipsProvider.commentList?[position].id ?? 0,
                          1,
                        );
                        clipsProvider.setDialogType(
                          position: position,
                          dialogType: comments.CommentDialogEnum.replies,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: MyText(
                          color: descTextColor,
                          text:
                              ((clipsProvider
                                          .commentList?[position]
                                          .totalReply ??
                                      0) >
                                  0)
                              ? "${Utils.withSuffix(clipsProvider.commentList?[position].totalReply ?? 0)} ${Locales.string(context, "reply")}"
                              : Locales.string(context, "reply"),
                          fontsizeNormal: 12,
                          fontsizeWeb: 14,
                          maxline: 3,
                          overflow: TextOverflow.ellipsis,
                          fontweight: FontWeight.normal,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                          isShadowText: true,
                        ),
                      ),
                    ),
                    // Edit (own comment only)
                    if (Constant.userID ==
                        (clipsProvider.commentList?[position].userId
                                .toString() ??
                            "0"))
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: InkWell(
                          onTap: () {
                            editCommentController = TextEditingController(
                              text:
                                  clipsProvider
                                      .commentList?[position]
                                      .comment ??
                                  "",
                            );
                            clipsProvider.wantToEditedComment(
                              !clipsProvider.wantToEdit,
                              position,
                            );
                          },
                          child: Container(
                            height: 20,
                            width: 20,
                            padding: const EdgeInsets.all(3),
                            child: MyImage(
                              imagePath:
                                  (clipsProvider.wantToEdit &&
                                      clipsProvider.commentPos == position)
                                  ? "ic_close.png"
                                  : "ic_edit.png",
                              color: descTextColor,
                            ),
                          ),
                        ),
                      ),
                    // Delete (own comment only)
                    if (Constant.userID ==
                        (clipsProvider.commentList?[position].userId
                                .toString() ??
                            ""))
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        child: InkWell(
                          onTap: () {
                            if (!clipsProvider.loading) {
                              _openConfirmDeleteDialog(position: position);
                            }
                          },
                          child: Container(
                            height: 20,
                            width: 20,
                            padding: const EdgeInsets.all(1),
                            child: MyImage(
                              imagePath: "ic_delete.png",
                              color: descTextColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Inline edit field
                if (clipsProvider.wantToEdit &&
                    clipsProvider.commentPos == position)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 40,
                    constraints: BoxConstraints(
                      minHeight: 0,
                      maxHeight: MediaQuery.of(context).size.height,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: editCommentController,
                            maxLines: 1,
                            scrollPhysics:
                                const AlwaysScrollableScrollPhysics(),
                            textAlign: TextAlign.left,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: Locales.string(
                                context,
                                "edit_comment_hint",
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                color: descTextColor,
                              ),
                              contentPadding: const EdgeInsets.only(right: 10),
                            ),
                            obscureText: false,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              color: titleTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            if (!clipsProvider.sendingEdited) {
                              await clipsProvider.editComments(
                                position,
                                widget.clipVideoId,
                                widget.clipVideoType,
                                widget.clipSubVideoType,
                                editCommentController.text.toString(),
                                clipsProvider.commentList?[position].id ?? 0,
                              );
                              editCommentController.clear();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: (!clipsProvider.sendingEdited)
                                ? MyImage(
                                    height: 15,
                                    width: 15,
                                    fit: BoxFit.contain,
                                    imagePath: "ic_send.png",
                                    color: descTextColor,
                                  )
                                : Utils.pageLoaderWithStroke(strokeWidth: 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildReplyList({required int commentIndex}) {
    if (clipsProvider.loadingReply && !clipsProvider.loadReplyMore) {
      return Center(child: Utils.pageLoader());
    }
    if ((clipsProvider.commentRepliesList?.length ?? 0) > 0) {
      return SingleChildScrollView(
        controller: repliesScrollController,
        child: AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          crossAxisSpacing: 0,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          mainAxisSpacing: 20,
          itemCount: clipsProvider.commentRepliesList?.length ?? 0,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, position) =>
              _buildReplyCommentItem(position: position),
        ),
      );
    }
    return const NoData(title: '', subTitle: '');
  }

  Widget _buildReplyCommentItem({required int position}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(minHeight: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.zero,
            width: 35,
            height: 35,
            decoration: Utils.setGradTTBBorderWithBG(
              white,
              white,
              transparent,
              20,
              1,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: MyNetworkImage(
                width: 35,
                height: 35,
                imageUrl:
                    clipsProvider.commentRepliesList?[position].userImage ?? "",
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: titleTextColor,
                  text:
                      clipsProvider.commentRepliesList?[position].userName ??
                      "",
                  fontsizeNormal: 13,
                  fontsizeWeb: 14,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.bold,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
                const SizedBox(height: 5),
                MyText(
                  color: titleTextColor,
                  text:
                      clipsProvider.commentRepliesList?[position].comment ?? "",
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.normal,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _openConfirmDeleteDialog({required int position}) {
    showDialog<dynamic>(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (_) => _buildDeleteDialog(position: position),
    );
  }

  Widget _buildDeleteDialog({required int position}) {
    return Dialog(
      alignment: Alignment.centerRight,
      backgroundColor: secondaryBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: EdgeInsets.all(
        MediaQuery.of(context).size.width > 900 ? 50 : 30,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: Wrap(
          children: [
            Container(
              decoration: Utils.setBGWithBorder(
                transparent,
                descTextColor,
                8,
                0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    alignment: Alignment.centerLeft,
                    child: MyText(
                      color: white,
                      text: "confirm_delete_msg",
                      multilanguage: true,
                      textalign: TextAlign.start,
                      fontsizeNormal: 14,
                      fontsizeWeb: 16,
                      fontweight: FontWeight.w500,
                      maxline: 5,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () => Utils.exitPage(context),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 75),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: descTextColor,
                                width: .5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: MyText(
                              color: white,
                              text: "cancel",
                              multilanguage: true,
                              textalign: TextAlign.center,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Utils.exitPage(context);
                            await clipsProvider.deleteComments(
                              position,
                              widget.clipVideoId,
                              widget.clipVideoType,
                              widget.clipSubVideoType,
                              clipsProvider.commentList?[position].id ?? 0,
                              clipsProvider.commentList?[position].userId ?? 0,
                            );
                            if (!mounted) return;
                            clipsProvider.notifyProvider();
                          },
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 75),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorAccent,
                              borderRadius: BorderRadius.circular(5),
                              shape: BoxShape.rectangle,
                            ),
                            child: MyText(
                              color: white,
                              text: "delete",
                              multilanguage: true,
                              textalign: TextAlign.center,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
