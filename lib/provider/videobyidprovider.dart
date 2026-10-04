import '../model/castdetailmodel.dart';
import '../model/contentbyidmodel.dart' as content;
import '../utils/constant.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class VideoByIDProvider extends ChangeNotifier {
  CastDetailModel castDetailModel = CastDetailModel();
  content.ContentByIdModel contentByIdModel = content.ContentByIdModel();
  List<content.Result>? contentList = [];

  bool loading = false;
  String? currentCatId, currentLangId, currentChannelId;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getCastDetails(dynamic castID) async {
    loading = true;
    castDetailModel = await ApiService().getCastDetails(castID);
    printLog("getCastDetails status :==> ${castDetailModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> getVideoByCategory(dynamic categoryID, pageNo) async {
    currentCatId = categoryID.toString();
    notifyListeners();
    printLog("getVideoByCategory userID :======> ${Constant.userID}");
    printLog("getVideoByCategory categoryID :==> $categoryID");
    printLog("getVideoByCategory pageNo =======> $pageNo");
    if (pageNo == 1) {
      contentList = [];
    }
    loading = true;
    contentByIdModel = content.ContentByIdModel();
    contentByIdModel = await ApiService().contentByCategory(categoryID, pageNo);
    printLog(
        "contentByIdModel length :=1=> ${(contentByIdModel.result?.length ?? 0)}");
    if (contentByIdModel.status == 200) {
      setPagination(contentByIdModel.totalRows, contentByIdModel.totalPage,
          contentByIdModel.currentPage, contentByIdModel.morePage);
      if (contentByIdModel.result != null &&
          (contentByIdModel.result?.length ?? 0) > 0) {
        printLog(
            "contentByIdModel length :=2=> ${(contentByIdModel.result?.length ?? 0)}");
        for (var i = 0; i < (contentByIdModel.result?.length ?? 0); i++) {
          contentList?.add(contentByIdModel.result?[i] ?? content.Result());
        }
        final Map<String, content.Result> postMap = {};
        contentList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        contentList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "contentByIdModel length :=3=> ${(contentByIdModel.result?.length ?? 0)}");
      } else {
        setLoadMore(false);
      }
    } else {
      setLoadMore(false);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getVideoByLanguage(dynamic languageID, pageNo) async {
    currentLangId = languageID.toString();
    notifyListeners();
    printLog("getVideoByLanguage userID :======> ${Constant.userID}");
    printLog("getVideoByLanguage languageID :==> $languageID");
    printLog("getVideoByLanguage pageNo =======> $pageNo");
    if (pageNo == 1) {
      contentList = [];
    }
    loading = true;
    contentByIdModel = content.ContentByIdModel();
    contentByIdModel = await ApiService().contentByLanguage(languageID, pageNo);
    printLog(
        "contentByIdModel length :=1=> ${(contentByIdModel.result?.length ?? 0)}");
    if (contentByIdModel.status == 200) {
      setPagination(contentByIdModel.totalRows, contentByIdModel.totalPage,
          contentByIdModel.currentPage, contentByIdModel.morePage);
      if (contentByIdModel.result != null &&
          (contentByIdModel.result?.length ?? 0) > 0) {
        printLog(
            "contentByIdModel length :=2=> ${(contentByIdModel.result?.length ?? 0)}");
        for (var i = 0; i < (contentByIdModel.result?.length ?? 0); i++) {
          contentList?.add(contentByIdModel.result?[i] ?? content.Result());
        }
        final Map<String, content.Result> postMap = {};
        contentList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        contentList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "contentByIdModel length :=3=> ${(contentByIdModel.result?.length ?? 0)}");
      } else {
        setLoadMore(false);
      }
    } else {
      setLoadMore(false);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getVideoByChannel(dynamic channelID, pageNo) async {
    currentChannelId = channelID.toString();
    notifyListeners();
    printLog("getVideoByChannel userID :=====> ${Constant.userID}");
    printLog("getVideoByChannel channelID :==> $channelID");
    printLog("getVideoByChannel pageNo ======> $pageNo");
    if (pageNo == 1) {
      contentList = [];
    }
    loading = true;
    contentByIdModel = content.ContentByIdModel();
    contentByIdModel = await ApiService().contentByChannel(channelID, pageNo);
    printLog(
        "contentByIdModel length :=1=> ${(contentByIdModel.result?.length ?? 0)}");
    if (contentByIdModel.status == 200) {
      setPagination(contentByIdModel.totalRows, contentByIdModel.totalPage,
          contentByIdModel.currentPage, contentByIdModel.morePage);
      if (contentByIdModel.result != null &&
          (contentByIdModel.result?.length ?? 0) > 0) {
        printLog(
            "contentByIdModel length :=2=> ${(contentByIdModel.result?.length ?? 0)}");
        for (var i = 0; i < (contentByIdModel.result?.length ?? 0); i++) {
          contentList?.add(contentByIdModel.result?[i] ?? content.Result());
        }
        final Map<String, content.Result> postMap = {};
        contentList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        contentList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "contentByIdModel length :=3=> ${(contentByIdModel.result?.length ?? 0)}");
      } else {
        setLoadMore(false);
      }
    } else {
      setLoadMore(false);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getVideoByCast(dynamic castID, pageNo) async {
    currentChannelId = castID.toString();
    notifyListeners();
    printLog("getVideoByCast userID :=====> ${Constant.userID}");
    printLog("getVideoByCast castID :=====> $castID");
    printLog("getVideoByCast pageNo ======> $pageNo");
    if (pageNo == 1) {
      contentList = [];
    }
    loading = true;
    contentByIdModel = content.ContentByIdModel();
    contentByIdModel = await ApiService().contentByCast(castID, pageNo);
    printLog(
        "contentByIdModel length :=1=> ${(contentByIdModel.result?.length ?? 0)}");
    if (contentByIdModel.status == 200) {
      setPagination(contentByIdModel.totalRows, contentByIdModel.totalPage,
          contentByIdModel.currentPage, contentByIdModel.morePage);
      if (contentByIdModel.result != null &&
          (contentByIdModel.result?.length ?? 0) > 0) {
        printLog(
            "contentByIdModel length :=2=> ${(contentByIdModel.result?.length ?? 0)}");
        for (var i = 0; i < (contentByIdModel.result?.length ?? 0); i++) {
          contentList?.add(contentByIdModel.result?[i] ?? content.Result());
        }
        final Map<String, content.Result> postMap = {};
        contentList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        contentList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "contentByIdModel length :=3=> ${(contentByIdModel.result?.length ?? 0)}");
      } else {
        setLoadMore(false);
      }
    } else {
      setLoadMore(false);
    }
    loading = false;
    notifyListeners();
  }

  void setLoadMore(bool loadMore) {
    printLog("setLoadMore loadMore :=> $loadMore");
    this.loadMore = loadMore;
    notifyListeners();
  }

  void setPagination(
      int? totalRows, int? totalPage, int? currentPage, bool? morePage) {
    printLog("setPagination currentPage :==> $currentPage");
    printLog("setPagination totalRows :====> $totalRows");
    printLog("setPagination totalPage :====> $totalPage");
    printLog("setPagination morePage :=====> $morePage");
    this.currentPage = currentPage;
    this.totalRows = totalRows;
    this.totalPage = totalPage;
    isMorePage = morePage;
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    contentByIdModel = content.ContentByIdModel();
    castDetailModel = CastDetailModel();
    loading = false;
    loadMore = false;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    isMorePage = null;
  }
}
