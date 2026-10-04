import 'package:flutter/material.dart';

import '../model/razorpayordermodel.dart';
import '../model/wallettransactionmodel.dart';
import '../utils/utils.dart';
import '../model/couponlistmodel.dart';
import '../model/couponmodel.dart';
import '../model/paymentoptionmodel.dart';
import '../model/paytmmodel.dart';
import '../model/successmodel.dart';
import '../utils/constant.dart';
import '../webservice/apiservices.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentOptionModel paymentOptionModel = PaymentOptionModel();
  PayTmModel payTmModel = PayTmModel();
  SuccessModel updateStatusModel = SuccessModel();
  SuccessModel transSuccessModel = SuccessModel();
  CouponModel couponModel = CouponModel();
  CouponListModel couponListModel = CouponListModel();
  RazorpayOrderModel razorpayOrderModel = RazorpayOrderModel();
  AddWalletAmountModel addWalletAmountModel = AddWalletAmountModel();

  bool loading = false,
      payLoading = false,
      couponLoading = false,
      couponListLoading = false,
      razorpayLoading = false;
  String? currentPayment = "", finalAmount = "";

  /* Current Payment Params */
  String? payType,
      itemId,
      producerId,
      itemTitle,
      typeId,
      videoType,
      subVideoType,
      productPackage,
      currency,
      paymentId;
  /* Current Payment Parameters */

  Future<void> setLoading(bool loading) async {
    this.loading = loading;
    notifyListeners();
  }

  Future<void> setCurrentPayParams({
    required String payType,
    required String itemId,
    required String price,
    required String itemTitle,
    required String typeId,
    required String videoType,
    required String productPackage,
    required String currency,
    required String paymentId,
  }) async {
    this.payType = payType;
    this.itemId = itemId;
    finalAmount = price;
    this.itemTitle = itemTitle;
    this.typeId = typeId;
    this.videoType = videoType;
    this.productPackage = productPackage;
    this.currency = currency;
    this.paymentId = paymentId;

    Utils.savePayParams(
      payType: payType,
      itemId: itemId,
      price: price,
      itemTitle: itemTitle,
      typeId: typeId,
      videoType: videoType,
      productPackage: productPackage,
      currency: currency,
      paymentId: paymentId,
    );
    notifyListeners();
  }

  Future<void> getPaymentOption() async {
    loading = true;
    paymentOptionModel = await ApiService().getPaymentOption();
    printLog("getPaymentOption status :==> ${paymentOptionModel.status}");
    printLog("getPaymentOption message :==> ${paymentOptionModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> getCreatedRazorpayOrder(dynamic price) async {
    printLog("getCreatedRazorpayOrder price :====> $price");
    razorpayLoading = true;
    razorpayOrderModel = await ApiService().createRazorpayOrder(price);
    printLog(
      "getCreatedRazorpayOrder status :===> ${razorpayOrderModel.status}",
    );
    printLog(
      "getCreatedRazorpayOrder message :==> ${razorpayOrderModel.message}",
    );
    razorpayLoading = false;
    notifyListeners();
  }

  Future<void> applyPackageCouponCode(dynamic couponCode, packageId) async {
    printLog("applyPackageCouponCode couponCode :==> $couponCode");
    printLog("applyPackageCouponCode packageId :==> $packageId");
    couponLoading = true;
    couponModel = await ApiService().applyPackageCoupon(couponCode, packageId);
    printLog("applyPackageCouponCode status :==> ${couponModel.status}");
    printLog("applyPackageCouponCode message :==> ${couponModel.message}");
    couponLoading = false;
    notifyListeners();
  }

  Future<void> applyRentCouponCode(
    dynamic couponCode,
    videoId,
    typeId,
    videoType,
    price,
  ) async {
    printLog("applyRentCouponCode couponCode :==> $couponCode");
    printLog("applyRentCouponCode videoId :==> $videoId");
    printLog("applyRentCouponCode typeId :==> $typeId");
    printLog("applyRentCouponCode videoType :==> $videoType");
    printLog("applyRentCouponCode price :==> $price");
    couponLoading = true;
    couponModel = await ApiService().applyRentCoupon(
      couponCode,
      videoId,
      typeId,
      videoType,
      price,
    );
    printLog("applyRentCouponCode status :==> ${couponModel.status}");
    printLog("applyRentCouponCode message :==> ${couponModel.message}");
    couponLoading = false;
    notifyListeners();
  }

  Future<void> getCouponList(dynamic type) async {
    printLog("getCouponList type :==> $type");
    couponListLoading = true;
    notifyListeners();
    couponListModel = await ApiService().getCouponList(type, 1);
    printLog("getCouponList status :==> ${couponListModel.status}");
    printLog("getCouponList message :==> ${couponListModel.message}");
    couponListLoading = false;
    notifyListeners();
  }

  void setFinalAmount(String? amount) {
    finalAmount = amount;
    printLog("setFinalAmount finalAmount :==> $finalAmount");
    notifyListeners();
  }

  Future<void> getPaytmToken(
    dynamic merchantID,
    orderId,
    custmoreID,
    channelID,
    txnAmount,
    website,
    callbackURL,
    industryTypeID,
  ) async {
    printLog("getPaytmToken merchantID :=======> $merchantID");
    printLog("getPaytmToken orderId :==========> $orderId");
    printLog("getPaytmToken custmoreID :=======> $custmoreID");
    printLog("getPaytmToken channelID :========> $channelID");
    printLog("getPaytmToken txnAmount :========> $txnAmount");
    printLog("getPaytmToken website :==========> $merchantID");
    printLog("getPaytmToken callbackURL :======> $merchantID");
    printLog("getPaytmToken industryTypeID :===> $industryTypeID");
    loading = true;
    payTmModel = await ApiService().getPaytmToken(
      merchantID,
      orderId,
      custmoreID,
      channelID,
      txnAmount,
      website,
      callbackURL,
      industryTypeID,
    );
    printLog("getPaytmToken status :===> ${payTmModel.status}");
    printLog("getPaytmToken message :==> ${payTmModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> updateTransStatus(
    dynamic type, // 1-Package Transaction, 2-Rent Transaction
    transId,
    transStatus, // 1-Processing, 2-Success, 3-Failed
  ) async {
    printLog("updateTransStatus userID :======> ${Constant.userID}");
    printLog("updateTransStatus type :========> $type");
    printLog("updateTransStatus transId :=====> $transId");
    printLog("updateTransStatus transStatus :=> $transStatus");
    payLoading = true;
    updateStatusModel = SuccessModel();
    updateStatusModel = await ApiService().updateTransaction(
      type,
      transId,
      transStatus,
    );
    printLog("updateTransStatus status :===> ${updateStatusModel.status}");
    printLog("updateTransStatus message :==> ${updateStatusModel.message}");
    payLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(
    dynamic packageId,
    description,
    amount,
    paymentId,
    couponCode, {
    int paymentType = 0,
  }) async {
    printLog("addTransaction userID :======> ${Constant.userID}");
    printLog("addTransaction packageId :===> $packageId");
    printLog("addTransaction couponCode :==> $couponCode");
    printLog("addTransaction paymentType :=> $paymentType");
    payLoading = true;
    transSuccessModel = SuccessModel();
    transSuccessModel = await ApiService().addTransaction(
      packageId,
      description,
      amount,
      paymentId,
      couponCode,
      paymentType: paymentType,
    );
    printLog("addTransaction status :===> ${transSuccessModel.status}");
    printLog("addTransaction message :==> ${transSuccessModel.message}");
    payLoading = false;
    notifyListeners();
  }

  Future<void> addRentTransaction(
    dynamic producerId,
    videoId,
    price,
    typeId,
    videoType,
    subVideoType,
    transactionId,
    description,
    couponCode, {
    int paymentType = 0,
  }) async {
    printLog("addRentTransaction userID :======> ${Constant.userID}");
    printLog("addRentTransaction producerId :==> $producerId");
    printLog("addRentTransaction videoId :=====> $videoId");
    printLog("addRentTransaction couponCode :==> $couponCode");
    printLog("addRentTransaction paymentType :=> $paymentType");
    payLoading = true;
    transSuccessModel = SuccessModel();
    transSuccessModel = await ApiService().addRentTransaction(
      producerId,
      videoId,
      price,
      typeId,
      videoType,
      subVideoType,
      transactionId,
      description,
      couponCode,
      paymentType: paymentType,
    );
    printLog("addRentTransaction status :===> ${transSuccessModel.status}");
    printLog("addRentTransaction message :==> ${transSuccessModel.message}");
    payLoading = false;
    notifyListeners();
  }

  void setCurrentPayment(String? payment) {
    currentPayment = payment;
    notifyListeners();
  }

  /* ── Add Wallet Amount ─────────────────────────────────── */

  Future<bool> addWalletAmount({
    required String userId,
    required String amount,
    required String transactionId,
  }) async {
    printLog("addWalletAmount userId :========> $userId");
    printLog("addWalletAmount amount :========> $amount");
    printLog("addWalletAmount transactionId :=> $transactionId");
    payLoading = true;
    addWalletAmountModel = AddWalletAmountModel();
    notifyListeners();
    try {
      addWalletAmountModel = await ApiService().addWalletAmount(
        userId,
        amount,
        transactionId,
      );
      printLog("addWalletAmount status :=> ${addWalletAmountModel.status}");
      printLog("addWalletAmount message :=> ${addWalletAmountModel.message}");
    } on Exception catch (e) {
      printLog("addWalletAmount Exception :=> $e");
    }
    payLoading = false;
    notifyListeners();
    return addWalletAmountModel.status == 200;
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    currentPayment = "";
    finalAmount = "";
    payType = null;
    itemId = null;
    itemTitle = null;
    typeId = null;
    videoType = null;
    productPackage = null;
    currency = null;
    paymentId = null;
    paymentOptionModel = PaymentOptionModel();
    couponListModel = CouponListModel();
    transSuccessModel = SuccessModel();
  }
}
