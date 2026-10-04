import '../model/subscriptionmodel.dart';
import '../utils/utils.dart';
import 'package:flutter/material.dart';
import '../webservice/apiservices.dart';

class MySubscribedPlanProvider extends ChangeNotifier {
  SubscriptionModel mySubscriptionModel = SubscriptionModel();
  SubscriptionModel upcomingPlanModel = SubscriptionModel();

  bool loading = false;

  Future setLoading(bool value) async {
    loading = value;
    notifyListeners();
  }

  Future<void> getMyPlan() async {
    loading = true;
    SubscriptionModel subscriptionModel = await ApiService()
        .subscriptionPackage();
    printLog("getMyPlan status :===> ${subscriptionModel.status}");
    printLog("getMyPlan message :==> ${subscriptionModel.message}");
    mySubscriptionModel = SubscriptionModel();
    mySubscriptionModel.result = [];
    upcomingPlanModel = SubscriptionModel();
    upcomingPlanModel.result = [];
    List<Result> allPlans = subscriptionModel.result ?? [];

    // Get the active plan
    Result? activePlan = allPlans.firstWhere(
      (plan) => plan.isActivePlan == 1,
      orElse: () => Result(),
    );
    mySubscriptionModel.result = [activePlan];

    // Get upcoming plans
    List<Result> upcomingPlans = allPlans
        .where((plan) => plan.isBuy == 1 && plan.isActivePlan == 0)
        .toList();
    upcomingPlanModel.result = upcomingPlans;

    printLog(
      "getMyPlan current plan =====> ${mySubscriptionModel.result?.length}",
    );
    printLog(
      "getMyPlan upcoming plan ====> ${upcomingPlanModel.result?.length}",
    );

    loading = false;
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    loading = false;
    upcomingPlanModel = SubscriptionModel();
    mySubscriptionModel = SubscriptionModel();
  }
}
