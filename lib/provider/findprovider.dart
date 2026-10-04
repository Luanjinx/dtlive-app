import '../model/searchmodel.dart' as search;
import '../model/successmodel.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class FindProvider extends ChangeNotifier {
  SuccessModel successModel = SuccessModel();
  search.SearchModel searchModel = search.SearchModel();
  List<search.Result>? searchDataList = [];

  /* For Speech Search */
  bool speechEnabled = false, isListening = false;
  String lastWords = '';

  bool loadingSearch = false;

  /* Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  void setSpeechStatus(bool isEnable) {
    speechEnabled = isEnable;
    notifyListeners();
  }

  Future<void> setSpeechListening(bool isListening) async {
    this.isListening = isListening;
    printLog("isListening ==> $isListening");
    notifyListeners();
  }

  void setSpeechLastWord(String lastWord) {
    lastWords = lastWord;
    notifyListeners();
  }

  void setSearchLoading(bool isLoading) {
    loadingSearch = isLoading;
    notifyListeners();
  }

  Future clearSearchData() async {
    searchDataList?.clear();
    searchDataList = [];
    notifyListeners();
  }

  Future<void> getSearchContent(dynamic searchText, pageNo) async {
    printLog("getSearchContent searchText :===> $searchText");
    printLog("getSearchContent pageNo :=======> $pageNo");
    if (pageNo == 1) {
      searchDataList = [];
    }
    loadingSearch = true;
    searchModel = search.SearchModel();
    searchModel = await ApiService().searchContent(searchText, pageNo);
    if (searchModel.status == 200) {
      setPagination(searchModel.totalRows, searchModel.totalPage,
          searchModel.currentPage, searchModel.morePage);
      if (searchModel.result != null && (searchModel.result?.length ?? 0) > 0) {
        printLog(
            "getSearchContent length :=1=> ${(searchModel.result?.length ?? 0)}");
        for (var i = 0; i < (searchModel.result?.length ?? 0); i++) {
          searchDataList?.add(searchModel.result?[i] ?? search.Result());
        }
        final Map<String, search.Result> postMap = {};
        searchDataList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        searchDataList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "getSearchContent length :=2=> ${(searchModel.result?.length ?? 0)}");
      }
    }
    loadingSearch = false;
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

  void notifyProvider() {
    notifyListeners();
  }

  void clearProvider() {
    printLog("============ clearProvider ============");
    loadingSearch = false;
    lastWords = '';
    successModel = SuccessModel();
    searchModel = search.SearchModel();
    searchDataList?.clear();
    searchDataList = [];
    speechEnabled = false;
    isListening = false;

    /* Pagination */
    loadMore = false;
    totalRows;
    totalPage;
    currentPage;
    isMorePage;
  }
}
