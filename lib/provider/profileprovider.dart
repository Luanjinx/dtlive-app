import '../model/devicesyncmodel.dart';
import '../model/profilemodel.dart';
import '../model/successmodel.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileModel profileModel = ProfileModel();
  SuccessModel successModel = SuccessModel();
  DeviceSyncModel deviceSyncModel = DeviceSyncModel();
  SuccessModel deviceLogoutModel = SuccessModel();

  bool loading = false,
      loadingUpdate = false,
      loadingLogout = false,
      loadingPCCheck = false;

  Future<void> getProfile(BuildContext context) async {
    printLog("getProfile userID :==> ${Constant.userID}");

    loading = true;
    if (Constant.userID != null) {
      try {
        profileModel = await ApiService().profile();
      } on Exception catch (e) {
        printLog("getProfile Exception :===> $e");
      }
      printLog("getProfile status :===> ${profileModel.status}");
      printLog("getProfile message :==> ${profileModel.message}");
      if (profileModel.status == 200 &&
          profileModel.result != null &&
          (profileModel.result?.length ?? 0) > 0) {
        Utils.saveUserPaymentCreds(
          userID: profileModel.result?[0].id.toString(),
          userName: profileModel.result?[0].userName.toString(),
          fullName: profileModel.result?[0].fullName.toString(),
          userEmail: profileModel.result?[0].email.toString(),
          userMobile: profileModel.result?[0].mobileNumber.toString(),
        );
        Utils.updatePremium(profileModel.result?[0].isBuy.toString() ?? "0");
        if (context.mounted) {
          printLog("========= loadAds =========");
          Utils.loadAds(context);
        }
      } else {
        printLog("<<<<<<<< USER NOT FOUND >>>>>>>>");
        // if (context.mounted) {
        //   Utils.openLogin(context: context, newPage: "");
        // }
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getUpdateProfile(
    dynamic name,
    email,
    mobileNumber,
    pickedImage,
    avatarId,
  ) async {
    printLog("getUpdateProfile userID :=======> ${Constant.userID}");
    printLog("getUpdateProfile name :=========> $name");
    printLog("getUpdateProfile email :========> $email");
    printLog("getUpdateProfile mobileNumber :=> $mobileNumber");
    printLog("getUpdateProfile pickedImage :==> $pickedImage");
    printLog("getUpdateProfile avatarId :=====> $avatarId");
    successModel = SuccessModel();
    loading = true;
    successModel = await ApiService().updateProfile(
      name,
      email,
      mobileNumber,
      pickedImage,
      avatarId,
    );
    printLog("getUpdateProfile status :===> ${successModel.status}");
    printLog("getUpdateProfile message :==> ${successModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> getUpdateDataForPayment(
    dynamic fullName,
    email,
    mobileNumber,
  ) async {
    printLog("getUpdateDataForPayment fullname :==> $fullName");
    printLog("getUpdateDataForPayment email :=====> $email");
    printLog("getUpdateDataForPayment mobile :====> $mobileNumber");
    successModel = SuccessModel();
    loadingUpdate = true;
    successModel = await ApiService().updateDataForPayment(
      fullName,
      email,
      mobileNumber,
    );
    printLog("getUpdateDataForPayment status :==> ${successModel.status}");
    printLog("getUpdateDataForPayment message :==> ${successModel.message}");
    loadingUpdate = false;
    notifyListeners();
  }

  Future<void> getUpdatePCPassword(dynamic password) async {
    printLog("getUpdatePCPassword password :==> $password");
    successModel = SuccessModel();
    loadingPCCheck = true;
    try {
      successModel = await ApiService().updatePCPassword(password);
    } on Exception catch (e) {
      printLog("getUpdatePCPassword Exception :===> $e");
    }
    printLog("getUpdatePCPassword status :==> ${successModel.status}");
    printLog("getUpdatePCPassword message :==> ${successModel.message}");
    loadingPCCheck = false;
    notifyListeners();
  }

  Future<void> parentControlCheckPassword(dynamic password) async {
    printLog("parentControlCheckPassword password :==> $password");
    successModel = SuccessModel();
    loadingPCCheck = true;
    successModel = await ApiService().parentControlCheckPassword(password);
    printLog("parentControlCheckPassword status :==> ${successModel.status}");
    printLog("parentControlCheckPassword message :==> ${successModel.message}");
    loadingPCCheck = false;
    notifyListeners();
  }

  Future<void> getDeviceSyncList() async {
    loading = true;
    deviceSyncModel = await ApiService().getDeviceSyncList();
    printLog("getDeviceSyncList status :===> ${deviceSyncModel.status}");
    printLog("getDeviceSyncList message :==> ${deviceSyncModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> logoutDevice(
    dynamic deviceSyncId,
    deviceType,
    deviceToken,
    deviceId,
  ) async {
    printLog("logoutDevice deviceSyncId :===> $deviceSyncId");
    printLog("logoutDevice deviceType :=====> $deviceType");
    printLog("logoutDevice deviceToken :====> $deviceToken");
    printLog("logoutDevice deviceId :=======> $deviceId");
    loadingLogout = true;
    deviceLogoutModel = await ApiService().logoutDeviceSync(
      deviceSyncId,
      deviceType,
      deviceToken,
      deviceId,
    );
    printLog("logoutDevice status :===> ${deviceLogoutModel.status}");
    printLog("logoutDevice message :==> ${deviceLogoutModel.message}");
    loadingLogout = false;
    notifyListeners();
  }

  void setUpdateLoading(bool isLoading) {
    loadingUpdate = isLoading;
    notifyListeners();
  }

  void setPCLoading(bool isLoading) {
    loadingPCCheck = isLoading;
    notifyListeners();
  }

  void notifyProvider() {
    notifyListeners();
  }

  void clearProvider() {
    profileModel = ProfileModel();
    successModel = SuccessModel();
    deviceSyncModel = DeviceSyncModel();
    deviceLogoutModel = SuccessModel();
    loading = false;
    loadingUpdate = false;
  }
}
