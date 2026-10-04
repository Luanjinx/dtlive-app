import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/download_item.dart';
import '../model/playermodel.dart';
import '../model/sharemodel.dart';
import '../pages/myepisodedownloads.dart';
import '../provider/videodownloadprovider.dart';
import '../routes/routes_constant.dart';
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

class MyDownloads extends StatefulWidget {
  final String viewFrom;
  const MyDownloads({super.key, required this.viewFrom});

  @override
  State<MyDownloads> createState() => _MyDownloadsState();
}

class _MyDownloadsState extends State<MyDownloads> {
  /* Create Instance And Initilize Hive */
  late Box<DownloadItem> downloadBox;
  late Box<SessionItem> seasonBox;
  late Box<EpisodeItem> episodeBox;
  List<DownloadItem>? myDownloadsList;

  @override
  void initState() {
    super.initState();
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
    myDownloadsList = [];
    myDownloadsList = downloadBox.values.toList();
    printLog("myDownloadsList =================> ${myDownloadsList?.length}");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (widget.viewFrom == RoutesConstant.homePage)
          ? Utils.myAppBar(context, "downloads", true)
          : Utils.myAppBarWithBack(context, "downloads", true),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(child: _buildDownloadList()),
    );
  }

  Widget _buildDownloadList() {
    return Consumer<VideoDownloadProvider>(
      builder: (context, downloadProvider, child) {
        if (myDownloadsList != null) {
          if ((myDownloadsList?.length ?? 0) > 0) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myDownloadsList?.length ?? 0,
                itemBuilder: (BuildContext context, int position) {
                  return _buildDownloadItem(position);
                },
              ),
            );
          } else {
            return const NoData(title: 'no_downloads', subTitle: '');
          }
        } else {
          return const NoData(title: 'no_downloads', subTitle: '');
        }
      },
    );
  }

  Widget _buildDownloadItem(int position) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(minHeight: Dimens.heightWatchlist),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () async {
          printLog("Clicked on position ==> $position");
          if ((myDownloadsList?[position].videoType ?? 0) ==
                  Constant.showContentType ||
              (myDownloadsList?[position].subVideoType ?? 0) ==
                  Constant.showContentType) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return MyEpisodeDownloads(
                    position,
                    myDownloadsList?[position].id ?? 0,
                    myDownloadsList?[position].videoType ?? 0,
                    myDownloadsList?[position].subVideoType ?? 0,
                    myDownloadsList?[position].typeId ?? 0,
                  );
                },
              ),
            );
            _getData();
          } else {
            openPlayer(position);
          }
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
                imagePath: myDownloadsList?[position].landscapeImg ?? "",
                fit: BoxFit.fill,
              ),
            ),
            ((myDownloadsList?[position].videoType ?? 0) ==
                        Constant.showContentType ||
                    (myDownloadsList?[position].subVideoType ?? 0) ==
                        Constant.showContentType)
                ? const SizedBox.shrink()
                : _buildWatchBtn(position),
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
                    text: myDownloadsList?[position].name ?? "",
                    textalign: TextAlign.start,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w600,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 3),
                  /* Release Year & Video Duration */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (myDownloadsList?[position].releaseYear != null &&
                              (myDownloadsList?[position].releaseYear ?? "") !=
                                  "")
                          ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: MyText(
                                color: descTextColor,
                                text: DateFormat("yyyy").format(
                                  DateTime.parse(
                                    (myDownloadsList?[position].releaseYear ??
                                        ""),
                                  ),
                                ),
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.start,
                                fontsizeNormal: 12,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            )
                          : const SizedBox.shrink(),
                      ((myDownloadsList?[position].videoType ?? 0) != 2 &&
                              (myDownloadsList?[position].subVideoType ?? 0) !=
                                  2)
                          ? (myDownloadsList?[position].videoDuration != null &&
                                    (myDownloadsList?[position].videoDuration ??
                                            0) >
                                        0)
                                ? Container(
                                    margin: const EdgeInsets.only(right: 20),
                                    child: MyText(
                                      color: descTextColor,
                                      text: Utils.convertInMin(
                                        myDownloadsList?[position]
                                                .videoDuration ??
                                            0,
                                      ),
                                      textalign: TextAlign.start,
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
                  const SizedBox(height: 6),
                  /* Prime TAG  & Rent TAG */
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Prime TAG */
                      (myDownloadsList?[position].isPremium ?? 0) == 1
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
                      (myDownloadsList?[position].isRent ?? 0) == 1
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
                onTap: () async {
                  if ((myDownloadsList?[position].videoType ?? 0) ==
                          Constant.showContentType ||
                      (myDownloadsList?[position].subVideoType ?? 0) ==
                          Constant.showContentType) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return MyEpisodeDownloads(
                            position,
                            myDownloadsList?[position].id ?? 0,
                            myDownloadsList?[position].videoType ?? 0,
                            myDownloadsList?[position].subVideoType ?? 0,
                            myDownloadsList?[position].typeId ?? 0,
                          );
                        },
                      ),
                    );
                    _getData();
                  } else {
                    _buildVideoMoreDialog(position);
                  }
                },
                child: Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  child: MyImage(
                    width: 18,
                    height: 18,
                    imagePath:
                        ((myDownloadsList?[position].videoType ?? 0) ==
                                Constant.showContentType ||
                            (myDownloadsList?[position].subVideoType ?? 0) ==
                                Constant.showContentType)
                        ? "ic_viewall.png"
                        : "ic_more.png",
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

  void _buildVideoMoreDialog(int position) {
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
                    text: myDownloadsList?[position].name ?? "",
                    multilanguage: false,
                    fontsizeNormal: 18,
                    fontsizeWeb: 18,
                    color: titleTextColor,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
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
                      (myDownloadsList?[position].releaseYear ?? "").isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: MyText(
                                color: descTextColor,
                                text:
                                    myDownloadsList?[position].releaseYear ??
                                    "",
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.center,
                                fontsizeNormal: 12,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            )
                          : const SizedBox.shrink(),
                      ((myDownloadsList?[position].videoType ?? 0) != 2 &&
                              (myDownloadsList?[position].subVideoType ?? 0) !=
                                  2)
                          ? (myDownloadsList?[position].videoDuration != null &&
                                    (myDownloadsList?[position].videoDuration ??
                                            0) >
                                        0)
                                ? Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: MyText(
                                      color: descTextColor,
                                      text: Utils.convertInMin(
                                        myDownloadsList?[position]
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
                      (myDownloadsList?[position].isPremium ?? 0) == 1
                          ? MyText(
                              color: colorPrimary,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 12,
                              fontsizeWeb: 13,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 5),
                      /* Rent TAG */
                      (myDownloadsList?[position].isRent ?? 0) == 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: complimentryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    shape: BoxShape.rectangle,
                                  ),
                                  margin: const EdgeInsets.only(right: 5),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(1),
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
                                  fontsizeWeb: 13,
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

                  /* Watch Now / Resume */
                  ((myDownloadsList?[position].videoType ?? 0) != 2 &&
                          (myDownloadsList?[position].subVideoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Utils.exitDialog(context);
                            openPlayer(position);
                          },
                          child: _buildDialogItems(
                            icon: "ic_play.png",
                            title: "watch_now",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Watch Trailer */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      PlayerModel playerModel = PlayerModel(
                        playType: "Trailer",
                        isLive: false,
                        videoId: myDownloadsList?[position].id ?? 0,
                        videoTitle: myDownloadsList?[position].name ?? "",
                        videoType: myDownloadsList?[position].videoType ?? 0,
                        subVideoType:
                            myDownloadsList?[position].subVideoType ?? 0,
                        typeId: myDownloadsList?[position].typeId ?? 0,
                        episodeId: 0,
                        videoUrl: "",
                        cipherMediaDetails: null,
                        trailerUrl: myDownloadsList?[position].trailerUrl ?? "",
                        uploadType:
                            myDownloadsList?[position].trailerUploadType ?? "",
                        videoThumb:
                            myDownloadsList?[position].landscapeImg ?? "",
                        stopTime: 0,
                        isPremium: myDownloadsList?[position].isPremium ?? 0,
                        isRent: myDownloadsList?[position].isRent ?? 0,
                        isBuy: myDownloadsList?[position].isBuy ?? 0,
                        rentBuy: myDownloadsList?[position].rentBuy ?? 0,
                        securityKey:
                            myDownloadsList?[position].securityKey ?? "",
                        securityIVKey: myDownloadsList?[position].securityIVKey,
                        currentEpiPos: 0,
                        episodeList: null,
                      );
                      await Utils.openPlayer(
                        context: context,
                        playerModel: playerModel,
                      );
                    },
                    child: _buildDialogItems(
                      icon: "ic_borderplay.png",
                      title: "watch_trailer",
                      isMultilang: true,
                    ),
                  ),

                  /* Download Add/Delete */
                  ((myDownloadsList?[position].videoType ?? 0) != 2 &&
                          (myDownloadsList?[position].subVideoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            printLog(
                              "Clicked on position =============> $position",
                            );
                            bool isDeleted = await deleteFromDownloads(
                              position,
                            );
                            printLog("isDeleted =============> $isDeleted");
                            if (!context.mounted) return;
                            Utils.exitDialog(context);
                            _getData();
                          },
                          child: _buildDialogItems(
                            icon: "ic_delete.png",
                            title: "delete_download",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Video Share */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Utils.exitDialog(context);
                      ShareModel shareModel = ShareModel(
                        newPage: RoutesConstant.contentDetailsPage,
                        videoTitle: myDownloadsList?[position].name ?? "",
                        videoId: myDownloadsList?[position].id ?? 0,
                        videoType: myDownloadsList?[position].videoType ?? 0,
                        subVideoType:
                            myDownloadsList?[position].subVideoType ?? 0,
                        typeId: myDownloadsList?[position].typeId ?? 0,
                      );
                      Utils.openShareDialog(
                        context: context,
                        shareModel: shareModel,
                      );
                    },
                    child: _buildDialogItems(
                      icon: "ic_share.png",
                      title: "share",
                      isMultilang: true,
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
                        videoId: myDownloadsList?[position].id ?? 0,
                        subVideoType:
                            myDownloadsList?[position].subVideoType ?? 0,
                        videoType: myDownloadsList?[position].videoType ?? 0,
                        typeId: myDownloadsList?[position].typeId ?? 0,
                        newPage: RoutesConstant.contentDetailsPage,
                        oldPage: '',
                        reqText: '',
                      );
                    },
                    child: _buildDialogItems(
                      icon: "ic_info.png",
                      title: "view_details",
                      isMultilang: true,
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
    printLog("deleteFromDownloads id ====> ${downloadBox.get(position)}");
    if (!mounted) return false;
    /* Remove from Hive START ***************** */
    printLog(
      "downloadBox length :======> ${downloadBox.values.toList().length}",
    );
    printLog("seasonBox length :========> ${seasonBox.values.toList().length}");
    printLog(
      "episodeBox length :=======> ${episodeBox.values.toList().length}",
    );
    printLog("videoType :=======> ${myDownloadsList?[position].videoType}");
    printLog("subVideoType :====> ${myDownloadsList?[position].subVideoType}");
    printLog("typeId :==========> ${myDownloadsList?[position].typeId}");
    if (downloadBox.values.toList().isNotEmpty) {
      /* Video/Show Delete */
      for (int i = 0; i < downloadBox.values.toList().length; i++) {
        final myDownloadData = downloadBox.getAt(i);
        if (myDownloadData != null &&
            myDownloadData.id == myDownloadsList?[position].id &&
            myDownloadData.videoType == myDownloadsList?[position].videoType &&
            myDownloadData.typeId == myDownloadsList?[position].typeId) {
          printLog(
            "myDownloadsList showId =======> ${myDownloadsList?[position].id}",
          );
          printLog("myDownloadData showId ========> ${myDownloadData.id}");
          printLog(
            "myDownloadData videoType =====> ${myDownloadData.videoType}",
          );
          printLog(
            "myDownloadData subVideoType ==> ${myDownloadData.subVideoType}",
          );
          if ((myDownloadData.videoType != 2 &&
                  myDownloadData.subVideoType != 2) &&
              myDownloadData.savedFile != null &&
              myDownloadData.savedFile != "") {
            try {
              File filePath = File(myDownloadData.savedFile ?? "");
              File filePortImgPath = File(myDownloadData.thumbnailImg ?? "");
              File fileLandImgPath = File(myDownloadData.landscapeImg ?? "");
              printLog("myDownloadData filePath =============> $filePath");
              printLog(
                "myDownloadData filePortImgPath ======> $filePortImgPath",
              );
              printLog(
                "myDownloadData fileLandImgPath ======> $fileLandImgPath",
              );
              bool? isFileExists = await filePath.exists();
              bool? isPortImgFileExists = await filePortImgPath.exists();
              bool? isLandImgFileExists = await fileLandImgPath.exists();
              printLog("myDownloadData isFileExists =========> $isFileExists");
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
          }
          await downloadBox.deleteAt(i);
          if (downloadBox.isEmpty) {
            downloadBox.clear();
            if ((myDownloadData.savedDir ?? "").isNotEmpty) {
              try {
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
      printLog("downloadBox length :======> ${downloadBox.length}");
      if (downloadBox.values.toList().isEmpty) {
        downloadBox.clear();
      }
    }
    /* ******************* Remove from Hive END */
    myDownloadsList?.removeAt(position);
    if (!mounted) return false;
    setState(() {});
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
              fontsizeWeb: 15,
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
    printLog("savedFile ======> ${myDownloadsList?[position].savedFile}");
    printLog("securityKey ====> ${myDownloadsList?[position].securityKey}");
    PlayerModel playerModel = PlayerModel(
      playType: "Download",
      isLive: false,
      videoId: myDownloadsList?[position].id ?? 0,
      videoTitle: myDownloadsList?[position].name ?? "",
      videoType: myDownloadsList?[position].videoType ?? 0,
      subVideoType: myDownloadsList?[position].subVideoType ?? 0,
      typeId: myDownloadsList?[position].typeId ?? 0,
      episodeId: 0,
      videoUrl: myDownloadsList?[position].savedFile ?? "",
      cipherMediaDetails: null,
      trailerUrl: myDownloadsList?[position].trailerUrl ?? "",
      uploadType: myDownloadsList?[position].videoUploadType ?? "",
      videoThumb: myDownloadsList?[position].landscapeImg ?? "",
      stopTime: myDownloadsList?[position].stopTime ?? 0,
      isPremium: myDownloadsList?[position].isPremium ?? 0,
      isRent: myDownloadsList?[position].isRent ?? 0,
      isBuy: myDownloadsList?[position].isBuy ?? 0,
      rentBuy: myDownloadsList?[position].rentBuy ?? 0,
      securityKey: myDownloadsList?[position].securityKey ?? "",
      securityIVKey: myDownloadsList?[position].securityIVKey,
      currentEpiPos: 0,
      episodeList: null,
    );
    if (!mounted) return;
    Utils.openPlayer(context: context, playerModel: playerModel);
  }
}
