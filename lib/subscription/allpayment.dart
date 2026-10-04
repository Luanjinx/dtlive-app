import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutterwave_standard_smart/flutterwave.dart';
import 'package:paytmpayments_allinonesdk/paytmpayments_allinonesdk.dart';
import 'package:razorpay_web/razorpay_web.dart';

import '../model/razorpayordermodel.dart' as razorpayorder;
import '../provider/bottombarprovider.dart';
import '../provider/paymentprovider.dart';
import '../provider/profileprovider.dart';
import '../routes/routes_constant.dart';
import '../subscription/instamojopg.dart';
import '../subscription/payuhashservice.dart';
import '../subscription/payuparams.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import 'couponlist.dart';
import '../subscription/wallet.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../subscription/stripe/stripe_checkout.dart';

final bool _kAutoConsume = Platform.isIOS || true;

class AllPayment extends StatefulWidget {
  final dynamic reqText;
  final String? payType,
      newPage,
      oldPage,
      producerId,
      itemId,
      price,
      itemTitle,
      typeId,
      videoType,
      subVideoType,
      productPackage,
      currency;
  const AllPayment({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    required this.payType,
    required this.producerId,
    required this.itemId,
    required this.price,
    required this.itemTitle,
    required this.typeId,
    required this.videoType,
    required this.subVideoType,
    required this.productPackage,
    required this.currency,
  });

  @override
  State<AllPayment> createState() => AllPaymentState();
}

