import 'package:flutter/material.dart';

import '../model/referandearnhistorymodel.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';

class ReferEarnHistoryProvider extends ChangeNotifier {
  ReferEarnHistoryModel historyModel = ReferEarnHistoryModel();
  List<ReferEarnItem> historyDataList = [];

  bool loading = false;

  /* Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  Future<void> getReferEarnHistory(dynamic pageNo) async {
    if (pageNo == 1) {
      historyDataList = [];
    }
    loading = true;
    notifyListeners();
    historyModel = ReferEarnHistoryModel();
    try {
      historyModel = await ApiService().getReferEarnHistory(pageNo);
      if (historyModel.status == 200) {
        setPagination(
          historyModel.totalRows,
          historyModel.totalPage,
          historyModel.currentPage,
          historyModel.morePage,
        );
        if (historyModel.result != null &&
            (historyModel.result?.length ?? 0) > 0) {
          printLog(
            "getReferEarnHistory result length :=> ${historyModel.result?.length ?? 0}",
          );
          for (var i = 0; i < (historyModel.result?.length ?? 0); i++) {
            historyDataList.add(historyModel.result?[i] ?? ReferEarnItem());
          }
          final Map<int, ReferEarnItem> postMap = {};
          for (final item in historyDataList) {
            postMap[item.id ?? 0] = item;
          }
          historyDataList = postMap.values.toList();
          setLoadMore(false);
        }
      }
    } on Exception catch (e) {
      printLog("getReferEarnHistory Exception :=> $e");
    }
    loading = false;
    notifyListeners();
  }

  void setLoadMore(bool value) {
    printLog("setLoadMore :=> $value");
    loadMore = value;
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

  void clearProvider() {
    historyModel = ReferEarnHistoryModel();
    historyDataList.clear();
  }
}
