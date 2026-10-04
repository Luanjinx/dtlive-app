import 'dart:async';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [UI]
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../main.dart';
import '../widget/mynetworkimg.dart';
import '../model/commentmodel.dart';
import '../model/sharemodel.dart';
import '../model/clipepisodesmodel.dart' as shortsepisode;
import '../model/contentdetailmodel.dart' as details;
import '../provider/clipsprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/centerplaybutton.dart';
import '../widget/muteunmutebutton.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import 'webcomman.dart';

String duration2String(Duration? dur) {
  final duration = dur ?? Duration.zero;

  if (duration.inSeconds <= 0) return "00:00";

  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;

  return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

class WebClipsEpisodes extends StatefulWidget {
  final String? newPage, oldPage, reqText;
  final int videoId, subVideoType, videoType, typeId;
  const WebClipsEpisodes({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    required this.videoId,
    required this.subVideoType,
    required this.videoType,
    required this.typeId,
    super.key,
  });

  @override
  State<WebClipsEpisodes> createState() => _WebClipsEpisodesState();
}

class _WebClipsEpisodesState extends State<WebClipsEpisodes> {
  late ClipsProvider clipsProvider;

  TextEditingController commentController = TextEditingController();
  TextEditingController editCommentController = TextEditingController();

  final PageController _pageController = PageController();
  Map<int, VideoPlayerController> _controllers = {};
  late ValueNotifier<int> _current;
  final Map<int, ValueNotifier<bool>> _isControllerInitialized = {};
  final int _preloadCount = 4;
  Timer? _debounce;

  final commentScrollController = ScrollController();
  final repliesScrollController = ScrollController();

  Future<void> _commentScrollListener() async {
    if (!commentScrollController.hasClients) return;
    if (commentScrollController.offset >=
            commentScrollController.position.maxScrollExtent &&
        !commentScrollController.position.outOfRange &&
        (clipsProvider.isCommentMorePage ?? false)) {
      clipsProvider.setCommentLoadMore(true);
      await clipsProvider.getComments(
        (clipsProvider.contentDetailModel.result?[0].id ?? 0),
        (clipsProvider.contentDetailModel.result?[0].videoType ?? 0),
        0,
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
  void initState() {
    super.initState();
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);
    commentScrollController.addListener(_commentScrollListener);
    repliesScrollController.addListener(_repliesScrollListener);
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
      await _preLoadEpisodes();

      final firstController = _controllers[0];
      if (firstController != null && firstController.value.isInitialized) {
        if (!_checkPremium(0)) await firstController.play();
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future _getAllEpisodes(int seasonPos) async {
    printLog("_getAllEpisodes seasonPos =====> $seasonPos");
    printLog(
      "_getAllEpisodes seasonId ======> ${clipsProvider.contentDetailModel.result?[0].season?[seasonPos].id ?? 0}",
    );
    await clipsProvider.setSeason(seasonPos);
    await clipsProvider.getEpisodesBySeason(
      widget.videoId,
      clipsProvider.contentDetailModel.result?[0].season?[seasonPos].id ?? 0,
      1,
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _preLoadEpisodes() async {
    final episodes = clipsProvider.shortFilmEpisodeModel.result;
    if (episodes == null || episodes.isEmpty) return;

    // Initialize the first episode and play if not premium
    await _prepare(0, playIfCurrent: true);

    // Preload the next few episodes in parallel (without playing)
    final futures = <Future>[];
    for (int i = 1; i <= _preloadCount && i < episodes.length; i++) {
      futures.add(_prepare(i));
    }
    await Future.wait(futures);
  }

  Future<void> _prepare(int index, {bool playIfCurrent = false}) async {
    final episodes = clipsProvider.shortFilmEpisodeModel.result;
    if (episodes == null || index < 0 || index >= episodes.length) return;
    if (_controllers.containsKey(index)) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(episodes[index].video320 ?? ""),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    _controllers[index] = controller;
    _isControllerInitialized[index] = ValueNotifier(false);

    unawaited(() async {
      try {
        await controller.initialize();
        controller.setLooping(true);

        // Only play current video
        if (playIfCurrent && !_checkPremium(index)) {
          await controller.play();
        }

        await controller.seekTo(Duration.zero);

        _isControllerInitialized[index]?.value = true;

        if (!mounted) return;
        setState(() {});
      } catch (e, s) {
        printLog("_prepare Video error at index = $index : $e\n$s");
      }
    }());
  }

  void _onPageChanged(int index) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      _current.value = index;

      // Play current, pause others
      for (final entry in _controllers.entries) {
        final i = entry.key;
        final c = entry.value;
        if (!c.value.isInitialized) continue;

        if (i == index) {
          if (!_checkPremium(index)) await c.play();
        } else {
          await c.pause();
          unawaited(c.seekTo(Duration.zero));
        }
      }

      // Preload neighbors
      final episodes = clipsProvider.shortFilmEpisodeModel.result;
      if (episodes != null) {
        final futures = <Future>[];
        for (int off = -_preloadCount; off <= _preloadCount; off++) {
          if (off == 0) continue;
          final neighborIndex = index + off;
          if (neighborIndex < 0 || neighborIndex >= episodes.length) continue;
          if (!_controllers.containsKey(neighborIndex)) {
            futures.add(_prepare(neighborIndex));
          }
        }
        await Future.wait(futures);
      }

      // Dispose far-away controllers
      _controllers.keys
          .where((i) => (i - index).abs() > _preloadCount)
          .toList()
          .forEach((i) {
            _controllers[i]?.dispose();
            _controllers.remove(i);
          });

      if (mounted) setState(() {});
    });
  }

  bool _checkPremium(int index) {
    return clipsProvider.shortFilmEpisodeModel.result?[index].isPremium == 1 &&
        clipsProvider.shortFilmEpisodeModel.result?[index].isBuy != 1;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _current.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildClipsUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: "",
    );
  }

  Widget _buildClipsUI() {
    final episodes = clipsProvider.shortFilmEpisodeModel.result;

    if (clipsProvider.isEpiLoading || episodes == null || episodes.isEmpty) {
      return ShimmerUtils.buildClipsEpisodeWEBShimmer(context);
    }

    return TweenAnimationBuilder<double>(
      // [UI]
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400), // [UI]
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: ValueListenableBuilder<int>(
        valueListenable: _current,
        builder: (context, current, _) {
          return Focus(
            // [UI]
            autofocus: true,
            onKeyEvent: (node, event) {
              // [UI]
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  final cur = _current.value;
                  final total =
                      clipsProvider.shortFilmEpisodeModel.result?.length ?? 0;
                  if (cur < total - 1) _pageController.jumpToPage(cur + 1);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  final cur = _current.value;
                  if (cur > 0) _pageController.jumpToPage(cur - 1);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.space) {
                  final c = _controllers[_current.value];
                  if (c != null && c.value.isInitialized) {
                    c.value.isPlaying ? c.pause() : c.play();
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: Dimens.homeTabHeight),
                width: MediaQuery.of(context).size.width,
                height:
                    MediaQuery.of(context).size.height -
                    Dimens.homeTabHeight -
                    kToolbarHeight, // [FIX-8]
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodes.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final isInitializedNotifier =
                        _isControllerInitialized[index];
                    if (isInitializedNotifier == null) {
                      return ShimmerUtils.buildClipsEpisodeWEBShimmer(context);
                    }

                    return ValueListenableBuilder<bool>(
                      valueListenable: isInitializedNotifier,
                      builder: (context, isInitialized, _) {
                        final controller = _controllers[index];
                        printLog(
                          "_buildClipsUI controller isInitialized =====> ${controller?.value.isInitialized}",
                        );
                        printLog(
                          "_buildClipsUI isInitialized =====> $isInitialized",
                        );
                        if (!isInitialized || controller == null) {
                          return ShimmerUtils.buildClipsEpisodeWEBShimmer(
                            context,
                          );
                        }

                        return _buildByPlatform(
                          index: index,
                          current: current,
                          controller: controller,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildByPlatform({
    required int index,
    required int current,
    required VideoPlayerController controller,
  }) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) {
      // [FIX-7]
      return _buildDesktopLayout(
        index: index,
        current: current,
        controller: controller,
      );
    } else if (w >= 700) {
      // [FIX-7]
      return _buildTabletLayout(
        index: index,
        current: current,
        controller: controller,
      );
    } else {
      return _buildMobileLayout(
        index: index,
        current: current,
        controller: controller,
      );
    }
  }

  /* ── Desktop layout (>= 1100px): 9:16 player + nav + sidebar ── */
  Widget _buildDesktopLayout({
    // [FIX-1]
    required int index,
    required int current,
    required VideoPlayerController controller,
  }) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    // Player zone = 42% of screen width — no dead-space Spacer // [FIX-1]
    final playerZoneW = screenW * 0.42; // [FIX-1]

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ZONE 1: Player (42% width, vertically centered) ── // [FIX-1]
        SizedBox(
          width: playerZoneW, // [FIX-1]
          height: screenH * 0.92,
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _EpisodePlayer(
                  controller: controller,
                  pageController: _pageController,
                  isCurrent: (current == index),
                  vIndex: index,
                  seasonList:
                      clipsProvider.contentDetailModel.result?[0].season ?? [],
                  episodeList: clipsProvider.shortFilmEpisodeModel.result ?? [],
                  onVideoEnd: () {
                    printLog("ShortsPlayer Auto-scroll triggered for $index");
                    if (index + 1 <
                        (clipsProvider.shortFilmEpisodeModel.result?.length ??
                            0)) {
                      _pageController.jumpToPage(index + 1);
                    }
                  },
                ),
              ),
            ),
          ),
        ),

        // ── ZONE 2: Nav buttons (64px fixed, vertically centered) ── // [FIX-1]
        SizedBox(
          width: 64, // [FIX-1]
          height: screenH * 0.92,
          child: Center(child: _buildPageChangeBtn(index: current)),
        ),

        // ── ZONE 3: Sidebar (fills remaining width via Expanded) ── // [FIX-1]
        Expanded(
          child: SizedBox(
            height: screenH * 0.92,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 24), // [FIX-1]
              child: _buildInfoPanel(index: index),
            ),
          ),
        ),
      ],
    );
  }

  /* ── Tablet layout (700–1099px): full-width player Stack + info below ── */
  Widget _buildTabletLayout({
    // [FIX-1]
    required int index,
    required int current,
    required VideoPlayerController controller,
  }) {
    final screenH = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player — full width, 55% screen height, nav as Positioned overlay // [FIX-1]
          Stack(
            children: [
              SizedBox(
                width: double.infinity, // [FIX-1]
                height: screenH * 0.55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _EpisodePlayer(
                    controller: controller,
                    pageController: _pageController,
                    isCurrent: (current == index),
                    vIndex: index,
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
                        _pageController.jumpToPage(index + 1);
                      }
                    },
                  ),
                ),
              ),
              // Nav overlay — right edge, vertically centered // [FIX-1]
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _buildPageChangeBtn(index: current)),
              ),
            ],
          ),
          const SizedBox(height: 20), // [FIX-1]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildInfoPanel(index: index),
          ),
        ],
      ),
    );
  }

  /* ── Mobile layout (< 700px): full-width player Stack + info below ── */
  Widget _buildMobileLayout({
    // [FIX-1]
    required int index,
    required int current,
    required VideoPlayerController controller,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player with Positioned nav overlay // [FIX-1]
          Stack(
            children: [
              SizedBox(
                width: double.infinity, // [FIX-1]
                height: Dimens.getResponsivePortHeight(context, 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _EpisodePlayer(
                    controller: controller,
                    pageController: _pageController,
                    isCurrent: (current == index),
                    vIndex: index,
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
                        _pageController.jumpToPage(index + 1);
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                right: 8, // [FIX-1]
                top: 0,
                bottom: 0,
                child: Center(child: _buildPageChangeBtn(index: current)),
              ),
            ],
          ),
          const SizedBox(height: 12), // [FIX-1]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // [FIX-1]
            child: _buildInfoPanel(index: index),
          ),
        ],
      ),
    );
  }

  /* ── Shared info panel — used by all 3 layouts ── */
  Widget _buildInfoPanel({required int index}) {
    // [UI]
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Series title
        MyText(
          color: colorPrimary,
          text: clipsProvider.contentDetailModel.result?[0].name ?? "",
          multilanguage: false,
          fontsizeNormal: 14, // [UI]
          fontsizeWeb: 16, // [UI]
          maxline: 2,
          overflow: TextOverflow.ellipsis,
          fontstyle: FontStyle.normal,
          fontweight: FontWeight.w700,
          textalign: TextAlign.start,
        ),
        const SizedBox(height: 10), // [UI]
        // Episode title — BUG-3 fix: color: titleTextColor
        MyText(
          color: titleTextColor, // [UI]
          text: clipsProvider.shortFilmEpisodeModel.result?[index].name ?? "",
          multilanguage: false,
          fontsizeNormal: 22, // [UI]
          fontsizeWeb: 26, // [UI]
          maxline: 3,
          overflow: TextOverflow.ellipsis,
          fontstyle: FontStyle.normal,
          fontweight: FontWeight.w700,
          textalign: TextAlign.start,
          isShadowText: true,
        ),
        const SizedBox(height: 16), // [UI]
        // Feature buttons row
        _buildFeatureBtns(index: index),
        const SizedBox(height: 20), // [UI]

        Utils.buildGradLine(),
        const SizedBox(height: 16), // [UI]
        // Description
        ExpandableText(
          clipsProvider.shortFilmEpisodeModel.result?[index].description ?? "",
          expandText: Locales.string(context, "more"),
          collapseText: Locales.string(context, "less"),
          expandOnTextTap: true,
          collapseOnTextTap: true,
          maxLines: kIsWeb ? 50 : 3,
          linkColor: colorPrimary,
          style: TextStyle(
            fontSize: kIsWeb ? 15 : 14,
            fontStyle: FontStyle.normal,
            color: descTextColor,
            fontWeight: FontWeight.w400,
            shadows: const [
              Shadow(
                color: black,
                offset: Offset(0.5, 0.5),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20), // [UI]

        Utils.buildGradLine(),
        const SizedBox(height: 20), // [UI]
        // Episodes section
        _buildEpisodeUI(index: index),
      ],
    );
  }

  Widget _buildEpisodeUI({required int index}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          child: MyText(
            color: titleTextColor,
            text: "episodes",
            multilanguage: true,
            textalign: TextAlign.start,
            fontsizeNormal: 18,
            fontweight: FontWeight.w600,
            fontsizeWeb: 20,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          child: _buildSeasonBtn(index: index),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          height: 0.5,
          decoration: Utils.setBackground(
            descTextColor.withValues(alpha: 0.6),
            0,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 15), // [FIX-5]
          child: ResponsiveGridList(
            minItemWidth: Dimens.widthEpiWeb,
            verticalGridSpacing: 8,
            horizontalGridSpacing: 8,
            minItemsPerRow: 1, // [FIX-5] let grid calculate naturally
            maxItemsPerRow: 6, // [FIX-5] cap to avoid overflow
            listViewBuilderOptions: ListViewBuilderOptions(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
            ),
            children: List.generate(
              (clipsProvider.shortFilmEpisodeModel.result?.length ?? 0),
              (position) {
                // [FIX-2] No Column+name below thumbnail — use Tooltip for name on hover
                return Material(
                  type: MaterialType.transparency,
                  child: Tooltip(
                    message:
                        clipsProvider
                            .shortFilmEpisodeModel
                            .result?[position]
                            .name ??
                        "", // [FIX-2]
                    preferBelow: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _pageController.jumpToPage(position),
                      child: AnimatedContainer(
                        // [FIX-2]
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (position == index)
                                ? colorPrimary
                                : transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            7,
                          ), // [FIX-2] 8-1 for border
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              MyNetworkImage(
                                imageUrl:
                                    clipsProvider
                                        .shortFilmEpisodeModel
                                        .result?[position]
                                        .thumbnail ??
                                    "",
                                width: Dimens.widthEpiWeb,
                                height: Dimens.heightEpiWeb,
                                fit: BoxFit.cover,
                              ),
                              if (position != 0)
                                Container(
                                  width: Dimens.widthEpiWeb,
                                  height: Dimens.heightEpiWeb,
                                  decoration: BoxDecoration(
                                    color: black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              // Number badge — top-right
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: const BoxDecoration(
                                    color: colorPrimary,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(7),
                                      bottomLeft: Radius.circular(7),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: MyText(
                                    color: black,
                                    text: "${position + 1}",
                                    multilanguage: false,
                                    textalign: TextAlign.center,
                                    fontsizeNormal: 12,
                                    fontweight: FontWeight.w600,
                                    fontsizeWeb: 14,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                              // Lock or wave icon — center
                              if (clipsProvider
                                          .shortFilmEpisodeModel
                                          .result?[position]
                                          .isPremium ==
                                      1 &&
                                  clipsProvider
                                          .shortFilmEpisodeModel
                                          .result?[position]
                                          .isBuy !=
                                      1)
                                SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: MyImage(
                                    imagePath: "ic_lock.png",
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else if (index == position)
                                SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: MyImage(
                                    imagePath: "ic_wave.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageChangeBtn({required int index}) {
    // [UI]
    final total =
        clipsProvider.shortFilmEpisodeModel.result?.length ?? 0; // [UI]
    final canGoUp = index > 0; // [UI]
    final canGoDown = index < total - 1; // [UI]

    return Column(
      mainAxisSize: MainAxisSize.min, // [UI]
      children: [
        _navArrowBtn(
          // [UI]
          icon: Icons.keyboard_arrow_up_rounded,
          enabled: canGoUp,
          tooltip: 'Previous clip',
          onTap: () {
            if (!canGoUp) return;
            _pageController.jumpToPage(
              ((_pageController.page ?? 0) - 1).toInt(),
            );
          },
        ),
        const SizedBox(height: 12), // [UI]
        // Current / Total indicator // [UI]
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ), // [UI]
          decoration: BoxDecoration(
            color: secondaryBgColor.withValues(alpha: 0.8), // [UI]
            borderRadius: BorderRadius.circular(12), // [UI]
          ),
          child: MyText(
            color: descTextColor,
            text: "${index + 1}/$total", // [UI]
            multilanguage: false,
            fontsizeNormal: 11, // [UI]
            fontsizeWeb: 12, // [UI]
            fontweight: FontWeight.w600,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
        ),
        const SizedBox(height: 12), // [UI]

        _navArrowBtn(
          // [UI]
          icon: Icons.keyboard_arrow_down_rounded,
          enabled: canGoDown,
          tooltip: 'Next clip',
          onTap: () {
            if (!canGoDown) return;
            _pageController.jumpToPage(
              ((_pageController.page ?? 0) + 1).toInt(),
            );
          },
        ),
      ],
    );
  }

  Widget _navArrowBtn({
    // [UI]
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          // [UI]
          duration: const Duration(milliseconds: 200),
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color:
                enabled // [UI]
                ? secondaryBgColor
                : secondaryBgColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  enabled // [UI]
                  ? colorPrimary.withValues(alpha: 0.4)
                  : transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? white : white.withValues(alpha: 0.3), // [UI]
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBtns({required int index}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: AlwaysScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /* Like */
          Consumer<ClipsProvider>(
            builder: (context, clipsProvider, child) {
              if ((clipsProvider.contentDetailModel.result?[0].isLike ?? 0) !=
                  1) {
                return SizedBox.shrink();
              }
              return _buildFeatureIcon(
                iconName:
                    ((clipsProvider.contentDetailModel.result?[0].isUserLike ??
                            0) ==
                        1)
                    ? 'ic_heartfill'
                    : 'ic_heart',
                index: index,
                isTitle: false,
                count: 0.toString(),
                onClick: () async {
                  printLog("Tapped on Heart! => $index");
                  if (!mounted) return;
                  if (Utils.checkLoginUser(context)) {
                    await clipsProvider.setLikeDislike(
                      context,
                      position: index,
                      videoId:
                          (clipsProvider.contentDetailModel.result?[0].id ?? 0),
                      videoType:
                          (clipsProvider
                              .contentDetailModel
                              .result?[0]
                              .videoType ??
                          0),
                      subVideoType: 0,
                    );
                  }
                },
              );
            },
          ),

          /* Comment */
          Consumer<ClipsProvider>(
            builder: (context, clipsProvider, child) {
              if ((clipsProvider.contentDetailModel.result?[0].isComment ??
                      0) !=
                  1) {
                return SizedBox.shrink();
              }
              return _buildFeatureIcon(
                iconName: 'ic_comment',
                index: index,
                isTitle: false,
                count:
                    (clipsProvider.contentDetailModel.result?[0].totalComment ??
                            0)
                        .toString(),
                onClick: () async {
                  printLog("Tapped on Comment! => $index");
                  if (!mounted) return;
                  if (Utils.checkLoginUser(context)) {
                    clipsProvider.setDialogState(true);
                    clipsProvider.resetCommentData();
                    clipsProvider.getComments(
                      (clipsProvider.contentDetailModel.result?[0].id ?? 0),
                      (clipsProvider.contentDetailModel.result?[0].videoType ??
                          0),
                      0,
                      1,
                    );
                    openCommentDialog(index);
                  }
                },
              );
            },
          ),

          /* Share */
          _buildFeatureIcon(
            iconName: 'ic_send',
            index: index,
            count: "share",
            isTitle: true,
            onClick: () async {
              printLog("Tapped on Share! => $index");
              ShareModel shareModel = ShareModel(
                newPage: RoutesConstant.clipsEpisodesPage,
                videoTitle:
                    clipsProvider.contentDetailModel.result?[0].name ?? "",
                videoId: clipsProvider.contentDetailModel.result?[0].id ?? 0,
                videoType:
                    clipsProvider.contentDetailModel.result?[0].videoType ?? 0,
                subVideoType:
                    clipsProvider.contentDetailModel.result?[0].subVideoType ??
                    0,
                typeId: clipsProvider.contentDetailModel.result?[0].typeId ?? 0,
              );
              Utils.openShareDialog(context: context, shareModel: shareModel);
            },
          ),

          /* BookMark */
          Consumer<ClipsProvider>(
            builder: (context, clipsProvider, child) {
              return _buildFeatureIcon(
                iconName:
                    ((clipsProvider.contentDetailModel.result?[0].isBookmark ??
                            0) ==
                        1)
                    ? 'ic_bookmarkfill'
                    : 'ic_bookmark',
                index: index,
                isTitle: false,
                count: "",
                onClick: () async {
                  printLog("Tapped on Bookmark! => $index");
                  if (!mounted) return;
                  if (Utils.checkLoginUser(context)) {
                    await clipsProvider.setBookmark(
                      context,
                      position: index,
                      videoId:
                          (clipsProvider.contentDetailModel.result?[0].id ?? 0),
                      videoType:
                          (clipsProvider
                              .contentDetailModel
                              .result?[0]
                              .videoType ??
                          0),
                      subVideoType: 0,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon({
    required String iconName,
    required int index,
    required String count,
    required bool isTitle,
    required Function() onClick,
  }) {
    final bool isLiked = iconName == "ic_heartfill"; // [UI]

    return Container(
      margin: const EdgeInsets.only(right: 10), // [UI]
      child: Tooltip(
        message: isTitle ? count : '', // [UI]
        child: InkWell(
          borderRadius: BorderRadius.circular(20), // [UI]
          onTap: onClick,
          child: AnimatedContainer(
            // [UI]
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ), // [UI]
            decoration: BoxDecoration(
              color:
                  isLiked // [UI]
                  ? colorPrimary.withValues(alpha: 0.15)
                  : secondaryBgColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20), // [UI]
              border: Border.all(
                color:
                    isLiked // [UI]
                    ? colorPrimary.withValues(alpha: 0.5)
                    : white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20, // [UI]
                  height: 20, // [UI]
                  child: MyImage(
                    imagePath: "$iconName.png",
                    fit: BoxFit.contain,
                    color: isLiked ? colorPrimary : titleTextColor, // [UI]
                  ),
                ),
                if (count.isNotEmpty) ...[
                  const SizedBox(width: 6), // [UI]
                  MyText(
                    color: isLiked ? colorPrimary : titleTextColor, // [UI]
                    text: isTitle
                        ? count
                        : Utils.withSuffix(int.tryParse(count) ?? 0),
                    multilanguage: isTitle,
                    fontsizeNormal: 12, // [UI]
                    fontsizeWeb: 13, // [UI]
                    fontweight: FontWeight.w600, // [UI]
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonBtn({required int index}) {
    final controller = _controllers[index];
    return Consumer<ClipsProvider>(
      builder: (context, clipsProvider, child) {
        if (clipsProvider.contentDetailModel.result?[0].season != null &&
            (clipsProvider.contentDetailModel.result?[0].season?.length ?? 0) >
                0) {
          return SizedBox(
            height: 50,
            // margin: EdgeInsets.fromLTRB(
            //   Dimens.isBigScreen(context) ? 35 : 12,
            //   Dimens.isBigScreen(context) ? 10 : 8,
            //   Dimens.isBigScreen(context) ? 35 : 12,
            //   0,
            // ),
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
                            onTap: () async {
                              _onSeasonChange(
                                index: index,
                                vController: controller,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                // [UI]
                                horizontal: 14,
                                vertical: 3,
                              ),
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
                      AnimatedContainer(
                        // [UI]
                        duration: const Duration(milliseconds: 200),
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

  Future<void> _onSeasonChange({
    required int index,
    required VideoPlayerController? vController,
  }) async {
    if (clipsProvider.seasonPos == index) return;
    LoadingOverlay().show(context);
    printLog(
      "SeasonID ====> ${(clipsProvider.contentDetailModel.result?[0].season?[index].id ?? 0)}",
    );
    printLog("index ====> $index");
    if (vController != null) {
      vController.pause();
    }
    clipsProvider.setEpiLoading(true);
    await clipsProvider.setSeason(index);
    printLog("seasonPos ====> ${clipsProvider.seasonPos}");
    await clipsProvider.getEpisodesBySeason(
      clipsProvider.contentDetailModel.result?[0].id ?? 0,
      clipsProvider.contentDetailModel.result?[0].season?[index].id ?? 0,
      1,
      forceRefresh: true,
    );
    _controllers.clear();
    _controllers = {};
    _current = ValueNotifier<int>(0);
    await _preLoadEpisodes();
    LoadingOverlay().hide();
    _pageController.jumpToPage(0);
    if (!mounted) return;
    setState(() {});
  }

  /* Comment Section START ********* */
  void openCommentDialog(int index) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: secondaryBgColor, // [UI]
          surfaceTintColor: transparent, // [UI]
          shape: RoundedRectangleBorder(
            // [UI]
            borderRadius: BorderRadius.circular(20), // [UI]
            side: BorderSide(
              // [UI]
              color: white.withValues(alpha: 0.08), // [UI]
              width: 1, // [UI]
            ), // [UI]
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 100,
            vertical: 50,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              maxHeight: 640,
            ), // [UI]
            child: _buildCommentDialog(index),
          ),
        );
      },
    ).whenComplete(() {
      clipsProvider.setDialogState(false);
      printLog(
        "openCommentSheet totalComment ====>>> ${(kIsWeb) ? (clipsProvider.contentDetailModel.result?[0].totalComment ?? 0) : (clipsProvider.contentDetailModel.result?[0].totalComment ?? 0)}",
      );
      clipsProvider.updateCommentCount(
        index,
        (clipsProvider.contentDetailModel.result?[0].totalComment ?? 0),
      );
      clipsProvider.setDialogType(
        position: 0,
        dialogType: CommentDialogEnum.comments,
      );
    });
  }

  Widget _buildCommentDialog(int videoPos) {
    return Consumer<ClipsProvider>(
      builder: (context, clipsProvider, child) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDialogHeader(),
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
                            CommentDialogEnum.comments)
                        ? _buildComments(videoPos: videoPos)
                        : _buildReplyComments(
                            videoPos: videoPos,
                            commentIndex:
                                clipsProvider.selectedCommentIndex ?? 0,
                          ),
                  ),
                ),
              ),
              /* Pagination loader */
              if (clipsProvider.loadCommentMore || clipsProvider.loadReplyMore)
                Container(
                  height: 40,
                  margin: EdgeInsets.only(top: 10, bottom: 10),
                  child: Utils.pageLoader(),
                )
              else
                const SizedBox.shrink(),
              Utils.buildGradLine(),
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
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: commentController,
                          maxLines: 1,
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
                        margin: EdgeInsets.only(right: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            printLog("Clicked on Send!");
                            if (!clipsProvider.sending) {
                              await clipsProvider.addComments(
                                commentController.text.toString(),
                                (clipsProvider.currentDialogPage ==
                                        CommentDialogEnum.comments)
                                    ? 0
                                    : (clipsProvider
                                              .commentList?[clipsProvider
                                                      .selectedCommentIndex ??
                                                  0]
                                              .id ??
                                          0),
                                (clipsProvider
                                        .contentDetailModel
                                        .result?[0]
                                        .id ??
                                    0),
                                (clipsProvider
                                        .contentDetailModel
                                        .result?[0]
                                        .videoType ??
                                    0),
                                0,
                              );
                              commentController.clear();
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            padding: const EdgeInsets.all(4),
                            child: Consumer<ClipsProvider>(
                              builder: (context, clipsProvider, child) {
                                if (!clipsProvider.sending) {
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader() {
    final isReplies =
        clipsProvider.currentDialogPage == CommentDialogEnum.replies;

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
                    dialogType: CommentDialogEnum.comments,
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

  Widget _buildComments({required int videoPos}) {
    if (clipsProvider.loadingComment && !clipsProvider.loadCommentMore) {
      return Center(child: Utils.pageLoader());
    } else {
      if (clipsProvider.commentList != null &&
          (clipsProvider.commentList?.length ?? 0) > 0) {
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
            itemBuilder: (BuildContext context, int position) {
              return _buildCommentItem(position: position, videoPos: videoPos);
            },
          ),
        );
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Widget _buildCommentItem({required int position, required int videoPos}) {
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
                  text: (clipsProvider.commentList?[position].userName ?? ""),
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
                    InkWell(
                      onTap: () async {
                        printLog("Clicked on position ==> $position");
                        printLog("Clicked on videoPos ==> $videoPos");
                        clipsProvider.getReplyComments(
                          clipsProvider.commentList?[position].id ?? 0,
                          1,
                        );
                        clipsProvider.setDialogType(
                          position: position,
                          dialogType: CommentDialogEnum.replies,
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
                    if (Constant.userID ==
                        (clipsProvider.commentList?[position].userId
                                .toString() ??
                            "0"))
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        child: InkWell(
                          onTap: () async {
                            printLog("Clicked on Edit! ==> $position");
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
                            padding: EdgeInsets.all(3),
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
                    if (Constant.userID ==
                        (clipsProvider.commentList?[position].userId
                                .toString() ??
                            ""))
                      Container(
                        margin: EdgeInsets.only(left: 12),
                        child: InkWell(
                          onTap: () async {
                            printLog("Clicked on remove!  ==>  $position");
                            if (!clipsProvider.loading) {
                              openConfirDialog(
                                position: position,
                                videoPos: videoPos,
                              );
                            }
                          },
                          child: Container(
                            height: 20,
                            width: 20,
                            padding: EdgeInsets.all(1),
                            child: MyImage(
                              imagePath: "ic_delete.png",
                              color: descTextColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (clipsProvider.wantToEdit &&
                    clipsProvider.commentPos == position)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 40,
                    constraints: BoxConstraints(
                      minHeight: 0,
                      maxHeight: MediaQuery.of(context).size.height,
                    ),
                    margin: const EdgeInsets.only(top: 0),
                    alignment: Alignment.center,
                    child: Center(
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
                                contentPadding: const EdgeInsets.only(
                                  left: 0,
                                  right: 10,
                                ),
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
                              printLog("Clicked on Send!");
                              if (!clipsProvider.sendingEdited) {
                                await clipsProvider.editComments(
                                  position,
                                  clipsProvider
                                          .contentDetailModel
                                          .result?[0]
                                          .id ??
                                      0,
                                  clipsProvider
                                          .contentDetailModel
                                          .result?[0]
                                          .videoType ??
                                      0,
                                  0,
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

  Widget _buildReplyComments({
    required int videoPos,
    required int commentIndex,
  }) {
    if (clipsProvider.loadingReply && !clipsProvider.loadReplyMore) {
      return Center(child: Utils.pageLoader());
    } else {
      if (clipsProvider.commentRepliesList != null &&
          (clipsProvider.commentRepliesList?.length ?? 0) > 0) {
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
            itemBuilder: (BuildContext context, int position) {
              return _buildReplyCommentItem(
                position: position,
                videoPos: videoPos,
                commentIndex: commentIndex,
              );
            },
          ),
        );
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Widget _buildReplyCommentItem({
    required int position,
    required int videoPos,
    required int commentIndex,
  }) {
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
                      (clipsProvider.commentRepliesList?[position].userName ??
                      ""),
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

  void openConfirDialog({required int position, required int videoPos}) {
    showDialog<dynamic>(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildDeleteDialog(position: position, videoPos: videoPos);
      },
    );
  }

  Widget _buildDeleteDialog({required int position, required int videoPos}) {
    return Dialog(
      alignment: Alignment.centerRight,
      backgroundColor: secondaryBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: EdgeInsets.fromLTRB(
        (MediaQuery.of(context).size.width > 900) ? 50 : 30,
        (MediaQuery.of(context).size.width > 900) ? 50 : 30,
        (MediaQuery.of(context).size.width > 900) ? 50 : 30,
        (MediaQuery.of(context).size.width > 900) ? 50 : 30,
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
                children: <Widget>[
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () {
                            Utils.exitPage(context);
                          },
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
                            printLog(
                              "comment count ====>>> ${clipsProvider.commentList?.length}",
                            );
                            Utils.exitPage(context);
                            await clipsProvider.deleteComments(
                              position,
                              clipsProvider.contentDetailModel.result?[0].id ??
                                  0,
                              clipsProvider
                                      .contentDetailModel
                                      .result?[0]
                                      .videoType ??
                                  0,
                              0,
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
                              textalign: TextAlign.center,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
                              multilanguage: true,
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

  /* ********* Comment Section END */
}

/// Single reel widget
class _EpisodePlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final PageController pageController;
  final bool isCurrent;
  final int vIndex;
  final List<details.Season> seasonList;
  final List<shortsepisode.Result> episodeList;
  final VoidCallback? onVideoEnd;
  const _EpisodePlayer({
    required this.controller,
    required this.pageController,
    required this.isCurrent,
    required this.vIndex,
    required this.seasonList,
    required this.episodeList,
    this.onVideoEnd,
  });

  @override
  State<_EpisodePlayer> createState() => _EpisodePlayerState();
}

class _EpisodePlayerState extends State<_EpisodePlayer>
    with TickerProviderStateMixin, RouteAware {
  late ClipsProvider clipsProvider;

  Timer? _hideTimer;
  bool _showPlayPause = true;
  bool _showControls = true;
  bool _isVideoStarted = false;

  bool _hasSignalledEnd = false;

  int _speedIndex = 1; // start at 1.0x (index 1)
  final List<double> _playbackSpeeds = [0.5, 1.0, 1.5, 2.0];

  // Track mute state per index
  final ValueNotifier<Map<int, bool?>> _muteStatesNotifier = ValueNotifier({});

  Future<void> toggleMute(int index) async {
    final currentStates = Map<int, bool>.from(_muteStatesNotifier.value);
    currentStates[index] = !(currentStates[index] ?? false); // default false
    _muteStatesNotifier.value = currentStates;
    final isMuted = currentStates[index] ?? false;
    widget.controller.setVolume(isMuted ? 0.0 : 1.0);
  }

  void _changeSpeed() {
    setState(() {
      // move to next index, loop back to 0
      _speedIndex = (_speedIndex + 1) % _playbackSpeeds.length;
    });

    final newSpeed = _playbackSpeeds[_speedIndex];
    widget.controller.setPlaybackSpeed(newSpeed);
  }

  Future<void> _togglePlayPause() async {
    printLog("_togglePlayPause _showPlayPause ====> $_showPlayPause");
    printLog("_togglePlayPause _isVideoStarted ===> $_isVideoStarted");
    _showPlayPause = !_showPlayPause;
    _isVideoStarted = (widget.controller.value.isPlaying);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleControls() async {
    printLog("_toggleControls _showControls =====> $_showControls");
    printLog("_toggleControls _isVideoStarted ===> $_isVideoStarted");
    _showControls = !_showControls;
    if (!mounted) return;
    setState(() {});
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    if (!mounted) return;
    _showPlayPause = true;
    _isVideoStarted = (widget.controller.value.isPlaying);

    if (!mounted) return;
    // _startHideTimer();
  }

  Future<void> _startHideTimer() async {
    printLog("_startHideTimer _showPlayPause =====> $_showPlayPause");
    printLog("_startHideTimer _isVideoStarted ===> $_isVideoStarted");
    if (_hideTimer != null) {
      _hideTimer?.cancel();
    }
    _hideTimer = Timer(const Duration(seconds: 5), () async {
      _showPlayPause = false;
      _isVideoStarted = (widget.controller.value.isPlaying);
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    clipsProvider = Provider.of<ClipsProvider>(context, listen: false);
    _speedIndex = 1;
    // Listen for video completion
    widget.controller.addListener(_videoListener);

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

  @override
  void didUpdateWidget(covariant _EpisodePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If controller instance changed, move listener
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_videoListener);
      widget.controller.addListener(_videoListener);

      // reset signalling state for new controller
      _hasSignalledEnd = false;
    }
  }

  void _videoListener() {
    final c = widget.controller;
    if (!c.value.isInitialized) return;

    final pos = c.value.position;
    final dur = c.value.duration;

    if (dur.inMilliseconds == 0) return;

    // tolerance to allow floating/time drift
    final tolerance = const Duration(milliseconds: 200);

    // If we are the current visible page, and position reaches (duration - tolerance),
    // and we haven't already signalled end, trigger onVideoEnd.
    if (widget.isCurrent && !_hasSignalledEnd && pos >= dur - tolerance) {
      _hasSignalledEnd = true;

      final total = clipsProvider.shortFilmEpisodeModel.result?.length ?? 0;
      final nextIndex = widget.vIndex + 1;
      printLog(
        "ShortsPlayer: end detected (pos=$pos dur=$dur) (totalEpi=$total) (nextIndex=$nextIndex) index=${widget.vIndex} DialogState=${clipsProvider.isDialogOpen}",
      );

      if (nextIndex < total) {
        if (!clipsProvider.isDialogOpen) {
          widget.onVideoEnd?.call();
        }
      } else {
        // Last video: stop
        c.pause();
        _showControls = true;
        _isVideoStarted = (widget.controller.value.isPlaying);
        if (!mounted) return;
        setState(() {});
        printLog("Reached last video, playback stopped.");
      }

      return;
    }

    // If position moves away from near-end (e.g. user rewound or restarted),
    // clear the flag so end can be signalled later again.
    if (pos < dur - tolerance && _hasSignalledEnd) {
      _hasSignalledEnd = false;
    }
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
  void didPush() {
    printLog("========= didPush =========");
    super.didPush();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    printLog("========= didPopNext =========");
    // returning back to this page
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
    super.didPushNext();
    printLog("========= didPushNext =========");
    // another page is pushed on top
    if (!clipsProvider.isDialogOpen) {
      widget.controller.pause();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _hideTimer?.cancel();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  bool _checkPremium() {
    return widget.episodeList[widget.vIndex].isPremium == 1 &&
        widget.episodeList[widget.vIndex].isBuy != 1;
  }

  bool _isFreeORBuy() {
    return widget.episodeList[widget.vIndex].isPremium == 0 ||
        widget.episodeList[widget.vIndex].isBuy == 1;
  }

  @override
  Widget build(BuildContext context) {
    final vCont = widget.controller;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_checkPremium())
          _buildSubscribeView(index: widget.vIndex)
        else
          VisibilityDetector(
            key: Key('episode_${widget.episodeList[widget.vIndex].id}'),
            onVisibilityChanged: (visibilityInfo) async {
              if (!mounted) return;
              var visiblePercentage = visibilityInfo.visibleFraction * 100;
              printLog(
                '=========== Widget ${visibilityInfo.key} is $visiblePercentage% visible===========',
              );
              if (visiblePercentage > 80) {
                printLog('=========== Widget PLAYED ===========');
                vCont.play();
              } else {
                printLog('=========== Widget PAUSED ===========');
                vCont.pause();
              }
            },
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

        Center(child: _buildHitArea()),

        // Mid-playback buffering spinner // [UI]
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: vCont,
          builder: (context, val, _) {
            if (!val.isBuffering || _checkPremium()) {
              return const SizedBox.shrink();
            }
            return const Center(
              child: SizedBox(
                width: 40, // [UI]
                height: 40, // [UI]
                child: CircularProgressIndicator(
                  color: white,
                  strokeWidth: 2.5, // [UI]
                ),
              ),
            );
          },
        ),

        // Overlays: progress + icons
        Column(
          children: [
            if (_isFreeORBuy()) _buildTopBar(index: widget.vIndex),
            SizedBox(height: 8),
            const Spacer(),
            SizedBox(height: 8),
            // Bottom gradient + controls wrapper // [UI]
            DecoratedBox(
              // [UI]
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80), // [UI]
                    transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Column(
                children: [
                  if (_showControls && _isFreeORBuy())
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
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
                                  enabledThumbRadius: 5, // [UI]
                                  pressedElevation: 0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10, // [UI]
                                ),
                                trackShape: const RoundedRectSliderTrackShape(),
                                minThumbSeparation: 0,
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                value: prog.clamp(0, 1),
                                onChanged: (v) =>
                                    vCont.seekTo(val.duration * v),
                                activeColor: colorPrimary,
                                inactiveColor: white.withValues(alpha: 0.30),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_isFreeORBuy()) _buildBottomBar(index: widget.vIndex),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                /* Lock */
                MyImage(
                  imagePath: 'ic_lock.png',
                  height: 48,
                  width: 48,
                ), // [UI]
                const SizedBox(height: 12), // [UI]
                /* "Subscribe to watch" label */
                MyText(
                  // [UI]
                  color: white,
                  text: "subscribe_to_watch",
                  multilanguage: true,
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w500,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
                /* Subscription Button */
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

  Widget _buildTopBar({required int index}) {
    final c = widget.controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 15, 15, 15), // [UI]
          child: Row(
            children: [
              // Episode title at top-left // [UI]
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8), // [FIX-3]
                  child: MyText(
                    color: white,
                    text: widget.episodeList.isNotEmpty
                        ? (widget.episodeList[widget.vIndex].name ?? "")
                        : "",
                    multilanguage: false,
                    textalign: TextAlign.start,
                    fontsizeNormal: 12, // [FIX-3]
                    fontsizeWeb: 13,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                    isShadowText: true,
                  ),
                ),
              ),
              /* Mute/Unmute */
              if (_showControls)
                MuteUnmuteButton(
                  index: widget.vIndex,
                  toggleMute: toggleMute,
                  muteStatesNotifier: _muteStatesNotifier,
                ),
              if (_showControls) SizedBox(width: 15),
              /* Fullscreen */
              Tooltip(
                message: 'Fullscreen/Halfscreen',
                child: InkWell(
                  onTap: () {
                    _toggleControls();
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    padding: EdgeInsets.all(3),
                    alignment: Alignment.center,
                    decoration: Utils.setBackground(
                      descTextColor.withValues(alpha: 0.75),
                      25,
                    ),
                    child: SimpleShadow(
                      color: black.withValues(alpha: 0.5),
                      sigma: 2,
                      child: MyImage(
                        height: _showControls ? 25 : 20,
                        width: _showControls ? 25 : 20,
                        imagePath: _showControls
                            ? "ic_screen_default.png"
                            : "ic_screen_full.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({required int index}) {
    final c = widget.controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_showControls) _buildPlayPause(),
              if (_showControls)
                MyText(
                  color: white,
                  text: duration2String(value.position),
                  multilanguage: false,
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontsizeWeb: 16,
                  fontweight: FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
              if (_showControls)
                MyText(
                  color: white,
                  text: " / ",
                  multilanguage: false,
                  textalign: TextAlign.center,
                  fontsizeNormal: 15,
                  fontsizeWeb: 17,
                  fontweight: FontWeight.w600,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
              if (_showControls)
                MyText(
                  color: white,
                  text: duration2String(value.duration),
                  multilanguage: false,
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontsizeWeb: 16,
                  fontweight: FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
              Spacer(),
              SizedBox(width: 15),
              if (_showControls)
                Tooltip(message: 'Playback Speed', child: _buildSpeedButton()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHitArea() {
    final c = widget.controller;
    final bool isFinished =
        (c.value.position >= c.value.duration) &&
        c.value.duration.inSeconds > 0;
    _isVideoStarted = (c.value.isPlaying);
    return GestureDetector(
      onTap: () {
        if (_checkPremium()) return;
        _isVideoStarted ? c.pause() : c.play();
        if (!mounted) return;
        _togglePlayPause();
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Container(
          height: 70,
          width: 70,
          color: transparent,
          child: CenterPlayButton(
            backgroundColor: black.withValues(alpha: 0.15),
            iconColor: white,
            isFinished: isFinished,
            isPlaying: _isVideoStarted,
            show: _showPlayPause,
            onPressed: () async {
              if (_checkPremium()) return;
              _isVideoStarted ? c.pause() : c.play();
              if (!mounted) return;
              setState(() {});
              printLog("Play/Pause _isVideoStarted ==> $_isVideoStarted");
              printLog("Play/Pause isPlaying ========> ${c.value.isPlaying}");
              if (c.value.isPlaying == false) {
                _cancelAndRestartTimer();
              } else {
                _startHideTimer();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause() {
    final c = widget.controller;
    _isVideoStarted = (c.value.isPlaying);
    return GestureDetector(
      onTap: () {
        if (_checkPremium()) return;
        _isVideoStarted ? c.pause() : c.play();
        if (!mounted) return;
        setState(() {});
        printLog("Play/Pause _isVideoStarted ==> $_isVideoStarted");
        printLog("Play/Pause isPlaying ========> ${c.value.isPlaying}");
      },
      child: Container(
        height: 40,
        width: 40,
        color: transparent,
        child: Tooltip(
          message: 'Play/Pause',
          child: AnimatedPlayPause(
            playing: _isVideoStarted,
            color: white,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSpeedButton() {
    return GestureDetector(
      onTap: _changeSpeed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MyText(
            color: white,
            text: "${_playbackSpeeds[_speedIndex]}x",
            multilanguage: false,
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
            child: Icon(Icons.speed, color: white, size: 25),
          ),
        ],
      ),
    );
  }
}
