import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/dimens.dart';
import '../webpages/webcomman.dart';
import '../widget/nodata.dart';
import '../provider/rentstoreprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/web_hover_card.dart';
import '../widget/mytext.dart';

class WebRentStore extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebRentStore({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebRentStore> createState() => WebRentStoreState();
}

class WebRentStoreState extends State<WebRentStore> {
  late RentStoreProvider rentStoreProvider;

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
    await setSelectedTab(position);
    _fetchNewPageData(0);
    Future.delayed(const Duration(milliseconds: 300)).then((value) async {
      if (!mounted) return;
      printLog("getTabData isMorePage ====> ${rentStoreProvider.isMorePage}");
      if (rentStoreProvider.isMorePage == true) {
        rentStoreProvider.setLoadMore(true);
        _fetchNewPageData(rentStoreProvider.currentPage ?? 0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    rentStoreProvider = Provider.of<RentStoreProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    Utils.getCurrencySymbol();
    await rentStoreProvider.getSectionType();
    await rentStoreProvider.getRentContentList("1", 1);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    Future.delayed(const Duration(milliseconds: 300)).then((value) async {
      if (!mounted) return;
      printLog("_getData isMorePage ====> ${rentStoreProvider.isMorePage}");
      if (rentStoreProvider.isMorePage == true) {
        rentStoreProvider.setLoadMore(true);
        _fetchNewPageData(rentStoreProvider.currentPage ?? 0);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
      newChild: SafeArea(
        child: Consumer<RentStoreProvider>(
          builder: (context, rentStoreProvider, child) {
            return Column(
              children: [
                SizedBox(height: Dimens.homeTabHeight),
                FittedBox(
                  child: Container(
                    height: Dimens.rentTabHeight,
                    padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
                    child: _buildTypeTabs(),
                  ),
                ),
                _buildTypeTabData(),
              ],
            );
          },
        ),
      ),
    );
  }

  /* Type START ************** */
  Widget _buildTypeTabs() {
    return Container(
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
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => Container(
          width: 1.5,
          margin: const EdgeInsets.fromLTRB(15, 2, 15, 2),
          decoration: Utils.setBackground(grayDark, 5),
        ),
        itemBuilder: (BuildContext context, int index) {
          return InteractiveIcon(
            builder: (isHovered) {
              return InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () async {
                  printLog("index ===========> $index");
                  await getTabData(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: (index == rentStoreProvider.selectedIndex)
                        ? white
                        : isHovered
                        ? white.withValues(alpha: 0.10)
                        : transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: MyText(
                    color: (index == rentStoreProvider.selectedIndex)
                        ? colorPrimaryDark
                        : isHovered
                        ? white
                        : white.withValues(alpha: 0.75),
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
          );
        },
      ),
    );
  }
  /* **************** Type END */

  Widget _buildTypeTabData() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildRentStore(),
      ),
    );
  }

  Widget _buildRentStore() {
    if (rentStoreProvider.loadingRent && !rentStoreProvider.loadMore) {
      return ShimmerUtils.responsiveGrid2(
        context,
        Dimens.heightPortOtherWeb,
        Dimens.widthPortOtherWeb,
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
            /* Rent */
            Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: List.generate(
                (rentStoreProvider.rentDataList?.length ?? 0),
                (position) {
                  return WebHoverCard(
                    cardW: Dimens.widthPortOtherWeb,
                    cardH: Dimens.heightPortOtherWeb,
                    borderRadius: Dimens.cardRadiusSmall,
                    imageUrl:
                        rentStoreProvider.rentDataList?[position].thumbnail
                            .toString() ??
                        "",
                    onTap: () {
                      printLog("Clicked on position ==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId:
                            rentStoreProvider.rentDataList?[position].id ?? 0,
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
                            rentStoreProvider.rentDataList?[position].typeId ??
                            0,
                        newPage: RoutesConstant.contentDetailsPage,
                        oldPage: widget.newPage ?? "",
                        reqText: "",
                      );
                    },
                    overlay: Positioned(
                      top: 0,
                      right: 0,
                      child: FittedBox(
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
                              topRight: Radius.circular(Dimens.cardRadiusSmall),
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
                    ),
                  );
                },
              ),
            ),

            /* Pagination loader */
            if (rentStoreProvider.loadMore)
              ShimmerUtils.responsiveGrid2(
                context,
                Dimens.heightPortOther,
                Dimens.widthPortOther,
                3,
                3,
                3,
                12,
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
