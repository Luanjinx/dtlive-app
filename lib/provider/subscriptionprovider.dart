import '../utils/utils.dart';
import '../model/subscriptionmodel.dart';
import '../utils/constant.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel subscriptionModel = SubscriptionModel();

  bool loading = false;

  Future setLoading(bool loading) async {
    this.loading = loading;
    notifyListeners();
  }

  Future<void> getPackages() async {
    printLog("getPackages userID :===> ${Constant.userID}");
    loading = true;
    subscriptionModel = await ApiService().subscriptionPackage();
    printLog("getPackages status :===> ${subscriptionModel.status}");
    printLog("getPackages message :==> ${subscriptionModel.message}");
    loading = false;
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearSubscriptionProvider ================>");
    subscriptionModel = SubscriptionModel();
    loading = false;
  }
}