class AllPaymentState extends State<AllPayment>
    implements PayUCheckoutProProtocol {
  SharedPre sharedPref = SharedPre();

  late PaymentProvider paymentProvider;
  late BottombarProvider bottombarProvider;
  late ProfileProvider profileProvider;

  final couponController = TextEditingController();

  String? userId, userName, userEmail, userMobileNo;
  String? strCouponCode = "", couponStatus;
  bool isPaymentDone = false;
  bool _useWallet = false;
  String? _couponErrorMsg;
  String? _appliedCouponCode;
  String? _appliedCouponSaving;
  int? _selectedPaymentIndex;

  /// Holds the actual gateway transaction ID captured in each success callback.
  /// Used for wallet_topup to credit the wallet with the real transaction ID.
  String? _gatewayTxnId;

  /* ── Wallet helpers ─────────────────────────────────────── */
  int get _walletBalance =>
      profileProvider.profileModel.result?[0].walletAmount ?? 0;

  double get _totalAmount =>
      double.tryParse(paymentProvider.finalAmount ?? '0') ?? 0;

  bool get _walletCoversAll => _walletBalance >= _totalAmount;

  bool get _couponApplied =>
      strCouponCode != null &&
      (strCouponCode ?? "").isNotEmpty &&
      paymentProvider.finalAmount != null &&
      paymentProvider.finalAmount != "" &&
      widget.price != null &&
      widget.price != "" &&
      double.parse(paymentProvider.finalAmount ?? "0") <
          double.parse(widget.price ?? "0");

  bool get _isFreeCheckout =>
      double.tryParse(paymentProvider.finalAmount ?? "0") == 0.0;

  /* InApp Purchase */
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late List<String> _kProductIds;
  final List<PurchaseDetails> _purchases = <PurchaseDetails>[];

  /* Razorpay */
  late Razorpay razorpay;

  /* Paytm */
  String paytmResult = "";

  /* Stripe */
  Map<String, dynamic>? paymentIntent;

  /* PayUMoney */
  late PayUCheckoutProFlutter _payUCheckoutPro;

  @override
  void initState() {
    super.initState();
    paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    if (!kIsWeb) {
      /* InApp Purchase */
      _kProductIds = <String>[widget.productPackage ?? ""];
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (List<PurchaseDetails> purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          _subscription.cancel();
        },
        onError: (Object error) {
          // handle error here.
          printLog("onError ============> ${error.toString()}");
          LoadingOverlay().hide(); // Stop Loading...
        },
      );
      initStoreInfo();
    }

    /* Razorpay */
    razorpay = Razorpay();
  }

  Future<void> _getData() async {
    printLog('_getData paymentId ==> ${paymentProvider.paymentId}');
    printLog('_getData itemId =====> ${widget.itemId}');
    /* Save Params */
    if (paymentProvider.paymentId == null) {
      paymentProvider.setFinalAmount(widget.price ?? "");
      printLog('_getData finalAmount ==> ${paymentProvider.finalAmount}');

      await paymentProvider.setCurrentPayParams(
        payType: widget.payType ?? "",
        itemId: widget.itemId ?? "",
        price: paymentProvider.finalAmount ?? "",
        itemTitle: widget.itemTitle ?? "",
        typeId: widget.typeId ?? "",
        videoType: widget.videoType ?? "",
        productPackage: widget.productPackage ?? "",
        currency: Constant.currency,
        paymentId: Utils.generateRandomOrderID(),
      );

      await paymentProvider.getPaymentOption();

      userId = await sharedPref.read("userid");
      userName = await sharedPref.read("userfullname");
      userEmail = await sharedPref.read("useremail");
      userMobileNo = await sharedPref.read("usermobile");
      printLog('_getData userId ==> $userId');
      printLog('_getData userName ==> $userName');
      printLog('_getData userEmail ==> $userEmail');
      printLog('_getData userMobileNo ==> $userMobileNo');

      couponStatus = await Utils.configByStatus(status: Constant.couponStatus);
      printLog('_getData couponStatus ==> $couponStatus');

      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    } else {
      printLog('_getData payment params already set in provider.');
    }
  }

  @override
  void dispose() {
    razorpay.clear();
    LoadingOverlay().hide();
    paymentProvider.clearProvider();
    if (!kIsWeb) {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        iosPlatformAddition.setDelegate(null);
      }
      _subscription.cancel();
    }
    couponController.dispose();
    super.dispose();
  }

  /* add_transaction API */
  Future addTransaction(
    dynamic pgName,
    packageId,
    description,
    amount,
    paymentId, {
    int paymentType = 0,
    int walletAmount = 0,
  }) async {
    printLog("addTransaction packageId :=====> $packageId");
    printLog("addTransaction description :===> $description");
    printLog("addTransaction amount :========> $amount");
    printLog("addTransaction paymentId :=====> $paymentId");
    printLog("addTransaction paymentType :===> $paymentType");
    printLog("addTransaction walletAmount :==> $walletAmount");
    printLog("addTransaction strCouponCode :=> $strCouponCode");
    await paymentProvider.addTransaction(
      packageId,
      description,
      amount,
      paymentId,
      (pgName == "inapp") ? "" : strCouponCode,
      paymentType: paymentType,
    );

    if (!paymentProvider.payLoading) {
      if (!mounted) return;
      printLog(
        "addTransaction status :===> ${paymentProvider.transSuccessModel.status}",
      );
      if (paymentProvider.transSuccessModel.status != 200) {
        Utils.showToast(paymentProvider.transSuccessModel.message ?? "");
      }
    }
  }

  /* add_rent_transaction API */
  Future addRentTransaction(
    dynamic pgName,
    videoId,
    amount,
    typeId,
    videoType, {
    int paymentType = 0,
    int walletAmount = 0,
  }) async {
    printLog("addRentTransaction videoId :======> $videoId");
    printLog("addRentTransaction typeId :=======> $typeId");
    printLog("addRentTransaction amount :=======> $amount");
    printLog("addRentTransaction videoType :====> $videoType");
    printLog("addRentTransaction paymentType :==> $paymentType");
    printLog("addRentTransaction walletAmount :=> $walletAmount");
    printLog("addRentTransaction strCouponCode :> $strCouponCode");
    await paymentProvider.addRentTransaction(
      widget.producerId,
      videoId,
      amount,
      typeId,
      videoType,
      widget.subVideoType,
      paymentProvider.paymentId,
      widget.itemTitle,
      (pgName == "inapp") ? "" : strCouponCode,
      paymentType: paymentType,
    );

    if (!paymentProvider.payLoading) {
      if (!mounted) return;
      printLog(
        "addRentTransaction status :===> ${paymentProvider.transSuccessModel.status}",
      );
      if (paymentProvider.transSuccessModel.status != 200) {
        Utils.showToast(paymentProvider.transSuccessModel.message ?? "");
      }
    }
  }

  /* apply_coupon API */
  Future applyCoupon() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _couponErrorMsg = null;
    _appliedCouponCode = couponController.text.trim();
    if (widget.payType == "Package") {
      await paymentProvider.applyPackageCouponCode(
        strCouponCode,
        widget.itemId,
      );
      if (!paymentProvider.couponLoading) {
        if (paymentProvider.couponModel.status == 200) {
          final double original = double.tryParse(widget.price ?? "0") ?? 0;
          final double discounted =
              double.tryParse(
                paymentProvider.couponModel.result?.discountAmount.toString() ??
                    "0",
              ) ??
              0;
          _appliedCouponSaving =
              "${Constant.currencySymbol}${(original - discounted).toStringAsFixed(2)}";
          couponController.clear();
          paymentProvider.setFinalAmount(
            paymentProvider.couponModel.result?.discountAmount.toString(),
          );
          strCouponCode = paymentProvider.couponModel.result?.uniqueId
              .toString();
          Utils.showToast(paymentProvider.couponModel.message ?? "");
        } else {
          _couponErrorMsg =
              paymentProvider.couponModel.message ?? "Invalid coupon code.";
          _appliedCouponCode = null;
          Utils.showToast(paymentProvider.couponModel.message ?? "");
        }
        if (mounted) setState(() {});
      }
    } else if (widget.payType == "Rent") {
      await paymentProvider.applyRentCouponCode(
        strCouponCode,
        widget.itemId,
        widget.typeId,
        widget.videoType,
        widget.price,
      );
      if (!paymentProvider.couponLoading) {
        if (paymentProvider.couponModel.status == 200) {
          final double original = double.tryParse(widget.price ?? "0") ?? 0;
          final double discounted =
              double.tryParse(
                paymentProvider.couponModel.result?.discountAmount.toString() ??
                    "0",
              ) ??
              0;
          _appliedCouponSaving =
              "${Constant.currencySymbol}${(original - discounted).toStringAsFixed(2)}";
          couponController.clear();
          paymentProvider.setFinalAmount(
            paymentProvider.couponModel.result?.discountAmount.toString(),
          );
          strCouponCode = paymentProvider.couponModel.result?.uniqueId
              .toString();
          Utils.showToast(paymentProvider.couponModel.message ?? "");
        } else {
          _couponErrorMsg =
              paymentProvider.couponModel.message ?? "Invalid coupon code.";
          _appliedCouponCode = null;
          Utils.showToast(paymentProvider.couponModel.message ?? "");
        }
        if (mounted) setState(() {});
      }
    }
  }

  void _removeCoupon() {
    strCouponCode = "";
    _couponErrorMsg = null;
    _appliedCouponCode = null;
    _appliedCouponSaving = null;
    paymentProvider.setFinalAmount(widget.price ?? "");
    if (mounted) {
      setState(() {});
      Utils.showToast(Locales.string(context, "coupon_removed"));
    }
  }

  void _openCouponList() async {
    final String? code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CouponList(payType: widget.payType ?? ""),
      ),
    );
    if (code != null && code.isNotEmpty) {
      couponController.text = code;
      strCouponCode = code;
      applyCoupon();
    }
  }

  /* update_transaction_status API — Package / Rent only */
  Future updateTransStatus(dynamic transStatus) async {
    /* Wallet top-up bypasses add_transaction and update_transaction_status.
       Route to the dedicated handler instead. */
    if (widget.payType == "wallet_topup") {
      if (transStatus == 2) {
        final String txnId = _gatewayTxnId ?? "";
        _gatewayTxnId = null;
        await _handleWalletTopupSuccess(txnId);
      } else {
        _gatewayTxnId = null;
        LoadingOverlay().hide();
        // Gateway callback already showed the failure toast
      }
      return;
    }

    LoadingOverlay().show(context);

    int transId = paymentProvider.transSuccessModel.result?[0].id ?? 0;
    printLog("updateTransStatus transId ===> $transId");

    await paymentProvider.updateTransStatus(
      (paymentProvider.payType == "Rent")
          ? 2
          : 1, // 1-Package Transaction, 2-Rent Transaction
      transId,
      transStatus, // 1-Processing, 2-Success, 3-Failed
    );

    if (!paymentProvider.payLoading) {
      if (!mounted) return;
      LoadingOverlay().hide();

      if (paymentProvider.updateStatusModel.status == 200 && transStatus == 2) {
        isPaymentDone = true;
        if (!mounted) return;
        await profileProvider.getProfile(context);

        if (!mounted) return;
        if (kIsWeb) {
          if (context.canPop()) {
            context.pop(isPaymentDone);
          }
          context.pushReplacementNamed(RoutesConstant.homePage);
        } else {
          await bottombarProvider.setBottomNavIndex(0);
          if (!mounted) return;
          Utils.redirectToMainPage(context: context);
        }
      } else {
        if (transStatus == 3) {
          await paymentProvider.setCurrentPayParams(
            payType: widget.payType ?? "",
            itemId: widget.itemId ?? "",
            price: paymentProvider.finalAmount ?? "",
            itemTitle: widget.itemTitle ?? "",
            typeId: widget.typeId ?? "",
            videoType: widget.videoType ?? "",
            productPackage: widget.productPackage ?? "",
            currency: Constant.currency,
            paymentId: Utils.generateRandomOrderID(),
          );
        }
        isPaymentDone = false;
        Utils.showToast(paymentProvider.updateStatusModel.message ?? "");
      }
    }
  }

  /* Wallet top-up success — calls add_wallet_amount via PaymentProvider */
  Future<void> _handleWalletTopupSuccess(String gatewayTxnId) async {
    if (!mounted) return;
    if (gatewayTxnId.isEmpty) {
      LoadingOverlay().hide();
      Utils.showToast(Locales.string(context, "payment_not_processed"));
      return;
    }
    LoadingOverlay().show(context);
    final bool success = await paymentProvider.addWalletAmount(
      userId: Constant.userID?.toString() ?? "",
      amount: paymentProvider.finalAmount ?? "",
      transactionId: gatewayTxnId,
    );
    if (!mounted) return;
    LoadingOverlay().hide();
    if (success) {
      if (!mounted) return;
      await profileProvider.getProfile(context);
      if (!mounted) return;
      final int newBalance =
          paymentProvider.addWalletAmountModel.walletAmount ?? 0;
      printLog("TopupSuccess newBalance ===> $newBalance");
      Utils.showToast(Locales.string(context, "wallet_topup_success"));
      Utils.exitPage(context);
    } else {
      Utils.showToast(paymentProvider.addWalletAmountModel.message ?? "");
    }
  }

  /* ── Wallet-only payment ───────────────────────────────── */
  Future<void> _payWithWallet() async {
    if (!_walletCoversAll) {
      Utils.showToast(Locales.string(context, "insufficient_wallet_balance"));
      return;
    }
    try {
      LoadingOverlay().show(context);
      if (widget.payType == "Package") {
        await addTransaction(
          "wallet",
          paymentProvider.itemId,
          paymentProvider.itemTitle,
          paymentProvider.finalAmount,
          paymentProvider.paymentId,
          paymentType: 1,
        );
      } else if (widget.payType == "Rent") {
        await addRentTransaction(
          "wallet",
          paymentProvider.itemId,
          paymentProvider.finalAmount,
          paymentProvider.typeId,
          paymentProvider.videoType,
          paymentType: 1,
        );
      }
      LoadingOverlay().hide();
      if (paymentProvider.transSuccessModel.result != null &&
          (paymentProvider.transSuccessModel.result?.length ?? 0) > 0) {
        await updateTransStatus(2);
      } else {
        Utils.showToast(paymentProvider.transSuccessModel.message ?? "");
      }
    } on Exception catch (e) {
      printLog("_payWithWallet Exception =====> $e");
      LoadingOverlay().hide();
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }

  void _navigateToWallet() {
    if (kIsWeb) {
      context.go("/${RoutesConstant.walletPage}");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Wallet()),
      );
    }
  }

  /* ── Online gateway payment ─────────────────────────────── */
  Future<void> openPayment({required String pgName}) async {
    printLog("openPayment finalAmount ===> ${paymentProvider.finalAmount}");
    try {
      LoadingOverlay().show(context);

      /* ── WALLET TOP-UP: skip add_transaction, open gateway directly ── */
      if (widget.payType == "wallet_topup") {
        LoadingOverlay().hide();
        _launchGateway(pgName);
        return;
      }

      /* ── PACKAGE / RENT: record transaction (online, payment_type=0) ── */
      if (widget.payType == "Package") {
        await addTransaction(
          pgName,
          paymentProvider.itemId,
          paymentProvider.itemTitle,
          paymentProvider.finalAmount,
          paymentProvider.paymentId,
        );
      } else if (widget.payType == "Rent") {
        await addRentTransaction(
          pgName,
          paymentProvider.itemId,
          paymentProvider.finalAmount,
          paymentProvider.typeId,
          paymentProvider.videoType,
        );
      }
      LoadingOverlay().hide();
      if (paymentProvider.transSuccessModel.result != null &&
          (paymentProvider.transSuccessModel.result?.length ?? 0) > 0) {
        if (paymentProvider.finalAmount != "0") {
          _launchGateway(pgName);
        } else {
          // Free package — mark success immediately
          await updateTransStatus(2);
        }
      } else {
        Utils.showToast(paymentProvider.transSuccessModel.message ?? "");
      }
    } on Exception catch (e) {
      printLog("openPayment Exception =====> $e");
      LoadingOverlay().hide();
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "cash_payment_msg"));
    }
  }

  /* Shared gateway initializer used by both Package/Rent and Wallet top-up */
  void _launchGateway(String pgName) {
    if (pgName == "paypal") {
      _paypalInit();
    } else if (pgName == "inapp") {
      _initInAppPurchase();
    } else if (pgName == "razorpay") {
      _initializeRazorpay();
    } else if (pgName == "flutterwave") {
      _flutterwaveInit();
    } else if (pgName == "paytm") {
      _paytmInit();
    } else if (pgName == "stripe") {
      _stripeInit();
    } else if (pgName == "payumoney") {
      _payUMoneyInit();
    } else if (pgName == "paystack") {
      _paystackInit();
    } else if (pgName == "instamojo") {
      _initInstamojo();
    } else if (pgName == "cash") {
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "cash_payment_msg"));
    }
  }

  bool checkKeysAndContinue({
    required String isLive,
    required bool isBothKeyReq,
    required String key1,
    required String key2,
  }) {
    if (isBothKeyReq) {
      if (key1 == "" || key2 == "") {
        Utils.showToast(Locales.string(context, "payment_not_processed"));
        return false;
      }
    } else {
      if (key1 == "") {
        Utils.showToast(Locales.string(context, "payment_not_processed"));
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await onBackPressed(didPop);
      },
      child: _buildPage(),
    );
  }

  Widget _buildPage() {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (kIsWeb || Constant.isTV)
          ? null
          : Utils.myAppBarWithBack(context, "payment_details", true),
      body: SafeArea(child: Center(child: _buildMobilePage())),
    );
  }

  Widget _buildMobilePage() {
    return Container(
      width: Dimens.isBigScreen(context)
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      margin: Dimens.isBigScreen(context)
          ? const EdgeInsets.fromLTRB(50, 0, 50, 50)
          : const EdgeInsets.all(0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.payType != "wallet_topup") ...[
                    _buildPlanCard(),
                    const SizedBox(height: 20),
                  ],
                  if (!_useWallet &&
                      couponStatus != null &&
                      couponStatus == "1" &&
                      widget.payType != "wallet_topup") ...[
                    _buildCouponSection(),
                    const SizedBox(height: 20),
                  ],
                  _buildPriceBreakdown(),
                  const SizedBox(height: 20),
                  if (!_isFreeCheckout && widget.payType != "wallet_topup")
                    _buildPaymentMethodSelector(),
                  if (_isFreeCheckout) const SizedBox(height: 8),
                  if (_useWallet && widget.payType != "wallet_topup")
                    _buildWalletPaymentView(),
                ],
              ),
            ),
          ),
          _buildBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MyText(
              color: white,
              text: widget.itemTitle ?? "",
              multilanguage: false,
              fontsizeNormal: 18,
              fontsizeWeb: 20,
              fontweight: FontWeight.w800,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText(
                color: colorPrimary,
                text: "${Constant.currencySymbol}${widget.price}",
                multilanguage: false,
                fontsizeNormal: 20,
                fontsizeWeb: 22,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.end,
                fontstyle: FontStyle.normal,
              ),
              MyText(
                color: descTextColor,
                text: widget.payType == "Rent" ? "rent" : "per_month",
                multilanguage: true,
                fontsizeNormal: 12,
                fontsizeWeb: 13,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.end,
                fontstyle: FontStyle.normal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MyText(
              color: white,
              text: "have_a_promo_code",
              multilanguage: true,
              fontsizeNormal: 14,
              fontsizeWeb: 15,
              fontweight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
            const Spacer(),
            GestureDetector(
              onTap: _openCouponList,
              child: MyText(
                color: colorPrimary,
                text: "browse_coupons",
                multilanguage: true,
                fontsizeNormal: 12,
                fontsizeWeb: 13,
                fontweight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.end,
                fontstyle: FontStyle.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_couponApplied) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: greenColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: greenColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: greenColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        color: greenColor,
                        text: _appliedCouponCode ?? "",
                        multilanguage: false,
                        fontsizeNormal: 14,
                        fontsizeWeb: 15,
                        fontweight: FontWeight.w700,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                      ),
                      if (_appliedCouponSaving != null)
                        MyText(
                          color: greenColor,
                          text:
                              "${Locales.string(context, "coupon_applied_savings")} ${_appliedCouponSaving!}",
                          multilanguage: false,
                          fontsizeNormal: 12,
                          fontsizeWeb: 13,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: const Icon(Icons.close, color: greenColor, size: 18),
                ),
              ],
            ),
          ),
        ] else ...[
          Consumer<PaymentProvider>(
            builder: (context, paymentProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: secondaryBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _couponErrorMsg != null
                            ? redColor.withValues(alpha: 0.6)
                            : descTextColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.text,
                            maxLines: 1,
                            style: const TextStyle(
                              color: white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(
                                color: descTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: Locales.string(
                                context,
                                "coupon_code_hint",
                              ),
                            ),
                            onChanged: (value) {
                              strCouponCode = value.isNotEmpty ? value : "";
                              if (_couponErrorMsg != null) {
                                setState(() => _couponErrorMsg = null);
                              }
                            },
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                strCouponCode = value;
                                applyCoupon();
                              }
                            },
                          ),
                        ),
                        paymentProvider.couponLoading
                            ? Container(
                                width: 70,
                                height: 36,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorPrimary,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  if (strCouponCode != null &&
                                      (strCouponCode ?? "").isNotEmpty) {
                                    applyCoupon();
                                  } else {
                                    Utils.showToast(
                                      Locales.string(
                                        context,
                                        "enter_coupon_code",
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: MyText(
                                    color: black,
                                    text: "apply",
                                    multilanguage: true,
                                    fontsizeNormal: 13,
                                    fontsizeWeb: 14,
                                    fontweight: FontWeight.w700,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textalign: TextAlign.center,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  if (_couponErrorMsg != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.cancel_rounded,
                          color: redColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MyText(
                            color: redColor,
                            text: _couponErrorMsg!,
                            multilanguage: false,
                            fontsizeNormal: 12,
                            fontsizeWeb: 13,
                            fontweight: FontWeight.w500,
                            maxline: 2,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (paymentProvider.couponLoading) ...[
                    const SizedBox(height: 6),
                    MyText(
                      color: descTextColor,
                      text: "validating_coupon",
                      multilanguage: true,
                      fontsizeNormal: 12,
                      fontsizeWeb: 13,
                      fontweight: FontWeight.w400,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.italic,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPriceRow(
                label: "plan_price",
                value: "${Constant.currencySymbol}${widget.price}",
                labelColor: descTextColor,
                valueColor: white,
                isMultilang: true,
              ),
              if (_couponApplied) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  label:
                      "${Locales.string(context, "discount")} (${_appliedCouponCode ?? ""})",
                  value:
                      "− ${Constant.currencySymbol}${((double.tryParse(widget.price ?? "0") ?? 0) - (double.tryParse(paymentProvider.finalAmount ?? "0") ?? 0)).toStringAsFixed(2)}",
                  labelColor: greenColor,
                  valueColor: greenColor,
                  isMultilang: false,
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: descTextColor.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 12),
              _buildPriceRow(
                label: "total",
                value:
                    "${Constant.currencySymbol}${paymentProvider.finalAmount ?? widget.price}",
                labelColor: white,
                valueColor: colorPrimary,
                isMultilang: true,
                isBold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required bool isMultilang,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          color: labelColor,
          text: label,
          multilanguage: isMultilang,
          fontsizeNormal: isBold ? 15 : 14,
          fontsizeWeb: isBold ? 16 : 15,
          fontweight: isBold ? FontWeight.w700 : FontWeight.w500,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        MyText(
          color: valueColor,
          text: value,
          multilanguage: false,
          fontsizeNormal: isBold ? 16 : 14,
          fontsizeWeb: isBold ? 18 : 15,
          fontweight: isBold ? FontWeight.w700 : FontWeight.w500,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.end,
          fontstyle: FontStyle.normal,
        ),
      ],
    );
  }

  /* ── Payment Method Selector ────────────────────────────── */
  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Online / Wallet toggle */
        Row(
          children: [
            Expanded(
              child: _buildMethodOption(
                labelKey: "online_payment",
                selectedLabelKey: "online_selected",
                icon: Icons.payment_rounded,
                selected: !_useWallet,
                onTap: () => setState(() => _useWallet = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMethodOption(
                labelKey: "use_wallet",
                selectedLabelKey: "wallet_selected",
                icon: Icons.account_balance_wallet_rounded,
                selected: _useWallet,
                onTap: () => setState(() => _useWallet = true),
              ),
            ),
          ],
        ),
        if (!_useWallet) ...[
          const SizedBox(height: 16),
          MyText(
            color: descTextColor,
            text: "select_payment_method",
            multilanguage: true,
            fontsizeNormal: 12,
            fontsizeWeb: 13,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 8),
          _buildGatewayList(),
        ],
      ],
    );
  }

  Widget _buildMethodOption({
    required String labelKey,
    required String selectedLabelKey,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorPrimary.withValues(alpha: 0.12)
              : secondaryBgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colorPrimary
                : descTextColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colorPrimary : descTextColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: MyText(
                color: selected ? colorPrimary : descTextColor,
                text: selected ? selectedLabelKey : labelKey,
                multilanguage: true,
                fontsizeNormal: 12,
                fontsizeWeb: 13,
                fontweight: selected ? FontWeight.w600 : FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayList() {
    if (paymentProvider.loading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        child: Utils.pageLoader(),
      );
    }
    final result = paymentProvider.paymentOptionModel.result;
    if (result == null) {
      return const NoData(title: 'no_payment', subTitle: 'no_payment_desc');
    }

    final List<_GatewayItem> gateways = [];
    if (kIsWeb) {
      if (result.razorpay?.visibility == "1") {
        gateways.add(
          const _GatewayItem("razorpay", "pg_razorpay.png", "Razorpay"),
        );
      }
      if (result.stripe?.visibility == "1") {
        gateways.add(const _GatewayItem("stripe", "pg_stripe.png", "Stripe"));
      }
    } else if (Platform.isIOS) {
      gateways.add(
        const _GatewayItem("inapp", "pg_inapp.png", "In-App Purchase"),
      );
    } else {
      if (result.inAppPurchage?.visibility == "1") {
        gateways.add(
          const _GatewayItem("inapp", "pg_inapp.png", "InApp Purchase"),
        );
      }
      if (result.paypal?.visibility == "1") {
        gateways.add(const _GatewayItem("paypal", "pg_paypal.png", "Paypal"));
      }
      if (result.razorpay?.visibility == "1") {
        gateways.add(
          const _GatewayItem("razorpay", "pg_razorpay.png", "Razorpay"),
        );
      }
      if (result.payTm?.visibility == "1") {
        gateways.add(const _GatewayItem("paytm", "pg_paytm.png", "Paytm"));
      }
      if (result.flutterWave?.visibility == "1") {
        gateways.add(
          const _GatewayItem(
            "flutterwave",
            "pg_flutterwave.png",
            "Flutterwave",
          ),
        );
      }
      if (result.payUMoney?.visibility == "1") {
        gateways.add(
          const _GatewayItem("payumoney", "pg_payumoney.png", "PayU Money"),
        );
      }
      if (result.instamojo?.visibility == "1") {
        gateways.add(
          const _GatewayItem("instamojo", "pg_instamojo.png", "Instamojo"),
        );
      }
      if (result.stripe?.visibility == "1") {
        gateways.add(const _GatewayItem("stripe", "pg_stripe.png", "Stripe"));
      }
      if (result.paystack?.visibility == "1") {
        gateways.add(
          const _GatewayItem("paystack", "pg_paystack.png", "Paystack"),
        );
      }
      if (result.cash?.visibility == "1") {
        gateways.add(const _GatewayItem("cash", "pg_cash.png", "Cash"));
      }
    }

    if (gateways.isEmpty) {
      return const NoData(title: 'no_payment', subTitle: 'no_payment_desc');
    }

    if (_selectedPaymentIndex == null && gateways.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedPaymentIndex = 0;
            paymentProvider.setCurrentPayment(gateways[0].pgName);
          });
        }
      });
    }

    return Column(
      children: List.generate(
        gateways.length,
        (i) => _buildGatewayCard(gateways[i], i),
      ),
    );
  }

  Widget _buildGatewayCard(_GatewayItem item, int index) {
    final bool selected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentIndex = index;
          paymentProvider.setCurrentPayment(item.pgName);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorPrimary.withValues(alpha: 0.06)
              : secondaryBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? colorPrimary
                : descTextColor.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            MyImage(
              imagePath: item.imageName,
              width: 60,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MyText(
                color: selected ? colorPrimary : titleTextColor,
                text: item.displayName,
                multilanguage: false,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? colorPrimary
                      : descTextColor.withValues(alpha: 0.4),
                  width: 2,
                ),
                color: selected
                    ? colorPrimary.withValues(alpha: 0.15)
                    : transparent,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: colorPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final bool isFree = _isFreeCheckout;
        final bool canProceed =
            isFree || _useWallet || _selectedPaymentIndex != null;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: appBgColor,
            border: Border(
              top: BorderSide(color: descTextColor.withValues(alpha: 0.1)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: canProceed ? colorPrimary : grayDark,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canProceed
                    ? () {
                        if (_useWallet && widget.payType != "wallet_topup") {
                          _payWithWallet();
                        } else {
                          openPayment(
                            pgName: paymentProvider.currentPayment ?? "",
                          );
                        }
                      }
                    : null,
                child: Center(
                  child: MyText(
                    color: black,
                    text: isFree
                        ? "activate_free_subscription"
                        : _useWallet
                        ? "pay_now"
                        : "proceed_to_pay",
                    multilanguage: true,
                    fontsizeNormal: 16,
                    fontsizeWeb: 17,
                    fontweight: FontWeight.w700,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* ── Wallet Payment View ─────────────────────────────────── */
  Widget _buildWalletPaymentView() {
    final int balance = _walletBalance;
    final bool sufficient = _walletCoversAll;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /* Available balance card */
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: secondaryBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sufficient
                    ? colorPrimary.withValues(alpha: 0.4)
                    : redColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sufficient
                        ? colorPrimary.withValues(alpha: 0.12)
                        : redColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: sufficient ? colorPrimary : redColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        color: descTextColor,
                        text: "available_balance",
                        multilanguage: true,
                        fontsizeNormal: 12,
                        fontsizeWeb: 13,
                        fontweight: FontWeight.w500,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 2),
                      MyText(
                        color: sufficient ? colorPrimary : redColor,
                        text: "${Constant.currencySymbol}$balance",
                        multilanguage: false,
                        fontsizeNormal: 20,
                        fontsizeWeb: 22,
                        fontweight: FontWeight.bold,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!sufficient) ...[
            /* Insufficient balance warning */
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: redColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: redColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MyText(
                      color: redColor,
                      text: "insufficient_wallet_balance",
                      multilanguage: true,
                      fontsizeNormal: 13,
                      fontsizeWeb: 14,
                      fontweight: FontWeight.w500,
                      maxline: 3,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            /* Recharge wallet button */
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _navigateToWallet,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: colorPrimary, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: colorPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    MyText(
                      color: colorPrimary,
                      text: "recharge_wallet",
                      multilanguage: true,
                      fontsizeNormal: 14,
                      fontsizeWeb: 15,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            /* Pay with wallet button */
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _payWithWallet,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: Utils.setGradLTRBGWithBorder(
                  colorPrimary,
                  colorPrimaryDark,
                  transparent,
                  10,
                  0,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: appBgColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    MyText(
                      color: appBgColor,
                      text: "pay_now",
                      multilanguage: true,
                      fontsizeNormal: 16,
                      fontsizeWeb: 17,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /* ********* InApp purchase START ********* */
  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {});
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase
        .queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null ||
        productDetailResponse.productDetails.isEmpty) {
      setState(() {});
      return;
    }
  }

  Future<void> _initInAppPurchase() async {
    LoadingOverlay().show(context); // Start Loading...
    printLog(
      "_initInAppPurchase _kProductIds ============> ${_kProductIds[0].toString()}",
    );
    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails(_kProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      LoadingOverlay().hide(); // Stop Loading...
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "check_sku"));
      return;
    }
    printLog("productID ============> ${response.productDetails[0].id}");
    late PurchaseParam purchaseParam;
    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: response.productDetails[0],
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: response.productDetails[0]);
    }
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      printLog("_initInAppPurchase Exception ============> $e");
      LoadingOverlay().hide(); // Stop Loading...
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "transaction_cancelled"));
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    printLog(
      "_listenToPurchaseUpdated purchaseDetailsList ===> ${purchaseDetailsList.length}",
    );
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      printLog(
        "_listenToPurchaseUpdated purchaseDetails status ===> ${purchaseDetails.status}",
      );
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          printLog(
            "_listenToPurchaseUpdated purchaseDetails ============> ${purchaseDetails.error.toString()}",
          );
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          LoadingOverlay().hide(); // Stop Loading...
          if (!mounted) return;
          Utils.showToast(Locales.string(context, "payment_cancel"));
        }
        if (Platform.isAndroid) {
          if (!_kAutoConsume && purchaseDetails.productID == _kProductIds[0]) {
            final InAppPurchaseAndroidPlatformAddition
            androidAddition = _inAppPurchase
                .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          printLog(
            "_listenToPurchaseUpdated pendingCompletePurchase ===> ${purchaseDetails.pendingCompletePurchase}",
          );
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    printLog("deliverProduct productID ===> ${purchaseDetails.productID}");
    LoadingOverlay().hide(); // Stop Loading...
    if (purchaseDetails.productID == _kProductIds[0]) {
      _gatewayTxnId = purchaseDetails.purchaseID; // InApp transaction ID
      // Payment Success
      updateTransStatus(2);
    } else {
      printLog("deliverProduct consumables else ===> $purchaseDetails");
      setState(() {
        _purchases.add(purchaseDetails);
      });
    }
  }

  void showPendingUI() {
    LoadingOverlay().hide(); // Stop Loading...
    setState(() {});
  }

  void handleError(IAPError error) {
    LoadingOverlay().hide(); // Stop Loading...
    setState(() {});
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    LoadingOverlay().hide(); // Stop Loading...
    printLog("invalid Purchase ===> $purchaseDetails");
  }
  /* ********* InApp purchase END ********* */

  /* ********* Razorpay START ********* */
  Future<void> _initializeRazorpay() async {
    if (paymentProvider.paymentOptionModel.result?.razorpay != null) {
      /* Check Keys */
      bool isContinue = checkKeysAndContinue(
        isLive:
            (paymentProvider.paymentOptionModel.result?.razorpay?.isLive ?? ""),
        isBothKeyReq: false,
        key1: (paymentProvider.paymentOptionModel.result?.razorpay?.key1 ?? ""),
        key2: "",
      );
      if (!isContinue) return;

      /* Check Keys */
      LoadingOverlay().show(context);
      await paymentProvider.getCreatedRazorpayOrder(
        paymentProvider.finalAmount ?? "",
      );
      LoadingOverlay().hide();

      if (paymentProvider.razorpayOrderModel.result != null) {
        printLog(
          'Razorpay amountDue :=====> ${paymentProvider.razorpayOrderModel.result?.amountDue}',
        );
        printLog(
          'Razorpay id :=====> ${paymentProvider.razorpayOrderModel.result?.id}',
        );
        payByRazorpay(razorpayOrder: paymentProvider.razorpayOrderModel.result);
      } else {
        if (!mounted) return;
        Utils.showToast(paymentProvider.razorpayOrderModel.errors ?? "");
      }
    } else {
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }

  Future payByRazorpay({razorpayorder.Result? razorpayOrder}) async {
    var options = {
      'key': (paymentProvider.paymentOptionModel.result?.razorpay?.key1 ?? ""),
      'currency': Constant.currency,
      'order_id': razorpayOrder?.id ?? "",
      'amount': razorpayOrder?.amountDue ?? 0,
      'name': widget.itemTitle ?? "",
      'description': widget.itemTitle ?? "",
      'send_sms_hash': true,
      'prefill': {'contact': userMobileNo, 'email': userEmail},
      'external': {
        'wallets': ['paytm'],
      },
    };
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);

    try {
      razorpay.open(options);
    } catch (e) {
      printLog('Razorpay Error :=========> $e');
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) async {
    /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
    Utils.showToast(Locales.string(context, "payment_fail"));
    updateTransStatus(3);
    paymentProvider.setCurrentPayment("");
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
    printLog("paymentId ====MAIN====> ${response.paymentId}");
    printLog("paymentId ====AUTO====> ${paymentProvider.paymentId}");
    _gatewayTxnId = response.paymentId; // Razorpay transaction ID
    Utils.showToast(Locales.string(context, "payment_success"));
    // Payment Success
    updateTransStatus(2);
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    printLog("============ External Wallet Selected ============");
  }
  /* ********* Razorpay END ********* */

  /* ********* Paytm START ********* */
  Future<void> _paytmInit() async {
    if (paymentProvider.paymentOptionModel.result?.payTm != null) {
      /* Check Keys */
      bool isContinue = checkKeysAndContinue(
        isLive:
            (paymentProvider.paymentOptionModel.result?.payTm?.isLive ?? ""),
        isBothKeyReq: false,
        key1: (paymentProvider.paymentOptionModel.result?.payTm?.key1 ?? ""),
        key2: "",
      );
      if (!isContinue) return;
      /* Check Keys */

      bool payTmIsStaging;
      String payTmMerchantID,
          payTmOrderId,
          payTmCustmoreID,
          payTmChannelID,
          payTmTxnAmount,
          payTmWebsite,
          payTmCallbackURL,
          payTmIndustryTypeID;

      payTmOrderId = paymentProvider.paymentId ?? "";
      payTmCustmoreID = "${Constant.userID}_${paymentProvider.paymentId}";
      payTmChannelID = "WAP";
      payTmTxnAmount = "${(paymentProvider.finalAmount ?? "")}.00";
      payTmIndustryTypeID = "Retail";

      if (paymentProvider.paymentOptionModel.result?.payTm?.isLive == "1") {
        payTmMerchantID =
            paymentProvider.paymentOptionModel.result?.payTm?.key1 ?? "";
        payTmIsStaging = false;
        payTmWebsite = "DEFAULT";
        payTmCallbackURL =
            "https://secure.paytmpayments.com/theia/paytmCallback?ORDER_ID=$payTmOrderId";
      } else {
        payTmMerchantID =
            paymentProvider.paymentOptionModel.result?.payTm?.key4 ?? "";
        payTmIsStaging = true;
        payTmWebsite = "WEBSTAGING";
        payTmCallbackURL =
            "https://securestage.paytmpayments.com/theia/paytmCallback?ORDER_ID=$payTmOrderId";
      }
      var sendMap = <String, dynamic>{
        "mid": payTmMerchantID,
        "orderId": payTmOrderId,
        "amount": payTmTxnAmount,
        "txnToken": paymentProvider.payTmModel.result?.paytmChecksum ?? "",
        "callbackUrl": payTmCallbackURL,
        "isStaging": payTmIsStaging,
        "restrictAppInvoke": true,
        "enableAssist": true,
      };
      printLog("sendMap ===> $sendMap");

      /* Generate CheckSum from Backend */
      await paymentProvider.getPaytmToken(
        payTmMerchantID,
        payTmOrderId,
        payTmCustmoreID,
        payTmChannelID,
        payTmTxnAmount,
        payTmWebsite,
        payTmCallbackURL,
        payTmIndustryTypeID,
      );

      if (!paymentProvider.loading) {
        if (paymentProvider.payTmModel.result != null &&
            paymentProvider.payTmModel.result?.paytmChecksum != null) {
          try {
            var response = PaytmPaymentsAllinonesdk().startTransaction(
              payTmMerchantID,
              payTmOrderId,
              payTmTxnAmount,
              paymentProvider.payTmModel.result?.paytmChecksum ?? "",
              payTmCallbackURL,
              payTmIsStaging,
              true,
              true,
            );
            response
                .then((value) {
                  printLog("value ====> $value");
                  setState(() {
                    paytmResult = value.toString();
                  });
                  if (value != null && value["RESPCODE"] == "01") {
                    _gatewayTxnId = value["TXNID"]
                        ?.toString(); // Paytm transaction ID
                    // Payment Success
                    updateTransStatus(2);
                  } else {
                    if (!mounted) return;
                    Utils.showToast(Locales.string(context, "payment_fail"));
                    updateTransStatus(3);
                  }
                })
                .catchError((onError) {
                  if (onError is PlatformException) {
                    setState(() {
                      paytmResult = "${onError.message} \n  ${onError.details}";
                    });
                  } else {
                    setState(() {
                      paytmResult = onError.toString();
                    });
                  }
                  updateTransStatus(3);
                });
          } catch (err) {
            paytmResult = err.toString();
          }
        } else {
          if (!mounted) return;
          Utils.showToast(Locales.string(context, "payment_not_processed"));
        }
      }
    } else {
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }
  /* ********* Paytm END *********** */

  /* ********* Paypal START ********* */
  Future<void> _paypalInit() async {
    if (paymentProvider.paymentOptionModel.result?.paypal != null) {
      /* Check Keys */
      bool isContinue = checkKeysAndContinue(
        isLive:
            (paymentProvider.paymentOptionModel.result?.paypal?.isLive ?? ""),
        isBothKeyReq: true,
        key1: (paymentProvider.paymentOptionModel.result?.paypal?.key1 ?? ""),
        key2: (paymentProvider.paymentOptionModel.result?.paypal?.key2 ?? ""),
      );
      if (!isContinue) return;
      /* Check Keys */

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => UsePaypal(
            sandboxMode:
                (paymentProvider.paymentOptionModel.result?.paypal?.isLive ??
                        "") ==
                    "1"
                ? false
                : true,
            clientId:
                paymentProvider.paymentOptionModel.result?.paypal?.key1 ?? "",
            secretKey:
                paymentProvider.paymentOptionModel.result?.paypal?.key2 ?? "",
            returnURL: "return.example.com",
            cancelURL: "cancel.example.com",
            transactions: [
              {
                "amount": {
                  "total": '${paymentProvider.finalAmount}',
                  "currency": Constant.currency,
                  "details": {
                    "subtotal": '${paymentProvider.finalAmount}',
                    "shipping": '0',
                    "shipping_discount": 0,
                  },
                },
                "description": widget.payType ?? "",
                "item_list": {
                  "items": [
                    {
                      "name": "${widget.itemTitle}",
                      "quantity": 1,
                      "price": '${paymentProvider.finalAmount}',
                      "currency": Constant.currency,
                    },
                  ],
                },
              },
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (params) async {
              printLog("onSuccess: ${params["paymentId"]}");
              _gatewayTxnId = params["paymentId"]
                  ?.toString(); // PayPal transaction ID
              await updateTransStatus(2);
            },
            onError: (params) {
              printLog("onError: ${params["message"]}");
              Utils.showToast(
                Locales.string(context, params["message"].toString()),
              );
              updateTransStatus(3);
            },
            onCancel: (params) {
              printLog('cancelled: $params');
              Utils.showToast(params.toString());
              updateTransStatus(3);
            },
          ),
        ),
      );
    } else {
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }
  /* ********* Paypal END *********** */

  /* ********* Stripe START ********* */
  Future createCustomer() async {
    try {
      var body = {"email": userEmail, "name": userName, "phone": userMobileNo};

      //final response  = await http.post(Uri.parse("https://api.stripe.com/v1/customers"),
      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/customers"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization":
              "Bearer ${paymentProvider.paymentOptionModel.result?.stripe?.key2}",
        },
        body: body,
      );
      printLog('createCustomer jsonDecode :=> ${jsonDecode(response.body)}');
      return jsonDecode(response.body);
    } catch (err) {
      printLog('createCustomer Error :=> ${err.toString()}');
      return null;
    }
  }

  Future<void> _stripeInit() async {
    if (paymentProvider.paymentOptionModel.result?.stripe != null) {
      /* Check Keys */
      bool isContinue = checkKeysAndContinue(
        isLive:
            (paymentProvider.paymentOptionModel.result?.stripe?.isLive ?? ""),
        isBothKeyReq: true,
        key1: (paymentProvider.paymentOptionModel.result?.stripe?.key1 ?? ""),
        key2: (paymentProvider.paymentOptionModel.result?.stripe?.key2 ?? ""),
      );
      if (!isContinue) return;
      /* Check Keys */

      stripe.Stripe.publishableKey =
          paymentProvider.paymentOptionModel.result?.stripe?.key1 ?? "";

      if (kIsWeb) {
        /* ******* INITIALIZE VALUES ******* */
        Constant.publishableKey =
            (paymentProvider.paymentOptionModel.result?.stripe?.key1 ?? "");
        Constant.secretKey =
            (paymentProvider.paymentOptionModel.result?.stripe?.key2 ?? "");
        Constant.packagePriceId = paymentProvider.productPackage ?? "";
        Constant.successURL = '${Constant.webDomainURL}#/success';
        Constant.cancelURL = '${Constant.webDomainURL}#/cancel';
        printLog("publishableKey ==> ${Constant.publishableKey}");
        printLog("secretKey =======> ${Constant.secretKey}");
        printLog("packagePriceId ==> ${Constant.packagePriceId}");
        printLog("successURL ======> ${Constant.successURL}");
        printLog("cancelURL =======> ${Constant.cancelURL}");
        /* ******* INITIALIZE VALUES ******* */

        redirectToCheckout(context);
      } else {
        try {
          final customerData = await createCustomer();
          printLog("customerData =====> $customerData");

          //STEP 1: Create Payment Intent
          paymentIntent = await createPaymentIntent(
            paymentProvider.finalAmount ?? "",
            Constant.currency,
          );

          //STEP 2: Initialize Payment Sheet
          await stripe.Stripe.instance
              .initPaymentSheet(
                paymentSheetParameters: stripe.SetupPaymentSheetParameters(
                  billingDetailsCollectionConfiguration:
                      const stripe.BillingDetailsCollectionConfiguration(
                        attachDefaultsToPaymentMethod: true,
                        address: stripe.AddressCollectionMode.automatic,
                        name: stripe.CollectionMode.always,
                        email: stripe.CollectionMode.always,
                        phone: stripe.CollectionMode.always,
                      ),
                  paymentIntentClientSecret: paymentIntent?['client_secret'],
                  style: ThemeMode.light,
                  merchantDisplayName: Constant.appName,
                  customerId: customerData['id'],
                  billingDetails: stripe.BillingDetails(
                    email: userEmail,
                    phone: userMobileNo,
                    name: userName,
                  ),
                ),
              )
              .then((value) {});

          //STEP 3: Display Payment sheet
          displayPaymentSheet();
        } catch (err) {
          printLog("_stripeInit Error =====> ${err.toString()}");
          throw Exception(err);
        }
      }
    } else {
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }

  Future createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'description': paymentProvider.itemTitle,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer ${paymentProvider.paymentOptionModel.result?.stripe?.key2 ?? ""}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  String calculateAmount(String amount) {
    final calculatedAmout = (double.parse(amount)) * 100;
    return calculatedAmout.toString();
  }

  Future<void> displayPaymentSheet() async {
    try {
      await stripe.Stripe.instance
          .presentPaymentSheet()
          .then((value) {
            if (!mounted) return;
            _gatewayTxnId = paymentIntent?["id"]
                ?.toString(); // Stripe payment intent ID
            Utils.showToast(Locales.string(context, "payment_success"));
            updateTransStatus(2);
            paymentIntent = null;
          })
          .onError((error, stackTrace) {
            throw Exception(error);
          });
    } on stripe.StripeException catch (e) {
      printLog('Error is:---> $e');
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_fail"));
      await updateTransStatus(3);
    } catch (e) {
      printLog('$e');
    }
  }
  /* ********* Stripe END ********* */

  /* ********* Flutterwave START ********* */
  Future<void> _flutterwaveInit() async {
    /* Check Keys */
    bool isContinue = checkKeysAndContinue(
      isLive:
          paymentProvider.paymentOptionModel.result?.flutterWave?.isLive ?? "",
      isBothKeyReq: false,
      key1: paymentProvider.paymentOptionModel.result?.flutterWave?.key1 ?? "",
      key2: "",
    );
    if (!isContinue) return;
    /* Check Keys */

    final Customer customer = Customer(
      email: userEmail ?? "",
      name: userName ?? "",
      phoneNumber: userMobileNo ?? '',
    );

    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey:
          paymentProvider.paymentOptionModel.result?.flutterWave?.key1 ?? "",
      currency: Constant.currency,
      redirectUrl: 'https://www.divinetechs.com',
      txRef: const Uuid().v1(),
      amount: paymentProvider.finalAmount.toString().trim(),
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: widget.itemTitle),
      isTestMode:
          paymentProvider.paymentOptionModel.result?.flutterWave?.isLive != "1",
    );
    ChargeResponse? response = await flutterwave.charge();
    printLog("Flutterwave response =====> ${response.toJson()}");
    if ((response.status == "success" ||
            response.status == "successful" ||
            (response.status ?? "").contains("success")) &&
        response.success == true) {
      paymentProvider.paymentId = response.transactionId.toString();
      _gatewayTxnId = response.transactionId
          ?.toString(); // Flutterwave transaction ID
      printLog("paymentId ========> ${paymentProvider.paymentId}");
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_success"));
      await updateTransStatus(2);
    } else if (response.status == "cancel" && response.status == "cancelled") {
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_cancel"));
      await updateTransStatus(3);
    } else {
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_fail"));
      await updateTransStatus(3);
    }
  }
  /* ********* Flutterwave END ********* */

  /* ********* PayUMoney START ********* */
  Future<void> _payUMoneyInit() async {
    printLog(
      "_payUMoneyInit isLive ======> ${paymentProvider.paymentOptionModel.result?.payUMoney?.isLive}",
    );
    /* Check Keys */
    bool isContinue = checkKeysAndContinue(
      isLive:
          (paymentProvider.paymentOptionModel.result?.payUMoney?.isLive ?? ""),
      isBothKeyReq: false,
      key1: (paymentProvider.paymentOptionModel.result?.payUMoney?.key3 ?? ""),
      key2: (paymentProvider.paymentOptionModel.result?.payUMoney?.key2 ?? ""),
    );
    if (!isContinue) return;
    /* Check Keys */

    Map<dynamic, dynamic> additionalParam = {
      PayUAdditionalParamKeys.udf1: "udf1",
      PayUAdditionalParamKeys.udf2: "udf2",
      PayUAdditionalParamKeys.udf3: "udf3",
      PayUAdditionalParamKeys.udf4: "udf4",
      PayUAdditionalParamKeys.udf5: "udf5",
    };

    Map<dynamic, dynamic> payUPaymentParams = {
      PayUPaymentParamKey.key:
          (paymentProvider.paymentOptionModel.result?.payUMoney?.key2 ?? ""),
      PayUPaymentParamKey.transactionId: paymentProvider.paymentId ?? "",
      PayUPaymentParamKey.amount: double.parse(widget.price ?? "0").toString(),
      PayUPaymentParamKey.productInfo: widget.itemTitle ?? "",
      PayUPaymentParamKey.firstName: userName ?? "",
      PayUPaymentParamKey.email: userEmail ?? "",
      PayUPaymentParamKey.phone: userMobileNo ?? "",
      PayUPaymentParamKey.ios_surl: "https://payu.herokuapp.com/ios_success",
      PayUPaymentParamKey.ios_furl: "https://payu.herokuapp.com/ios_failure",
      PayUPaymentParamKey.android_surl: "https://payu.herokuapp.com/success",
      PayUPaymentParamKey.android_furl: "https://payu.herokuapp.com/failure",
      PayUPaymentParamKey.environment:
          (paymentProvider.paymentOptionModel.result?.payUMoney?.isLive == "1")
          ? "0"
          : "1", //0 => Production, 1 => Test
      PayUPaymentParamKey.additionalParam: additionalParam,
      PayUPaymentParamKey.userCredential:
          ('${paymentProvider.paymentOptionModel.result?.payUMoney?.key2}:${userEmail ?? ""}'),
    };
    printLog("_payUMoneyInit Params ======> ${payUPaymentParams.toString()}");

    try {
      _payUCheckoutPro.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: PayUParams.createPayUConfigParams(),
      );
    } on Exception catch (e) {
      printLog("_payUMoneyInit Exception ======> ${e.toString()}");
    }
  }

  @override
  generateHash(Map response) {
    // Pass response param to your backend server
    // Backend will generate the hash and will callback to
    Map<dynamic, dynamic> hashResponse = PayUHashService(
      (paymentProvider.paymentOptionModel.result?.payUMoney?.isLive == "1")
          ? (paymentProvider.paymentOptionModel.result?.payUMoney?.key3 ?? "")
          : (paymentProvider.paymentOptionModel.result?.payUMoney?.key3 ?? ""),
    ).generateHash(response);
    printLog("hashResponse =====> $hashResponse");
    _payUCheckoutPro.hashGenerated(hash: hashResponse);
  }

  @override
  onError(Map? response) {
    printLog("onError response ======> $response");
    if (!mounted) return;
    Utils.showToast(Locales.string(context, "payment_fail"));
  }

  @override
  onPaymentCancel(Map? response) {
    printLog("onPaymentCancel response ======> $response");
    if (!mounted) return;
    Utils.showToast(Locales.string(context, "payment_cancel"));
    updateTransStatus(3);
  }

  @override
  onPaymentFailure(response) {
    printLog("onPaymentFailure response ======> $response");
    if (!mounted) return;
    Utils.showToast(Locales.string(context, "payment_fail"));
    updateTransStatus(3);
  }

  @override
  onPaymentSuccess(response) {
    printLog("onPaymentSuccess response ======> $response");
    if (!mounted) return;
    _gatewayTxnId = response['mihpayid']
        ?.toString(); // PayUMoney transaction ID
    Utils.showToast(Locales.string(context, "payment_success"));
    updateTransStatus(2);
  }
  /* ********** PayUMoney END ********** */

  /* ********* Paystack START ********* */
  Future<void> _paystackInit() async {
    /* Check Keys */
    bool isContinue = checkKeysAndContinue(
      isLive:
          (paymentProvider.paymentOptionModel.result?.paystack?.isLive ?? ""),
      isBothKeyReq: false,
      key1: (paymentProvider.paymentOptionModel.result?.paystack?.key1 ?? ""),
      key2: (paymentProvider.paymentOptionModel.result?.paystack?.key2 ?? ""),
    );
    if (!isContinue) return;
    /* Check Keys */

    printLog("_paystackInit finalAmount ==> ${paymentProvider.finalAmount}");
    printLog("_paystackInit currency =====> ${Constant.currency}");
    PayWithPayStack().now(
      context: context,
      customerEmail: userEmail ?? "",
      reference: DateTime.now().microsecondsSinceEpoch.toString(),
      currency: Constant.currency,
      amount: double.parse(paymentProvider.finalAmount ?? "0") * 100,
      secretKey:
          (paymentProvider.paymentOptionModel.result?.paystack?.isLive == "1")
          ? (paymentProvider.paymentOptionModel.result?.paystack?.key1 ?? "")
          : (paymentProvider.paymentOptionModel.result?.paystack?.key4 ?? ""),
      transactionCompleted: (paymentData) async {
        printLog("Transaction Successful => ${paymentData.gatewayResponse}");
        printLog("paymentId ========> ${paymentProvider.paymentId}");
        _gatewayTxnId = paymentData.reference?.toString(); // Paystack reference
        if (!mounted) return;
        Utils.showToast(Locales.string(context, "payment_success"));
        await updateTransStatus(2);
      },
      transactionNotCompleted: (transaction) async {
        printLog("Transaction Not Successful! $transaction");
        if (!mounted) return;
        Utils.showToast(Locales.string(context, "payment_fail"));
        await updateTransStatus(3);
      },
      callbackUrl: 'https://yourappname.divinetechs.in/',
    );
  }
  /* ********* Paystack END ********* */

  /* ********* Instamojo START ********* */
  Future<void> _initInstamojo() async {
    /* Check Keys */
    bool isContinue = checkKeysAndContinue(
      isLive:
          (paymentProvider.paymentOptionModel.result?.instamojo?.isLive ?? ""),
      isBothKeyReq: false,
      key1: (paymentProvider.paymentOptionModel.result?.instamojo?.key1 ?? ""),
      key2: (paymentProvider.paymentOptionModel.result?.instamojo?.key2 ?? ""),
    );
    if (!isContinue) return;
    /* Check Keys */

    String apiKey =
        paymentProvider.paymentOptionModel.result?.instamojo?.key1 ?? "";
    String authToken =
        paymentProvider.paymentOptionModel.result?.instamojo?.key2 ?? "";
    String requestURL =
        ((paymentProvider.paymentOptionModel.result?.instamojo?.isLive ?? "") ==
            "1")
        ? 'https://www.instamojo.com/api/1.1/payment-requests/'
        : 'https://test.instamojo.com/api/1.1/payment-requests/';
    printLog("_initInstamojo apiKey =========> $apiKey");
    printLog("_initInstamojo authToken ======> $authToken");
    printLog("_initInstamojo requestURL =====> $requestURL");

    final Map<String, dynamic> orderData = {
      'amount': double.parse(
        paymentProvider.finalAmount ?? '0',
      ).toString(), // Amount in INR
      'purpose': widget.payType ?? '',
      'buyer_name': userName ?? '',
      'email': userEmail ?? '',
      'phone': userMobileNo ?? '',
      'currency': Constant.currency,
      'send_email': 'False',
      'send_sms': 'False',
      'allow_repeated_payments': 'False',
    };

    final response = await http.post(
      Uri.parse(requestURL),
      headers: {
        "Accept": "application/json",
        'Content-Type': 'application/x-www-form-urlencoded',
        "X-Api-Key": apiKey,
        "X-Auth-Token": authToken,
      },
      body: orderData,
    );

    printLog('createInstamojoOrder statusCode : ${response.statusCode}');
    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String paymentUrl = responseData['payment_request']['longurl'];
      final String paymentReqID = responseData['payment_request']['id'];

      // Now you can open this payment URL in a WebView or a browser
      printLog('Payment URL : $paymentUrl');
      printLog('Payment ID  : $paymentReqID');
      if (!mounted) return;
      dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) =>
              InstamojoPG(paymentUrl: paymentUrl, paymentId: paymentReqID),
        ),
      );

      printLog("result =====> $result");
      printLog("paymentReqID =====> $paymentReqID");
      if (result != null && result == true) {
        _checkPaymentStatus(paymentReqID);
      }
    } else {
      // Handle error
      printLog('Failed to create Instamojo order');
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_not_processed"));
    }
  }

  Future<void> _checkPaymentStatus(String id) async {
    printLog("_checkPaymentStatus id =========> $id");
    String apiKey =
        paymentProvider.paymentOptionModel.result?.instamojo?.key1 ?? "";
    String authToken =
        paymentProvider.paymentOptionModel.result?.instamojo?.key2 ?? "";
    String requestURL =
        ((paymentProvider.paymentOptionModel.result?.instamojo?.isLive ?? "") ==
            "1")
        ? 'https://www.instamojo.com/api/1.1/payment-requests/'
        : 'https://test.instamojo.com/api/1.1/payment-requests/';
    printLog("_checkPaymentStatus apiKey =========> $apiKey");
    printLog("_checkPaymentStatus authToken ======> $authToken");
    printLog("_checkPaymentStatus requestURL =====> $requestURL");

    final response = await http.get(
      Uri.parse('$requestURL$id/'),
      headers: {
        "Accept": "application/json",
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Api-Key': apiKey,
        'X-Auth-Token': authToken,
      },
    );

    printLog('createInstamojoOrder statusCode : ${response.statusCode}');
    final Map<String, dynamic> realResponse = json.decode(response.body);
    if (realResponse['success'] == true &&
        realResponse["payment_request"]['payments'] != null) {
      List<dynamic> myPayments = [];
      myPayments = realResponse["payment_request"]['payments'];
      if (myPayments.isNotEmpty) {
        if (myPayments[0]['status'] == "Credit") {
          paymentProvider.paymentId = myPayments[0]['payment_id'];
          _gatewayTxnId = myPayments[0]['payment_id']
              ?.toString(); // Instamojo payment ID
          printLog(
            'createInstamojoOrder paymentId : ${paymentProvider.paymentId}',
          );

          if (!mounted) return;
          Utils.showToast(Locales.string(context, "payment_success"));

          await updateTransStatus(2);
          printLog("PAYMENT STATUS SUCCESS");
          //payment is successful.
        } else {
          printLog("PAYMENT STATUS PENDING");
          if (!mounted) return;
          Utils.showToast(Locales.string(context, "payment_fail"));
          await updateTransStatus(3);
          //payment failed or pending.
        }
      } else {
        printLog("PAYMENT STATUS PENDING");
        if (!mounted) return;
        Utils.showToast(Locales.string(context, "payment_cancel"));
        await updateTransStatus(3);
        //payment failed or pending.
      }
    } else {
      printLog("PAYMENT STATUS PENDING");
      if (!mounted) return;
      Utils.showToast(Locales.string(context, "payment_fail"));
      await updateTransStatus(3);
      //payment failed or pending.
    }
  }
  /* ********* Instamojo END ********* */

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    if (kIsWeb) {
      if (context.canPop()) {
        context.pop(isPaymentDone);
      }
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, isPaymentDone);
      }
    }
  }
}

