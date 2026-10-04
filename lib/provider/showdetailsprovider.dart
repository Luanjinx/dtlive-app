import '../model/episodebyseasonmodel.dart' as episode;
import '../model/contentdetailmodel.dart';
import '../model/relatedcontentmodel.dart';
import '../model/successmodel.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class ShowDetailsProvider extends ChangeNotifier {
  SuccessModel successModel = SuccessModel();
  ContentDetailModel contentDetailModel = ContentDetailModel();
  RelatedContentModel relatedContentModel = RelatedContentModel();
  List<episode.Result>? episodeList = [];

  bool loading = false;
  int seasonPos = 0, mCurrentEpiPos = -1;
  String tabClickedOn = "related";

  bool relatedLoading = false;
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

  Future<void> setEpisodeBySeason(List<episode.Result>? episodeList) async {
    this.episodeList = [];
    final Map<int, episode.Result> postMap = {};
    episodeList?.forEach((item) {
      postMap[item.id ?? 0] = item;
    });
    this.episodeList = postMap.values.toList();
    printLog(
        "setEpisodeBySeason episodeList ================> ${this.episodeList?.length}");
    getLastWatchedEpisode();
    notifyListeners();
  }

  void getLastWatchedEpisode() {
    for (var i = 0; i < (episodeList?.length ?? 0); i++) {
      if ((episodeList?[i].stopTime ?? 0) > 0) {
        if (episodeList?[i].videoDuration != null) {
          if ((episodeList?[i].videoDuration ?? 0) > 0 &&
              (episodeList?[i].videoDuration ?? 0) !=
                  (episodeList?[i].stopTime ?? 0) &&
              (episodeList?[i].videoDuration ?? 0) >
                  (episodeList?[i].stopTime ?? 0)) {
            mCurrentEpiPos = i;
            return;
          } else {
            mCurrentEpiPos = 0;
          }
        }
      }
    }
    if ((episodeList?.length ?? 0) > 0 && mCurrentEpiPos == -1) {
      mCurrentEpiPos = 0;
    }
    printLog("mCurrentEpiPos ========> $mCurrentEpiPos");
  }

  Future<void> setBookMark(
      BuildContext context, subVideoType, videoType, videoId) async {
    loading = true;
    if ((contentDetailModel.result?[0].isBookmark ?? 0) == 0) {
      contentDetailModel.result?[0].isBookmark = 1;
      Utils.showSnackbar(context, "success", "addwatchlistmessage", true);
    } else {
      contentDetailModel.result?[0].isBookmark = 0;
      Utils.showSnackbar(context, "success", "removewatchlistmessage", true);
    }
    loading = false;
    notifyListeners();
    getAddBookMark(subVideoType, videoType, videoId);
  }

  Future<void> getAddBookMark(dynamic subVideoType, videoType, videoId) async {
    printLog("getAddBookMark subVideoType :==> $subVideoType");
    printLog("getAddBookMark videoType :=====> $videoType");
    printLog("getAddBookMark videoId :=======> $videoId");
    successModel =
        await ApiService().addRemoveBookmark(subVideoType, videoType, videoId);
    printLog("getAddBookMark status :===> ${successModel.status}");
    printLog("getAddBookMark message :==> ${successModel.message}");
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

  Future<void> setSeasonPosition(int position) async {
    printLog("setSeasonPosition ===> $position");
    mCurrentEpiPos = -1;
    getLastWatchedEpisode();
    seasonPos = position;
    notifyListeners();
  }

  void setTabClick(String clickedOn) {
    printLog("clickedOn ===> $clickedOn");
    tabClickedOn = clickedOn;
    notifyListeners();
  }

  Future notifyProvider() async {
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    loading = false;
    episodeList?.clear();
    episodeList = [];
    successModel = SuccessModel();
    seasonPos = 0;
    mCurrentEpiPos = -1;
    tabClickedOn = "related";
  }
}
