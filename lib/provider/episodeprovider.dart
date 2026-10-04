import '../model/episodebyseasonmodel.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class EpisodeProvider extends ChangeNotifier {
  EpisodeBySeasonModel episodeBySeasonModel = EpisodeBySeasonModel();
  List<Result>? episodeList = [];

  bool loading = false;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getEpisodeBySeason(dynamic seasonId, showId, pageNo) async {
    printLog("getEpisodeBySeason seasonId =====> $seasonId");
    printLog("getEpisodeBySeason showId =======> $showId");
    printLog("getEpisodeBySeason pageNo =======> $pageNo");
    if (pageNo == 1) {
      episodeList?.clear();
      episodeList = [];
    }
    loading = true;
    episodeBySeasonModel = EpisodeBySeasonModel();
    episodeBySeasonModel =
        await ApiService().episodeBySeason(seasonId, showId, pageNo);
    printLog(
        "episodeBySeasonModel length :=1=> ${(episodeBySeasonModel.result?.length ?? 0)}");
    if (episodeBySeasonModel.status == 200) {
      setPagination(
          episodeBySeasonModel.totalRows,
          episodeBySeasonModel.totalPage,
          episodeBySeasonModel.currentPage,
          episodeBySeasonModel.morePage);
      if (episodeBySeasonModel.result != null &&
          (episodeBySeasonModel.result?.length ?? 0) > 0) {
        printLog(
            "episodeBySeasonModel length :=2=> ${(episodeBySeasonModel.result?.length ?? 0)}");
        for (var i = 0; i < (episodeBySeasonModel.result?.length ?? 0); i++) {
          episodeList?.add(episodeBySeasonModel.result?[i] ?? Result());
        }
        final Map<int, Result> postMap = {};
        episodeList?.forEach((item) {
          postMap[item.id ?? 0] = item;
        });
        episodeList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "episodeBySeasonModel length :=3=> ${(episodeBySeasonModel.result?.length ?? 0)}");
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

  void clearOldData() {
    episodeList?.clear();
    episodeList = [];
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
    episodeBySeasonModel = EpisodeBySeasonModel();
    loadMore = false;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    isMorePage = null;
  }
}
