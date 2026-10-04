import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/findprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../webwidget/web_hover_card.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../webwidget/safesearchbar.dart';

class WebSearch extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebSearch({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebSearch> createState() => WebSearchState();
}

class WebSearchState extends State<WebSearch> {
  late FindProvider findProvider;
  final searchController = TextEditingController();
  late final FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    findProvider = Provider.of<FindProvider>(context, listen: false);
    searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    await findProvider.getSearchContent("", 1);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  /* Search Data by Type START *********** */
  Future<void> getTabData() async {
    if (!mounted) return;
    findProvider.setSearchLoading(true);
    await findProvider.clearSearchData();
    if (searchController.text.toString().isEmpty) {
      await findProvider.getSearchContent("", 1);
      return;
    }
    printLog("searchController ====> ${searchController.text}");
    await findProvider.getSearchContent(searchController.text.toString(), 1);
  }
  /* ************* Search Data by Type END */

  @override
  void dispose() {
    searchController.dispose();
    findProvider.clearProvider();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: searchController.text.toString(),
      newChild: Consumer<FindProvider>(
        builder: (context, findProvider, child) {
          return _buildPageUI();
        },
      ),
    );
  }

  Widget _buildPageUI() {
    return Column(
      children: [
        SizedBox(height: Dimens.homeTabHeight),
        _buildSearchBox(),
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
          child: MyText(
            color: white,
            text: "people_search_for",
            multilanguage: true,
            textalign: TextAlign.start,
            fontsizeNormal: 15,
            fontweight: FontWeight.w600,
            fontsizeWeb: 17,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
        ),
        _buildSearchData(),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 55,
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: Utils.setBackground(white, 15),
      child: Row(
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: MyImage(
              imagePath: "ic_find.png",
              color: defaultIconColor,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: SafeSearchBar(
              hint: Locales.string(context, "search_here"),
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: (text) async {
                printLog("Search: $text");
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (text.isNotEmpty) {
                    getTabData();
                  } else {
                    await findProvider.getSearchContent("", 1);
                  }
                });
              },
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) {
              if (value.text.isEmpty) return SizedBox(width: 42);
              return InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  searchController.clear();
                  getTabData();
                },
                child: Container(
                  width: 42,
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: MyImage(
                    imagePath: "ic_close.png",
                    color: defaultIconColor,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /* Search Data */
  Widget _buildSearchData() {
    if (findProvider.loadingSearch && !findProvider.loadMore) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
        child: ShimmerUtils.responsiveGrid2(
          context,
          Dimens.isBigScreen(context)
              ? Dimens.heightPortOtherWeb
              : Dimens.heightPortOther,
          Dimens.isBigScreen(context)
              ? Dimens.widthPortOtherWeb
              : Dimens.widthPortOther,
          3,
          3,
          3,
          12,
        ),
      );
    }
    if (findProvider.searchDataList == null ||
        (findProvider.searchDataList?.length ?? 0) == 0) {
      return const NoData(title: 'no_search_title', subTitle: 'no_search_desc');
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
      child: Column(
        children: [
          Wrap(
            spacing: Dimens.isBigScreen(context) ? 12 : 8,
            runSpacing: Dimens.isBigScreen(context) ? 16 : 10,
            alignment: WrapAlignment.start,
            children: List.generate(
              (findProvider.searchDataList?.length ?? 0),
              (position) => _buildVideoContent(position: position),
            ),
          ),

          /* Pagination loader */
          if (findProvider.loadMore)
            Container(
              height: 80,
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Utils.pageLoader(),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildVideoContent({required int position}) {
    return WebHoverCard(
      cardW: Dimens.isBigScreen(context)
          ? Dimens.widthPortOtherWeb
          : Dimens.widthPortOther,
      cardH: Dimens.isBigScreen(context)
          ? Dimens.heightPortOtherWeb
          : Dimens.heightPortOther,
      borderRadius: Dimens.cardRadiusSmall,
      imageUrl:
          findProvider.searchDataList?[position].thumbnail.toString() ?? "",
      onTap: () {
        printLog("Clicked on position ==> $position");
        Utils.openDetails(
          context: context,
          videoId: findProvider.searchDataList?[position].id ?? 0,
          subVideoType:
              findProvider.searchDataList?[position].subVideoType ?? 0,
          videoType: findProvider.searchDataList?[position].videoType ?? 0,
          typeId: findProvider.searchDataList?[position].typeId ?? 0,
          newPage: RoutesConstant.contentDetailsPage,
          oldPage: widget.newPage ?? "",
          reqText: '',
        );
      },
      overlay: Positioned(
        top: 8,
        right: 0,
        child: Utils.buildRentPremiumTAG(
          context: context,
          isPremium: findProvider.searchDataList?[position].isPremium ?? 0,
          isRent: findProvider.searchDataList?[position].isRent ?? 0,
          rentPrice: findProvider.searchDataList?[position].price ?? 0,
        ),
      ),
    );
  }
}
