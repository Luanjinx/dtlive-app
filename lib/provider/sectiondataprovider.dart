import '../model/sectionbannermodel.dart';
import '../model/sectionlistmodel.dart' as section;
import '../model/successmodel.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class SectionDataProvider extends ChangeNotifier {
  SectionBannerModel sectionBannerModel = SectionBannerModel();
  section.SectionListModel sectionListModel = section.SectionListModel();
  List<section.Result>? sectionList = [];
  SuccessModel successModel = SuccessModel();

  bool loadingBanner = false, loadingSection = false;
  bool isBannerHovered = false;
  int? cBannerIndex = 0, lastTabPosition;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  Future<void> getSectionBanner(dynamic typeId, isHomePage) async {
    cBannerIndex = 0;
    printLog("getSectionBanner typeId :==> $typeId");
    printLog("getSectionBanner isHomePage :==> $isHomePage");
    loadingBanner = true;
    sectionBannerModel = SectionBannerModel();
    sectionBannerModel = await ApiService().sectionBanner(typeId, isHomePage);
    printLog("getSectionBanner message :==> ${sectionBannerModel.message}");
    loadingBanner = false;
    notifyListeners();
  }

  Future<void> clearOldData() async {
    sectionBannerModel = SectionBannerModel();
    sectionList?.clear();
    sectionList = [];
    notifyListeners();
  }

  void setLoading(bool flagLoading) {
    loadingBanner = flagLoading;
    loadingSection = flagLoading;
    notifyListeners();
  }

  void setTabPosition(int position) {
    lastTabPosition = position;
    notifyListeners();
  }

  void setCurrentBanner(int index) {
    cBannerIndex = index;
    notifyListeners();
  }

  void setBannerHovered(bool value) {
    if (isBannerHovered == value) return;
    isBannerHovered = value;
    notifyListeners();
  }

  Future<void> getSectionList(dynamic typeId, isHomePage, pageNo) async {
    printLog("getSectionList typeId :======> $typeId");
    printLog("getSectionList isHomePage :==> $isHomePage");
    printLog("getSectionList pageNo :======> $pageNo");
    if (pageNo == 1) {
      sectionList?.clear();
      sectionList = [];
    }
    loadingSection = true;
    printLog("getSectionList length :======> ${sectionList?.length}");
    sectionListModel = section.SectionListModel();
    sectionListModel =
        await ApiService().sectionList(typeId, isHomePage, pageNo);
    printLog("getSectionList message :==> ${sectionListModel.message}");
    printLog(
        "sectionListModel length :=1=> ${(sectionListModel.result?.length ?? 0)}");
    if (pageNo == 1) {
      sectionList?.clear();
      sectionList = [];
    }
    if (sectionListModel.status == 200) {
      setPagination(sectionListModel.totalRows, sectionListModel.totalPage,
          sectionListModel.currentPage, sectionListModel.morePage);
      if (sectionListModel.result != null &&
          (sectionListModel.result?.length ?? 0) > 0) {
        printLog(
            "sectionListModel length :=2=> ${(sectionListModel.result?.length ?? 0)}");
        for (var i = 0; i < (sectionListModel.result?.length ?? 0); i++) {
          sectionListModel.result?[i].scrollController = ScrollController();
          sectionList?.add(sectionListModel.result?[i] ?? section.Result());
        }
        final Map<String, section.Result> postMap = {};
        sectionList?.forEach((item) {
          final key =
              '${item.id}-${item.typeId}-${item.videoType}-${item.subVideoType}';
          postMap[key] = item;
        });
        sectionList = postMap.values.toList();
        setLoadMore(false);
        printLog(
            "sectionListModel length :=3=> ${(sectionListModel.result?.length ?? 0)}");
      } else {
        setLoadMore(false);
      }
    } else {
      setLoadMore(false);
    }
    loadingSection = false;
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

  Future<void> setBookMark(BuildContext context, position) async {
    if ((sectionBannerModel.result?[position].isBookmark ?? 0) == 0) {
      sectionBannerModel.result?[position].isBookmark = 1;
      Utils.showSnackbar(context, "success", "addwatchlistmessage", true);
    } else {
      sectionBannerModel.result?[position].isBookmark = 0;
      Utils.showSnackbar(context, "success", "removewatchlistmessage", true);
    }
    notifyListeners();
    addRemoveBookmark(
      sectionBannerModel.result?[position].subVideoType ?? 0,
      sectionBannerModel.result?[position].videoType ?? 0,
      sectionBannerModel.result?[position].id,
    );
  }

  Future<void> addRemoveBookmark(
      dynamic subVideoType, videoType, videoId) async {
    printLog("addRemoveBookmark subVideoType :==> $subVideoType");
    printLog("addRemoveBookmark videoType :=====> $videoType");
    printLog("addRemoveBookmark videoId :=======> $videoId");
    successModel =
        await ApiService().addRemoveBookmark(subVideoType, videoType, videoId);
    printLog("addRemoveBookmark status :===> ${successModel.status}");
    printLog("addRemoveBookmark message :==> ${successModel.message}");
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    loadingBanner = false;
    loadingSection = false;
    loadMore = false;
    sectionBannerModel = SectionBannerModel();
    sectionListModel = section.SectionListModel();
    successModel = SuccessModel();
    cBannerIndex = 0;
    lastTabPosition = 0;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    isMorePage = null;
  }
}
