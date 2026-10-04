import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../model/download_item.dart';
import '../model/playermodel.dart';
import '../model/sharemodel.dart';
import '../provider/videodownloadprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/myfileimage.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class MyEpisodeDownloads extends StatefulWidget {
  final int position, showId, videoType, subVideoType, typeId;
  const MyEpisodeDownloads(
    this.position,
    this.showId,
    this.videoType,
    this.subVideoType,
    this.typeId, {
    super.key,
  });

  @override
  State<MyEpisodeDownloads> createState() => _MyEpisodeDownloadsState();
}

class _MyEpisodeDownloadsState extends State<MyEpisodeDownloads> {
  late VideoDownloadProvider downloadProvider;
  /* Create Instance And Initilize Hive */
  late Box<DownloadItem> downloadBox;
  late Box<SessionItem> seasonBox;
  late Box<EpisodeItem> episodeBox;
  List<SessionItem>? mySeasonList;
  List<EpisodeItem>? myEpisodeList;

  @override
  void initState() {
    super.initState();
    downloadProvider = Provider.of<VideoDownloadProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
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
    mySeasonList = [];
    mySeasonList = seasonBox.values.where((seasonItem) {
      return (seasonItem.showId == widget.showId);
    }).toList();
    printLog("mySeasonList =================> ${mySeasonList?.length}");

    myEpisodeList = [];
    if ((mySeasonList?.length ?? 0) > 0) {
      downloadProvider.setSelectedSeason(0);

      myEpisodeList = episodeBox.values.where((episodeItem) {
        return (episodeItem.showId == widget.showId &&
            episodeItem.sessionId == mySeasonList?[0].id);
      }).toList();
      printLog("myEpisodeList ================> ${myEpisodeList?.length}");
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    downloadProvider.clearProvider();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "episodes", true),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              constraints: const BoxConstraints.expand(),
              padding: EdgeInsets.only(
                top: (Dimens.tabSeasonHeight + 12),
                bottom: 10,
              ),
              child: SingleChildScrollView(child: _buildPage()),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: _buildSeason(mySeasonList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    return Consumer<VideoDownloadProvider>(
      builder: (context, downloadProvider, child) {
        if (downloadProvider.loading) {
          return ShimmerUtils.buildDownloadShimmer(context, 10);
        } else {
          if (myEpisodeList != null) {
            if ((myEpisodeList?.length ?? 0) > 0) {
              return AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myEpisodeList?.length ?? 0,
                itemBuilder: (BuildContext context, int position) {
                  return _buildDownloadItem(position);
                },
              );
            } else {
              return const NoData(title: 'no_downloads', subTitle: '');
            }
          } else {
            return const NoData(title: 'no_downloads', subTitle: '');
          }
        }
      },
    );
  }

