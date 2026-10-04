import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../model/clipsmodel.dart' as clips;
import '../pages/clipsepisodes.dart';
import '../shimmer/shimmerutils.dart';
import '../provider/clipsprovider.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/mytext.dart';

class Clips extends StatefulWidget {
  final int clipId;
  final String openFrom;
  const Clips({required this.clipId, required this.openFrom, super.key});

  @override
  State<Clips> createState() => _ClipsState();
}

class _ClipsState extends State<Clips> {
  late ClipsProvider clipsProvider;

  final PageController _pageController = PageController(viewportFraction: 0.88);
  late ClipsPlaybackManager _playbackManager;

  int _previousIndex = 0;
  Timer? _activationDebounce;
  bool _isPaginating = false;

  @override
  void initState() {
    super.initState();
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);
    _playbackManager = ClipsPlaybackManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    printLog("_getData clipId =====> ${widget.clipId}");
    await clipsProvider.getAllShorts(widget.clipId, 1, forceRefresh: true);

    if (!mounted) return;
    final clipsList = clipsProvider.shortFilmsList ?? [];
    if (clipsList.isNotEmpty) {
      await _playbackManager.activate(0, clipsList[0].trailerUrl ?? '');
    }
    setState(() {});
  }

  void _onPageChanged(int index) {
    _activationDebounce?.cancel();

    _playbackManager.deactivate(_previousIndex);
    _previousIndex = index;

    _activationDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      final clipsList = clipsProvider.shortFilmsList ?? [];
      if (index < clipsList.length) {
        _playbackManager.activate(index, clipsList[index].trailerUrl ?? '');
      }
    });

    final clipsList = clipsProvider.shortFilmsList ?? [];
    if (index >= clipsList.length - 3) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isPaginating) return;
    if (clipsProvider.isMorePage == false) return;
    _isPaginating = true;
    printLog("_loadMore page =====> ${(clipsProvider.currentPage ?? 0) + 1}");
    clipsProvider
        .getAllShorts(
          widget.clipId,
          (clipsProvider.currentPage ?? 0) + 1,
          forceRefresh: true,
        )
        .then((_) {
          if (mounted) setState(() => _isPaginating = false);
        });
  }

  @override
  void dispose() {
    _activationDebounce?.cancel();
    _pageController.dispose();
    _playbackManager.disposeAll();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClipsProvider>(
      builder: (context, cp, _) {
        if (cp.isLoading && !cp.loadMore) {
          return Scaffold(
            backgroundColor: appBgColor,
            body: ShimmerUtils.buildClipsShimmer(
              context,
              widget.openFrom == "bottom",
            ),
          );
        }

        final clipsList = cp.shortFilmsList ?? [];

        return Scaffold(
          backgroundColor: appBgColor,
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: clipsList.length,
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: TadkaClipItem(
                        key: ValueKey(clipsList[index].id ?? index),
                        clip: clipsList[index],
                        index: index,
                        manager: _playbackManager,
                        clipId: widget.clipId,
                        openFrom: widget.openFrom,
                        onVideoEnd: () {
                          printLog("onVideoEnd auto-scroll index=$index");
                          if (index + 1 < clipsList.length) {
                            _pageController.animateToPage(
                              index + 1,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),

                if (_isPaginating)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: white.withValues(alpha: 0.54),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TadkaClipItem — portrait card clip
// ─────────────────────────────────────────────
class TadkaClipItem extends StatefulWidget {
  final clips.Result clip;
  final int index;
  final ClipsPlaybackManager manager;
  final int clipId;
  final String openFrom;
  final VoidCallback? onVideoEnd;

  const TadkaClipItem({
    required this.clip,
    required this.index,
    required this.manager,
    required this.clipId,
    required this.openFrom,
    this.onVideoEnd,
    super.key,
  });

  @override
  State<TadkaClipItem> createState() => _TadkaClipItemState();
}

class _TadkaClipItemState extends State<TadkaClipItem>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late ClipsProvider clipsProvider;

  final ValueNotifier<bool> _ready = ValueNotifier(false);

  bool _hasSignalledEnd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);

    widget.manager.addReadyListener(widget.index, _onControllerReady);

    final c = widget.manager.controllerFor(widget.index);
    if (c != null && c.value.isInitialized) {
      _onControllerReady();
    }
  }

  void _onControllerReady() {
    if (!mounted) return;
    _ready.value = true;
    final c = widget.manager.controllerFor(widget.index);
    if (c != null) {
      c.removeListener(_videoListener);
      c.addListener(_videoListener);
    }
  }

  void _videoListener() {
    final c = widget.manager.controllerFor(widget.index);
    if (c == null || !c.value.isInitialized) return;

    final pos = c.value.position;
    final dur = c.value.duration;
    if (dur.inMilliseconds == 0) return;

    final tolerance = const Duration(milliseconds: 200);

    if (!_hasSignalledEnd && pos >= dur - tolerance) {
      _hasSignalledEnd = true;
      printLog(
        "TadkaClipItem: end detected index=${widget.index} DialogState=${clipsProvider.isDialogOpen}",
      );
      if (!clipsProvider.isDialogOpen) {
        widget.onVideoEnd?.call();
      }
    }
    if (pos < dur - tolerance && _hasSignalledEnd) {
      _hasSignalledEnd = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      widget.manager.controllerFor(widget.index)?.pause();
    }
  }

  @override
  void didPushNext() {
    if (!clipsProvider.isDialogOpen) {
      widget.manager.controllerFor(widget.index)?.pause();
    }
  }

  @override
  void didPopNext() {
    if (!clipsProvider.isDialogOpen) {
      final c = widget.manager.controllerFor(widget.index);
      if (c != null && c.value.isInitialized) c.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    widget.manager.controllerFor(widget.index)?.removeListener(_videoListener);
    widget.manager.removeReadyListener(widget.index);
    _ready.dispose();
    super.dispose();
  }

  // ── Action handlers ──────────────────────────────────────

  void _handleEpisodes() async {
    printLog("Episodes tapped index=${widget.index}");
    final int typeId = clipsProvider.shortFilmsList?[widget.index].typeId ?? 0;
    final int videoType =
        clipsProvider.shortFilmsList?[widget.index].videoType ?? 0;
    final int videoId = clipsProvider.shortFilmsList?[widget.index].id ?? 0;
    const int subVideoType = 0;
    try {
      clipsProvider.setEpiLoading(true);
      clipsProvider.getShortsDetails(
        typeId,
        videoType,
        videoId,
        subVideoType,
        forceRefresh: true,
      );
    } on Exception catch (e) {
      printLog("_handleEpisodes Exception => $e");
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClipsEpisodes(
          videoId: videoId,
          subVideoType: subVideoType,
          videoType: videoType,
          typeId: typeId,
        ),
      ),
    );
    final c = widget.manager.controllerFor(widget.index);
    if (c != null && c.value.isInitialized && !c.value.isPlaying) {
      await c.play();
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _handleEpisodes();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: black.withValues(alpha: 0.50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 0: Video / poster
              Positioned.fill(child: _buildVideoBackground()),

              // Layer 1: Top gradient (banner-style)
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
                        colors: [
                          black.withValues(alpha: 0.55),
                          black.withValues(alpha: 0.20),
                          black.withValues(alpha: 0.05),
                          transparent,
                        ],
                        stops: const [0.0, 0.25, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 2: Bottom gradient (banner-style)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 300,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          black.withValues(alpha: 0.92),
                          black.withValues(alpha: 0.82),
                          black.withValues(alpha: 0.70),
                          black.withValues(alpha: 0.50),
                          black.withValues(alpha: 0.28),
                          black.withValues(alpha: 0.08),
                          transparent,
                        ],
                        stops: const [0.0, 0.18, 0.32, 0.52, 0.68, 0.82, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 3: Top bar — back (optional) + badge + mute
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: back button (when not opened from bottom sheet)
                    if (widget.openFrom != "bottom")
                      GestureDetector(
                        onTap: () => Utils.exitPage(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: black.withValues(alpha: 0.50),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: white,
                              size: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    // Right: mute toggle
                    GestureDetector(
                      onTap: widget.manager.toggleMute,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: black.withValues(alpha: 0.50),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.manager.isMuted,
                            builder: (_, muted, child) => Icon(
                              muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Layer 5+6: Title/description + play button — same row, same baseline
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildBottomContentPanel()),
                    const SizedBox(width: 10),
                    _buildCardPlayButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return ValueListenableBuilder<bool>(
      valueListenable: _ready,
      builder: (context, ready, _) {
        if (ready) {
          final controller = widget.manager.controllerFor(widget.index);
          if (controller != null && controller.value.isInitialized) {
            return FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            );
          }
        }
        return _buildPoster();
      },
    );
  }

  Widget _buildPoster() {
    final url = widget.clip.thumbnail ?? '';
    if (url.isEmpty) {
      return Container(color: appBgColor);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, _, _) => Container(color: appBgColor),
    );
  }

  Widget _buildCardPlayButton() {
    return GestureDetector(
      onTap: _handleEpisodes,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: white.withValues(alpha: 0.65), width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.play_arrow_rounded, color: white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomContentPanel() {
    final title = widget.clip.name ?? '';
    final desc = widget.clip.description ?? '';
    final categoryName = widget.clip.categoryName ?? '';
    // Show languageId only when it is a readable name, not a numeric ID
    final langStr = widget.clip.languageId ?? '';
    final showLang = langStr.isNotEmpty && int.tryParse(langStr) == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          MyText(
            color: titleTextColor,
            text: title,
            fontsizeNormal: 16,
            fontsizeWeb: 18,
            fontweight: FontWeight.w700,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            isShadowText: true,
          ),

        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          ExpandableText(
            desc,
            expandText: Locales.string(context, "more"),
            collapseText: Locales.string(context, "less"),
            expandOnTextTap: true,
            collapseOnTextTap: true,
            maxLines: kIsWeb ? 50 : 2,
            linkColor: colorPrimary,
            style: TextStyle(
              color: white.withValues(alpha: 0.80),
              fontSize: kIsWeb ? 14 : 12,
              height: 1.4,
              shadows: [
                Shadow(color: black.withValues(alpha: 0.87), blurRadius: 6),
              ],
            ),
          ),
        ],

        // Metadata row: language • episode info
        if (showLang) ...[
          const SizedBox(height: 5),
          MyText(
            color: descTextColor,
            text: langStr,
            fontsizeNormal: 11,
            fontsizeWeb: 13,
            fontweight: FontWeight.w400,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            isShadowText: true,
          ),
        ],

        // Metadata row: category tags
        if (categoryName.isNotEmpty) ...[
          const SizedBox(height: 5),
          MyText(
            color: white.withValues(alpha: 0.8),
            text: categoryName
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .join(' | '),
            fontsizeNormal: 11,
            fontsizeWeb: 13,
            fontweight: FontWeight.w600,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            isShadowText: true,
          ),
        ],

        const SizedBox(height: 4),
        SmartBannerAd(isSpacing: true, topSpace: 4, bottomSpace: 4),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildProgressSlider() {
    final controller = widget.manager.controllerFor(widget.index);
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(height: 4);
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, val, _) {
        final dur = val.duration.inMilliseconds;
        final pos = val.position.inMilliseconds;
        final prog = dur > 0 ? pos / dur : 0.0;
        return SizedBox(
          height: 4,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 2,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: const RoundedRectSliderTrackShape(),
              minThumbSeparation: 0,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: prog.clamp(0.0, 1.0),
              onChanged: (v) => controller.seekTo(val.duration * v),
              activeColor: colorPrimary,
              inactiveColor: white.withValues(alpha: 0.30),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// ClipsPlaybackManager — controller pool (max 3 alive: active ± 1)
// ─────────────────────────────────────────────
class ClipsPlaybackManager {
  final Map<int, VideoPlayerController> _pool = {};
  final ValueNotifier<bool> isMuted = ValueNotifier(true);
  int? _activeIndex;
  Timer? _playDelayTimer;

  final Map<int, VoidCallback> _readyListeners = {};

  VideoPlayerController? controllerFor(int index) => _pool[index];

  void addReadyListener(int index, VoidCallback listener) {
    _readyListeners[index] = listener;
  }

  void removeReadyListener(int index) {
    _readyListeners.remove(index);
  }

  Future<void> activate(int index, String videoUrl) async {
    if (videoUrl.isEmpty) return;

    if (_activeIndex == index && (_pool[index]?.value.isPlaying == true)) {
      return;
    }
    _activeIndex = index;

    if (!_pool.containsKey(index)) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
      _pool[index] = controller;
      try {
        await controller.initialize();
        controller.setLooping(true);
        // readyListener deferred to timer so poster stays visible until play
      } catch (e) {
        printLog("ClipsPlaybackManager: init error at $index: $e");
        _pool.remove(index);
        return;
      }
    }

    final controller = _pool[index];
    if (controller == null || !controller.value.isInitialized) return;

    await controller.setLooping(true);
    await controller.setVolume(isMuted.value ? 0.0 : 1.0);
    // Always start every clip from the beginning (covers prev/next navigation)
    await controller.seekTo(Duration.zero);

    _playDelayTimer?.cancel();
    _playDelayTimer = Timer(const Duration(milliseconds: 800), () {
      if (_activeIndex == index) {
        // Signal ready here so poster stays visible until the moment video plays
        _readyListeners[index]?.call();
        _pool[index]?.play();
      }
    });

    _prunePool(index);
  }

  Future<void> deactivate(int index, {bool dispose = false}) async {
    _playDelayTimer?.cancel();
    final controller = _pool[index];
    if (controller == null) return;
    if (controller.value.isInitialized && controller.value.isPlaying) {
      await controller.pause();
    }
    if (dispose) {
      controller.dispose();
      _pool.remove(index);
      _readyListeners.remove(index);
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (_activeIndex != null) {
      _pool[_activeIndex!]?.setVolume(isMuted.value ? 0.0 : 1.0);
    }
  }

  void _prunePool(int activeIndex) {
    final allowed = {activeIndex - 1, activeIndex, activeIndex + 1};
    final toRemove = _pool.keys.where((k) => !allowed.contains(k)).toList();
    for (final k in toRemove) {
      _pool[k]?.pause();
      _pool[k]?.dispose();
      _pool.remove(k);
      _readyListeners.remove(k);
    }
  }

  void disposeAll() {
    _playDelayTimer?.cancel();
    for (final c in _pool.values) {
      if (c.value.isInitialized && c.value.isPlaying) c.pause();
      c.dispose();
    }
    _pool.clear();
    _readyListeners.clear();
    isMuted.dispose();
  }
}
