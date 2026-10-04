import '../utils/utils.dart';
import '../model/rentmodel.dart';
import '../utils/constant.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class PurchaselistProvider extends ChangeNotifier {
  RentModel rentModel = RentModel();
  List<Result>? contentList = [];
  bool loading = false;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setLoading(bool loading) {
    this.loading = loading;
    notifyListeners();
  }

  Future<void> getUserRentVideoList(dynamic pageNo) async {
    printLog("getUserRentVideoList userID :======> ${Constant.userID}");
    printLog("getUserRentVideoList pageNo =======> $pageNo");
    if (pageNo == 1) {
      contentList = [];
    }
    loading = true;
    rentModel = RentModel();
    rentModel = await ApiService().userRentContentList(pageNo);
    printLog("rentModel length :=1=> ${(rentModel.result?.length ?? 0)}");
    if (rentModel.status == 200) {
      setPagination(rentModel.totalRows, rentModel.totalPage,
          rentModel.currentPage, rentModel.morePage);
      if (rentModel.result != null && (rentModel.result?.length ?? 0) > 0) {
        printLog("rentModel length :=2=> ${(rentModel.result?.length ?? 0)}");
        for (var i = 0; i < (rentModel.result?.length ?? 0); i++) {
          contentList?.add(rentModel.result?[i] ?? Result());
        }
        final Map<String, Result> postMap = {};
        contentList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        contentList = postMap.values.toList();
        setLoadMore(false);
        printLog("rentModel length :=3=> ${(rentModel.result?.length ?? 0)}");
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
    rentModel = RentModel();
    loading = false;
    loadMore = false;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    isMorePage = null;
  }
}