  Widget _buildSeason(List<SessionItem>? seasonList) {
    return Consumer<VideoDownloadProvider>(
      builder: (context, showDownloadProvider, child) {
        return Container(
          height: Dimens.tabSeasonHeight,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: AlignedGridView.count(
              shrinkWrap: true,
              crossAxisCount: 1,
              crossAxisSpacing: 0,
              mainAxisSpacing: 10,
              itemCount: (seasonList?.length ?? 0),
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
                            printLog("index ===========> $index");
                            myEpisodeList = [];
                            await _getEpisodeBySeason(
                              index,
                              seasonList?[index].id ?? 0,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            alignment: Alignment.center,
                            child: MyText(
                              color:
                                  (showDownloadProvider.seasonClickIndex ==
                                      index)
                                  ? titleTextColor
                                  : descTextColor,
                              text: seasonList?[index].name ?? "-",
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
                        (showDownloadProvider.seasonClickIndex == index)
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
      },
    );
  }

  Future<void> _getEpisodeBySeason(int position, int seasonId) async {
    downloadProvider.setSelectedSeason(position);
    myEpisodeList = [];
    myEpisodeList = episodeBox.values.where((episodeItem) {
      return (episodeItem.showId == widget.showId &&
          episodeItem.sessionId == seasonId);
    }).toList();
    printLog("myEpisodeList =======> ${myEpisodeList?.length}");
  }

  Widget _buildDownloadItem(int position) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(minHeight: Dimens.heightWatchlist),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () {
          printLog("Clicked on position ==> $position");
          openPlayer(position);
        },
        child: Row(
          children: [
            _buildImage(position: position),
            _buildDetails(position: position),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({required int position}) {
    return Container(
      constraints: BoxConstraints(
        minHeight: Dimens.heightWatchlist,
        maxWidth: MediaQuery.of(context).size.width * 0.44,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: [
            Container(
              constraints: BoxConstraints(
                minHeight: Dimens.heightWatchlist,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: MyFileImage(
                imagePath: myEpisodeList?[position].landscape ?? "",
                fit: BoxFit.fill,
              ),
            ),
            _buildWatchBtn(position),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails({required int position}) {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          minHeight: Dimens.heightWatchlist,
          maxWidth: MediaQuery.of(context).size.width * 0.66,
        ),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /* Title */
                  MyText(
                    color: titleTextColor,
                    text: myEpisodeList?[position].description ?? "",
                    textalign: TextAlign.start,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w600,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 3),
                  /* Release Year & Video Duration */
                  (myEpisodeList?[position].videoDuration != null &&
                          (myEpisodeList?[position].videoDuration ?? 0) > 0)
                      ? Container(
                          margin: const EdgeInsets.only(right: 20),
                          child: MyText(
                            color: descTextColor,
                            text: Utils.convertInMin(
                              myEpisodeList?[position].videoDuration ?? 0,
                            ),
                            textalign: TextAlign.start,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            fontsizeNormal: 12,
                            fontweight: FontWeight.w500,
                            fontstyle: FontStyle.normal,
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 6),
                  /* Prime TAG  & Rent TAG */
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Prime TAG */
                      (myEpisodeList?[position].isPremium ?? 0) == 1
                          ? MyText(
                              color: colorPrimary,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 10,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 3),
                      /* Rent TAG */
                      (myEpisodeList?[position].isRent ?? 0) == 1
                          ? MyText(
                              color: titleTextColor,
                              text: "renttag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 11,
                              fontweight: FontWeight.w500,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: InkWell(
                onTap: () {
                  _buildShowMoreDialog(position);
                },
                child: Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  child: MyImage(
                    width: 18,
                    height: 18,
                    imagePath: "ic_more.png",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchBtn(int position) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        openPlayer(position);
      },
      child: Container(
        width: 35,
        height: 35,
        padding: const EdgeInsets.all(5),
        child: MyImage(imagePath: "play.png"),
      ),
    );
  }

  void _buildShowMoreDialog(int position) {
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
                  /* Title */
                  MyText(
                    text: myEpisodeList?[position].description ?? "",
                    multilanguage: false,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    color: titleTextColor,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w600,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 5),
                  /* Release year, Video duration & Comment Icon */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ((myEpisodeList?[position].videoType ?? 0) != 2 &&
                              (myEpisodeList?[position].subVideoType ?? 0) != 2)
                          ? (myEpisodeList?[position].videoDuration != null &&
                                    (myEpisodeList?[position].videoDuration ??
                                            0) >
                                        0)
                                ? Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: MyText(
                                      color: descTextColor,
                                      text: Utils.convertInMin(
                                        myEpisodeList?[position]
                                                .videoDuration ??
                                            0,
                                      ),
                                      textalign: TextAlign.center,
                                      maxline: 1,
                                      overflow: TextOverflow.ellipsis,
                                      fontsizeNormal: 12,
                                      fontweight: FontWeight.w500,
                                      fontstyle: FontStyle.normal,
                                    ),
                                  )
                                : const SizedBox.shrink()
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  /* Prime TAG  & Rent TAG */
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Prime TAG */
                      (myEpisodeList?[position].isPremium ?? 0) == 1
                          ? MyText(
                              color: colorPrimary,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 12,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 5),
                      /* Rent TAG */
                      (myEpisodeList?[position].isRent ?? 0) == 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: complimentryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    shape: BoxShape.rectangle,
                                  ),
                                  margin: const EdgeInsets.only(right: 5),
                                  alignment: Alignment.center,
                                  child: MyText(
                                    color: white,
                                    text: Constant.currencySymbol,
                                    textalign: TextAlign.center,
                                    fontsizeNormal: 10,
                                    fontsizeWeb: 12,
                                    multilanguage: false,
                                    fontweight: FontWeight.w800,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                                MyText(
                                  color: titleTextColor,
                                  text: "renttag",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 12,
                                  fontweight: FontWeight.w500,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /* Watch Now */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      openPlayer(position);
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_play.png",
                            fit: BoxFit.contain,
                            color: defaultIconColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "watch_now",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
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

                  /* Download Delete */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      printLog("Clicked on position =============> $position");
                      bool isDeleted = await deleteFromDownloads(position);
                      printLog("isDeleted =============> $isDeleted");
                      if (isDeleted) {
                        if (!context.mounted) return;
                        Utils.exitPage(context);
                      }
                    },
                    child: _buildDialogItems(
                      icon: "ic_delete.png",
                      title: "delete_download",
                      isMultilang: true,
                    ),
                  ),

                  /* Video Share */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      ShareModel shareModel = ShareModel(
                        newPage: RoutesConstant.contentDetailsPage,
                        videoTitle:
                            "${myEpisodeList?[position].name} - ${myEpisodeList?[position].description}",
                        videoId: myEpisodeList?[position].showId ?? 0,
                        videoType: myEpisodeList?[position].videoType ?? 0,
                        subVideoType:
                            myEpisodeList?[position].subVideoType ?? 0,
                        typeId: myEpisodeList?[position].typeId ?? 0,
                      );
                      Utils.openShareDialog(
                        context: context,
                        shareModel: shareModel,
                      );
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_share.png",
                            fit: BoxFit.contain,
                            color: defaultIconColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "share",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
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

                  /* View Details */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      printLog("Clicked on position :==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId: widget.showId,
                        subVideoType: widget.subVideoType,
                        videoType: widget.videoType,
                        typeId: widget.typeId,
                        newPage: RoutesConstant.contentDetailsPage,
                        oldPage: '',
                        reqText: '',
                      );
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_info.png",
                            fit: BoxFit.contain,
                            color: defaultIconColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "view_details",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
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

  Future<bool> deleteFromDownloads(int position) async {
    printLog("deleteFromDownloads pos ===> $position");
    printLog("deleteFromDownloads id ====> ${downloadBox.get(position)?.id}");
    int? episodeId = myEpisodeList?[position].id;
    int? seasonId = mySeasonList?[downloadProvider.seasonClickIndex ?? 0].id;
    int? showId = myEpisodeList?[position].showId;
    printLog("deleteFromDownloads episodeId ===> $episodeId");
    printLog("deleteFromDownloads seasonId ====> $seasonId");
    printLog("deleteFromDownloads showId ======> $showId");
    if (!mounted) return false;
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
            myDownloadData.videoType == widget.videoType &&
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
      if (downloadBox.length == 0) {
        downloadBox.clear();
      }
    }
    downloadProvider.notifyProvider();
    /* ******************* Remove from Hive END */
    myEpisodeList?.removeAt(position);
    if (mounted) {
      setState(() {});
    }
    return true;
  }

  Widget _buildDialogItems({
    required String icon,
    required String title,
    required bool isMultilang,
  }) {
    return Container(
      height: Dimens.minHtDialogContent,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MyImage(
            width: Dimens.dialogIconSize,
            height: Dimens.dialogIconSize,
            imagePath: icon,
            fit: BoxFit.contain,
            color: defaultIconColor,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: MyText(
              text: title,
              multilanguage: isMultilang,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
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
    );
  }

  Future<void> openPlayer(int position) async {
    printLog("securityKey ====> ${myEpisodeList?[position].securityKey}");
    PlayerModel playerModel = PlayerModel(
      playType: "Download",
      isLive: false,
      videoId: myEpisodeList?[position].id ?? 0,
      videoTitle: myEpisodeList?[position].description ?? "",
      videoType: int.tryParse(
            myEpisodeList?[position].videoType?.toString() ?? "") ?? 0, // [FIX]
      subVideoType: int.tryParse(
            myEpisodeList?[position].subVideoType?.toString() ?? "") ?? 0, // [FIX]
      typeId: 4,
      episodeId: myEpisodeList?[position].showId ?? 0,
      videoUrl: myEpisodeList?[position].savedFile ?? "",
      cipherMediaDetails: null,
      trailerUrl: "",
      uploadType: myEpisodeList?[position].videoUploadType ?? "",
      videoThumb: myEpisodeList?[position].landscape ?? "",
      stopTime: myEpisodeList?[position].stopTime ?? 0,
      isPremium: myEpisodeList?[position].isPremium ?? 0,
      isRent: myEpisodeList?[position].isRent ?? 0,
      isBuy: myEpisodeList?[position].isBuy ?? 0,
      rentBuy: myEpisodeList?[position].rentBuy ?? 0,
      securityKey: myEpisodeList?[position].securityKey ?? "",
      securityIVKey: myEpisodeList?[position].securityIVKey,
      currentEpiPos: 0,
      episodeList: null,
    );
    if (!mounted) return;
    Utils.openPlayer(context: context, playerModel: playerModel);
  }
}
