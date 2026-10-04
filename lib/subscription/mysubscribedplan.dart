import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../webpages/webcomman.dart';
import '../provider/mysubscribedplanprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/subscriptionprovider.dart';
import '../routes/routes_constant.dart';
import '../subscription/subscription.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class MySubscribedPlan extends StatefulWidget {
  final String? newPage, oldPage;
  const MySubscribedPlan({
    required this.newPage,
    required this.oldPage,
    super.key,
  });

  @override
  State<MySubscribedPlan> createState() => _MySubscribedPlanState();
}

class _MySubscribedPlanState extends State<MySubscribedPlan> {
  late MySubscribedPlanProvider mySubscribedPlanProvider;
  late ProfileProvider profileProvider;

  @override
  void initState() {
    super.initState();
    mySubscribedPlanProvider = Provider.of<MySubscribedPlanProvider>(
      context,
      listen: false,
    );
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    await mySubscribedPlanProvider.getMyPlan();
    if (!mounted) return;
    profileProvider.getProfile(context);

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    mySubscribedPlanProvider.clearProvider();
    super.dispose();
  }

  String get topTitleText {
    if (mySubscribedPlanProvider.mySubscriptionModel.result != null &&
        (mySubscribedPlanProvider.mySubscriptionModel.result?.length ?? 0) >
            0) {
      if ((mySubscribedPlanProvider.mySubscriptionModel.result?[0].type ?? "")
                  .toLowerCase() ==
              'month' &&
          int.parse(
                mySubscribedPlanProvider.mySubscriptionModel.result?[0].time ??
                    "0",
              ) ==
              1) {
        return 'Monthly pack activated through';
      } else if ((mySubscribedPlanProvider
                          .mySubscriptionModel
                          .result?[0]
                          .type ??
                      "")
                  .toLowerCase() ==
              'month' &&
          int.parse(
                mySubscribedPlanProvider.mySubscriptionModel.result?[0].time ??
                    "0",
              ) ==
              3) {
        return 'Quarterly pack activated through';
      } else if ((mySubscribedPlanProvider
                      .mySubscriptionModel
                      .result?[0]
                      .type ??
                  "")
              .toLowerCase() ==
          'year') {
        return 'Yearly pack activated through';
      } else {
        return 'Subscription pack activated through';
      }
    } else {
      return 'Subscription pack activated through';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: widget.newPage,
        oldPage: widget.oldPage,
        reqText: '',
        newChild: _setPageUI(),
      );
    } else {
      return Scaffold(
        backgroundColor: appBgColor,
        appBar: Utils.myAppBarWithBack(context, "my_subscription", true),
        body: _setPageUI(),
      );
    }
  }

  Widget _setPageUI() {
    if (kIsWeb) {
      return Column(
        children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 40 : 25,
              (Dimens.homeTabHeight + 10),
              Dimens.isBigScreen(context) ? 40 : 25,
              20,
            ),
            child: MyText(
              text: 'my_subscription',
              multilanguage: true,
              color: colorPrimary,
              fontsizeNormal: 20,
              fontsizeWeb: 25,
              maxline: 1,
              fontweight: FontWeight.w600,
              fontstyle: FontStyle.normal,
              textalign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width > 1080
                ? (MediaQuery.of(context).size.width * 0.65)
                : ((MediaQuery.of(context).size.width <= 1080 &&
                          (MediaQuery.of(context).size.width > 720))
                      ? (MediaQuery.of(context).size.width * 0.8)
                      : MediaQuery.of(context).size.width),
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 50 : 20,
              0,
              Dimens.isBigScreen(context) ? 50 : 30,
              0,
            ),
            padding: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 30 : 20,
              0,
              Dimens.isBigScreen(context) ? 30 : 20,
              0,
            ),
            alignment: Alignment.center,
            child: _buildPage(),
          ),
        ],
      );
    } else {
      return _buildPage();
    }
  }

  Widget _buildPage() {
    return Consumer<MySubscribedPlanProvider>(
      builder: (context, mySubscribedPlanProvider, child) {
        if (mySubscribedPlanProvider.loading) {
          return Center(
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Utils.pageLoader(),
            ),
          );
        }
        if (mySubscribedPlanProvider.mySubscriptionModel.result != null &&
            (mySubscribedPlanProvider.mySubscriptionModel.result?.length ?? 0) >
                0) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 25),
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /* Title & AppIcon */
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(17, 20, 17, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: MyText(
                          color: titleTextColor,
                          text: topTitleText,
                          textalign: TextAlign.start,
                          fontsizeNormal: 14,
                          fontsizeWeb: 17,
                          maxline: 4,
                          multilanguage: false,
                          overflow: TextOverflow.ellipsis,
                          fontweight: FontWeight.w500,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                      /* App Icon */
                      Container(
                        height: Dimens.isBigScreen(context)
                            ? Dimens.appIconSettingHeightWeb
                            : Dimens.appIconSettingHeight,
                        width: Dimens.isBigScreen(context)
                            ? Dimens.appIconSettingWidthWeb
                            : Dimens.appIconSettingWidth,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        alignment: Alignment.center,
                        decoration: Utils.setBGWithBorder(
                          transparent,
                          descTextColor.withValues(alpha: 0.3),
                          10,
                          0.5,
                        ),
                        child: MyImage(
                          imagePath: "appicon.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                /* Purchased Plan details */
                _buildCurrentPlan(),
                /* Upgrade Now */
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(17, 15, 17, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: MyText(
                          color: titleTextColor,
                          text: "upgrade_plan_desc",
                          textalign: TextAlign.start,
                          fontsizeNormal: 14,
                          fontsizeWeb: 16,
                          maxline: 4,
                          multilanguage: true,
                          overflow: TextOverflow.ellipsis,
                          fontweight: FontWeight.w500,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                      /* Upgrade Now */
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          final subscriptionProvider =
                              Provider.of<SubscriptionProvider>(
                                context,
                                listen: false,
                              );
                          await subscriptionProvider.setLoading(true);
                          if (!context.mounted) return;
                          if (Constant.userID != null) {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                      return Subscription(
                                        newPage:
                                            RoutesConstant.subscriptionPage,
                                        oldPage: widget.newPage ?? "",
                                      );
                                    },
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child;
                                    },
                              ),
                            );
                          } else {
                            Utils.openLogin(context: context, newPage: "");
                          }
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: MyText(
                            color: black,
                            text: "upgrade_now",
                            textalign: TextAlign.center,
                            fontsizeNormal: 14,
                            fontsizeWeb: 16,
                            fontweight: FontWeight.w500,
                            multilanguage: true,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.7,
                  margin: const EdgeInsets.fromLTRB(0, 23, 0, 23),
                  width: MediaQuery.of(context).size.width,
                  decoration: Utils.setBackground(
                    white.withValues(alpha: 0.6),
                    1,
                  ),
                ),

                /* Upcoming Plan */
                if (mySubscribedPlanProvider.upcomingPlanModel.result != null &&
                    (mySubscribedPlanProvider
                                .upcomingPlanModel
                                .result
                                ?.length ??
                            0) >
                        0)
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                    child: MyText(
                      color: titleTextColor,
                      text: "upcoming_subscription",
                      multilanguage: true,
                      textalign: TextAlign.start,
                      fontsizeNormal: 17,
                      fontsizeWeb: 19,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      fontweight: FontWeight.w600,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                if (mySubscribedPlanProvider.upcomingPlanModel.result != null &&
                    (mySubscribedPlanProvider
                                .upcomingPlanModel
                                .result
                                ?.length ??
                            0) >
                        0)
                  _buildUpcomingPlan(),
              ],
            ),
          );
        } else {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NoData(
                    title: "no_purchase_plan",
                    subTitle: "no_purchase_plan_desc",
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        final subscriptionProvider =
                            Provider.of<SubscriptionProvider>(
                              context,
                              listen: false,
                            );
                        if (!mounted) return;
                        if (Constant.userID != null) {
                          await subscriptionProvider.setLoading(true);
                          if (!context.mounted) return;
                          if (kIsWeb) {
                            context.go(
                              "/${RoutesConstant.subscriptionPage}",
                              extra: widget.newPage,
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    return Subscription(
                                      newPage: RoutesConstant.subscriptionPage,
                                      oldPage: widget.newPage,
                                    );
                                  },
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return child;
                                  },
                            ),
                          );
                        } else {
                          Utils.openLogin(context: context, newPage: "");
                        }
                      },
                      child: FittedBox(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              MyText(
                                color: black,
                                text: "subscribe_now",
                                textalign: TextAlign.center,
                                fontsizeNormal: 14,
                                fontsizeWeb: 16,
                                fontweight: FontWeight.w500,
                                multilanguage: true,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(width: 3),
                              MyImage(
                                height: 10,
                                width: 10,
                                imagePath: "ic_right.png",
                                fit: BoxFit.contain,
                                color: black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  /* ************** CURRENT PLAN START ************** */
  Widget _buildCurrentPlan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      padding: EdgeInsets.fromLTRB(
        0,
        Dimens.isBigScreen(context) ? 30 : 15,
        0,
        Dimens.isBigScreen(context) ? 40 : 20,
      ),
      decoration: Utils.setBackground(lightBlack, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 20 : 10,
              0,
              Dimens.isBigScreen(context) ? 20 : 10,
              0,
            ),
            alignment: Alignment.centerLeft,
            child: MyText(
              color: titleTextColor,
              text:
                  mySubscribedPlanProvider
                      .mySubscriptionModel
                      .result?[0]
                      .name ??
                  "",
              textalign: TextAlign.start,
              fontsizeNormal: 20,
              fontsizeWeb: 22,
              maxline: 3,
              multilanguage: false,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.bold,
              fontstyle: FontStyle.normal,
            ),
          ),
          Container(
            height: 1,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 20 : 10,
              15,
              Dimens.isBigScreen(context) ? 20 : 10,
              15,
            ),
            width: MediaQuery.of(context).size.width,
            decoration: Utils.setBackground(white.withValues(alpha: 0.11), 1),
          ),
          /* Benifits */
          _buildCurrentPlanBenefits(index: 0),
          Container(
            height: 1,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 20 : 10,
              15,
              Dimens.isBigScreen(context) ? 20 : 10,
              15,
            ),
            width: MediaQuery.of(context).size.width,
            decoration: Utils.setBackground(white.withValues(alpha: 0.11), 1),
          ),
          _buildCurrentPlanPrice(),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 20 : 10,
              0,
              Dimens.isBigScreen(context) ? 20 : 10,
              0,
            ),
            alignment: Alignment.centerLeft,
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return MyText(
                  color: colorPrimary,
                  text:
                      (profileProvider.profileModel.result != null &&
                          (profileProvider.profileModel.result?.length ?? 0) >
                              0)
                      ? (((profileProvider.profileModel.result?[0].isBuy ??
                                        0) ==
                                    1 &&
                                (profileProvider
                                            .profileModel
                                            .result?[0]
                                            .expiryDate ??
                                        "")
                                    .isNotEmpty)
                            ? "Valid upto ${DateFormat('dd MMM yyyy').format(DateTime.parse((profileProvider.profileModel.result?[0].expiryDate ?? "")))}"
                            : "-")
                      : "-",
                  textalign: TextAlign.start,
                  fontsizeNormal: 12,
                  fontsizeWeb: 16,
                  maxline: 1,
                  multilanguage: false,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.w500,
                  fontstyle: FontStyle.normal,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBenefits({required int index}) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 20 : 10,
        2,
        Dimens.isBigScreen(context) ? 30 : 15,
        5,
      ),
      itemCount:
          mySubscribedPlanProvider
              .mySubscriptionModel
              .result?[index]
              .data
              ?.length ??
          0,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          constraints: BoxConstraints(
            minHeight: Dimens.isBigScreen(context) ? 50 : 25,
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: MyText(
                  color: white,
                  text:
                      mySubscribedPlanProvider
                          .mySubscriptionModel
                          .result?[index]
                          .data?[position]
                          .packageKey ??
                      "",
                  textalign: TextAlign.start,
                  multilanguage: false,
                  fontsizeNormal: 12,
                  fontsizeWeb: 16,
                  maxline: 10,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.w400,
                  fontstyle: FontStyle.normal,
                ),
              ),
              const SizedBox(width: 10),
              (((mySubscribedPlanProvider
                                      .mySubscriptionModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1" ||
                          (mySubscribedPlanProvider
                                      .mySubscriptionModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "0") &&
                      !(mySubscribedPlanProvider
                                  .mySubscriptionModel
                                  .result?[index]
                                  .data?[position]
                                  .packageKey ??
                              "")
                          .contains(RegExp(r'[0-9]')))
                  ? MyImage(
                      width: Dimens.isBigScreen(context) ? 25 : 15,
                      height: Dimens.isBigScreen(context) ? 25 : 15,
                      color:
                          (mySubscribedPlanProvider
                                      .mySubscriptionModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1"
                          ? colorPrimary
                          : redColor,
                      imagePath:
                          (mySubscribedPlanProvider
                                      .mySubscriptionModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1"
                          ? "tick_mark.png"
                          : "cross_mark.png",
                    )
                  : MyImage(
                      width: Dimens.isBigScreen(context) ? 25 : 15,
                      height: Dimens.isBigScreen(context) ? 25 : 15,
                      color: white,
                      imagePath: "ic_devices.png",
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentPlanPrice() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 20 : 10,
        0,
        Dimens.isBigScreen(context) ? 20 : 10,
        0,
      ),
      margin: const EdgeInsets.only(top: 3),
      alignment: Alignment.centerLeft,
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          text: Constant.currencySymbol,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              color: white,
              fontSize: kIsWeb ? 16 : 14,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.normal,
            ),
          ),
          children: <TextSpan>[
            TextSpan(
              text:
                  mySubscribedPlanProvider.mySubscriptionModel.result?[0].price
                      .toString() ??
                  "-",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  color: white,
                  fontSize: kIsWeb ? 24 : 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
            TextSpan(
              text:
                  " per ${((mySubscribedPlanProvider.mySubscriptionModel.result?[0].type ?? "").toLowerCase() == "month" && (mySubscribedPlanProvider.mySubscriptionModel.result?[0].time ?? "") == "3") ? "quarter" : (mySubscribedPlanProvider.mySubscriptionModel.result?[0].type ?? "").toLowerCase()}",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  color: white,
                  fontSize: kIsWeb ? 16 : 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  /* *************** CURRENT PLAN END *************** */

  /* ************** UPCOMING PLAN START ************** */
  Widget _buildUpcomingPlan() {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      itemCount: mySubscribedPlanProvider.upcomingPlanModel.result?.length ?? 0,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int position) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                0,
                Dimens.isBigScreen(context) ? 30 : 15,
                0,
                Dimens.isBigScreen(context) ? 40 : 20,
              ),
              decoration: Utils.setBackground(lightBlack, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      Dimens.isBigScreen(context) ? 20 : 10,
                      0,
                      Dimens.isBigScreen(context) ? 20 : 10,
                      0,
                    ),
                    alignment: Alignment.centerLeft,
                    child: MyText(
                      color: titleTextColor,
                      text:
                          mySubscribedPlanProvider
                              .upcomingPlanModel
                              .result?[position]
                              .name ??
                          "",
                      textalign: TextAlign.start,
                      fontsizeNormal: 20,
                      fontsizeWeb: 22,
                      maxline: 3,
                      multilanguage: false,
                      overflow: TextOverflow.ellipsis,
                      fontweight: FontWeight.bold,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: EdgeInsets.fromLTRB(
                      Dimens.isBigScreen(context) ? 20 : 10,
                      15,
                      Dimens.isBigScreen(context) ? 20 : 10,
                      15,
                    ),
                    width: MediaQuery.of(context).size.width,
                    decoration: Utils.setBackground(
                      white.withValues(alpha: 0.11),
                      1,
                    ),
                  ),
                  /* Benifits */
                  _buildUpcomingPlanBenefits(index: position),
                  Container(
                    height: 1,
                    margin: EdgeInsets.fromLTRB(
                      Dimens.isBigScreen(context) ? 20 : 10,
                      15,
                      Dimens.isBigScreen(context) ? 20 : 10,
                      15,
                    ),
                    width: MediaQuery.of(context).size.width,
                    decoration: Utils.setBackground(
                      white.withValues(alpha: 0.11),
                      1,
                    ),
                  ),
                  _buildUpcomingPlanPrice(position: position),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: EdgeInsets.fromLTRB(
                      Dimens.isBigScreen(context) ? 20 : 10,
                      0,
                      Dimens.isBigScreen(context) ? 20 : 10,
                      0,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Consumer<ProfileProvider>(
                      builder: (context, profileProvider, child) {
                        return MyText(
                          color: colorPrimary,
                          text:
                              ((profileProvider
                                              .profileModel
                                              .result?[position]
                                              .isBuy ??
                                          0) ==
                                      1 &&
                                  (profileProvider
                                              .profileModel
                                              .result?[position]
                                              .expiryDate ??
                                          "")
                                      .isNotEmpty)
                              ? "Valid upto ${DateFormat('dd MMM yyyy').format(DateTime.parse((profileProvider.profileModel.result?[position].expiryDate ?? "")))}"
                              : "-",
                          textalign: TextAlign.start,
                          fontsizeNormal: 12,
                          fontsizeWeb: 16,
                          maxline: 1,
                          multilanguage: false,
                          overflow: TextOverflow.ellipsis,
                          fontweight: FontWeight.w500,
                          fontstyle: FontStyle.normal,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: Utils.setBackground(
                  black.withValues(alpha: 0.6),
                  12,
                ),
              ),
            ),
            FittedBox(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: Utils.setBackground(
                  grayDark.withValues(alpha: 0.9),
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 14,
                  children: [
                    MyImage(
                      width: 24,
                      height: 24,
                      color: white,
                      imagePath: "ic_lock.png",
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: MyText(
                        color: titleTextColor,
                        text: "unlocking_soon",
                        multilanguage: true,
                        textalign: TextAlign.center,
                        fontsizeNormal: 12,
                        fontsizeWeb: 15,
                        maxline: 3,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.w600,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingPlanBenefits({required int index}) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 20 : 10,
        2,
        Dimens.isBigScreen(context) ? 30 : 15,
        5,
      ),
      itemCount:
          mySubscribedPlanProvider
              .upcomingPlanModel
              .result?[index]
              .data
              ?.length ??
          0,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int position) {
        return Container(
          constraints: BoxConstraints(
            minHeight: Dimens.isBigScreen(context) ? 50 : 25,
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: MyText(
                  color: white,
                  text:
                      mySubscribedPlanProvider
                          .upcomingPlanModel
                          .result?[index]
                          .data?[position]
                          .packageKey ??
                      "",
                  textalign: TextAlign.start,
                  multilanguage: false,
                  fontsizeNormal: 12,
                  fontsizeWeb: 16,
                  maxline: 10,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.w400,
                  fontstyle: FontStyle.normal,
                ),
              ),
              const SizedBox(width: 10),
              (((mySubscribedPlanProvider
                                      .upcomingPlanModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1" ||
                          (mySubscribedPlanProvider
                                      .upcomingPlanModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "0") &&
                      !(mySubscribedPlanProvider
                                  .upcomingPlanModel
                                  .result?[index]
                                  .data?[position]
                                  .packageKey ??
                              "")
                          .contains(RegExp(r'[0-9]')))
                  ? MyImage(
                      width: Dimens.isBigScreen(context) ? 25 : 15,
                      height: Dimens.isBigScreen(context) ? 25 : 15,
                      color:
                          (mySubscribedPlanProvider
                                      .upcomingPlanModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1"
                          ? colorPrimary
                          : redColor,
                      imagePath:
                          (mySubscribedPlanProvider
                                      .upcomingPlanModel
                                      .result?[index]
                                      .data?[position]
                                      .packageValue ??
                                  "") ==
                              "1"
                          ? "tick_mark.png"
                          : "cross_mark.png",
                    )
                  : MyImage(
                      width: Dimens.isBigScreen(context) ? 25 : 15,
                      height: Dimens.isBigScreen(context) ? 25 : 15,
                      color: white,
                      imagePath: "ic_devices.png",
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingPlanPrice({required int position}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.isBigScreen(context) ? 20 : 10,
        0,
        Dimens.isBigScreen(context) ? 20 : 10,
        0,
      ),
      margin: const EdgeInsets.only(top: 3),
      alignment: Alignment.centerLeft,
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          text: Constant.currencySymbol,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              color: white,
              fontSize: kIsWeb ? 16 : 14,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.normal,
            ),
          ),
          children: <TextSpan>[
            TextSpan(
              text:
                  mySubscribedPlanProvider
                      .upcomingPlanModel
                      .result?[position]
                      .price
                      .toString() ??
                  "-",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  color: white,
                  fontSize: kIsWeb ? 24 : 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
            TextSpan(
              text:
                  " per ${((mySubscribedPlanProvider.upcomingPlanModel.result?[position].type ?? "").toLowerCase() == "month" && (mySubscribedPlanProvider.upcomingPlanModel.result?[position].time ?? "") == "3") ? "quarter" : (mySubscribedPlanProvider.upcomingPlanModel.result?[position].type ?? "").toLowerCase()}",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  color: white,
                  fontSize: kIsWeb ? 16 : 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* *************** UPCOMING PLAN END *************** */
}
