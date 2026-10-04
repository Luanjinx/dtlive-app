import 'package:flutter/material.dart';

import '../model/successmodel.dart' as successdata;
import '../model/watchlistmodel.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';

class WatchlistProvider extends ChangeNotifier {
  WatchlistModel watchlistModel = WatchlistModel();
  successdata.SuccessModel successModel = successdata.SuccessModel();
  List<Result>? watchlistDataList = [];

  bool loading = false;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getWatchlist(dynamic pageNo) async {
    if (pageNo == 1) {
      watchlistDataList?.clear();
      watchlistDataList = [];
    }
    watchlistModel = WatchlistModel();
    loading = true;
    watchlistModel = await ApiService().watchlist(pageNo);
    if (watchlistModel.status == 200) {
      setPagination(
        watchlistModel.totalRows,
        watchlistModel.totalPage,
        watchlistModel.currentPage,
        watchlistModel.morePage,
      );
      if (watchlistModel.result != null &&
          (watchlistModel.result?.length ?? 0) > 0) {
        for (var i = 0; i < (watchlistModel.result?.length ?? 0); i++) {
          watchlistDataList?.add(watchlistModel.result?[i] ?? Result());
        }
        final Map<String, Result> postMap = {};
        watchlistDataList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        watchlistDataList = postMap.values.toList();
        setLoadMore(false);
        printLog(
          "getWatchlist length :=2=> ${(watchlistDataList?.length ?? 0)}",
        );
      }
      printLog("getWatchlist status :===> ${watchlistModel.status}");
      printLog("getWatchlist message :==> ${watchlistModel.message}");
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
    int? totalRows,
    int? totalPage,
    int? currentPage,
    bool? morePage,
  ) {
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

  Future<void> setBookMark(
    BuildContext context,
    position,
    subVideoType,
    videoType,
    videoId,
  ) async {
    loading = true;
    printLog("setBookMark typeId :==> $subVideoType");
    printLog("setBookMark videoType :==> $videoType");
    printLog("setBookMark videoId :==> $videoId");
    printLog(
      "watchlistModel videoId :==> ${(watchlistDataList?[position].id ?? 0)}",
    );
    if ((watchlistDataList?[position].isBookmark ?? 0) == 0) {
      watchlistDataList?[position].isBookmark = 1;
      Utils.showSnackbar(context, "success", "addwatchlistmessage", true);
    } else {
      watchlistDataList?[position].isBookmark = 0;
      watchlistDataList?.removeAt(position);
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
    successModel = await ApiService().addRemoveBookmark(
      subVideoType,
      videoType,
      videoId,
    );
    printLog("getAddBookMark status :===> ${successModel.status}");
    printLog("getAddBookMark message :==> ${successModel.message}");
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    watchlistModel = WatchlistModel();
    successModel = successdata.SuccessModel();
    watchlistDataList?.clear();
    watchlistDataList = [];
    loading = false;
    loadMore = false;
    totalRows;
    totalPage;
    currentPage;
    isMorePage;
  }
}
