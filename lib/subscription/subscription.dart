import 'dart:async';
import 'dart:io';
import '../provider/paymentprovider.dart';
import '../provider/subhistoryprovider.dart';
import '../routes/routes_constant.dart';
import '../subscription/contactus.dart';
import '../subscription/subscriptionhistory.dart';
import 'package:go_router/go_router.dart';

import '../model/subscriptionmodel.dart';
import '../shimmer/shimmerutils.dart';
import '../subscription/allpayment.dart';
import '../utils/adhelper.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/sharedpre.dart';
import '../webpages/webcomman.dart';
import '../widget/nodata.dart';
import '../provider/subscriptionprovider.dart';
import '../utils/color.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class Subscription extends StatefulWidget {
  final String? newPage, oldPage;
  const Subscription({required this.newPage, required this.oldPage, super.key});

  @override
  State<Subscription> createState() => SubscriptionState();
}

class SubscriptionState extends State<Subscription> {
  late SubscriptionProvider subscriptionProvider;
  SharedPre sharedPre = SharedPre();
  String? userName, userEmail, userMobileNo;
  int _webHoveredCardIndex = -1;

  @override
  void initState() {
    super.initState();
    subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    _getData();
  }

  Future<void> _getData() async {
    Utils.getCurrencySymbol();
    await subscriptionProvider.getPackages();
    await _getUserData();
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscriptionProvider.clearProvider();
    super.dispose();
  }

