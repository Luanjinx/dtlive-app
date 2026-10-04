import '../model/historymodel.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class SubHistoryProvider extends ChangeNotifier {
  HistoryModel historyModel = HistoryModel();
  List<Result>? historyDataList = [];

  bool loading = false;

  /* Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool loading) {
    this.loading = loading;
    notifyListeners();
  }

  Future<void> getSubscriptionList(dynamic pageNo) async {
    if (pageNo == 1) {
      historyDataList = [];
    }
    loading = true;
    historyModel = HistoryModel();
    historyModel = await ApiService().subscriptionList(pageNo);
    if (historyModel.status == 200) {
      setPagination(historyModel.totalRows, historyModel.totalPage,
          historyModel.currentPage, historyModel.morePage);
      if (historyModel.result != null &&
          (historyModel.result?.length ?? 0) > 0) {
        printLog(
            "sectionListModel length :=1=> ${(historyModel.result?.length ?? 0)}");
        for (var i = 0; i < (historyModel.result?.length ?? 0); i++) {
          historyDataList?.add(historyModel.result?[i] ?? Result());
        }
        final Map<int, Result> postMap = {};
        historyDataList?.forEach((item) {
          postMap[item.id ?? 0] = item;
        });
        historyDataList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "sectionListModel length :=2=> ${(historyModel.result?.length ?? 0)}");
      }
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
    printLog("============ clearSearchProvider ============");
    historyModel = HistoryModel();
    historyDataList?.clear();
    historyDataList = [];
  }
}
