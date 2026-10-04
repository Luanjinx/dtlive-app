import 'package:flutter/material.dart';
import '../utils/utils.dart';

class VideoDownloadProvider extends ChangeNotifier {
  int dProgress = 0;
  int? seasonClickIndex;
  int? itemId;
  bool loading = false;

  double _progress = 0.0;

  double get encryptProgress => _progress;

  void setEncryptProgress(double newProgress) {
    _progress = newProgress;
    notifyListeners(); // Notify listeners of the change
  }

  void setDownloadProgress(int progress, int itemId) {
    loading = (progress != -1);
    dProgress = progress;
    notifyListeners();
    // printLog('setDownloadProgress dProgress ==============> $dProgress');
  }

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  void setCurrentDownload(int? itemId) {
    this.itemId = itemId;
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    dProgress = 0;
    itemId = null;
    loading = false;
  }

  void setSelectedSeason(int index) {
    seasonClickIndex = index;
    notifyListeners();
  }

  void notifyProvider() {
    notifyListeners();
  }
}