class _GatewayItem {
  final String pgName;
  final String imageName;
  final String displayName;
  const _GatewayItem(this.pgName, this.imageName, this.displayName);
}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  SharedPre sharedPref = SharedPre();
  late PaymentProvider paymentProvider;
  late BottombarProvider bottombarProvider;
  late ProfileProvider profileProvider;

  @override
  void initState() {
    super.initState();
    paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? payType = await sharedPref.read("payType");
      String? itemId = await sharedPref.read("itemId");
      String? price = await sharedPref.read("price");
      String? itemTitle = await sharedPref.read("itemTitle");
      String? typeId = await sharedPref.read("typeId");
      String? videoType = await sharedPref.read("videoType");
      String? productPackage = await sharedPref.read("productPackage");
      String? currency = await sharedPref.read("currency");
      String? paymentId = await sharedPref.read("paymentId");

      /* Save Params */
      await paymentProvider.setCurrentPayParams(
        payType: payType ?? "",
        itemId: itemId ?? "",
        price: price ?? "",
        itemTitle: itemTitle ?? "",
        typeId: typeId ?? "",
        videoType: videoType ?? "",
        productPackage: productPackage ?? "",
        currency: currency ?? "",
        paymentId: paymentId ?? "",
      );
      printLog('_getData payType =========> ${paymentProvider.payType}');
      printLog('_getData itemId ==========> ${paymentProvider.itemId}');
      printLog('_getData finalAmount =====> ${paymentProvider.finalAmount}');
      printLog('_getData itemTitle =======> ${paymentProvider.itemTitle}');
      printLog('_getData typeId ==========> ${paymentProvider.typeId}');
      printLog('_getData videoType =======> ${paymentProvider.videoType}');
      printLog('_getData productPackage ==> ${paymentProvider.productPackage}');
      printLog('_getData currency ========> ${paymentProvider.currency}');
      printLog('_getData paymentId =======> ${paymentProvider.paymentId}');
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        if (!mounted) return;
        _redirectTo();
      });
    });
  }

  /* update_transaction_status API */
  Future<void> _redirectTo() async {
    LoadingOverlay().show(context);

    int transId = paymentProvider.transSuccessModel.result?[0].id ?? 0;
    printLog("updateTransStatus transId ===> $transId");

    try {
      await paymentProvider.updateTransStatus(
        (paymentProvider.payType == "Rent")
            ? 2
            : 1, // 1-Package Transaction, 2-Rent Transaction
        transId,
        2, // 1-Processing, 2-Success, 3-Failed
      );

      if (!paymentProvider.payLoading) {
        if (!mounted) return;
        LoadingOverlay().hide();

        if (paymentProvider.updateStatusModel.status == 200) {
          await profileProvider.getProfile(context);
          if (!(context.mounted)) return;
          Utils.clearPayParams();
          paymentProvider.clearProvider();
          if (!mounted) return;
          if (kIsWeb) {
            Utils.exitPage(context);
            if (!mounted) return;
            context.pushReplacementNamed(RoutesConstant.homePage);
          } else {
            await bottombarProvider.setBottomNavIndex(0);
            if (!mounted) return;
            Utils.redirectToMainPage(context: context);
          }
        } else {
          Utils.showToast(paymentProvider.updateStatusModel.message ?? "");
        }
      }
    } on Exception catch (e) {
      printLog("updateTransStatus Error ===> ${e.toString()}");
      if (!mounted) return;
      LoadingOverlay().hide();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MyText(
          color: greenColor,
          text: "Payment Successful.",
          multilanguage: false,
          fontsizeNormal: 30,
          fontsizeWeb: 40,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w700,
          textalign: TextAlign.center,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }
}

class CancelPage extends StatefulWidget {
  const CancelPage({super.key});

  @override
  State<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends State<CancelPage> {
  late PaymentProvider paymentProvider;
  late BottombarProvider bottombarProvider;
  late ProfileProvider profileProvider;

  @override
  void initState() {
    super.initState();
    paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        if (!mounted) return;
        _redirectTo();
      });
    });
  }

  /* update_transaction_status API */
  Future<void> _redirectTo() async {
    LoadingOverlay().show(context);

    int transId = paymentProvider.transSuccessModel.result?[0].id ?? 0;
    printLog("updateTransStatus transId ===> $transId");

    try {
      await paymentProvider.updateTransStatus(
        (paymentProvider.payType == "Rent")
            ? 2
            : 1, // 1-Package Transaction, 2-Rent Transaction
        transId,
        3, // 1-Processing, 2-Success, 3-Failed
      );

      if (!paymentProvider.payLoading) {
        if (!mounted) return;
        LoadingOverlay().hide();

        if (paymentProvider.updateStatusModel.status == 200) {
          await profileProvider.getProfile(context);

          Utils.clearPayParams();
          paymentProvider.clearProvider();
          if (!mounted) return;
          if (kIsWeb) {
            Utils.exitPage(context);
            if (!mounted) return;
            context.pushReplacementNamed(RoutesConstant.homePage);
          } else {
            await bottombarProvider.setBottomNavIndex(0);
            if (!mounted) return;
            Utils.redirectToMainPage(context: context);
          }
        } else {
          Utils.showToast(paymentProvider.updateStatusModel.message ?? "");
        }
      }
    } on Exception catch (e) {
      printLog("updateTransStatus Error ===> ${e.toString()}");
      if (!mounted) return;
      LoadingOverlay().hide();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MyText(
          color: redColor,
          text: "Payment Cancelled.",
          multilanguage: false,
          fontsizeNormal: 30,
          fontsizeWeb: 40,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w700,
          textalign: TextAlign.center,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }
}
