import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../main.dart';
import '../model/playermodel.dart';
import '../model/sharemodel.dart';
import '../players/model/vdociphermodel.dart' hide Result;
import '../provider/videobyidprovider.dart';
import '../routes/routes_constant.dart';
import '../webwidget/interactive_icon.dart';
import '../model/contentdetailmodel.dart';
import '../shimmer/shimmerutils.dart';
import '../webpages/webcomman.dart';
import '../utils/dimens.dart';
import '../widget/castcrew.dart';
import '../widget/myusernetworkimg.dart';
import '../widget/nodata.dart';
import '../provider/episodeprovider.dart';
import '../provider/showdetailsprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../widget/episodebyseason.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';
import '../widget/mynetworkimg.dart';
import '../widget/ratingreview.dart';
import '../widget/relatedvideoshow.dart';

class WebContentShowDetails extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  final int videoId, subVideoType, videoType, typeId;
  const WebContentShowDetails(
    this.videoId,
    this.subVideoType,
    this.videoType,
    this.typeId, {
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebContentShowDetails> createState() => WebContentShowDetailsState();
}

class WebContentShowDetailsState extends State<WebContentShowDetails>
    with RouteAware {
  /* Trailer init */
  VideoPlayerController? _trailerNormalController;
  YoutubePlayerController? _trailerYoutubeController;

  late ShowDetailsProvider showDetailsProvider;
  late EpisodeProvider episodeProvider;

  List<Cast>? directorList;
  String? rentStatus;

  @override
  void initState() {
    super.initState();
    showDetailsProvider = Provider.of<ShowDetailsProvider>(
      context,
      listen: false,
    );
    episodeProvider = Provider.of<EpisodeProvider>(context, listen: false);
    printLog("initState videoId ==> ${widget.videoId}");
    printLog("initState videoType ==> ${widget.videoType}");
    printLog("initState typeId ==> ${widget.typeId}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData(forceRefresh: false);
    });
  }

  Future<void> _getData({bool forceRefresh = false}) async {
    Utils.getCurrencySymbol();
    rentStatus = await Utils.configByStatus(status: Constant.rentStatus);
    printLog('_getData rentStatus =====> $rentStatus');

    await Future.wait([
      showDetailsProvider.getContentDetails(
        widget.typeId,
        widget.videoType,
        widget.videoId,
        widget.subVideoType,
        forceRefresh: forceRefresh,
      ),
      showDetailsProvider.getRelatedContent(
        widget.typeId,
        widget.videoType,
        widget.videoId,
        widget.subVideoType,
        1,
      ),
    ]);

    if (showDetailsProvider.contentDetailModel.status == 200) {
      if (showDetailsProvider.contentDetailModel.result != null &&
          (showDetailsProvider.contentDetailModel.result?.length ?? 0) > 0) {
        /* Trailer set-up */
        _setUpTrailer();

        /* Cast */
        if (showDetailsProvider.contentDetailModel.result?[0].cast != null &&
            (showDetailsProvider.contentDetailModel.result?[0].cast?.length ??
                    0) >
                0) {
          directorList = <Cast>[];
          for (
            int i = 0;
            i <
                (showDetailsProvider
                        .contentDetailModel
                        .result?[0]
                        .cast
                        ?.length ??
                    0);
            i++
          ) {
            if (showDetailsProvider
                    .contentDetailModel
                    .result?[0]
                    .cast?[i]
                    .type ==
                "Director") {
              Cast cast =
                  showDetailsProvider.contentDetailModel.result?[0].cast?[i] ??
                  Cast();
              directorList?.add(cast);
            }
          }
        }
      }
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {
        printLog("setState videoId ======================> ${widget.videoId}");
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    if (_trailerYoutubeController != null) {
      _trailerYoutubeController?.dispose();
      _trailerYoutubeController = null;
    }
    if (_trailerNormalController != null) {
      _trailerNormalController?.dispose();
      _trailerNormalController = null;
    }
    showDetailsProvider.clearProvider();
    episodeProvider.clearProvider();
  }

  Future<void> getAllEpisode(int position, List<Season>? seasonList) async {
    printLog("position ====> $position");
    printLog("seasonList seasonID ====> ${seasonList?[position].id}");
    episodeProvider.clearOldData();
    await episodeProvider.getEpisodeBySeason(
      seasonList?[position].id ?? 0,
      widget.videoId,
      1,
    );
    if (episodeProvider.episodeBySeasonModel.status == 200) {
      if (episodeProvider.episodeList != null &&
          (episodeProvider.episodeList?.length ?? 0) > 0) {
        if (showDetailsProvider.mCurrentEpiPos == -1) return;
        /* Set-up Subtitle URLs */
        Utils.setSubtitleURLs(
          subtitleUrl1:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitle1 ??
              ""),
          subtitleUrl2:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitle2 ??
              ""),
          subtitleUrl3:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitle3 ??
              ""),
          subtitleLang1:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitleLang1 ??
              ""),
          subtitleLang2:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitleLang2 ??
              ""),
          subtitleLang3:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .subtitleLang3 ??
              ""),
        );
      }
    }
  }

  /* ********* Widget LIFE CYCLES ********* */
  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPop() {
    printLog("didPop");
    super.didPop();
  }

  @override
  void didPopNext() {
    printLog("didPopNext");
    if (showDetailsProvider.contentDetailModel.result?[0].trailerType ==
        "youtube") {
      if (_trailerYoutubeController == null) {
        loadTrailer(
          showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
          showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
        );
      } else {
        if (_trailerYoutubeController != null) {
          _trailerYoutubeController?.seekTo(Duration.zero);
          _trailerYoutubeController?.play();
        }
      }
    } else {
      if (_trailerNormalController == null) {
        loadTrailer(
          showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
          showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
        );
      }
    }
    super.didPopNext();
  }

  @override
  void didPush() {
    printLog("didPush");
    super.didPush();
  }

  @override
  void didPushNext() {
    printLog("didPushNext");
    if (_trailerYoutubeController != null) {
      _trailerYoutubeController?.dispose();
      _trailerYoutubeController = null;
    }
    if (_trailerNormalController != null) {
      _trailerNormalController?.dispose();
      _trailerNormalController = null;
    }
    super.didPushNext();
  }
  /* ********* Widget LIFE CYCLES ********* */

  /* ********* Trailer Set-Up & Loading START ********* */
  void _setUpTrailer() {
    printLog(
      "trailerUrl ===========> ${showDetailsProvider.contentDetailModel.result?[0].trailerUrl}",
    );
    printLog(
      "trailerType ==========> ${showDetailsProvider.contentDetailModel.result?[0].trailerType}",
    );
    if (showDetailsProvider.contentDetailModel.result?[0].trailerUrl != null ||
        showDetailsProvider.contentDetailModel.result?[0].trailerUrl != "") {
      if (showDetailsProvider.contentDetailModel.result?[0].trailerType ==
          "youtube") {
        if (_trailerYoutubeController == null) {
          loadTrailer(
            showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
            showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
          );
        } else {
          _trailerYoutubeController?.seekTo(Duration.zero);
        }
      } else {
        if (_trailerNormalController == null) {
          loadTrailer(
            showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
            showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
          );
        } else {
          _trailerNormalController?.seekTo(Duration.zero);
        }
      }
    }
  }

  Future<void> loadTrailer(dynamic trailerUrl, trailerType) async {
    printLog("loadTrailer URL ==========> $trailerUrl");
    printLog("loadTrailer Type =========> $trailerType");
    bool? isAutoPlay = await Utils.getTrailerAutoPlay();
    printLog("loadTrailer isAutoPlay ===> $isAutoPlay");
    if (isAutoPlay && trailerUrl != null && trailerUrl.toString().isNotEmpty) {
      if (trailerType == "youtube") {
        var videoId = YoutubePlayer.convertUrlToId(trailerUrl ?? "");
        printLog("Youtube Trailer videoId :====> $videoId");
        _trailerYoutubeController = YoutubePlayerController(
          initialVideoId: videoId ?? '',
          flags: const YoutubePlayerFlags(
            mute: false,
            autoPlay: true,
            disableDragSeek: false,
            loop: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
          ),
        );
        _trailerYoutubeController?.play();
        _trailerYoutubeController?.addListener(listener);
        Future.delayed(Duration.zero).then((value) {
          if (!mounted) return;
          setState(() {});
        });
      } else {
        _trailerNormalController =
            VideoPlayerController.networkUrl(
                Uri.parse(trailerUrl ?? ""),
                videoPlayerOptions: VideoPlayerOptions(
                  mixWithOthers: false,
                  allowBackgroundPlayback: false,
                ),
              )
              ..initialize().then((value) {
                if (!context.mounted) return;
                setState(() {
                  printLog(
                    "isPlaying =========> ${_trailerNormalController?.value.isPlaying}",
                  );
                  _trailerNormalController?.play();
                });
              });
        _trailerNormalController?.setLooping(false);
        _trailerNormalController?.addListener(() async {
          if (_trailerNormalController?.value.hasError ?? false) {
            printLog(
              "VideoScreen errorDescription ====> ${_trailerNormalController?.value.errorDescription}",
            );
          }
          if (_trailerNormalController?.value.isCompleted ?? false) {
            setState(() {});
          }
        });
      }
    }
  }

  void listener() {
    if (mounted &&
        _trailerYoutubeController != null &&
        _trailerYoutubeController?.value.playerState == PlayerState.ended) {
      setState(() {});
    }
  }
  /* ********* Trailer Set-Up & Loading END *********** */

  /* ========= Open Player ========= */
  Future<void> openPlayer(String playType) async {
    printLog("mCurrentEpiPos ========> ${showDetailsProvider.mCurrentEpiPos}");
    if ((episodeProvider.episodeList?.length ?? 0) > 0) {
      if (showDetailsProvider.mCurrentEpiPos == -1) return;
      /* CHECK SUBSCRIPTION */
      if (playType != "Trailer") {
        bool? isPrimiumUser = await Utils.checkSubsRentLogin(
          context: context,
          isPremium:
              episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .isPremium ??
              0,
          isBuy:
              episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .isBuy ??
              0,
          isRent: showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0,
          rentBuy:
              showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0,
          producerId:
              (showDetailsProvider.contentDetailModel.result?[0].producerId ??
                      0)
                  .toString(),
          videoId: (showDetailsProvider.contentDetailModel.result?[0].id ?? 0)
              .toString(),
          rentPrice:
              (showDetailsProvider.contentDetailModel.result?[0].price ?? 0)
                  .toString(),
          vTitle: (showDetailsProvider.contentDetailModel.result?[0].name ?? 0)
              .toString(),
          typeId:
              (showDetailsProvider.contentDetailModel.result?[0].typeId ?? 0)
                  .toString(),
          vType:
              (showDetailsProvider.contentDetailModel.result?[0].videoType ?? 0)
                  .toString(),
          subVideoType:
              (showDetailsProvider.contentDetailModel.result?[0].subVideoType ??
                      0)
                  .toString(),
          rentProductId: (kIsWeb)
              ? (showDetailsProvider.contentDetailModel.result?[0].webPriceId
                        .toString() ??
                    '')
              : (Platform.isIOS
                    ? (showDetailsProvider
                              .contentDetailModel
                              .result?[0]
                              .iosProductPackage
                              .toString() ??
                          '')
                    : (showDetailsProvider
                              .contentDetailModel
                              .result?[0]
                              .androidProductPackage
                              .toString() ??
                          '')),
          newPage: widget.newPage ?? "",
          oldPage: widget.oldPage ?? "",
          reqText: widget.reqText ?? "",
        );
        printLog("isPrimiumUser =============> $isPrimiumUser");
        if (!isPrimiumUser) return;
      }
      /* CHECK SUBSCRIPTION */

      int? epiID =
          (episodeProvider
              .episodeList?[showDetailsProvider.mCurrentEpiPos]
              .id ??
          0);
      int? showID =
          (episodeProvider
              .episodeList?[showDetailsProvider.mCurrentEpiPos]
              .showId ??
          0);
      int? vType = widget.videoType;
      int? vSubType = widget.subVideoType;
      int? vTypeID = widget.typeId;
      int? stopTime;
      if (playType == "startOver" || playType == "Trailer") {
        stopTime = 0;
      } else {
        stopTime =
            (episodeProvider
                .episodeList?[showDetailsProvider.mCurrentEpiPos]
                .stopTime ??
            0);
      }
      String? videoThumb =
          (episodeProvider
              .episodeList?[showDetailsProvider.mCurrentEpiPos]
              .landscape ??
          "");
      printLog("epiID ========> $epiID");
      printLog("showID =======> $showID");
      printLog("vType ========> $vType");
      printLog("vSubType =====> $vSubType");
      printLog("vTypeID ======> $vTypeID");
      printLog("stopTime =====> $stopTime");
      printLog("videoThumb ===> $videoThumb");

      String? vUrl, vUploadType;
      if (playType == "Trailer") {
        Utils.clearQualitySubtitle();
        vUploadType =
            (showDetailsProvider.contentDetailModel.result?[0].trailerType ??
            "");
        vUrl =
            (showDetailsProvider.contentDetailModel.result?[0].trailerUrl ??
            "");
      } else {
        /* Set-up Quality URLs */
        Utils.setQualityURLs(
          video320:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .video320 ??
              ""),
          video480:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .video480 ??
              ""),
          video720:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .video720 ??
              ""),
          video1080:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .video1080 ??
              ""),
        );

        vUrl =
            (episodeProvider
                .episodeList?[showDetailsProvider.mCurrentEpiPos]
                .video320 ??
            "");
        vUploadType =
            (episodeProvider
                .episodeList?[showDetailsProvider.mCurrentEpiPos]
                .videoUploadType ??
            "");
      }

      printLog("openPlayer vUploadType ===> $vUploadType");
      printLog("openPlayer stopTime ======> $stopTime");

      if (!mounted) return;
      if (vUrl.isEmpty || vUrl == "") {
        if (playType == "Trailer") {
          Utils.showSnackbar(context, "info", "trailer_not_found", true);
        } else {
          Utils.showSnackbar(context, "info", "episode_not_found", true);
        }
        return;
      }

      /* VdoCipher OTP */
      VdoCipherModel? vdocipherDetails;
      if (vUploadType == Constant.vdocipherPlayType && playType != "Trailer") {
        if (!mounted) return;
        vdocipherDetails = await Utils.getVdoCipherOTP(
          context: context,
          videoId:
              (episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .video320 ??
              ""),
        );
        printLog(
          "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
        );
      }
      /* VdoCipher OTP */

      PlayerModel playerModel = PlayerModel(
        playType: playType == "Trailer" ? "Trailer" : "Show",
        isLive: false,
        videoId: showID,
        videoTitle:
            showDetailsProvider.contentDetailModel.result?[0].name ?? "",
        videoType: vType,
        subVideoType: vSubType,
        typeId: vTypeID,
        episodeId: epiID,
        videoUrl: vUrl,
        trailerUrl:
            showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
        uploadType: vUploadType,
        videoThumb: videoThumb,
        stopTime: stopTime,
        isPremium:
            episodeProvider
                .episodeList?[showDetailsProvider.mCurrentEpiPos]
                .isPremium ??
            0,
        isBuy:
            episodeProvider
                .episodeList?[showDetailsProvider.mCurrentEpiPos]
                .isBuy ??
            0,
        isRent: showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0,
        rentBuy: showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0,
        securityKey: "",
        securityIVKey: null,
        cipherMediaDetails:
            (vdocipherDetails != null && vdocipherDetails.result != null)
            ? (vdocipherDetails.result)
            : null,
        currentEpiPos: showDetailsProvider.mCurrentEpiPos,
        episodeList: episodeProvider.episodeBySeasonModel.result,
      );

      if (!mounted) return;
      dynamic isContinue = await Utils.openPlayer(
        context: context,
        playerModel: playerModel,
      );

      printLog("isContinue ===> $isContinue");
      if (isContinue != null && isContinue == true) {
        await _getData(forceRefresh: true);
        await getAllEpisode(
          showDetailsProvider.seasonPos,
          showDetailsProvider.contentDetailModel.result?[0].season,
        );
      }
    } else {
      String? vUrl, vUploadType;
      if (playType == "Trailer") {
        int? stopTime = 0;
        String? videoThumb =
            (showDetailsProvider.contentDetailModel.result?[0].landscape ?? "");
        printLog("stopTime =====> $stopTime");
        printLog("videoThumb ===> $videoThumb");
        Utils.clearQualitySubtitle();
        vUploadType =
            (showDetailsProvider.contentDetailModel.result?[0].trailerType ??
            "");
        vUrl =
            (showDetailsProvider.contentDetailModel.result?[0].trailerUrl ??
            "");

        printLog("vUploadType ===> $vUploadType");
        printLog("stopTime ===> $stopTime");

        if (!mounted) return;
        if (vUrl.isEmpty || vUrl == "") {
          Utils.showSnackbar(context, "info", "trailer_not_found", true);
          return;
        }

        /* VdoCipher OTP */
        VdoCipherModel? vdocipherDetails;
        if (vUploadType == Constant.vdocipherPlayType &&
            playType != "Trailer") {
          if (!mounted) return;
          vdocipherDetails = await Utils.getVdoCipherOTP(
            context: context,
            videoId:
                (episodeProvider
                    .episodeList?[showDetailsProvider.mCurrentEpiPos]
                    .video320 ??
                ""),
          );
          printLog(
            "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
          );
        }
        /* VdoCipher OTP */

        PlayerModel playerModel = PlayerModel(
          playType: "Trailer",
          isLive: false,
          videoId: showDetailsProvider.contentDetailModel.result?[0].id ?? 0,
          videoTitle:
              showDetailsProvider.contentDetailModel.result?[0].name ?? "",
          videoType:
              showDetailsProvider.contentDetailModel.result?[0].videoType ?? 0,
          subVideoType:
              showDetailsProvider.contentDetailModel.result?[0].subVideoType ??
              0,
          typeId: showDetailsProvider.contentDetailModel.result?[0].typeId ?? 0,
          episodeId: 0,
          videoUrl: vUrl,
          cipherMediaDetails:
              (vdocipherDetails != null && vdocipherDetails.result != null)
              ? (vdocipherDetails.result)
              : null,
          trailerUrl:
              showDetailsProvider.contentDetailModel.result?[0].trailerUrl ??
              "",
          uploadType: vUploadType,
          videoThumb: videoThumb,
          stopTime: stopTime,
          isPremium:
              episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .isPremium ??
              0,
          isBuy:
              episodeProvider
                  .episodeList?[showDetailsProvider.mCurrentEpiPos]
                  .isBuy ??
              0,
          isRent: showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0,
          rentBuy:
              showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0,
          securityKey: "",
          securityIVKey: null,
          currentEpiPos: showDetailsProvider.mCurrentEpiPos,
          episodeList: episodeProvider.episodeBySeasonModel.result,
        );
        if (!mounted) return;
        await Utils.openPlayer(context: context, playerModel: playerModel);
      } else {
        if (!mounted) return;
        Utils.showSnackbar(context, "info", "episode_not_found", true);
      }
    }
  }
  /* ========= Open Player ========= */

  bool _checkExpiry() {
    printLog(
      "rentExpiryDate =======> ${showDetailsProvider.contentDetailModel.result?[0].rentExpiryDate}",
    );
    if ((showDetailsProvider.contentDetailModel.result?[0].rentExpiryDate ??
            "") !=
        "") {
      return DateTime.now().isBefore(
        DateTime.parse(
          showDetailsProvider.contentDetailModel.result?[0].rentExpiryDate ??
              "",
        ),
      );
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: widget.reqText,
    );
  }

  Widget _buildPageUI() {
    if (showDetailsProvider.loading) {
      return SingleChildScrollView(
        child: Dimens.isBigScreen(context)
            ? ShimmerUtils.buildDetailWebShimmer(context, "show")
            : ShimmerUtils.buildDetailMobileShimmer(context, "show"),
      );
    } else {
      if (showDetailsProvider.contentDetailModel.status == 200 &&
          showDetailsProvider.contentDetailModel.result != null) {
        return _buildTVWebData();
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Widget _buildTVWebData() {
    final item = showDetailsProvider.contentDetailModel.result?[0];
    if (item == null) return const NoData(title: '', subTitle: '');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHero(item), _buildBody(item)],
      ),
    );
  }

  /* ─────────────────────────────────────────────
     HERO — full-bleed cinematic layout
  ───────────────────────────────────────────── */
  Widget _buildHero(Result item) {
    final screenW = MediaQuery.of(context).size.width;
    final bool isBig = Dimens.isBigScreen(context);

    if (!isBig) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ((item.trailerUrl ?? "").isNotEmpty)
                  ? setUpTrailerView()
                  : _buildMobilePoster(),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: Dimens.homeTabHeight + 16,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [appBgColor, transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBadgeRow(item),
                const SizedBox(height: 10),
                MyText(
                  color: white,
                  text: item.name ?? "",
                  textalign: TextAlign.start,
                  fontsizeNormal: 24,
                  fontsizeWeb: 24,
                  fontweight: FontWeight.w800,
                  maxline: 2,
                  multilanguage: false,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 8),
                _buildHeroMeta(item),
                const SizedBox(height: 8),
                _buildGenrePills(item),
                const SizedBox(height: 10),
                _buildHeroDescription(item),
                const SizedBox(height: 16),
                _buildHeroActions(item),
              ],
            ),
          ),
        ],
      );
    }

    final heroH = (screenW * 0.44).clamp(460.0, 640.0);
    final contentW = (screenW * 0.42).clamp(0.0, 580.0);

    return SizedBox(
      width: screenW,
      height: heroH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ((item.trailerUrl ?? "").isNotEmpty)
                ? setUpTrailerView()
                : MyNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: (item.landscape ?? "").isNotEmpty
                        ? (item.landscape ?? "")
                        : (item.thumbnail ?? ""),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    appBgColor,
                    appBgColor.withValues(alpha: 0.95),
                    appBgColor.withValues(alpha: 0.80),
                    appBgColor.withValues(alpha: 0.55),
                    appBgColor.withValues(alpha: 0.28),
                    appBgColor.withValues(alpha: 0.08),
                    transparent,
                  ],
                  stops: const [0.0, 0.12, 0.26, 0.44, 0.64, 0.82, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroH * 0.30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    appBgColor,
                    appBgColor.withValues(alpha: 0.75),
                    appBgColor.withValues(alpha: 0.30),
                    transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: heroH * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    appBgColor,
                    appBgColor.withValues(alpha: 0.95),
                    appBgColor.withValues(alpha: 0.70),
                    appBgColor.withValues(alpha: 0.30),
                    appBgColor.withValues(alpha: 0.08),
                    transparent,
                  ],
                  stops: const [0.0, 0.10, 0.28, 0.55, 0.78, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 35,
            bottom: 40,
            top: Dimens.homeTabHeight + 16,
            width: contentW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeroBadgeRow(item),
                const SizedBox(height: 14),
                MyText(
                  color: white,
                  text: item.name ?? "",
                  textalign: TextAlign.start,
                  fontsizeNormal: 32,
                  fontsizeWeb: screenW < 1100 ? 38 : 50,
                  fontweight: FontWeight.w800,
                  maxline: 2,
                  multilanguage: false,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 10),
                _buildHeroMeta(item),
                const SizedBox(height: 10),
                _buildGenrePills(item),
                const SizedBox(height: 14),
                _buildHeroDescription(item),
                const SizedBox(height: 20),
                _buildHeroActions(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadgeRow(Result item) {
    final int seasonCount = item.season?.length ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _heroBadge("TV Show", descTextColor, white.withValues(alpha: 0.08)),
        if ((item.isPremium ?? 0) == 1)
          _heroBadge(
            "✦ Prime",
            colorPrimary,
            colorPrimary.withValues(alpha: 0.18),
          ),
        if (widget.videoType == Constant.upcomingContentType)
          _heroBadge(
            "Upcoming",
            colorAccent,
            colorAccent.withValues(alpha: 0.18),
          )
        else if ((item.releaseDate ?? "").isNotEmpty)
          _heroBadge(
            "New Release",
            colorAccent,
            colorAccent.withValues(alpha: 0.18),
          ),
        if (seasonCount > 0)
          _heroBadge(
            "$seasonCount Season${seasonCount == 1 ? '' : 's'}",
            descTextColor,
            white.withValues(alpha: 0.08),
          ),
        _heroBadge("HD", descTextColor, white.withValues(alpha: 0.08)),
      ],
    );
  }

  Widget _heroBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: textColor.withValues(alpha: 0.40), width: 1),
      ),
      child: MyText(
        color: textColor,
        text: text,
        multilanguage: false,
        fontsizeNormal: 10,
        fontsizeWeb: 11,
        fontweight: FontWeight.w700,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  Widget _buildHeroMeta(Result item) {
    final year =
        (item.releaseDate != null && (item.releaseDate ?? "").isNotEmpty)
        ? DateFormat(
            "yyyy",
          ).format(DateTime.tryParse(item.releaseDate ?? "") ?? DateTime.now())
        : "";
    final int seasonCount = item.season?.length ?? 0;
    final seasonText = seasonCount > 0
        ? "$seasonCount Season${seasonCount == 1 ? '' : 's'}"
        : "";
    final ratingNum = (item.avgRating as num?)?.toDouble();
    final rating = (ratingNum != null && ratingNum > 0)
        ? (ratingNum == ratingNum.floorToDouble()
              ? ratingNum.toInt().toString()
              : ratingNum.toStringAsFixed(1))
        : "";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (year.isNotEmpty) _metaChip(year),
          if (year.isNotEmpty && seasonText.isNotEmpty) _metaDot(),
          if (seasonText.isNotEmpty) _metaChip(seasonText),
          if (rating.isNotEmpty) ...[
            _metaDot(),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: colorPrimary, size: 15),
                const SizedBox(width: 4),
                MyText(
                  color: colorPrimary,
                  text: rating,
                  multilanguage: false,
                  fontsizeNormal: 13,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(String text) {
    return MyText(
      color: descTextColor,
      text: text,
      multilanguage: false,
      fontsizeNormal: 12,
      fontsizeWeb: 13,
      fontweight: FontWeight.w500,
      maxline: 1,
      overflow: TextOverflow.ellipsis,
      textalign: TextAlign.start,
      fontstyle: FontStyle.normal,
    );
  }

  Widget _metaDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 3,
      height: 3,
      decoration: const BoxDecoration(color: grayDark, shape: BoxShape.circle),
    );
  }

  Widget _buildGenrePills(Result item) {
    final raw = item.categoryName ?? "";
    if (raw.isEmpty) return const SizedBox.shrink();
    final genres = raw
        .split(",")
        .map<String>((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (genres.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: genres.take(5).map((g) {
        return InteractiveIcon(
          builder: (isHovered) => GestureDetector(
            onTap: () {},
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isHovered
                      ? colorPrimary.withValues(alpha: 0.14)
                      : white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHovered
                        ? colorPrimary.withValues(alpha: 0.60)
                        : white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHovered ? colorPrimary : descTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeroDescription(Result item) {
    final desc = item.description ?? "";
    if (desc.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: ExpandableText(
        desc,
        expandText: "",
        collapseText: "",
        maxLines: 3,
        linkColor: descTextColor,
        expandOnTextTap: true,
        collapseOnTextTap: true,
        style: kIsWeb
            ? TextStyle(
                fontSize: Dimens.isBigScreen(context) ? 14 : 13,
                fontStyle: FontStyle.normal,
                color: descTextColor,
                fontWeight: FontWeight.normal,
                height: 1.65,
              )
            : GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: Dimens.isBigScreen(context) ? 14 : 13,
                  fontStyle: FontStyle.normal,
                  color: descTextColor,
                  fontWeight: FontWeight.normal,
                  height: 1.65,
                ),
              ),
      ),
    );
  }

  Widget _buildHeroActions(Result item) {
    if (!Dimens.isBigScreen(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.videoType != Constant.upcomingContentType
              ? _buildWatchNowNew()
              : _buildWatchTrailerNew(),
          const SizedBox(height: 10),
          Row(
            children: [
              if (widget.videoType != Constant.upcomingContentType)
                _buildSecondaryBtn(
                  icon: Icons.play_circle_outline_rounded,
                  label: "Trailer",
                  onTap: () => openPlayer("Trailer"),
                ),
              _buildRentBtnNew(),
              const SizedBox(width: 8),
              _buildIconActions(),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 260.0,
            child: widget.videoType != Constant.upcomingContentType
                ? _buildWatchNowNew()
                : _buildWatchTrailerNew(),
          ),
          const SizedBox(width: 10),
          if (widget.videoType != Constant.upcomingContentType)
            _buildSecondaryBtn(
              icon: Icons.play_circle_outline_rounded,
              label: "Trailer",
              onTap: () => openPlayer("Trailer"),
            ),
          _buildRentBtnNew(),
          const SizedBox(width: 14),
          _buildIconActions(),
        ],
      ),
    );
  }

  Widget _buildWatchNowNew() {
    return Consumer<EpisodeProvider>(
      builder: (context, ep, child) {
        final int pos = showDetailsProvider.mCurrentEpiPos;
        final bool hasList =
            ep.episodeList != null && (ep.episodeList?.length ?? 0) > 0;
        final bool hasProg =
            pos != -1 &&
            hasList &&
            pos < (ep.episodeList?.length ?? 0) &&
            (ep.episodeList?[pos].stopTime ?? 0) > 0 &&
            ep.episodeList?[pos].videoDuration != null;
        final double pct = hasProg
            ? Utils.getPercentage(
                ep.episodeList![pos].videoDuration!,
                ep.episodeList![pos].stopTime!,
              )
            : 0.0;

        return InteractiveIcon(
          builder: (isHovered) => GestureDetector(
            onTap: () => openPlayer("Show"),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                constraints: const BoxConstraints(),
                decoration: BoxDecoration(
                  color: isHovered
                      ? colorPrimary.withValues(alpha: 0.88)
                      : colorPrimary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: colorPrimary.withValues(alpha: 0.55),
                            blurRadius: 22,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: colorPrimary.withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: appBgColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: MyText(
                                  color: appBgColor,
                                  text: pos == -1
                                      ? "Watch Episode 1"
                                      : "Continue E${(pos + 1)}",
                                  multilanguage: false,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 14,
                                  fontweight: FontWeight.w700,
                                  fontsizeWeb: 15,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasProg)
                        SizedBox(
                          height: 3,
                          child: LinearPercentIndicator(
                            padding: EdgeInsets.zero,
                            barRadius: const Radius.circular(0),
                            lineHeight: 3,
                            percent: pct,
                            backgroundColor: secProgressColor,
                            progressColor: appBgColor.withValues(alpha: 0.7),
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
    );
  }

  Widget _buildWatchTrailerNew() {
    return _buildSecondaryBtn(
      icon: Icons.play_circle_outline_rounded,
      label: "Watch Trailer",
      onTap: () => openPlayer("Trailer"),
    );
  }

  Widget _buildSecondaryBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InteractiveIcon(
      builder: (isHovered) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isHovered
                  ? white.withValues(alpha: 0.18)
                  : white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered
                    ? white.withValues(alpha: 0.45)
                    : white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isHovered ? white : white.withValues(alpha: 0.80),
                  size: 18,
                ),
                const SizedBox(width: 8),
                MyText(
                  color: isHovered ? white : white.withValues(alpha: 0.80),
                  text: label,
                  multilanguage: false,
                  textalign: TextAlign.start,
                  fontsizeNormal: 13,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 14,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRentBtnNew() {
    final item = showDetailsProvider.contentDetailModel.result?[0];
    if (item == null) return const SizedBox.shrink();
    if (rentStatus != null && rentStatus != "1" && Constant.userIsKid == true) {
      return const SizedBox.shrink();
    }
    if ((item.isRent ?? 0) != 1) return const SizedBox.shrink();

    if ((item.rentBuy ?? 0) == 1) {
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: _buildIconActionBtn(
          icon: Icons.check_circle_rounded,
          label: "Rented",
          isActive: true,
          onTap: () {},
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: InteractiveIcon(
        builder: (isHovered) => GestureDetector(
          onTap: () async {
            if (Constant.userID != null) {
              dynamic isRented = await Utils.paymentForRent(
                context: context,
                videoId: (item.id ?? 0).toString(),
                rentPrice: (item.price ?? 0).toString(),
                vTitle: (item.name ?? '').toString(),
                typeId: (item.typeId ?? 0).toString(),
                vType: (item.videoType ?? 0).toString(),
                subVideoType: (item.subVideoType ?? 0).toString(),
                producerId: (item.producerId ?? 0).toString(),
                rentProductId: (item.webPriceId ?? '').toString(),
                newPage: widget.newPage ?? "",
                oldPage: widget.oldPage ?? "",
                reqText: widget.reqText ?? "",
              );
              if (isRented != null && isRented == true) {
                _getData(forceRefresh: true);
              }
            } else {
              await Utils.openLogin(
                context: context,
                newPage: widget.newPage ?? "",
              );
              _getData(forceRefresh: true);
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isHovered
                    ? colorAccent.withValues(alpha: 0.25)
                    : colorAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHovered
                      ? colorAccent.withValues(alpha: 0.75)
                      : colorAccent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_outlined,
                    color: colorAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  MyText(
                    color: colorAccent,
                    text:
                        "Rent · ${Constant.currencySymbol}${item.price ?? ''}",
                    multilanguage: false,
                    textalign: TextAlign.start,
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconActions() {
    return Row(
      children: [
        Consumer<ShowDetailsProvider>(
          builder: (context, sdp, child) {
            final isBookmarked =
                (sdp.contentDetailModel.result?[0].isBookmark ?? 0) == 1;
            return _buildIconActionBtn(
              icon: isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_add_outlined,
              label: "List",
              isActive: isBookmarked,
              onTap: () async {
                if (Constant.userID != null) {
                  await sdp.setBookMark(
                    context,
                    widget.videoType,
                    widget.subVideoType,
                    widget.videoId,
                  );
                } else {
                  await Utils.openLogin(
                    context: context,
                    newPage: widget.newPage ?? "",
                  );
                }
              },
            );
          },
        ),
        Consumer<ShowDetailsProvider>(
          builder: (context, sdp, child) {
            if ((sdp.contentDetailModel.result?[0].isLike ?? 0) != 1) {
              return const SizedBox.shrink();
            }
            final isLiked =
                (sdp.contentDetailModel.result?[0].isUserLike ?? 0) == 1;
            return _buildIconActionBtn(
              icon: isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              label: "Like",
              isActive: isLiked,
              onTap: () async {
                if (Utils.checkLoginUser(context)) {
                  await sdp.setLikeDislike(
                    context,
                    subVideoType: widget.subVideoType,
                    videoType: widget.videoType,
                    videoId: widget.videoId,
                  );
                }
              },
            );
          },
        ),
        _buildIconActionBtn(
          icon: Icons.ios_share_rounded,
          label: "Share",
          isActive: false,
          onTap: () {
            ShareModel shareModel = ShareModel(
              newPage: RoutesConstant.contentDetailsPage,
              videoTitle:
                  showDetailsProvider.contentDetailModel.result?[0].name ?? "",
              videoId:
                  showDetailsProvider.contentDetailModel.result?[0].id ?? 0,
              videoType:
                  showDetailsProvider.contentDetailModel.result?[0].videoType ??
                  0,
              subVideoType:
                  showDetailsProvider
                      .contentDetailModel
                      .result?[0]
                      .subVideoType ??
                  0,
              typeId:
                  showDetailsProvider.contentDetailModel.result?[0].typeId ?? 0,
            );
            Utils.openShareDialog(context: context, shareModel: shareModel);
          },
        ),
      ],
    );
  }

  Widget _buildIconActionBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InteractiveIcon(
      builder: (isHovered) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isHovered || isActive)
                  ? colorPrimary.withValues(alpha: 0.16)
                  : white.withValues(alpha: 0.07),
              border: Border.all(
                color: (isHovered || isActive)
                    ? colorPrimary.withValues(alpha: 0.65)
                    : white.withValues(alpha: 0.18),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: (isHovered || isActive) ? colorPrimary : white,
                  size: 17,
                ),
                const SizedBox(height: 2),
                MyText(
                  color: (isHovered || isActive) ? colorPrimary : descTextColor,
                  text: label,
                  multilanguage: false,
                  fontsizeNormal: 9,
                  fontsizeWeb: 9,
                  fontweight: FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.clip,
                  textalign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ─────────────────────────────────────────────
     BODY — stats, episodes, reviews, related, cast, director
  ───────────────────────────────────────────── */
  Widget _buildBody(Result item) {
    final hPad = Dimens.isBigScreen(context) ? 40.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReleaseDate(),
          const SizedBox(height: 15),
          if (widget.videoType != Constant.upcomingContentType)
            _buildRentExpiryTAG(),
          _buildStatsRow(item),
          const SizedBox(height: 32),
          _buildEpisodesSection(),
          Consumer<ShowDetailsProvider>(
            builder: (context, sdp, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingReviewCard(),
                  RelatedVideoShow(
                    relatedDataList: sdp.relatedContentModel.result,
                    newPage: widget.newPage,
                    oldPage: widget.oldPage,
                    reqText: widget.reqText,
                    videoId: widget.videoId,
                    subVideoType: widget.subVideoType,
                    videoType: widget.videoType,
                    typeId: widget.typeId,
                  ),
                  CastCrew(
                    castList: sdp.contentDetailModel.result?[0].cast,
                    newPage: widget.newPage,
                  ),
                  _buildDirectorNew(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesSection() {
    if (widget.videoType == Constant.upcomingContentType) {
      return const SizedBox.shrink();
    }

    return Consumer2<ShowDetailsProvider, EpisodeProvider>(
      builder: (context, showDetailsProvider, episodeProvider, child) {
        final seasons =
            showDetailsProvider.contentDetailModel.result?[0].season;
        if (seasons == null || seasons.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* Header with colorPrimary left accent bar */
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                MyText(
                  color: titleTextColor,
                  text: "episodes",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 17,
                  fontsizeWeb: 20,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
            /* Divider */
            Container(
              width: double.infinity,
              height: 0.5,
              margin: const EdgeInsets.only(top: 8),
              color: grayDark,
            ),
            /* Season tabs */
            _buildSeasonBtn(),
            /* Episode list — full width */
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 50),
              child: EpisodeBySeason(
                widget.videoId,
                widget.subVideoType,
                widget.typeId,
                showDetailsProvider.seasonPos,
                showDetailsProvider.contentDetailModel.result?[0].season,
                showDetailsProvider.contentDetailModel.result?[0],
                newPage: widget.newPage ?? "",
                oldPage: widget.oldPage ?? "",
                reqText: widget.reqText ?? "",
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(Result item) {
    final stats = <Map<String, String>>[];

    final ratingVal = (item.avgRating as num?)?.toDouble();
    if (ratingVal != null && ratingVal > 0) {
      stats.add({
        "val": ratingVal == ratingVal.floorToDouble()
            ? ratingVal.toInt().toString()
            : ratingVal.toStringAsFixed(1),
        "label": "Rating",
      });
    }

    final int seasonCount = item.season?.length ?? 0;
    if (seasonCount > 0) {
      stats.add({"val": seasonCount.toString(), "label": "Seasons"});
    }

    if ((item.totalView?.toString() ?? "").isNotEmpty &&
        item.totalView.toString() != "0") {
      stats.add({"val": _formatCount(item.totalView ?? 0), "label": "Views"});
    }

    if ((item.totalLike?.toString() ?? "").isNotEmpty &&
        item.totalLike.toString() != "0") {
      stats.add({"val": _formatCount(item.totalLike ?? 0), "label": "Liked"});
    }

    if ((item.releaseDate ?? "").isNotEmpty) {
      stats.add({
        "val": DateFormat(
          "yyyy",
        ).format(DateTime.tryParse(item.releaseDate ?? "") ?? DateTime.now()),
        "label": "Year",
      });
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: white.withValues(alpha: 0.08), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: stats.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: i < stats.length - 1
                        ? BorderSide(
                            color: white.withValues(alpha: 0.08),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MyText(
                        color: colorPrimary,
                        text: s["val"] ?? "",
                        multilanguage: false,
                        fontsizeNormal: 18,
                        fontsizeWeb: 22,
                        fontweight: FontWeight.w800,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        (s["label"] ?? "").toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: descTextColor.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatCount(dynamic raw) {
    final n = (raw is int) ? raw : int.tryParse(raw.toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  Widget _buildDirectorNew() {
    if (directorList == null || (directorList?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    final director = directorList![0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.fromLTRB(0, 8, 0, 20),
          color: white.withValues(alpha: 0.06),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorPrimary.withValues(alpha: 0.25)),
          ),
          child: const Text(
            "Director",
            style: TextStyle(
              fontSize: 11,
              color: colorPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InteractiveIcon(
          builder: (isHovered) => GestureDetector(
            onTap: () async {
              final videoByIDProvider = Provider.of<VideoByIDProvider>(
                context,
                listen: false,
              );
              videoByIDProvider.setLoading(true);
              if (!mounted) return;
              context.go(
                "/${RoutesConstant.videoByCastPage}/${director.id ?? 0}",
                extra: {
                  'newpage': widget.newPage.toString(),
                  'itemid': (director.id ?? 0).toString(),
                  'title': director.name ?? '',
                  'layouttype': 'ByCast',
                },
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isHovered
                      ? white.withValues(alpha: 0.06)
                      : white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHovered
                        ? colorPrimary.withValues(alpha: 0.25)
                        : white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: Dimens.isBigScreen(context) ? 70 : 58,
                      height: Dimens.isBigScreen(context) ? 70 : 58,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isHovered
                              ? colorPrimary.withValues(alpha: 0.65)
                              : colorPrimary.withValues(alpha: 0.30),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: MyUserNetworkImage(
                          imageUrl: director.image ?? "",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            color: isHovered ? colorPrimary : white,
                            text: director.name ?? "",
                            multilanguage: false,
                            fontsizeNormal: 14,
                            fontsizeWeb: 16,
                            fontweight: FontWeight.w700,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                          ),
                          const SizedBox(height: 6),
                          if ((director.personalInfo ?? "").isNotEmpty)
                            MyText(
                              color: descTextColor,
                              text: director.personalInfo ?? "",
                              multilanguage: false,
                              fontsizeNormal: 12,
                              fontsizeWeb: 13,
                              fontweight: FontWeight.w400,
                              maxline: 5,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                              fontstyle: FontStyle.normal,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMobilePoster() {
    final imageUrl =
        (showDetailsProvider.contentDetailModel.result?[0].landscape ?? "")
            .isNotEmpty
        ? (showDetailsProvider.contentDetailModel.result?[0].landscape ?? "")
        : (showDetailsProvider.contentDetailModel.result?[0].thumbnail ?? "");

    if (Dimens.isBigScreen(context)) {
      return MyNetworkImage(fit: BoxFit.cover, imageUrl: imageUrl);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: Dimens.getResponsiveHeight(context, 24),
              child: MyNetworkImage(fit: BoxFit.cover, imageUrl: imageUrl),
            ),
          ),
          Positioned(top: 8, right: 8, child: Utils.buildCloseBtn(context)),
        ],
      ),
    );
  }

  Widget _buildSeasonBtn() {
    return Consumer<ShowDetailsProvider>(
      builder: (context, showDetailsProvider, child) {
        final seasons =
            showDetailsProvider.contentDetailModel.result?[0].season;
        if (seasons == null || seasons.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              top: Dimens.isBigScreen(context) ? 6 : 4,
              bottom: Dimens.isBigScreen(context) ? 6 : 4,
            ),
            itemCount: seasons.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final isActive = index == showDetailsProvider.seasonPos;
              return InteractiveIcon(
                builder: (isHovered) {
                  return InkWell(
                    onTap: () async {
                      printLog("SeasonID ====> ${seasons[index].id ?? 0}");
                      printLog("index ====> $index");
                      episodeProvider.setLoading(true);
                      await showDetailsProvider.setSeasonPosition(index);
                      printLog(
                        "seasonPos ====> ${showDetailsProvider.seasonPos}",
                      );
                      await getAllEpisode(
                        showDetailsProvider.seasonPos,
                        showDetailsProvider
                            .contentDetailModel
                            .result?[0]
                            .season,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorPrimary.withValues(alpha: 0.15)
                            : isHovered
                            ? white.withValues(alpha: 0.07)
                            : transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? colorPrimary
                                : isHovered
                                ? white.withValues(alpha: 0.25)
                                : transparent,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                      ),
                      child: MyText(
                        color: isActive
                            ? white
                            : isHovered
                            ? white.withValues(alpha: 0.85)
                            : descTextColor,
                        text: seasons[index].name ?? "-",
                        fontsizeNormal: 13,
                        fontsizeWeb: 15,
                        fontstyle: FontStyle.normal,
                        fontweight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        multilanguage: false,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /* ── Rating card — constrained width ── */
  Widget _buildRatingReviewCard() {
    final result = showDetailsProvider.contentDetailModel.result;
    if (result == null || result.isEmpty) return const SizedBox.shrink();
    final title = result[0].name ?? '';
    final poster = result[0].landscape ?? result[0].thumbnail ?? '';

    return RatingReviewSummaryCard(
      videoId: widget.videoId,
      videoType: widget.videoType,
      subVideoType: widget.subVideoType,
      videoTitle: title,
      posterUrl: poster,
      onTap: () {
        context.go(
          '/${RoutesConstant.ratingReviewPage}/${widget.videoType}/${widget.subVideoType}/${widget.videoId}',
          extra: {
            'newpage': widget.newPage ?? '',
            'title': title,
            'poster': poster,
            'contenttype': 'show',
          },
        );
      },
    );
  }

  Widget _buildReleaseDate() {
    if (widget.videoType == Constant.upcomingContentType) {
      if (showDetailsProvider.contentDetailModel.result?[0].releaseDate !=
              null &&
          (showDetailsProvider.contentDetailModel.result?[0].releaseDate ??
                  "") !=
              "") {
        return Container(
          margin: EdgeInsets.fromLTRB(
            Dimens.isBigScreen(context) ? 0 : 20,
            20,
            20,
            0,
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              MyText(
                color: white,
                text: "release_date",
                multilanguage: true,
                textalign: TextAlign.start,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(width: 5),
              MyText(
                color: white,
                text: ":",
                multilanguage: false,
                textalign: TextAlign.start,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: MyText(
                  color: complimentryColor,
                  text: DateFormat("dd MMM, yyyy").format(
                    DateTime.parse(
                      showDetailsProvider
                              .contentDetailModel
                              .result?[0]
                              .releaseDate ??
                          "",
                    ),
                  ),
                  multilanguage: false,
                  textalign: TextAlign.start,
                  fontsizeNormal: 14,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w700,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  /* ********************************** */
  /* Trailer View START *************** */
  Widget setUpTrailerView() {
    if ((showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "") ==
        "youtube") {
      if (_trailerYoutubeController != null) {
        if (_trailerYoutubeController?.value.playerState != PlayerState.ended) {
          return _buildTrailerView(
            showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
          );
        } else {
          return _buildMobilePoster();
        }
      } else {
        return _buildMobilePoster();
      }
    } else {
      if (_trailerNormalController != null &&
          (_trailerNormalController?.value.isInitialized ?? false)) {
        if (!(_trailerNormalController?.value.isCompleted ?? false) &&
            (_trailerNormalController?.value.isPlaying ?? false)) {
          return _buildTrailerView(
            showDetailsProvider.contentDetailModel.result?[0].trailerType ?? "",
          );
        } else {
          return _buildMobilePoster();
        }
      } else {
        return _buildMobilePoster();
      }
    }
  }

  Widget _buildTrailerView(String trailerType) {
    if (trailerType == "youtube") {
      return VisibilityDetector(
        key: Key('show_${widget.videoId}'),
        onVisibilityChanged: (visibilityInfo) async {
          if (!mounted) return;
          var visiblePercentage = visibilityInfo.visibleFraction * 100;
          printLog(
            '=========== Widget ${visibilityInfo.key} is $visiblePercentage% visible===========',
          );
          if (_trailerYoutubeController != null) {
            if (_trailerYoutubeController?.value.playerState !=
                PlayerState.ended) {
              if (visiblePercentage > 50.0) {
                _trailerYoutubeController?.play();
              } else {
                _trailerYoutubeController?.pause();
              }
            }
          }
        },
        child: Container(
          padding: Dimens.isBigScreen(context)
              ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
              : const EdgeInsets.fromLTRB(12, 5, 12, 0),
          child: ClipRRect(
            borderRadius: Dimens.isBigScreen(context)
                ? BorderRadius.circular(0)
                : BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(0),
                  width: MediaQuery.of(context).size.width,
                  height: Dimens.getResponsiveHeight(context, 0),
                  child: YoutubePlayer(controller: _trailerYoutubeController!),
                ),
                Positioned.fill(
                  child: PointerInterceptor(
                    child: Container(
                      color: transparent,
                      padding: const EdgeInsets.all(0),
                      width: MediaQuery.of(context).size.width,
                      height: Dimens.getResponsiveHeight(context, 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return VisibilityDetector(
        key: Key('show_${widget.videoId}'),
        onVisibilityChanged: (visibilityInfo) async {
          if (!mounted) return;
          var visiblePercentage = visibilityInfo.visibleFraction * 100;
          printLog(
            '=========== Widget ${visibilityInfo.key} is $visiblePercentage% visible===========',
          );
          if (_trailerNormalController != null &&
              (_trailerNormalController?.value.isInitialized ?? false)) {
            if (!(_trailerNormalController?.value.isCompleted ?? false)) {
              if (visiblePercentage > 50.0) {
                await _trailerNormalController?.play();
              } else {
                await _trailerNormalController?.pause();
              }
            }
          }
        },
        child: Container(
          padding: Dimens.isBigScreen(context)
              ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
              : const EdgeInsets.fromLTRB(12, 5, 12, 0),
          child: ClipRRect(
            borderRadius: Dimens.isBigScreen(context)
                ? BorderRadius.circular(0)
                : BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(0),
              width: MediaQuery.of(context).size.width,
              height: Dimens.getResponsiveHeight(context, 0),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _trailerNormalController?.value.size.width,
                    height: _trailerNormalController?.value.size.height,
                    child: AspectRatio(
                      aspectRatio:
                          _trailerNormalController?.value.aspectRatio ??
                          (16 / 9),
                      child: VideoPlayer(_trailerNormalController!),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  /* ***************** Trailer View END */
  /* ********************************** */

  Widget _buildRentExpiryTAG() {
    if ((showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0) == 1) {
      if ((showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0) ==
              1 &&
          (showDetailsProvider.contentDetailModel.result?[0].rentExpiryDate ??
                  "")
              .isNotEmpty) {
        return FittedBox(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
            margin: EdgeInsets.only(
              top:
                  ((showDetailsProvider
                              .contentDetailModel
                              .result?[0]
                              .isPremium ??
                          0) ==
                      1)
                  ? 10
                  : 20,
              bottom: 20,
            ),
            decoration: Utils.setBGWithBorder(
              transparent,
              defaultIconColor,
              3,
              0.4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MyText(
                  multilanguage: true,
                  color: titleTextColor,
                  text: _checkExpiry() ? "rent_expire_on" : "rent_expired",
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w500,
                  fontsizeWeb: 16,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
                if (_checkExpiry())
                  MyText(
                    color: titleTextColor,
                    multilanguage: false,
                    text: " : ",
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 16,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    isShadowText: true,
                  ),
                if (_checkExpiry())
                  MyText(
                    color: _checkExpiry() ? colorPrimary : redColor,
                    multilanguage: false,
                    text: DateFormat("dd MMM, yyyy").format(
                      DateTime.parse(
                        showDetailsProvider
                                .contentDetailModel
                                .result?[0]
                                .rentExpiryDate ??
                            "",
                      ),
                    ),
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    isShadowText: true,
                  ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          margin: EdgeInsets.only(
            top:
                ((showDetailsProvider.contentDetailModel.result?[0].isPremium ??
                        0) ==
                    1)
                ? 10
                : 20,
            bottom: 20,
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: Utils.setBackground(complimentryColor, 18),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(1),
                child: MyText(
                  color: white,
                  text: Constant.currencySymbol,
                  textalign: TextAlign.center,
                  fontsizeNormal: 10,
                  fontsizeWeb: 12,
                  fontweight: FontWeight.w700,
                  multilanguage: false,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5),
                child: MyText(
                  color: titleTextColor,
                  text: "renttag",
                  textalign: TextAlign.center,
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w600,
                  multilanguage: true,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