  Future<void> _checkAndPay(List<Result>? packageList, int index) async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    if (Utils.checkLoginUser(context)) {
      if (packageList?[index].isBuy == 1) {
        printLog("<============= Purchaged =============>");
        Utils.showSnackbar(context, "info", "already_purchased", true);
        return;
      }
      if (userName == null ||
          (userName ?? "").isEmpty ||
          (userName ?? "").contains("null") ||
          userEmail == null ||
          (userEmail ?? "").isEmpty ||
          (userEmail ?? "").contains("null") ||
          userMobileNo == null ||
          (userMobileNo ?? "").isEmpty ||
          (userMobileNo ?? "").contains("null")) {
        updateDataDialog(
          isNameReq:
              (userName == null ||
              (userName ?? "").isEmpty ||
              (userName ?? "").contains("null")),
          isEmailReq:
              userEmail == null ||
              (userEmail ?? "").isEmpty ||
              (userEmail ?? "").contains("null"),
          isMobileReq:
              userMobileNo == null ||
              (userMobileNo ?? "").isEmpty ||
              (userMobileNo ?? "").contains("null"),
        );
        return;
      }
      await paymentProvider.setLoading(true);
      if (!mounted) return;
      if (kIsWeb) {
        final extraParams = {
          'newpage': widget.newPage.toString(),
          'paytype': 'Package',
          'producerid': '',
          'itemid': packageList?[index].id.toString() ?? '',
          'price': packageList?[index].price.toString() ?? '',
          'title': packageList?[index].name.toString() ?? '',
          'videotype': '',
          'subvideotype': '',
          'typeid': '',
          'currency': '',
          'productpackage': (kIsWeb)
              ? (packageList?[index].webPriceId.toString() ?? '')
              : (Platform.isIOS
                    ? (packageList?[index].iosProductPackage.toString() ?? '')
                    : (packageList?[index].androidProductPackage.toString() ??
                          '')),
        };
        context.go("/${RoutesConstant.paymentPage}", extra: extraParams);
      } else {
        if (widget.newPage != RoutesConstant.subscriptionPage) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AllPayment(
                  newPage: RoutesConstant.paymentPage,
                  oldPage: widget.newPage.toString(),
                  reqText: '',
                  payType: 'Package',
                  producerId: '',
                  itemId: packageList?[index].id.toString() ?? '',
                  price: packageList?[index].price.toString() ?? '',
                  itemTitle: packageList?[index].name.toString() ?? '',
                  typeId: '',
                  videoType: '',
                  subVideoType: '',
                  productPackage: (kIsWeb)
                      ? (packageList?[index].webPriceId.toString() ?? '')
                      : (Platform.isIOS
                            ? (packageList?[index].iosProductPackage
                                      .toString() ??
                                  '')
                            : (packageList?[index].androidProductPackage
                                      .toString() ??
                                  '')),
                  currency: '',
                );
              },
            ),
          );
        } else {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return AllPayment(
                  newPage: RoutesConstant.paymentPage,
                  oldPage: widget.newPage,
                  reqText: Constant.userID,
                  payType: 'Package',
                  producerId: '',
                  itemId: packageList?[index].id.toString() ?? '',
                  price: packageList?[index].price.toString() ?? '',
                  itemTitle: packageList?[index].name.toString() ?? '',
                  typeId: '',
                  videoType: '',
                  subVideoType: '',
                  productPackage: (kIsWeb)
                      ? (packageList?[index].webPriceId.toString() ?? '')
                      : (Platform.isIOS
                            ? (packageList?[index].iosProductPackage
                                      .toString() ??
                                  '')
                            : (packageList?[index].androidProductPackage
                                      .toString() ??
                                  '')),
                  currency: '',
                );
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return child;
                  },
            ),
          );
        }
      }
    }
  }

  Future<void> _getUserData() async {
    userName = await sharedPre.read("userfullname");
    userEmail = await sharedPre.read("useremail");
    userMobileNo = await sharedPre.read("usermobile");
    printLog('getUserData userName ======> $userName');
    printLog('getUserData userEmail =====> $userEmail');
    printLog('getUserData userMobileNo ==> $userMobileNo');
  }

  Future<void> updateDataDialog({
    required bool isNameReq,
    required bool isEmailReq,
    required bool isMobileReq,
  }) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    if (!context.mounted) return;
    dynamic result;
    if (kIsWeb || Constant.isTV) {
      result = await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            alignment: Alignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            insetPadding: EdgeInsets.fromLTRB(
              (MediaQuery.of(context).size.width > 1000) ? 50 : 30,
              (MediaQuery.of(context).size.width > 1000)
                  ? ((MediaQuery.of(context).size.height > 500) ? 50 : 30)
                  : 30,
              (MediaQuery.of(context).size.width > 1000) ? 50 : 30,
              (MediaQuery.of(context).size.width > 1000)
                  ? ((MediaQuery.of(context).size.height > 500) ? 50 : 30)
                  : 30,
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            backgroundColor: lightBlack,
            child: Utils.dataUpdateDialog(
              context,
              isNameReq: isNameReq,
              isEmailReq: isEmailReq,
              isMobileReq: isMobileReq,
              nameController: nameController,
              emailController: emailController,
              mobileController: mobileController,
            ),
          );
        },
      );
    } else {
      result = await showModalBottomSheet<dynamic>(
        context: context,
        backgroundColor: lightBlack,
        isScrollControlled: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              Utils.dataUpdateDialog(
                context,
                isNameReq: isNameReq,
                isEmailReq: isEmailReq,
                isMobileReq: isMobileReq,
                nameController: nameController,
                emailController: emailController,
                mobileController: mobileController,
              ),
            ],
          );
        },
      );
    }
    if (result != null) {
      await _getUserData();
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: widget.newPage,
        oldPage: widget.oldPage,
        reqText: '',
        newChild: _buildSubscription(),
      );
    } else {
      return Scaffold(
        backgroundColor: appBgColor,
        bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
        appBar: Utils.myAppBarWithBack(context, "subsciption", true),
        body: SingleChildScrollView(child: _buildSubscription()),
      );
    }
  }

  // ─────────────────────────── STATE HELPERS ───────────────────────────────

  bool _isCurrentPlan(Result pkg) => pkg.isBuy == 1 && pkg.isActivePlan == 1;
  bool _isUpcomingPlan(Result pkg) => pkg.isBuy == 1 && pkg.isActivePlan != 1;

  bool _isBestValue(List<Result> packageList, int index) {
    if (packageList.length < 2) return false;
    if (packageList[index].isBuy == 1) return false;
    return index == packageList.length ~/ 2;
  }

  // ─────────────────────────── MAIN COLUMN ─────────────────────────────────

  Widget _buildSubscription() {
    if (subscriptionProvider.loading) {
      return Dimens.isBigScreen(context)
          ? ShimmerUtils.buildSubscribeWebShimmer(context)
          : ShimmerUtils.buildSubscribeShimmer(context);
    }
    if (subscriptionProvider.subscriptionModel.status == 200) {
      final bool isWeb = Dimens.isBigScreen(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: isWeb ? (Dimens.homeTabHeight + 20) : 20),
          _buildPremiumHeroSection(),
          SizedBox(height: isWeb ? 44 : 28),
          _buildPlansSection(subscriptionProvider.subscriptionModel.result),
          SizedBox(height: isWeb ? 44 : 32),
          _buildHistoryBtn(),
          SizedBox(height: isWeb ? 20 : 16),
          _buildBottomView(),
          SizedBox(height: isWeb ? 40 : 24),
        ],
      );
    }
    return const NoData(title: '', subTitle: '');
  }

  // ─────────────────────────── HERO SECTION ────────────────────────────────

  Widget _buildPremiumHeroSection() {
    final bool isWeb = Dimens.isBigScreen(context);

    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        isWeb ? 60 : 24,
        isWeb ? 44 : 30,
        isWeb ? 60 : 24,
        isWeb ? 44 : 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorPrimary.withValues(alpha: 0.32),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyImage(
                  imagePath: "ic_star.png",
                  width: 12,
                  height: 12,
                  color: colorPrimary,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                MyText(
                  color: colorPrimary,
                  text: "premium_access",
                  multilanguage: true,
                  fontsizeNormal: 11,
                  fontsizeWeb: 12,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                  letterSpacing: 0.6,
                ),
              ],
            ),
          ),
          SizedBox(height: isWeb ? 20 : 16),
          // Large title
          MyText(
            color: white,
            text: "subsciption",
            multilanguage: true,
            fontsizeNormal: 28,
            fontsizeWeb: 40,
            fontweight: FontWeight.w800,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
            letterSpacing: isWeb ? -1.0 : -0.5,
          ),
          const SizedBox(height: 12),
          // Subtitle
          MyText(
            color: descTextColor,
            text: "subscriptiondesc",
            multilanguage: true,
            fontsizeNormal: 13,
            fontsizeWeb: 16,
            fontweight: FontWeight.w400,
            maxline: 3,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          if (isWeb) ...[
            const SizedBox(height: 8),
            MyText(
              color: descTextColor.withValues(alpha: 0.50),
              text: "subsciptionnotes",
              multilanguage: true,
              fontsizeNormal: 12,
              fontsizeWeb: 14,
              fontweight: FontWeight.w400,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.italic,
            ),
          ],
        ],
      ),
    );

    final Widget hero = Stack(
      children: [
        // Radial glow
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.9,
                  colors: [colorPrimary.withValues(alpha: 0.07), transparent],
                ),
              ),
            ),
          ),
        ),
        content,
      ],
    );

    final Widget container = Container(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lightBlack,
            secondaryBgColor.withValues(alpha: 0.45),
            appBgColor,
          ],
          stops: const [0.0, 0.50, 1.0],
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        border: Border.all(color: white.withValues(alpha: 0.07), width: 1),
      ),
      child: hero,
    );

    if (isWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: container,
        ),
      );
    }
    return container;
  }

  // ─────────────────────────── PLANS SECTION ───────────────────────────────

  Widget _buildPlansSection(List<Result>? packageList) {
    if (packageList == null || packageList.isEmpty) {
      return const SizedBox.shrink();
    }
    if (Dimens.isBigScreen(context)) {
      return _buildWebPlans(packageList);
    }
    return _buildMobilePlans(packageList);
  }

  /// Mobile: vertical stacked list — no carousel, all plans visible at once.
  Widget _buildMobilePlans(List<Result> packageList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(packageList.length, (index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
            child: _buildPlanCard(packageList, index, isMobile: true),
          );
        }),
      ),
    );
  }

  /// Web: responsive grid, max 3 columns, constrained to 1100px.
  Widget _buildWebPlans(List<Result> packageList) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ResponsiveGridList(
            minItemWidth: 280.0,
            verticalGridSpacing: 24,
            horizontalGridSpacing: 24,
            minItemsPerRow: 1,
            maxItemsPerRow: 3,
            listViewBuilderOptions: ListViewBuilderOptions(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            children: List.generate(packageList.length, (index) {
              final bool isHovered = _webHoveredCardIndex == index;
              final bool isCurrent = _isCurrentPlan(packageList[index]);
              final bool isUpcoming = _isUpcomingPlan(packageList[index]);
              return MouseRegion(
                cursor: (isCurrent || isUpcoming)
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                onEnter: (_) => setState(() => _webHoveredCardIndex = index),
                onExit: (_) => setState(() => _webHoveredCardIndex = -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  transform: isHovered
                      ? (Matrix4.identity()
                          ..translateByDouble(0.0, -4.0, 0.0, 1.0))
                      : Matrix4.identity(),
                  child: _buildPlanCard(
                    packageList,
                    index,
                    isHovered: isHovered,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── PLAN CARD ───────────────────────────────────

  Widget _buildPlanCard(
    List<Result> packageList,
    int index, {
    bool isMobile = false,
    bool isHovered = false,
  }) {
    final Result pkg = packageList[index];
    final bool isCurrent = _isCurrentPlan(pkg);
    final bool isUpcoming = _isUpcomingPlan(pkg);
    final bool isBestValue = _isBestValue(packageList, index);

    final Color borderColor = isCurrent
        ? colorPrimary
        : (isUpcoming
              ? descTextColor.withValues(alpha: 0.25)
              : (isHovered
                    ? white.withValues(alpha: 0.22)
                    : white.withValues(alpha: 0.09)));

    // Benefits widget differs: mobile = full column, web = constrained with inner scroll
    final Widget benefitsWidget = isMobile
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: _buildBenefitsList(packageList, index),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: _buildBenefitsList(packageList, index),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? lightBlack : secondaryBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1.0),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: colorPrimary.withValues(alpha: 0.13),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ]
            : (isHovered && !isMobile)
            ? [
                BoxShadow(
                  color: black.withValues(alpha: 0.40),
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top accent strip
            _buildAccentStrip(isCurrent, isBestValue),
            // Plan name + badge row
            _buildPlanHeader(pkg, isCurrent, isUpcoming, isBestValue),
            // Price
            _buildPlanPrice(pkg),
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: white.withValues(alpha: 0.07),
            ),
            // Benefits
            benefitsWidget,
            // Bottom divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: white.withValues(alpha: 0.05),
            ),
            // CTA
            _buildPlanCTA(packageList, index, isCurrent, isUpcoming),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentStrip(bool isCurrent, bool isBestValue) {
    final List<Color> colors;
    if (isCurrent) {
      colors = [colorPrimary, colorPrimaryDark];
    } else if (isBestValue) {
      colors = [
        colorAccent.withValues(alpha: 0.85),
        colorAccent.withValues(alpha: 0.45),
      ];
    } else {
      return const SizedBox(height: 3);
    }
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildPlanHeader(
    Result pkg,
    bool isCurrent,
    bool isUpcoming,
    bool isBestValue,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MyText(
              color: white,
              text: pkg.name ?? "",
              multilanguage: false,
              fontsizeNormal: 18,
              fontsizeWeb: 20,
              fontweight: FontWeight.w700,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(width: 8),
          _buildPlanBadge(isCurrent, isUpcoming, isBestValue),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(bool isCurrent, bool isUpcoming, bool isBestValue) {
    if (!isCurrent && !isUpcoming && !isBestValue) {
      return const SizedBox.shrink();
    }

    final String text;
    final Color bg;
    final Color border;
    final Color fg;

    if (isCurrent) {
      text = "current";
      bg = colorPrimary.withValues(alpha: 0.14);
      border = colorPrimary.withValues(alpha: 0.42);
      fg = colorPrimary;
    } else if (isUpcoming) {
      text = "upcoming";
      bg = descTextColor.withValues(alpha: 0.08);
      border = descTextColor.withValues(alpha: 0.26);
      fg = descTextColor;
    } else {
      text = "best_value";
      bg = colorAccent.withValues(alpha: 0.10);
      border = colorAccent.withValues(alpha: 0.36);
      fg = colorAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: MyText(
        color: fg,
        text: text,
        multilanguage: true,
        fontsizeNormal: 10,
        fontsizeWeb: 11,
        fontweight: FontWeight.w600,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  Widget _buildPlanPrice(Result pkg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Currency symbol (superscript style)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MyText(
              color: descTextColor,
              text: Constant.currencySymbol,
              multilanguage: false,
              fontsizeNormal: 16,
              fontsizeWeb: 18,
              fontweight: FontWeight.w500,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(width: 2),
          // Big price
          MyText(
            color: colorPrimary,
            text: "${pkg.price}",
            multilanguage: false,
            fontsizeNormal: 36,
            fontsizeWeb: 42,
            fontweight: FontWeight.w800,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(width: 6),
          // Duration — sit near baseline
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MyText(
              color: descTextColor.withValues(alpha: 0.70),
              text: "/ ${pkg.time ?? ""} ${pkg.type ?? ""}",
              multilanguage: false,
              fontsizeNormal: 12,
              fontsizeWeb: 13,
              fontweight: FontWeight.w400,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── BENEFITS LIST ───────────────────────────────

  Widget _buildBenefitsList(List<Result>? packageList, int index) {
    final data = packageList?[index].data;
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(data.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < data.length - 1 ? 12 : 0),
          child: _buildBenefitRow(
            data[i].packageKey ?? "",
            data[i].packageValue ?? "",
          ),
        );
      }),
    );
  }

  Widget _buildBenefitRow(String keyText, String valueText) {
    final bool showToggle =
        (valueText == "1" || valueText == "0") &&
        !keyText.contains(RegExp(r'[0-9]'));
    final bool isEnabled = valueText == "1";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: MyText(
            color: descTextColor,
            text: keyText,
            multilanguage: false,
            fontsizeNormal: 13,
            fontsizeWeb: 14,
            fontweight: FontWeight.w400,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: showToggle
                ? (isEnabled
                      ? colorPrimary.withValues(alpha: 0.12)
                      : redColor.withValues(alpha: 0.09))
                : white.withValues(alpha: 0.07),
            shape: BoxShape.circle,
            border: Border.all(
              color: showToggle
                  ? (isEnabled
                        ? colorPrimary.withValues(alpha: 0.36)
                        : redColor.withValues(alpha: 0.30))
                  : white.withValues(alpha: 0.13),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: showToggle
              ? MyImage(
                  imagePath: isEnabled ? "tick_mark.png" : "cross_mark.png",
                  width: 10,
                  height: 10,
                  color: isEnabled ? colorPrimary : redColor,
                  fit: BoxFit.contain,
                )
              : MyText(
                  color: white,
                  text: valueText,
                  multilanguage: false,
                  fontsizeNormal: 9,
                  fontsizeWeb: 10,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
        ),
      ],
    );
  }

  // ─────────────────────────── PLAN CTA ────────────────────────────────────

  Widget _buildPlanCTA(
    List<Result> packageList,
    int index,
    bool isCurrent,
    bool isUpcoming,
  ) {
    final bool locked = isCurrent || isUpcoming;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Material(
        color: transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: locked ? null : () => _checkAndPay(packageList, index),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: locked
                  ? null
                  : const LinearGradient(
                      colors: [colorPrimary, colorPrimaryDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: locked ? transparent : null,
              borderRadius: BorderRadius.circular(12),
              border: locked
                  ? Border.all(
                      color: isCurrent
                          ? colorPrimary.withValues(alpha: 0.35)
                          : descTextColor.withValues(alpha: 0.20),
                      width: 1,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: MyText(
              color: locked
                  ? (isCurrent ? colorPrimary : descTextColor)
                  : black,
              text: isCurrent
                  ? "current"
                  : (isUpcoming ? "upcoming" : "chooseplan"),
              multilanguage: true,
              fontsizeNormal: 15,
              fontsizeWeb: 16,
              fontweight: FontWeight.w700,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── HISTORY BUTTON ──────────────────────────────

  Widget _buildHistoryBtn() {
    if (Constant.userIsKid == true) return const SizedBox.shrink();
    final bool isWeb = Dimens.isBigScreen(context);

    final Widget btn = MouseRegion(
      cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final subHistoryProvider = Provider.of<SubHistoryProvider>(
            context,
            listen: false,
          );
          if (!mounted) return;
          if (Constant.userID != null) {
            subHistoryProvider.setLoading(true);
            if (!mounted) return;
            if (kIsWeb) {
              context.go(
                "/${RoutesConstant.subsHistoryPage}",
                extra: widget.newPage,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionHistory(
                    newPage: RoutesConstant.subsHistoryPage,
                    oldPage: '',
                    reqText: '',
                  ),
                ),
              );
            }
          } else {
            Utils.openLogin(context: context, newPage: "");
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 32 : 24,
            vertical: isWeb ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: secondaryBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: white.withValues(alpha: 0.11), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyImage(
                imagePath: "ic_eye.png",
                width: 15,
                height: 15,
                color: descTextColor,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              MyText(
                color: white,
                text: "view_transactions",
                multilanguage: true,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ],
          ),
        ),
      ),
    );

    return Center(child: btn);
  }

  // ─────────────────────────── BOTTOM SUPPORT VIEW ─────────────────────────

  Widget _buildBottomView() {
    final bool isWeb = Dimens.isBigScreen(context);

    final Widget card = Container(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 16),
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightBlack, secondaryBgColor],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: white.withValues(alpha: 0.07), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorPrimary.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: MyImage(
              imagePath: "ic_calling.png",
              height: 20,
              width: 20,
              fit: BoxFit.contain,
              color: colorPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: titleTextColor,
                  text: "subscription_issue_help",
                  multilanguage: true,
                  fontsizeNormal: 13,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w500,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 5),
                MouseRegion(
                  cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
                  child: GestureDetector(
                    onTap: () {
                      if (kIsWeb) {
                        context.go(
                          "/${RoutesConstant.contactUsPage}",
                          extra: RoutesConstant.subscriptionPage,
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactUs(
                              newPage: RoutesConstant.contactUsPage,
                              oldPage: RoutesConstant.subscriptionPage,
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(
                          color: colorPrimary,
                          text: "contact_support_team",
                          multilanguage: true,
                          fontsizeNormal: 13,
                          fontsizeWeb: 15,
                          fontweight: FontWeight.w600,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(width: 4),
                        MyImage(
                          imagePath: "ic_arrow_right.png",
                          width: 12,
                          height: 12,
                          color: colorPrimary,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: card,
        ),
      );
    }
    return card;
  }
}
