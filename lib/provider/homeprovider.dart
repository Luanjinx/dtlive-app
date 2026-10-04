import '../model/genresmodel.dart';
import '../model/langaugemodel.dart';
import '../model/channelmodel.dart';
import '../model/sectiontypemodel.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  SectionTypeModel sectionTypeModel = SectionTypeModel();
  LangaugeModel langaugeModel = LangaugeModel();
  GenresModel genresModel = GenresModel();
  ChannelModel channelModel = ChannelModel();

  bool loading = false;
  int selectedIndex = -1;
  String currentPage = "";

  void notifyProvider() {
    notifyListeners();
  }

  Future<void> getSectionType() async {
    loading = true;
    try {
      sectionTypeModel = await ApiService().sectionType();
    } on Exception catch (e) {
      printLog("getSectionType Exception :==> $e");
    }
    printLog("getSectionType status :==> ${sectionTypeModel.status}");
    printLog("getSectionType message :==> ${sectionTypeModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> getGenres() async {
    try {
      genresModel = await ApiService().genres();
    } on Exception catch (e) {
      printLog("getGenres Exception :==> $e");
    }
    printLog("getGenres status :===> ${genresModel.status}");
    printLog("getGenres message :==> ${genresModel.message}");
    notifyListeners();
  }

  Future<void> getLanguage() async {
    try {
      langaugeModel = await ApiService().language();
    } on Exception catch (e) {
      printLog("getLanguage Exception :==> $e");
    }
    printLog("getLanguage status :===> ${langaugeModel.status}");
    printLog("getLanguage message :==> ${langaugeModel.message}");
    notifyListeners();
  }

  Future<void> getChannel() async {
    try {
      channelModel = await ApiService().channel();
    } on Exception catch (e) {
      printLog("getChannel Exception :==> $e");
    }
    printLog("getChannel status :===> ${channelModel.status}");
    printLog("getChannel message :==> ${channelModel.message}");
    notifyListeners();
  }

  Future<void> setLoading(bool isLoading) async {
    loading = isLoading;
    notifyListeners();
  }

  void setSelectedTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void setCurrentPage(String pageName) {
    currentPage = pageName;
    notifyListeners();
  }

  void homeNotifyProvider() {
    notifyListeners();
  }

  void clearProvider() {
    sectionTypeModel = SectionTypeModel();
    langaugeModel = LangaugeModel();
    genresModel = GenresModel();
    channelModel = ChannelModel();
    loading = false;
    selectedIndex = -1;
    currentPage = "";
  }
}
