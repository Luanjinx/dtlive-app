import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../widget/nodata.dart';
import '../provider/rentstoreprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';

class RentStore extends StatefulWidget {
  const RentStore({super.key});

  @override
  State<RentStore> createState() => RentStoreState();
}

class RentStoreState extends State<RentStore> {
  late RentStoreProvider rentStoreProvider;
  final nestedScrollController = ScrollController();
  final tabScrollController = ScrollController();
  late ListObserverController observerController;

  Future<void> _nestedScrollListener() async {
    if (!nestedScrollController.hasClients) return;
    if (nestedScrollController.position.pixels < 170) {
      rentStoreProvider.setAppbarVisibility(true);
    } else if (nestedScrollController.position.pixels > 175) {
      rentStoreProvider.setAppbarVisibility(false);
    }
    if (nestedScrollController.offset >=
            nestedScrollController.position.maxScrollExtent &&
        !nestedScrollController.position.outOfRange &&
        (rentStoreProvider.isMorePage ?? false)) {
      rentStoreProvider.setLoadMore(true);
      _fetchNewPageData(rentStoreProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchNewPageData(int? nextPage) async {
    printLog("_fetchNewPageData nextPage  ========> $nextPage");
    printLog(
      "_fetchNewPageData isMorePage  ======> ${rentStoreProvider.isMorePage}",
    );
    printLog(
      "_fetchNewPageData currentPage ======> ${rentStoreProvider.currentPage}",
    );
    printLog(
      "_fetchNewPageData totalPage   ======> ${rentStoreProvider.totalPage}",
    );

    await rentStoreProvider.getRentContentList(
      rentStoreProvider
              .sectionTypeList?[rentStoreProvider.selectedIndex]
              .type ??
          0,
      (nextPage ?? 0) + 1,
    );
    printLog(
      "rentDataList length ==> ${rentStoreProvider.rentDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> setSelectedTab(int tabPos) async {
    printLog("setSelectedTab tabPos ====> $tabPos");
    if (!mounted) return;
    rentStoreProvider.setSelectedTab(tabPos);
    printLog(
      "setSelectedTab selectedIndex ====> ${rentStoreProvider.selectedIndex}",
    );
    printLog(
      "setSelectedTab lastTabPosition ====> ${rentStoreProvider.lastTabPosition}",
    );
    if (rentStoreProvider.lastTabPosition == tabPos) {
      return;
    } else {
      rentStoreProvider.setTabPosition(tabPos);
    }
  }

  Future<void> getTabData(int position) async {
    printLog("getTabData position ====> $position");
    await rentStoreProvider.clearOldData();
    rentStoreProvider.setRentLoading(true);
    rentStoreProvider.setAppbarVisibility(true);

    if (nestedScrollController.hasClients) {
      await nestedScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
    await setSelectedTab(position);
    _fetchNewPageData(0);
  }

  @override
  void initState() {
    super.initState();
    nestedScrollController.addListener(_nestedScrollListener);
    observerController = ListObserverController(
      controller: tabScrollController,
    );
    rentStoreProvider = Provider.of<RentStoreProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    await rentStoreProvider.getSectionType();
    await rentStoreProvider.getRentContentList("1", 1);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    rentStoreProvider.clearProvider();
    LoadingOverlay().hide();
  }

  void _scrollToCurrent() {
    if (rentStoreProvider.selectedIndex == -1) return;
    printLog(
      "selectedIndex ======> ${rentStoreProvider.selectedIndex.toDouble()}",
    );
    observerController.animateTo(
      index: rentStoreProvider.selectedIndex,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBar(context, "stor", true),
      body: SafeArea(
        child: Consumer<RentStoreProvider>(
          builder: (context, rentStoreProvider, child) {
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _buildTypeTabData(),
                FittedBox(
                  child: Container(
                    height: Dimens.rentTabHeight,
                    padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
                    child: _buildTypeTabs(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /* Type START ************** */
  Widget _buildTypeTabs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tabScrollController.hasClients) {
        _scrollToCurrent();
      }
    });
    return ListViewObserver(
      controller: observerController,
      child: Container(
        constraints: const BoxConstraints(minHeight: 45),
        decoration: Utils.setBGWithBorder(
          secondaryBgColor,
          transparent,
          Dimens.menuRadius,
          0,
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: ListView.separated(
          itemCount: rentStoreProvider.sectionTypeList?.length ?? 0,
          shrinkWrap: true,
          controller: tabScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (context, index) => Container(
            width: 1.5,
            margin: const EdgeInsets.fromLTRB(15, 2, 15, 2),
            decoration: Utils.setBackground(grayDark, 5),
          ),
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () async {
                printLog("index ===========> $index");
                AdHelper.checkAndShowAds(
                  context: context,
                  buttonKey: "",
                  adType: Constant.interstialAdType,
                  alwaysShowAd: false,
                  showOnByClick: true,
                  onAdComplete: () async {
                    await getTabData(index);
                  },
                );
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                decoration: Utils.setBackground(
                  (index == rentStoreProvider.selectedIndex)
                      ? white
                      : transparent,
                  25,
                ),
                child: MyText(
                  color: (index == rentStoreProvider.selectedIndex)
                      ? black
                      : white,
                  multilanguage: false,
                  text:
                      rentStoreProvider.sectionTypeList?[index].name
                          .toString() ??
                      "",
                  fontsizeNormal: 12,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 14,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  /* **************** Type END */

  Widget _buildTypeTabData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: RefreshIndicator(
        backgroundColor: white,
        color: complimentryColor,
        displacement: 80,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 1500)).then((
            value,
          ) {
            printLog(
              "selectedIndex ===========> ${rentStoreProvider.selectedIndex}",
            );
            getTabData(rentStoreProvider.selectedIndex);
          });
        },
        child: SingleChildScrollView(
          controller: nestedScrollController,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildPage(),
        ),
      ),
    );
  }

  Widget _buildPage() {
    if (rentStoreProvider.loadingRent && !rentStoreProvider.loadMore) {
      return ShimmerUtils.responsiveGrid2(
        context,
        Dimens.heightPortOther,
        Dimens.widthPortOther,
        3,
        3,
        3,
        12,
      );
    } else {
      if (rentStoreProvider.rentDataList != null &&
          (rentStoreProvider.rentDataList?.length ?? 0) > 0) {
        return Column(
          children: [
            SmartBannerAd(isSpacing: true, bottomSpace: 10),
            /* Rent */
            ResponsiveGridList(
              minItemWidth: Dimens.widthPortOther,
              verticalGridSpacing: 3,
              horizontalGridSpacing: 3,
              minItemsPerRow: 3,
              maxItemsPerRow: 8,
              listViewBuilderOptions: ListViewBuilderOptions(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
              children: List.generate(
                (rentStoreProvider.rentDataList?.length ?? 0),
                (position) {
                  return Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimens.cardRadiusSmall,
                      ),
                      child: InkWell(
                        focusColor: white,
                        onTap: () {
                          printLog("Clicked on position ==> $position");
                          Utils.openDetails(
                            context: context,
                            videoId:
                                rentStoreProvider.rentDataList?[position].id ??
                                0,
                            subVideoType:
                                rentStoreProvider
                                    .rentDataList?[position]
                                    .subVideoType ??
                                0,
                            videoType:
                                rentStoreProvider
                                    .rentDataList?[position]
                                    .videoType ??
                                0,
                            typeId:
                                rentStoreProvider
                                    .rentDataList?[position]
                                    .typeId ??
                                0,
                            newPage:
                                ((rentStoreProvider
                                                .rentDataList?[position]
                                                .subVideoType ??
                                            0) ==
                                        2 ||
                                    (rentStoreProvider
                                                .rentDataList?[position]
                                                .videoType ??
                                            0) ==
                                        2)
                                ? RoutesConstant.contentDetailsPage
                                : RoutesConstant.contentDetailsPage,
                            oldPage: "",
                            reqText: "",
                          );
                        },
                        child: Container(
                          padding: Dimens.isBigScreen(context)
                              ? const EdgeInsets.all(2.0)
                              : const EdgeInsets.all(0),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: Dimens.widthPortOther,
                                height: Dimens.heightPortOther,
                                alignment: Alignment.center,
                                child: MyNetworkImage(
                                  imageUrl:
                                      rentStoreProvider
                                          .rentDataList?[position]
                                          .thumbnail
                                          .toString() ??
                                      "",
                                  fit: BoxFit.cover,
                                  height: MediaQuery.of(context).size.height,
                                  width: MediaQuery.of(context).size.width,
                                ),
                              ),
                              FittedBox(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 15,
                                    minWidth: 30,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: colorPrimary,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(3),
                                      topRight: Radius.circular(
                                        Dimens.cardRadiusSmall,
                                      ),
                                      bottomLeft: const Radius.circular(8),
                                      bottomRight: const Radius.circular(3),
                                    ),
                                  ),
                                  child: MyText(
                                    color: black,
                                    text:
                                        "${Constant.currencySymbol} ${rentStoreProvider.rentDataList?[position].price.toString() ?? "0"}",
                                    textalign: TextAlign.center,
                                    fontsizeNormal: 10,
                                    fontsizeWeb: 12,
                                    fontweight: FontWeight.w700,
                                    maxline: 1,
                                    multilanguage: false,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /* Pagination loader */
            if (rentStoreProvider.loadMore)
              Container(
                height: 80,
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Utils.pageLoader(),
              )
            else
              const SizedBox.shrink(),
            SizedBox(height: Dimens.rentTabHeight),
          ],
        );
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }
}
