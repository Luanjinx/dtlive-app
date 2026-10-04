import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../model/download_item.dart';
import '../model/playermodel.dart';
import '../pages/mydownloads.dart';
import '../provider/connectivityprovider.dart';
import '../provider/videodownloadprovider.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../webservice/apiservices.dart';
import '../model/contentdetailmodel.dart';
import '../model/episodebyseasonmodel.dart' as episode;
import '../players/model/vdociphermodel.dart' as vdocipher;
import '../provider/episodeprovider.dart';
import '../provider/showdetailsprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../webwidget/web_hover_card.dart';
import '../widget/mytext.dart';

class EpisodeBySeason extends StatefulWidget {
  final int? videoId, upcomingType, typeId, seasonPos;
  final List<Season>? seasonList;
  final Result? sectionDetails;
  final String? newPage, oldPage, reqText;
  const EpisodeBySeason(
    this.videoId,
    this.upcomingType,
    this.typeId,
    this.seasonPos,
    this.seasonList,
    this.sectionDetails, {
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<EpisodeBySeason> createState() => _EpisodeBySeasonState();
}

class _EpisodeBySeasonState extends State<EpisodeBySeason> {
  /* Create Instance And Initilize Hive */
  late Box<DownloadItem> downloadBox;
  late Box<SessionItem> seasonBox;
  late Box<EpisodeItem> episodeBox;

  late EpisodeProvider episodeProvider;
  late ShowDetailsProvider showDetailsProvider;
  late ConnectivityProvider connectivityProvider;
  late VideoDownloadProvider downloadProvider;

  Map<String, String> qualityUrlList = <String, String>{};
  String? subscriptionStatus;

  @override
  void initState() {
    super.initState();
    /* Initilize Hive */
    if (!kIsWeb) {
      if (Constant.userID != null) {
        if (Constant.userIsKid == true) {
          downloadBox = Hive.box<DownloadItem>(
            '${Constant.hiveDownloadBox}_${Constant.userID}_KID',
          );
          seasonBox = Hive.box<SessionItem>(
            '${Constant.hiveSeasonDownloadBox}_${Constant.userID}_KID',
          );
          episodeBox = Hive.box<EpisodeItem>(
            '${Constant.hiveEpiDownloadBox}_${Constant.userID}_KID',
          );
        } else {
          downloadBox = Hive.box<DownloadItem>(
            '${Constant.hiveDownloadBox}_${Constant.userID}',
          );
          seasonBox = Hive.box<SessionItem>(
            '${Constant.hiveSeasonDownloadBox}_${Constant.userID}',
          );
          episodeBox = Hive.box<EpisodeItem>(
            '${Constant.hiveEpiDownloadBox}_${Constant.userID}',
          );
        }
      } else {
        downloadBox = Hive.box<DownloadItem>(Constant.hiveDownloadBox);
        seasonBox = Hive.box<SessionItem>(Constant.hiveSeasonDownloadBox);
        episodeBox = Hive.box<EpisodeItem>(Constant.hiveEpiDownloadBox);
      }
    }

    episodeProvider = Provider.of<EpisodeProvider>(context, listen: false);
    downloadProvider = Provider.of<VideoDownloadProvider>(
      context,
      listen: false,
    );
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    showDetailsProvider = Provider.of<ShowDetailsProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAllEpisode();
    });
  }

  Future<void> getAllEpisode() async {
    printLog("seasonPos =====EpisodeBySeason=======> ${widget.seasonPos}");
    printLog("videoId =======EpisodeBySeason=======> ${widget.videoId}");
    if ((episodeProvider.currentPage ?? 0) == 0) {
      episodeProvider.setLoading(true);
    } else {
      episodeProvider.setLoadMore(true);
    }
    subscriptionStatus = await Utils.configByStatus(
      status: Constant.subscriptionStatus,
    );
    printLog('getAllEpisode subscriptionStatus ===> $subscriptionStatus');

    await Future.wait([
      episodeProvider.getEpisodeBySeason(
        widget.seasonList?[(widget.seasonPos ?? 0)].id ?? 0,
        widget.videoId,
        ((episodeProvider.currentPage ?? 0) + 1),
      ),
      showDetailsProvider.setEpisodeBySeason(episodeProvider.episodeList),
    ]);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (episodeProvider.loading && !episodeProvider.loadMore) {
      return ShimmerUtils.buildEpisodeShimmer(context, 5);
    }
    if (Constant.isTV) {
      return _buildTVUI();
    } else {
      return _buildWebUI();
    }
  }

