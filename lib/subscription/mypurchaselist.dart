import '../model/sharemodel.dart';
import '../provider/purchaselistprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class MyPurchaselist extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const MyPurchaselist({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<MyPurchaselist> createState() => _MyPurchaselistState();
}

class _MyPurchaselistState extends State<MyPurchaselist> {
  late PurchaselistProvider purchaselistProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    purchaselistProvider =
        Provider.of<PurchaselistProvider>(context, listen: false);
    _getData();
  }

  Future<void> _getData() async {
    purchaselistProvider.contentList?.clear();
    purchaselistProvider.contentList = [];
    await purchaselistProvider.getUserRentVideoList(1);
    Future.delayed(const Duration(milliseconds: 300)).then((value) async {
      if (purchaselistProvider.isMorePage == true) {
        await _fetchNewData(purchaselistProvider.currentPage ?? 0);
      }
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _scrollListener() async {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (purchaselistProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.rentPurchasePage) {
      purchaselistProvider.setLoadMore(true);
      _fetchNewData(purchaselistProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchNewData(int? nextPage) async {
    printLog("_fetchNewData nextPage  ========> $nextPage");
    printLog(
        "_fetchNewData isMorePage  ======> ${purchaselistProvider.isMorePage}");
    printLog(
        "_fetchNewData currentPage ======> ${purchaselistProvider.currentPage}");
    printLog(
        "_fetchNewData totalPage   ======> ${purchaselistProvider.totalPage}");

    await purchaselistProvider.getUserRentVideoList((nextPage ?? 0) + 1);
    printLog(
        "_fetchNewData length ==> ${purchaselistProvider.contentList?.length}");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    purchaselistProvider.clearProvider();
    super.dispose();
  }

  bool _checkExpiry(int position) {
    printLog("position ======> $position");
    printLog(
        "rentExpiryDate =======> ${purchaselistProvider.contentList?[position].rentExpiryDate}");
    if ((purchaselistProvider.contentList?[position].rentExpiryDate ?? "") !=
        "") {
      return DateTime.now().isBefore(DateTime.parse(
          purchaselistProvider.contentList?[position].rentExpiryDate ?? ""));
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: widget.newPage,
        oldPage: widget.oldPage,
        reqText: '',
        newChild: _buildForWeb(),
      );
    } else {
      return Scaffold(
        backgroundColor: appBgColor,
        bottomNavigationBar: SmartBannerAd(
          isSpacing: true,
          bottomSpace: 10,
        ),
        appBar: Utils.myAppBarWithBack(context, "purchases", true),
        body: _buildForOther(),
      );
    }
  }

  Widget _buildForWeb() {
    return Column(
      children: [
        SizedBox(height: Dimens.homeTabHeight + 30),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                color: colorPrimary,
                text: "purchases",
                multilanguage: true,
                textalign: TextAlign.center,
                maxline: 2,
                fontsizeNormal: 20,
                fontsizeWeb: 25,
                fontweight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
              if (purchaselistProvider.contentList != null &&
                  (purchaselistProvider.contentList?.length ?? 0) > 0)
                const SizedBox(width: 15),
              if (purchaselistProvider.contentList != null &&
                  (purchaselistProvider.contentList?.length ?? 0) > 0)
                MyText(
                  color: descTextColor,
                  text: (purchaselistProvider.contentList?.length ?? 0) > 1
                      ? "(${(purchaselistProvider.contentList?.length ?? 0)} items)"
                      : "(${(purchaselistProvider.contentList?.length ?? 0)} item)",
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontsizeWeb: 16,
                  maxline: 1,
                  fontweight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Consumer<PurchaselistProvider>(
          builder: (context, purchaselistProvider, child) {
            if (purchaselistProvider.loading) {
              return ShimmerUtils.buildRentShimmer(
                  context, Dimens.heightLand, Dimens.widthLand);
            } else {
              if (purchaselistProvider.contentList == null ||
                  (purchaselistProvider.contentList?.length ?? 0) == 0) {
                return const NoData(
                  title: 'rent_and_buy_your_favorites',
                  subTitle: 'no_purchases_note',
                );
              } else {
                if (purchaselistProvider.contentList != null) {
                  return _buildPurchasedList();
                } else {
                  return const NoData(
                    title: 'rent_and_buy_your_favorites',
                    subTitle: 'no_purchases_note',
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildForOther() {
    return SafeArea(
      child: Consumer<PurchaselistProvider>(
        builder: (context, purchaselistProvider, child) {
          if (purchaselistProvider.loading) {
            return SingleChildScrollView(
              child: ShimmerUtils.responsiveGrid2(context,
                  Dimens.heightPortOther, Dimens.widthPortOther, 3, 3, 3, 12),
            );
          } else {
            if (purchaselistProvider.contentList == null ||
                (purchaselistProvider.contentList?.length ?? 0) == 0) {
              return const NoData(
                title: 'rent_and_buy_your_favorites',
                subTitle: 'no_purchases_note',
              );
            } else {
              if (purchaselistProvider.contentList != null) {
                return RefreshIndicator(
                  backgroundColor: white,
                  color: complimentryColor,
                  displacement: 80,
                  onRefresh: () async {
                    purchaselistProvider.setLoading(true);
                    await Future.delayed(const Duration(milliseconds: 1500))
                        .then((value) {
                      _getData();
                    });
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildPurchasedList(),
                  ),
                );
              } else {
                return const NoData(
                  title: 'rent_and_buy_your_favorites',
                  subTitle: 'no_purchases_note',
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildPurchasedList() {
    if ((purchaselistProvider.contentList?.length ?? 0) > 0) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ResponsiveGridList(
          minItemWidth: Dimens.isBigScreen(context)
              ? Dimens.widthPortOtherWeb
              : Dimens.widthPortOther,
          verticalGridSpacing: 3,
          horizontalGridSpacing: 3,
          minItemsPerRow: 3,
          maxItemsPerRow: 15,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(
            (purchaselistProvider.contentList?.length ?? 0),
            (position) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.cardRadiusSmall),
                child: InkWell(
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    Utils.openDetails(
                      context: context,
                      videoId:
                          purchaselistProvider.contentList?[position].id ?? 0,
                      subVideoType: purchaselistProvider
                              .contentList?[position].subVideoType ??
                          0,
                      videoType: purchaselistProvider
                              .contentList?[position].videoType ??
                          0,
                      typeId:
                          purchaselistProvider.contentList?[position].typeId ??
                              0,
                      newPage: ((purchaselistProvider
                                          .contentList?[position].videoType ??
                                      0) ==
                                  2 ||
                              (purchaselistProvider.contentList?[position]
                                          .subVideoType ??
                                      0) ==
                                  2)
                          ? RoutesConstant.contentDetailsPage
                          : RoutesConstant.contentDetailsPage,
                      oldPage: "",
                      reqText: "",
                    );
                  },
                  child: Container(
                    width: Dimens.isBigScreen(context)
                        ? Dimens.widthPortOtherWeb
                        : Dimens.widthPortOther,
                    height: Dimens.isBigScreen(context)
                        ? Dimens.heightPortOtherWeb
                        : Dimens.heightPortOther,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: AlignmentDirectional.bottomEnd,
                      children: [
                        MyNetworkImage(
                          imageUrl: purchaselistProvider
                                  .contentList?[position].thumbnail
                                  .toString() ??
                              "",
                          fit: BoxFit.cover,
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                        ),
                        /* Bottom Gradient */
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.getBannerHeight(context),
                          alignment: Alignment.bottomRight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomRight,
                              colors: [
                                transparent,
                                transparent,
                                transparent,
                                appBgColor.withValues(alpha: 0.1),
                                appBgColor.withValues(alpha: 0.5),
                                appBgColor.withValues(alpha: 0.9),
                                appBgColor,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: InkWell(
                            onTap: () {
                              _buildMoreDialog(position);
                            },
                            child: Container(
                              width: 45,
                              height: 45,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              child: MyImage(
                                width: 23,
                                height: 23,
                                imagePath: "ic_info.png",
                                color: white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _buildMoreDialog(int position) {
    if (kIsWeb) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.transparency,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: Dimens.isBigScreen(context)
                      ? (MediaQuery.of(context).size.width * 0.3)
                      : (MediaQuery.of(context).size.width),
                  margin: const EdgeInsets.fromLTRB(50, 50, 50, 50),
                  padding: const EdgeInsets.all(23),
                  decoration: Utils.setBackground(lightBlack, 5),
                  child: _buildDialogContent(position: position),
                ),
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: lightBlack,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (BuildContext context) {
          return Wrap(
            children: <Widget>[
              _buildDialogContent(position: position),
            ],
          );
        },
      );
    }
  }

  Widget _buildDialogContent({required int position}) {
    return Container(
      padding: const EdgeInsets.all(23),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /* Title */
          MyText(
            text: purchaselistProvider.contentList?[position].name ?? "",
            multilanguage: false,
            fontsizeNormal: 18,
            fontsizeWeb: 20,
            color: titleTextColor,
            fontstyle: FontStyle.normal,
            fontweight: FontWeight.w700,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
          ),

          /* Expired Date */
          if ((purchaselistProvider.contentList?[position].rentExpiryDate ?? "")
              .isNotEmpty)
            const SizedBox(height: 15),
          if ((purchaselistProvider.contentList?[position].rentExpiryDate ?? "")
              .isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MyText(
                  multilanguage: true,
                  color: titleTextColor,
                  text: _checkExpiry(position)
                      ? "rent_expire_on"
                      : "rent_expired",
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w500,
                  fontsizeWeb: 16,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  isShadowText: true,
                ),
                if (_checkExpiry(position))
                  MyText(
                    color: titleTextColor,
                    multilanguage: false,
                    text: " : ",
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 16,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    isShadowText: true,
                  ),
                if (_checkExpiry(position))
                  MyText(
                    color: colorPrimary,
                    multilanguage: false,
                    text: DateFormat("dd MMM, yyyy").format(DateTime.parse(
                        purchaselistProvider
                                .contentList?[position].rentExpiryDate ??
                            "")),
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    isShadowText: true,
                  ),
              ],
            ),
          const SizedBox(height: 20),

          /* View Details */
          _buildDialogItems(
            icon: "ic_info.png",
            title: "view_details",
            isMultilang: true,
            onClick: () async {
              Utils.exitDialog(context);
              printLog("Clicked on position :==> $position");
              Utils.openDetails(
                context: context,
                videoId: purchaselistProvider.contentList?[position].id ?? 0,
                subVideoType:
                    purchaselistProvider.contentList?[position].subVideoType ??
                        0,
                videoType:
                    purchaselistProvider.contentList?[position].videoType ?? 0,
                typeId: purchaselistProvider.contentList?[position].typeId ?? 0,
                newPage: ((purchaselistProvider
                                    .contentList?[position].subVideoType ??
                                0) ==
                            2 ||
                        (purchaselistProvider
                                    .contentList?[position].videoType ??
                                0) ==
                            2)
                    ? RoutesConstant.contentDetailsPage
                    : RoutesConstant.contentDetailsPage,
                oldPage: "",
                reqText: "",
              );
            },
          ),

          /* Video Share */
          if (!kIsWeb)
            _buildDialogItems(
              icon: "ic_share.png",
              title: "share",
              isMultilang: true,
              onClick: () async {
                Utils.exitDialog(context);
                ShareModel shareModel = ShareModel(
                  newPage:
                      ((purchaselistProvider.contentList?[position].videoType ??
                                      0) ==
                                  2 ||
                              (purchaselistProvider.contentList?[position]
                                          .subVideoType ??
                                      0) ==
                                  2)
                          ? RoutesConstant.contentDetailsPage
                          : RoutesConstant.contentDetailsPage,
                  videoTitle:
                      purchaselistProvider.contentList?[position].name ?? "",
                  videoId: purchaselistProvider.contentList?[position].id ?? 0,
                  videoType:
                      purchaselistProvider.contentList?[position].videoType ??
                          0,
                  subVideoType: purchaselistProvider
                          .contentList?[position].subVideoType ??
                      0,
                  typeId:
                      purchaselistProvider.contentList?[position].typeId ?? 0,
                );
                Utils.openShareDialog(
                  context: context,
                  shareModel: shareModel,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDialogItems({
    required String icon,
    required String title,
    required bool isMultilang,
    required Function()? onClick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onClick,
      child: Container(
        height: Dimens.minHtDialogContent,
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            MyImage(
              width: Dimens.dialogIconSize,
              height: Dimens.dialogIconSize,
              imagePath: icon,
              fit: BoxFit.contain,
              color: defaultIconColor,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MyText(
                text: title,
                multilanguage: isMultilang,
                fontsizeNormal: 14,
                fontsizeWeb: 16,
                color: titleTextColor,
                fontstyle: FontStyle.normal,
                fontweight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
