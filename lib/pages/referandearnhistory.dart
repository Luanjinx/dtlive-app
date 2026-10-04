import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../model/referandearnhistorymodel.dart';
import '../provider/referandearnhistoryprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class ReferEarnHistory extends StatefulWidget {
  const ReferEarnHistory({super.key});

  @override
  State<ReferEarnHistory> createState() => _ReferEarnHistoryState();
}

class _ReferEarnHistoryState extends State<ReferEarnHistory> {
  late ReferEarnHistoryProvider referEarnProvider;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    referEarnProvider = Provider.of<ReferEarnHistoryProvider>(
      context,
      listen: false,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(1);
    });
  }

  Future<void> _loadData(int page) async {
    _currentPage = page;
    await referEarnProvider.getReferEarnHistory(page);
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange &&
        !(referEarnProvider.loadMore) &&
        (referEarnProvider.isMorePage ?? false)) {
      referEarnProvider.setLoadMore(true);
      _loadData(_currentPage + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    referEarnProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: RoutesConstant.referEarnHistoryPage,
        oldPage: RoutesConstant.referEarnPage,
        reqText: '',
        newChild: _buildForWeb(),
      );
    }
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "referral_history", true),
      body: SafeArea(child: _buildPageBody()),
    );
  }

  Widget _buildForWeb() {
    return Column(
      children: [
        SizedBox(height: Dimens.homeTabHeight + 30),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(left: 20, right: 20),
          alignment: Alignment.center,
          child: MyText(
            color: colorPrimary,
            text: "referral_history",
            multilanguage: true,
            textalign: TextAlign.center,
            maxline: 2,
            fontsizeNormal: 20,
            fontsizeWeb: 25,
            fontweight: FontWeight.w600,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            top: Dimens.isBigScreen(context) ? 40 : 12,
            bottom: Dimens.isBigScreen(context) ? 40 : 12,
          ),
          child: _buildPageBody(),
        ),
      ],
    );
  }

  Widget _buildPageBody() {
    return Consumer<ReferEarnHistoryProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return ShimmerUtils.buildReferEarnHistoryShimmer(context);
        }
        if (referEarnProvider.historyDataList.isEmpty) {
          return Center(
            child: NoData(title: "no_referral_history", subTitle: ""),
          );
        }
        if (Dimens.isBigScreen(context)) {
          return _buildWebItem();
        } else {
          return _buildOtherItem();
        }
      },
    );
  }

  Widget _buildWebItem() {
    final items = referEarnProvider.historyDataList;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 30, right: 30, bottom: 15),
      child: ResponsiveGridList(
        minItemWidth: (Dimens.isBigScreen(context))
            ? Dimens.widthPackageWeb
            : Dimens.widthPackage,
        verticalGridSpacing: 8,
        horizontalGridSpacing: 6,
        minItemsPerRow: 1,
        maxItemsPerRow: 3,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(
          items.length + (referEarnProvider.loadMore ? 1 : 0),
          (position) {
            if (position == items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Utils.pageLoader()),
              );
            }
            return _buildItem(items[position]);
          },
        ),
      ),
    );
  }

  Widget _buildOtherItem() {
    final items = referEarnProvider.historyDataList;
    return SingleChildScrollView(
      controller: _scrollController,
      child: AlignedGridView.count(
        shrinkWrap: true,
        crossAxisCount: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 12,
        padding: const EdgeInsets.only(left: 15, right: 15),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length + (referEarnProvider.loadMore ? 1 : 0),
        itemBuilder: (BuildContext context, int position) {
          if (position == items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Utils.pageLoader()),
            );
          }
          return _buildItem(items[position]);
        },
      ),
    );
  }

  Widget _buildItem(ReferEarnItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: secondaryBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Avatar */
          CircleAvatar(
            radius: 22,
            backgroundColor: colorPrimary.withValues(alpha: 0.15),
            child: MyText(
              color: colorPrimary,
              text: item.avatarChar,
              multilanguage: false,
              fontsizeNormal: 20,
              fontsizeWeb: 22,
              fontweight: FontWeight.bold,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(width: 12),

          /* Details */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* User display name */
                MyText(
                  color: titleTextColor,
                  text: item.displayName,
                  multilanguage: false,
                  fontsizeNormal: 15,
                  fontsizeWeb: 16,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 6),

                /* You Earned */
                if (item.parentEarn != null)
                  _buildEarnRow(
                    labelKey: "you_earned",
                    amount: item.parentEarn!,
                    color: colorPrimary,
                  ),
                if (item.parentEarn != null) const SizedBox(height: 3),

                /* Friend Earned */
                if (item.childEarn != null)
                  _buildEarnRow(
                    labelKey: "friend_earned",
                    amount: item.childEarn!,
                    color: descTextColor,
                  ),

                /* Reference Code */
                if (item.referenceCode != null &&
                    (item.referenceCode ?? "").isNotEmpty) ...[
                  const SizedBox(height: 5),
                  MyText(
                    color: descTextColor,
                    text: item.referenceCode ?? "",
                    multilanguage: false,
                    fontsizeNormal: 11,
                    fontsizeWeb: 13,
                    fontweight: FontWeight.w500,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnRow({
    required String labelKey,
    required int amount,
    required Color color,
  }) {
    return Row(
      children: [
        MyText(
          color: color,
          text: labelKey,
          multilanguage: true,
          fontsizeNormal: 13,
          fontsizeWeb: 14,
          fontweight: FontWeight.w500,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        MyText(
          color: color,
          text: ": ${Constant.currencySymbol}$amount",
          multilanguage: false,
          fontsizeNormal: 13,
          fontsizeWeb: 14,
          fontweight: FontWeight.w600,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
      ],
    );
  }
}