  Widget buildOtherUI() {
    return ResponsiveGridList(
      minItemWidth: 60,
      verticalGridSpacing: 8,
      horizontalGridSpacing: 8,
      minItemsPerRow: 1,
      maxItemsPerRow: (kIsWeb && MediaQuery.of(context).size.width > 720)
          ? 2
          : 1,
      listViewBuilderOptions: ListViewBuilderOptions(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
      children: List.generate((episodeProvider.episodeList?.length ?? 0), (
        position,
      ) {
        return ExpandableNotifier(
          child: Wrap(
            children: [
              Container(
                color: lightBlack,
                child: ScrollOnExpand(
                  scrollOnExpand: true,
                  scrollOnCollapse: false,
                  child: ExpandablePanel(
                    theme: const ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                      tapBodyToCollapse: true,
                      tapBodyToExpand: true,
                    ),
                    collapsed: Container(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      constraints: const BoxConstraints(minHeight: 60),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                focusColor: white.withValues(alpha: 0.5),
                                onTap: () async {
                                  printLog("===> position $position");
                                  openPlayer(
                                    "Show",
                                    position,
                                    episodeProvider.episodeList,
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: MyImage(
                                      fit: BoxFit.cover,
                                      height: 32,
                                      width: 32,
                                      imagePath: "play.png",
                                    ),
                                  ),
                                ),
                              ),
                              (episodeProvider
                                              .episodeList?[position]
                                              .videoDuration !=
                                          null &&
                                      (episodeProvider
                                                  .episodeList?[position]
                                                  .stopTime ??
                                              0) >
                                          0)
                                  ? Container(
                                      height: 2,
                                      width: 32,
                                      margin: const EdgeInsets.only(top: 8),
                                      child: LinearPercentIndicator(
                                        padding: const EdgeInsets.all(0),
                                        barRadius: const Radius.circular(2),
                                        lineHeight: 2,
                                        percent: Utils.getPercentage(
                                          episodeProvider
                                                  .episodeList?[position]
                                                  .videoDuration ??
                                              0,
                                          episodeProvider
                                                  .episodeList?[position]
                                                  .stopTime ??
                                              0,
                                        ),
                                        backgroundColor: secProgressColor,
                                        progressColor: colorPrimary,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                MyText(
                                  color: titleTextColor,
                                  text:
                                      episodeProvider
                                          .episodeList?[position]
                                          .name ??
                                      "-",
                                  textalign: TextAlign.start,
                                  fontstyle: FontStyle.normal,
                                  fontsizeNormal: 14,
                                  fontsizeWeb: 14,
                                  maxline: 2,
                                  overflow: TextOverflow.ellipsis,
                                  fontweight: FontWeight.w600,
                                ),
                                const SizedBox(height: 5),
                                MyText(
                                  color: descTextColor,
                                  text:
                                      episodeProvider
                                          .episodeList?[position]
                                          .description ??
                                      "",
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 12,
                                  fontsizeWeb: 12,
                                  multilanguage: false,
                                  fontweight: FontWeight.w400,
                                  maxline: 2,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                                const SizedBox(height: 5),
                                MyText(
                                  color: colorPrimary,
                                  text:
                                      ((episodeProvider
                                                  .episodeList?[position]
                                                  .videoDuration ??
                                              0) >
                                          0)
                                      ? Utils.convertToColonText(
                                          episodeProvider
                                                  .episodeList?[position]
                                                  .videoDuration ??
                                              0,
                                        )
                                      : "-",
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 11,
                                  fontsizeWeb: 12,
                                  fontweight: FontWeight.w600,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    expanded: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MyNetworkImage(
                          fit: BoxFit.cover,
                          height: Dimens.epiPoster,
                          width: MediaQuery.of(context).size.width,
                          imageUrl:
                              (episodeProvider
                                  .episodeList?[position]
                                  .landscape ??
                              ""),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
                          child: MyText(
                            color: titleTextColor,
                            text:
                                episodeProvider.episodeList?[position].name ??
                                "",
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                            fontsizeNormal: 14,
                            fontsizeWeb: 14,
                            maxline: 2,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: MyText(
                            color: descTextColor,
                            text:
                                episodeProvider
                                    .episodeList?[position]
                                    .description ??
                                "",
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                            fontsizeNormal: 12,
                            fontsizeWeb: 12,
                            maxline: 5,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              MyText(
                                color: descTextColor,
                                text:
                                    ((episodeProvider
                                                .episodeList?[position]
                                                .videoDuration ??
                                            0) >
                                        0)
                                    ? Utils.convertTimeToText(
                                        episodeProvider
                                                .episodeList?[position]
                                                .videoDuration ??
                                            0,
                                      )
                                    : "-",
                                textalign: TextAlign.start,
                                fontsizeNormal: 12,
                                fontsizeWeb: 14,
                                fontweight: FontWeight.w600,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              if ((episodeProvider
                                          .episodeList?[position]
                                          .isPremium ??
                                      0) ==
                                  1)
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: MyText(
                                    color: colorPrimary,
                                    text: "primetag",
                                    textalign: TextAlign.start,
                                    fontsizeNormal: 12,
                                    fontsizeWeb: 14,
                                    multilanguage: true,
                                    fontweight: FontWeight.w600,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    builder: (_, collapsed, expanded) {
                      return Expandable(
                        collapsed: collapsed,
                        expanded: expanded,
                        theme: const ExpandableThemeData(crossFadePoint: 0),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTVUI() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLand,
      child: ListView.separated(
        itemCount: episodeProvider.episodeList?.length ?? 0,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, position) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int position) {
          return kIsWeb
              ? WebHoverCard(
                  cardW: Dimens.isBigScreen(context)
                      ? Dimens.widthLandWeb
                      : Dimens.widthLand,
                  cardH: Dimens.isBigScreen(context)
                      ? Dimens.heightLandWeb
                      : Dimens.heightLand,
                  borderRadius: 4,
                  imageUrl:
                      episodeProvider.episodeList?[position].landscape ?? "",
                  onTap: () {
                    printLog("===> position $position");
                    openPlayer("Show", position, episodeProvider.episodeList);
                  },
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(4),
                  focusColor: white,
                  onTap: () {
                    printLog("===> position $position");
                    openPlayer("Show", position, episodeProvider.episodeList);
                  },
                  child: Container(
                    width: Dimens.widthLand,
                    height: Dimens.heightLand,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(2.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: MyNetworkImage(
                        imageUrl:
                            episodeProvider.episodeList?[position].landscape ??
                            "",
                        fit: BoxFit.cover,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildWebUI() {
    return Column(
      children: [
        Stack(
          children: [
            Consumer<EpisodeProvider>(
              builder: (context, episodeProvider, child) {
                return AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 1,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 15,
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodeProvider.episodeList?.length ?? 0,
                  itemBuilder: (BuildContext context, int position) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(4),
                      focusColor: white,
                      onTap: () {
                        printLog("position ===> $position");
                        openPlayer(
                          "Show",
                          position,
                          episodeProvider.episodeList,
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      kIsWeb
                                          ? Dimens.cardRadiusMedium
                                          : Dimens.cardRadius,
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: MyNetworkImage(
                                      imageUrl:
                                          (episodeProvider
                                              .episodeList?[position]
                                              .landscape ??
                                          ""),
                                      fit: BoxFit.cover,
                                      height: Dimens.isBigScreen(context)
                                          ? Dimens.heightEpiLandWeb
                                          : Dimens.heightEpiLand,
                                      width: Dimens.isBigScreen(context)
                                          ? Dimens.widthEpiLandWeb
                                          : Dimens.widthEpiLand,
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    bottom: kIsWeb ? 13 : 8,
                                    child: MyImage(
                                      width: kIsWeb ? 15 : 13,
                                      height: kIsWeb ? 15 : 13,
                                      imagePath: "ic_play.png",
                                      color: white,
                                    ),
                                  ),
                                  if ((episodeProvider
                                                  .episodeList?[position]
                                                  .stopTime ??
                                              0) >
                                          0 &&
                                      episodeProvider
                                              .episodeList?[position]
                                              .videoDuration !=
                                          null)
                                    Positioned(
                                      left: 2,
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        height: 3,
                                        constraints: const BoxConstraints(
                                          minWidth: 0,
                                        ),
                                        child: LinearPercentIndicator(
                                          padding: const EdgeInsets.all(0),
                                          barRadius: const Radius.circular(2),
                                          lineHeight: 3,
                                          percent: Utils.getPercentage(
                                            episodeProvider
                                                    .episodeList?[position]
                                                    .videoDuration ??
                                                0,
                                            episodeProvider
                                                    .episodeList?[position]
                                                    .stopTime ??
                                                0,
                                          ),
                                          backgroundColor: descTextColor,
                                          progressColor: colorPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    color: titleTextColor,
                                    text:
                                        episodeProvider
                                            .episodeList?[position]
                                            .name ??
                                        "",
                                    fontweight: FontWeight.w500,
                                    fontsizeNormal: 14,
                                    fontsizeWeb: 18,
                                    maxline: 2,
                                    textalign: TextAlign.start,
                                    fontstyle: FontStyle.normal,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        MyText(
                                          color: descTextColor,
                                          text:
                                              ((episodeProvider
                                                          .episodeList?[position]
                                                          .videoDuration ??
                                                      0) >
                                                  0)
                                              ? Utils.convertInMin(
                                                  episodeProvider
                                                          .episodeList?[position]
                                                          .videoDuration ??
                                                      0,
                                                )
                                              : "-",
                                          textalign: TextAlign.start,
                                          fontsizeNormal: 12,
                                          fontsizeWeb: 14,
                                          fontweight: FontWeight.w600,
                                          maxline: 1,
                                          overflow: TextOverflow.ellipsis,
                                          fontstyle: FontStyle.normal,
                                        ),
                                        if ((episodeProvider
                                                    .episodeList?[position]
                                                    .isPremium ??
                                                0) ==
                                            1)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 10,
                                            ),
                                            child: MyText(
                                              color: colorPrimary,
                                              text: "primetag",
                                              textalign: TextAlign.start,
                                              multilanguage: true,
                                              fontsizeNormal: 10,
                                              fontsizeWeb: 14,
                                              fontweight: FontWeight.w600,
                                              maxline: 1,
                                              overflow: TextOverflow.ellipsis,
                                              fontstyle: FontStyle.normal,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (Dimens.isBigScreen(context))
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      child: MyText(
                                        color: descTextColor,
                                        text:
                                            episodeProvider
                                                .episodeList?[position]
                                                .description ??
                                            "",
                                        fontsizeNormal: 13,
                                        fontsizeWeb: 14,
                                        fontweight: FontWeight.w400,
                                        maxline: 3,
                                        overflow: TextOverflow.ellipsis,
                                        textalign: TextAlign.start,
                                        fontstyle: FontStyle.normal,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildDownloadWithSubCheck(epiPos: position),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
              bottom: 0,
              child: Consumer<EpisodeProvider>(
                builder: (context, episodeProvider, child) {
                  if (episodeProvider.isMorePage == false ||
                      episodeProvider.loadMore) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    alignment: Alignment.center,
                    height: (kIsWeb && MediaQuery.of(context).size.width > 1000)
                        ? Dimens.heightEpiLandWeb
                        : Dimens.heightLand,
                    width: (kIsWeb && MediaQuery.of(context).size.width > 1000)
                        ? (MediaQuery.of(context).size.width * 0.7)
                        : MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          appBgColor.withValues(alpha: 0.1),
                          appBgColor.withValues(alpha: 0.3),
                          appBgColor.withValues(alpha: 0.7),
                          appBgColor.withValues(alpha: 0.9),
                          appBgColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(0),
                      shape: BoxShape.rectangle,
                    ),
                    child: FittedBox(
                      child: InkWell(
                        onTap: () async {
                          getAllEpisode();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: Utils.setBackground(secondaryBgColor, 30),
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MyImage(
                                height: 15,
                                width: 15,
                                imagePath: 'ic_down.png',
                                color: defaultIconColor,
                              ),
                              const SizedBox(width: 10),
                              MyText(
                                color: descTextColor,
                                multilanguage: true,
                                text: "view_more",
                                fontstyle: FontStyle.normal,
                                maxline: 1,
                                fontsizeNormal: 14,
                                fontsizeWeb: 16,
                                fontweight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        /* Pagination loader */
        Consumer<EpisodeProvider>(
          builder: (context, episodeProvider, child) {
            if (episodeProvider.loadMore) {
              return ShimmerUtils.buildEpisodeShimmer(context, 1);
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  /* ========= Download ========= */
  Widget _buildDownloadWithSubCheck({required int epiPos}) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    if ((episodeProvider.episodeList?[epiPos].isDownload ?? 0) == 0) {
      return const SizedBox.shrink();
    }
    if ((episodeProvider.episodeList?[epiPos].isPremium ?? 0) == 1 &&
        (showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0) == 1) {
      if ((episodeProvider.episodeList?[epiPos].isBuy ?? 0) == 1 ||
          (showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0) ==
              1) {
        return _buildDownloadBtn(position: epiPos);
      } else {
        return const SizedBox.shrink();
      }
    } else if ((episodeProvider.episodeList?[epiPos].isPremium ?? 0) == 1) {
      if ((episodeProvider.episodeList?[epiPos].isBuy ?? 0) == 1) {
        return _buildDownloadBtn(position: epiPos);
      } else {
        return const SizedBox.shrink();
      }
    } else if ((showDetailsProvider.contentDetailModel.result?[0].isRent ??
            0) ==
        1) {
      if ((showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0) ==
          1) {
        return _buildDownloadBtn(position: epiPos);
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return _buildDownloadBtn(position: epiPos);
    }
  }

  Widget _buildDownloadBtn({required int position}) {
    if ((episodeProvider.episodeList?[position].videoUploadType ==
                "server_video" ||
            episodeProvider.episodeList?[position].videoUploadType ==
                "external") &&
        (episodeProvider.episodeList?[position].videoExtension ?? "").contains(
          "mp4",
        )) {
      return Consumer2<ShowDetailsProvider, VideoDownloadProvider>(
        builder: (context, showDetailsProvider, downloadProvider, child) {
          bool isInDownload = false;
          if (!kIsWeb) {
            if (episodeBox.isOpen && episodeBox.values.toList().isNotEmpty) {
              List<EpisodeItem> myEpisodeList = episodeBox.values.where((
                episodeItem,
              ) {
                return (episodeItem.id ==
                        episodeProvider.episodeList?[position].id &&
                    episodeItem.showId ==
                        episodeProvider.episodeList?[position].showId);
              }).toList();
              printLog(
                "_buildDownloadBtn myEpisodeList =====> ${myEpisodeList.length}",
              );

              if (myEpisodeList.isNotEmpty) {
                isInDownload = (myEpisodeList[0].isDownloaded == 1);
                printLog("_buildDownloadBtn isInDownload ==> $isInDownload");
              }
            }
          }
          return Container(
            alignment: Alignment.center,
            width: 35,
            height: 35,
            margin: const EdgeInsets.only(left: 15),
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              focusColor: gray.withValues(alpha: 0.5),
              onTap: () async {
                if (Constant.userID != null) {
                  if (!isInDownload) {
                    if ((downloadProvider.dProgress == 0 ||
                            downloadProvider.dProgress == -1 ||
                            downloadProvider.encryptProgress == 0.0) &&
                        !downloadProvider.loading &&
                        (downloadProvider.itemId == null ||
                            downloadProvider.itemId == 0)) {
                      _checkAndDownload(position: position);
                    } else {
                      Utils.showSnackbar(context, "info", "please_wait", true);
                    }
                  } else {
                    buildDownloadCompleteDialog(position: position);
                  }
                } else {
                  await Utils.openLogin(context: context, newPage: "");
                }
              },
              child: Container(
                padding: const EdgeInsets.all(3.0),
                child:
                    (downloadProvider.dProgress != 0 &&
                        downloadProvider.dProgress > 0 &&
                        downloadProvider.dProgress < 100 &&
                        !isInDownload &&
                        (downloadProvider.itemId ==
                            episodeProvider.episodeList?[position].id))
                    ? Container(
                        alignment: Alignment.center,
                        child: CircularPercentIndicator(
                          radius: (Dimens.featureIconSize / 2),
                          lineWidth: 2.0,
                          percent: (downloadProvider.dProgress / 100)
                              .toDouble(),
                          progressColor: complimentryColor,
                        ),
                      )
                    : ((downloadProvider.encryptProgress > 0 &&
                              downloadProvider.encryptProgress < 1.0 &&
                              (downloadProvider.itemId ==
                                  episodeProvider.episodeList?[position].id))
                          ? Container(
                              width: Dimens.featureIconSize,
                              height: Dimens.featureIconSize,
                              alignment: Alignment.center,
                              child: CircularPercentIndicator(
                                radius: (Dimens.featureIconSize / 2),
                                lineWidth: 2.0,
                                percent: downloadProvider.encryptProgress,
                                progressColor: complimentryColor,
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: MyImage(
                                width: Dimens.featureIconSize,
                                height: Dimens.featureIconSize,
                                color: defaultIconColor,
                                imagePath: isInDownload
                                    ? "ic_download_done.png"
                                    : "ic_download.png",
                              ),
                            )),
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> _checkAndDownload({required int position}) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!connectivityProvider.isOnline) {
      Utils.showSnackbar(context, "fail", "no_internet", true);
      return;
    }
    printLog(
      "video320 ----------> ${episodeProvider.episodeList?[position].video320}",
    );
    if ((episodeProvider.episodeList?[position].video320 ?? "").isNotEmpty) {
      printLog("seasonPos ---------> ${showDetailsProvider.seasonPos}");
      printLog("episode Length ----> ${episodeProvider.episodeList?.length}");
      if (!mounted) return;
      prepareShowDownload(
        context,
        contentDetails: showDetailsProvider.contentDetailModel.result?[0],
        seasonPos: showDetailsProvider.seasonPos,
        episodePos: position,
        episodeDetails: episodeProvider.episodeList?[position],
      );
    } else {
      if (!mounted) return;
      Utils.showSnackbar(context, "fail", "invalid_url", true);
    }
  }

  void buildDownloadCompleteDialog({required int position}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MyText(
                    text: "download_options",
                    multilanguage: true,
                    fontsizeNormal: 16,
                    color: titleTextColor,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 5),
                  MyText(
                    text: "download_options_note",
                    multilanguage: true,
                    fontsizeNormal: 10,
                    color: descTextColor,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w500,
                    maxline: 5,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  /* To Download */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () async {
                      Utils.exitDialog(context);
                      if (Constant.userID != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MyDownloads(viewFrom: ''),
                          ),
                        );
                        setState(() {});
                      } else {
                        await Utils.openLogin(context: context, newPage: "");
                      }
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_setting.png",
                            fit: BoxFit.fill,
                            color: defaultIconColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "take_me_to_the_downloads_page",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              color: titleTextColor,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w600,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* Delete */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () async {
                      Utils.exitDialog(context);
                      deleteFromDownloads(position);
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_delete.png",
                            fit: BoxFit.fill,
                            color: defaultIconColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "delete_download",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              color: titleTextColor,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w600,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteFromDownloads(int position) async {
    printLog("deleteFromDownloads pos ===> $position");
    printLog("deleteFromDownloads id ====> ${downloadBox.get(position)?.id}");
    int? episodeId = episodeProvider.episodeBySeasonModel.result?[position].id;
    int? seasonId = showDetailsProvider
        .contentDetailModel
        .result?[0]
        .season?[showDetailsProvider.seasonPos]
        .id;
    int? showId = showDetailsProvider.contentDetailModel.result?[0].id;
    printLog("deleteFromDownloads episodeId ===> $episodeId");
    printLog("deleteFromDownloads seasonId ====> $seasonId");
    printLog("deleteFromDownloads showId ======> $showId");
    if (!mounted) return;
    /* Remove from Hive START ***************** */
    printLog(
      "downloadBox length :======> ${downloadBox.values.toList().length}",
    );
    printLog("seasonBox length :========> ${seasonBox.values.toList().length}");
    printLog(
      "episodeBox length :=======> ${episodeBox.values.toList().length}",
    );

    /* Episode Delete */
    for (int i = 0; i < episodeBox.values.toList().length; i++) {
      final myEpisodeData = episodeBox.getAt(i);
      printLog("myEpisodeData ====> $myEpisodeData");
      if (myEpisodeData != null &&
          myEpisodeData.id == episodeId &&
          myEpisodeData.showId == showId) {
        printLog("myEpisodeData showId ====> ${myEpisodeData.showId}");
        if (myEpisodeData.savedFile != null && myEpisodeData.savedFile != "") {
          try {
            File filePath = File(myEpisodeData.savedFile ?? "");
            File filePortImgPath = File(myEpisodeData.thumbnail ?? "");
            File fileLandImgPath = File(myEpisodeData.landscape ?? "");
            printLog("myEpisodeData filePath =============> $filePath");
            printLog("myEpisodeData filePortImgPath ======> $filePortImgPath");
            printLog("myEpisodeData fileLandImgPath ======> $fileLandImgPath");
            bool? isFileExists = await filePath.exists();
            bool? isPortImgFileExists = await filePortImgPath.exists();
            bool? isLandImgFileExists = await fileLandImgPath.exists();
            printLog("myEpisodeData isFileExists =========> $isFileExists");
            printLog(
              "myEpisodeData isPortImgFileExists ==> $isPortImgFileExists",
            );
            printLog(
              "myEpisodeData isLandImgFileExists ==> $isLandImgFileExists",
            );
            if (isFileExists) {
              await filePath.delete();
            }
            if (isPortImgFileExists) {
              await filePortImgPath.delete();
            }
            if (isLandImgFileExists) {
              await fileLandImgPath.delete();
            }
          } on Exception catch (exception) {
            printLog("Episode DeleteFile Exception ==> $exception");
          }
        }
        await episodeBox.deleteAt(i);
        if (episodeBox.isEmpty) {
          episodeBox.clear();
          if ((myEpisodeData.savedDir ?? "").isNotEmpty) {
            try {
              String dirPath = myEpisodeData.savedDir ?? "";
              printLog("dirPath ==> $dirPath");
              File dirFolder = File(dirPath);
              printLog("File existsSync ==> ${dirFolder.existsSync()}");
              dirFolder.deleteSync(recursive: true);
            } on Exception catch (exception) {
              printLog("Episode Delete Exception ==> $exception");
            }
          }
        }
      }
    }
    if (episodeBox.values.toList().isEmpty) {
      episodeBox.clear();
    }

    /* Season Delete */
    for (int i = 0; i < seasonBox.values.toList().length; i++) {
      final mySeasonData = seasonBox.getAt(i);
      List<EpisodeItem>? episodeBySeasonList = [];
      if (mySeasonData != null &&
          mySeasonData.id == seasonId &&
          mySeasonData.showId == showId) {
        printLog("mySeasonData showId =======> ${mySeasonData.showId}");
        episodeBySeasonList = episodeBox.values.where((episodeItem) {
          return (episodeItem.showId == showId &&
              episodeItem.sessionId == seasonId);
        }).toList();
        printLog("episodeBySeasonList =======> ${episodeBySeasonList.length}");
        if (episodeBySeasonList.isEmpty) {
          await seasonBox.deleteAt(i);
        }
      }
    }
    if (seasonBox.values.toList().isEmpty) {
      seasonBox.clear();
    }

    printLog("episodeBox length :======> ${episodeBox.values.toList().length}");
    printLog("seasonBox length :=======> ${seasonBox.length}");
    printLog("seasonBox length :=======> ${seasonBox.values.toList().length}");
    /* Show Delete */
    if (downloadBox.values.toList().isNotEmpty) {
      for (int i = 0; i < downloadBox.values.toList().length; i++) {
        List<SessionItem>? seasonByShowList = [];
        final myDownloadData = downloadBox.getAt(i);
        if (myDownloadData != null &&
            myDownloadData.id == showId &&
            myDownloadData.videoType ==
                showDetailsProvider.contentDetailModel.result?[0].videoType &&
            myDownloadData.typeId == widget.typeId) {
          printLog("myDownloadData showId ========> ${myDownloadData.id}");
          printLog(
            "myDownloadData videoType =====> ${myDownloadData.videoType}",
          );
          printLog(
            "myDownloadData subVideoType ==> ${myDownloadData.subVideoType}",
          );

          seasonByShowList = seasonBox.values.where((seasonItem) {
            return (seasonItem.showId == showId);
          }).toList();
          printLog(
            "seasonByShowList =================> ${seasonByShowList.length}",
          );
          if (seasonByShowList.isEmpty) {
            await downloadBox.deleteAt(i);
            if (downloadBox.isEmpty) {
              downloadBox.clear();
              if ((myDownloadData.savedDir ?? "").isNotEmpty) {
                try {
                  /* Images Delete */
                  try {
                    File filePath = File(myDownloadData.savedFile ?? "");
                    File filePortImgPath = File(
                      myDownloadData.thumbnailImg ?? "",
                    );
                    File fileLandImgPath = File(
                      myDownloadData.landscapeImg ?? "",
                    );
                    printLog(
                      "myDownloadData filePath =============> $filePath",
                    );
                    printLog(
                      "myDownloadData filePortImgPath ======> $filePortImgPath",
                    );
                    printLog(
                      "myDownloadData fileLandImgPath ======> $fileLandImgPath",
                    );
                    bool? isFileExists = await filePath.exists();
                    bool? isPortImgFileExists = await filePortImgPath.exists();
                    bool? isLandImgFileExists = await fileLandImgPath.exists();
                    printLog(
                      "myDownloadData isFileExists =========> $isFileExists",
                    );
                    printLog(
                      "myDownloadData isPortImgFileExists ==> $isPortImgFileExists",
                    );
                    printLog(
                      "myDownloadData isLandImgFileExists ==> $isLandImgFileExists",
                    );
                    if (isFileExists) {
                      await filePath.delete();
                    }
                    if (isPortImgFileExists) {
                      await filePortImgPath.delete();
                    }
                    if (isLandImgFileExists) {
                      await fileLandImgPath.delete();
                    }
                  } on Exception catch (exception) {
                    printLog("Video DeleteFile Exception ==> $exception");
                  }
                  /* Images Delete */

                  String dirPath = myDownloadData.savedDir ?? "";
                  printLog("dirPath ==> $dirPath");
                  File dirFolder = File(dirPath);
                  printLog("File existsSync ==> ${dirFolder.existsSync()}");
                  dirFolder.deleteSync(recursive: true);
                } on Exception catch (exception) {
                  printLog("All Delete Exception ==> $exception");
                }
              }
            }
          }
        }
      }
      printLog("downloadBox length :======> ${downloadBox.length}");
      if (downloadBox.values.toList().isEmpty) {
        downloadBox.clear();
      }
    }
    downloadProvider.notifyProvider();
    /* ******************* Remove from Hive END */
  }
  /* ========= Download ========= */

  /* ========= Open Player ========= */
  Future<void> openPlayer(
    String playType,
    int epiPos,
    List<episode.Result>? episodeList,
  ) async {
    if ((episodeList?.length ?? 0) > 0) {
      /* CHECK SUBSCRIPTION */
      if (playType != "Trailer") {
        bool? isPrimiumUser = await Utils.checkSubsRentLogin(
          context: context,
          isPremium: episodeProvider.episodeList?[epiPos].isPremium ?? 0,
          isBuy: episodeProvider.episodeList?[epiPos].isBuy ?? 0,
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

      int? epiID = (episodeList?[epiPos].id ?? 0);
      int? showID = (episodeList?[epiPos].showId ?? 0);
      int? vType =
          (showDetailsProvider.contentDetailModel.result?[0].videoType ?? 0);
      int? vSubType =
          (showDetailsProvider.contentDetailModel.result?[0].subVideoType ?? 0);
      int? vTypeID = widget.typeId;
      int? stopTime = (episodeList?[epiPos].stopTime ?? 0);
      String? vUploadType = (episodeList?[epiPos].videoUploadType ?? "");
      String? videoThumb = (episodeList?[epiPos].landscape ?? "");
      String? epiUrl = (episodeList?[epiPos].video320 ?? "");
      printLog("epiID ========> $epiID");
      printLog("showID =======> $showID");
      printLog("vType ========> $vType");
      printLog("vSubType =====> $vSubType");
      printLog("vTypeID ======> $vTypeID");
      printLog("stopTime =====> $stopTime");
      printLog("vUploadType ==> $vUploadType");
      printLog("videoThumb ===> $videoThumb");
      printLog("epiUrl =======> $epiUrl");

      if (!mounted) return;
      if (epiUrl.isEmpty || epiUrl == "") {
        Utils.showSnackbar(context, "info", "episode_not_found", true);
        return;
      }

      /* Set-up Quality URLs */
      Utils.setQualityURLs(
        video320: (episodeProvider.episodeList?[epiPos].video320 ?? ""),
        video480: (episodeProvider.episodeList?[epiPos].video480 ?? ""),
        video720: (episodeProvider.episodeList?[epiPos].video720 ?? ""),
        video1080: (episodeProvider.episodeList?[epiPos].video1080 ?? ""),
      );

      /* VdoCipher OTP */
      vdocipher.VdoCipherModel? vdocipherDetails;
      if (vUploadType == Constant.vdocipherPlayType && playType != "Trailer") {
        vdocipherDetails = await Utils.getVdoCipherOTP(
          context: context,
          videoId: epiUrl,
        );
        printLog(
          "openPlayer vdocipherDetails ======> ${vdocipherDetails?.result?.otp}",
        );
      }
      /* VdoCipher OTP */

      PlayerModel playerModel = PlayerModel(
        playType: "Show",
        isLive: false,
        videoId: showID,
        videoTitle:
            showDetailsProvider.contentDetailModel.result?[0].name ?? "",
        videoType: vType,
        subVideoType: vSubType,
        typeId: vTypeID,
        episodeId: epiID,
        videoUrl: epiUrl,
        cipherMediaDetails:
            (vdocipherDetails != null && vdocipherDetails.result != null)
            ? (vdocipherDetails.result)
            : null,
        trailerUrl:
            showDetailsProvider.contentDetailModel.result?[0].trailerUrl ?? "",
        uploadType: vUploadType,
        videoThumb: videoThumb,
        stopTime: stopTime,
        isPremium: episodeProvider.episodeList?[epiPos].isPremium ?? 0,
        isBuy: episodeProvider.episodeList?[epiPos].isBuy ?? 0,
        isRent: showDetailsProvider.contentDetailModel.result?[0].isRent ?? 0,
        rentBuy: showDetailsProvider.contentDetailModel.result?[0].rentBuy ?? 0,
        securityKey: "",
        securityIVKey: null,
        currentEpiPos: epiPos,
        episodeList: episodeList,
      );

      if (!mounted) return;
      AdHelper.checkAndShowAds(
        context: context,
        buttonKey: "",
        adType: Constant.interstialAdType,
        alwaysShowAd: false,
        showOnByClick: true,
        onAdComplete: () async {
          dynamic isContinue = await Utils.openPlayer(
            context: context,
            playerModel: playerModel,
          );

          printLog("isContinue ===> $isContinue");
          if (isContinue != null && isContinue == true) {
            await getAllEpisode();
          }
        },
      );
    }
  }

  /* ========= Open Player ========= */
}
