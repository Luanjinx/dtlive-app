import '../model/relatedcontentmodel.dart' as related;
import '../model/continuewatchingmodel.dart' as continuewatch;
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class ViewAllProvider extends ChangeNotifier {
  related.RelatedContentModel relatedContentModel =
      related.RelatedContentModel();
  List<related.Result>? relatedList = [];
  continuewatch.ContinueWatchingModel continueWatchingModel =
      continuewatch.ContinueWatchingModel();
  List<continuewatch.Result>? continueWatchList = [];

  bool loading = false;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getRelatedContent(
      dynamic typeId, videoType, videoId, subVideoType, pageNo) async {
    printLog("getRelatedContent typeId :========> $typeId");
    printLog("getRelatedContent videoType :=====> $videoType");
    printLog("getRelatedContent videoId :=======> $videoId");
    printLog("getRelatedContent subVideoType :==> $subVideoType");
    printLog("getRelatedContent pageNo :========> $pageNo");

    relatedContentModel = related.RelatedContentModel();
    loading = true;
    relatedContentModel = await ApiService()
        .relatedContent(typeId, videoType, videoId, subVideoType, pageNo);
    if (relatedContentModel.status == 200) {
      setPagination(
          relatedContentModel.totalRows,
          relatedContentModel.totalPage,
          relatedContentModel.currentPage,
          relatedContentModel.morePage);
      if (relatedContentModel.result != null &&
          (relatedContentModel.result?.length ?? 0) > 0) {
        for (var i = 0; i < (relatedContentModel.result?.length ?? 0); i++) {
          relatedList?.add(relatedContentModel.result?[i] ?? related.Result());
        }
        final Map<String, related.Result> postMap = {};
        relatedList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        relatedList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "getRelatedContent length :=2=> ${(relatedContentModel.result?.length ?? 0)}");
      }
      printLog("getRelatedContent status :===> ${relatedContentModel.status}");
      printLog("getRelatedContent message :==> ${relatedContentModel.message}");
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getContinueWatching(dynamic pageNo) async {
    printLog("getContinueWatching pageNo :========> $pageNo");

    continueWatchingModel = continuewatch.ContinueWatchingModel();
    loading = true;
    continueWatchingModel = await ApiService().getContinueWatching(pageNo);
    if (continueWatchingModel.status == 200) {
      setPagination(
          continueWatchingModel.totalRows,
          continueWatchingModel.totalPage,
          continueWatchingModel.currentPage,
          continueWatchingModel.morePage);
      if (continueWatchingModel.result != null &&
          (continueWatchingModel.result?.length ?? 0) > 0) {
        for (var i = 0; i < (continueWatchingModel.result?.length ?? 0); i++) {
          continueWatchList
              ?.add(continueWatchingModel.result?[i] ?? continuewatch.Result());
        }
        final Map<String, continuewatch.Result> postMap = {};
        continueWatchList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        continueWatchList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "getContinueWatching length :=2=> ${(continueWatchingModel.result?.length ?? 0)}");
      }
      printLog(
          "getContinueWatching status :===> ${continueWatchingModel.status}");
      printLog(
          "getContinueWatching message :==> ${continueWatchingModel.message}");
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
    relatedContentModel = related.RelatedContentModel();
    relatedList?.clear();
    relatedList = [];
    continueWatchingModel = continuewatch.ContinueWatchingModel();
    continueWatchList?.clear();
    continueWatchList = [];
    loading = false;
    loadMore = false;
    totalRows;
    totalPage;
    currentPage;
    isMorePage;
  }
}
