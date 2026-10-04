import '../model/avatarmodel.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class AvatarProvider extends ChangeNotifier {
  AvatarModel avatarModel = AvatarModel();

  bool loading = false;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> getAvatar() async {
    loading = true;
    avatarModel = await ApiService().getAvatar();
    printLog("getAvatar status :==> ${avatarModel.status}");
    loading = false;
    notifyListeners();
  }

  void clearProvider() {
    avatarModel = AvatarModel();
  }
}
