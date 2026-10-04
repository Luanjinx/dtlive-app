import '../model/contentdetailmodel.dart';
import '../model/download_item.dart';
import '../model/relatedcontentmodel.dart';
import '../model/successmodel.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class VideoDetailsProvider extends ChangeNotifier {
  SuccessModel successModel = SuccessModel();
  ContentDetailModel contentDetailModel = ContentDetailModel();
  RelatedContentModel relatedContentModel = RelatedContentModel();

  bool loading = false;
  bool relatedLoading = false;
  String tabClickedOn = "related";
  int? _currentTypeId;
  int? _currentVideoType;
  int? _currentVideoId;
  int? _currentSubVideoType;

  bool get isLoading => loading;
  bool get isRelatedLoading => relatedLoading;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getContentDetails(
    dynamic typeId,
    videoType,
    videoId,
    subVideoType, {
    bool forceRefresh = false,
  }) async {
    printLog("getContentDetails typeId :========> $typeId");
    printLog("getContentDetails videoType :=====> $videoType");
    printLog("getContentDetails videoId :=======> $videoId");
    printLog("getContentDetails subVideoType :==> $subVideoType");
    // Skip reloading if same video request
    if (!forceRefresh &&
        _currentTypeId == typeId &&
        _currentVideoType == videoType &&
        _currentVideoId == videoId &&
        _currentSubVideoType == subVideoType) {
      printLog("Skipping reload, same video details requested.");
      loading = false;
      notifyListeners();
      return;
    }

    // Update current params
    _currentTypeId = typeId;
    _currentVideoType = videoType;
    _currentVideoId = videoId;
    _currentSubVideoType = subVideoType;

    loading = true;
    notifyListeners();
    try {
      contentDetailModel = await ApiService()
          .contentDetails(typeId, videoType, videoId, subVideoType);
      printLog("getContentDetails status :===> ${contentDetailModel.status}");
      printLog("getContentDetails message :==> ${contentDetailModel.message}");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> getRelatedContent(
      dynamic typeId, videoType, videoId, subVideoType, pageNo) async {
    printLog("getRelatedContent typeId :========> $typeId");
    printLog("getRelatedContent videoType :=====> $videoType");
    printLog("getRelatedContent videoId :=======> $videoId");
    printLog("getRelatedContent subVideoType :==> $subVideoType");
    printLog("getRelatedContent pageNo :========> $pageNo");

    relatedLoading = true;
    notifyListeners();

    try {
      relatedContentModel = await ApiService()
          .relatedContent(typeId, videoType, videoId, subVideoType, pageNo);
      printLog("getRelatedContent status :===> ${relatedContentModel.status}");
      printLog("getRelatedContent message :==> ${relatedContentModel.message}");
    } finally {
      relatedLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBookMark(
      BuildContext context, videoType, subVideoType, videoId) async {
    if ((contentDetailModel.result?[0].isBookmark ?? 0) == 0) {
      contentDetailModel.result?[0].isBookmark = 1;
      Utils.showSnackbar(context, "success", "addwatchlistmessage", true);
    } else {
      contentDetailModel.result?[0].isBookmark = 0;
      Utils.showSnackbar(context, "success", "removewatchlistmessage", true);
    }
    notifyListeners();
    getAddBookMark(subVideoType, videoType, videoId);
  }

  Future<void> getAddBookMark(dynamic subVideoType, videoType, videoId) async {
    printLog("getAddBookMark videoType :======> $videoType");
    printLog("getAddBookMark subVideoType :===> $subVideoType");
    printLog("getAddBookMark videoId :========> $videoId");
    successModel =
        await ApiService().addRemoveBookmark(subVideoType, videoType, videoId);
    printLog("getAddBookMark status :===> ${successModel.status}");
    printLog("getAddBookMark message :==> ${successModel.message}");
  }

  Future<void> removeFromContinue(
      dynamic videoId, videoType, subVideoType) async {
    contentDetailModel.result?[0].stopTime = 0;
    notifyListeners();

    printLog("removeFromContinue videoType :=====> $videoType");
    printLog("removeFromContinue videoId :=======> $videoId");
    printLog("removeFromContinue subVideoType :==> $subVideoType");
    successModel = await ApiService()
        .removeContinueWatching(videoId, videoType, subVideoType);
    printLog("removeFromContinue message :==> ${successModel.message}");
  }

  Future<void> addRemoveDownload(
      BuildContext context, videoId, videoType, subVideoType) async {
    printLog("addRemoveDownload subVideoType :==> $subVideoType");
    printLog("addRemoveDownload videoType :=====> $videoType");
    printLog("addRemoveDownload videoId :=======> $videoId");
    /* Remove from Hive */
    late Box<DownloadItem> downloadBox;
    if (Constant.userID != null) {
      if (Constant.userIsKid == true) {
        downloadBox = Hive.box<DownloadItem>(
            '${Constant.hiveDownloadBox}_${Constant.userID}_KID');
      } else {
        downloadBox = Hive.box<DownloadItem>(
            '${Constant.hiveDownloadBox}_${Constant.userID}');
      }
    } else {
      downloadBox = Hive.box<DownloadItem>(Constant.hiveDownloadBox);
    }
    printLog(
        "downloadBox length :========> ${downloadBox.values.toList().length}");
    if (downloadBox.values.toList().isNotEmpty) {
      printLog(
          "downloadBox indexWhere =====> ${downloadBox.values.toList().indexWhere((downloadItem) => (downloadItem.id == videoId && downloadItem.videoType == videoType && downloadItem.subVideoType == subVideoType))}");
      await downloadBox
          .delete(downloadBox.values.toList().indexWhere((downloadItem) {
        printLog("downloadBox videoId :=======> ${downloadItem.id}");
        printLog("downloadBox videoType :=====> ${downloadItem.videoType}");
        printLog("downloadBox subVideoType :==> ${downloadItem.subVideoType}");
        return (downloadItem.id == videoId &&
            downloadItem.videoType == videoType &&
            downloadItem.subVideoType == subVideoType);
      }));
      if (downloadBox.values.toList().isEmpty) {
        downloadBox.clear();
      }
    } else {
      downloadBox.clear();
    }
    if (context.mounted) {
      Utils.showSnackbar(context, "success", "download_remove_success", true);
    }
    notifyListeners();
    /* Remove from Hive */
  }

  /* ********* Like/Dislike START ********* */
  Future<void> setLikeDislike(
    BuildContext context, {
    required subVideoType,
    required videoType,
    required videoId,
  }) async {
    if ((contentDetailModel.result?[0].isUserLike ?? 0) == 0) {
      contentDetailModel.result?[0].isUserLike = 1;
      contentDetailModel.result?[0].totalLike =
          (contentDetailModel.result?[0].totalLike ?? 0) + 1;
    } else {
      contentDetailModel.result?[0].isUserLike = 0;
      if ((contentDetailModel.result?[0].totalLike ?? 0) > 0) {
        contentDetailModel.result?[0].totalLike =
            (contentDetailModel.result?[0].totalLike ?? 0) - 1;
      }
    }
    notifyListeners();
    addRemoveLike(subVideoType, videoType, videoId);
  }

  Future<void> addRemoveLike(dynamic subVideoType, videoType, videoId) async {
    printLog("addRemoveLike subVideoType :==> $subVideoType");
    printLog("addRemoveLike videoType :=====> $videoType");
    printLog("addRemoveLike videoId :=======> $videoId");
    successModel =
        await ApiService().addRemoveLike(subVideoType, videoType, videoId);
    printLog("addRemoveLike status :===> ${successModel.status}");
    printLog("addRemoveLike message :==> ${successModel.message}");
  }
  /* ********* Like/Dislike END ********* */

  void setTabClick(String clickedOn) {
    printLog("clickedOn ===> $clickedOn");
    tabClickedOn = clickedOn;
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    successModel = SuccessModel();
    tabClickedOn = "related";
  }
}
