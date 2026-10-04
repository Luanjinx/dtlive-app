import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/watchlistprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../utils/color.dart';
import '../webwidget/web_hover_card.dart';

class WebMyWatchlist extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebMyWatchlist({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebMyWatchlist> createState() => WebMyWatchlistState();
}

class WebMyWatchlistState extends State<WebMyWatchlist> {
  late WatchlistProvider watchlistProvider;

  @override
  void initState() {
    super.initState();
    watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    watchlistProvider.watchlistDataList?.clear();
    watchlistProvider.watchlistDataList = [];
    await watchlistProvider.getWatchlist(1);
    Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (watchlistProvider.isMorePage == true) {
        await watchlistProvider.getWatchlist(2);
      }
      if (!context.mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    watchlistProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
    );
  }

  Widget _buildPageUI() {
    return Column(
      children: [
        SizedBox(height: Dimens.homeTabHeight),
        _buildAppbar(),
        _buildContentItem(),

        /* Pagination loader */
        Consumer<WatchlistProvider>(
          builder: (context, watchlistProvider, child) {
            if (watchlistProvider.loadMore) {
              return ShimmerUtils.responsiveGrid(
                context,
                Dimens.isBigScreen(context)
                    ? Dimens.heightPortOtherWeb
                    : Dimens.heightPortOther,
                Dimens.isBigScreen(context)
                    ? Dimens.widthPortOtherWeb
                    : Dimens.widthPortOther,
                2,
                10,
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildAppbar() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
      child: MyText(
        text: 'watchlist',
        multilanguage: true,
        color: colorPrimary,
        fontsizeNormal: 20,
        fontsizeWeb: 25,
        maxline: 1,
        fontweight: FontWeight.w600,
        fontstyle: FontStyle.normal,
        textalign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContentItem() {
    return Consumer<WatchlistProvider>(
      builder: (context, watchlistProvider, child) {
        if (watchlistProvider.loading && !watchlistProvider.loadMore) {
          return ShimmerUtils.responsiveGrid(
            context,
            Dimens.isBigScreen(context)
                ? Dimens.heightPortOtherWeb
                : Dimens.heightPortOther,
            Dimens.isBigScreen(context)
                ? Dimens.widthPortOtherWeb
                : Dimens.widthPortOther,
            2,
            Dimens.isBigScreen(context) ? 40 : 20,
          );
        }
        if (watchlistProvider.watchlistDataList == null ||
            (watchlistProvider.watchlistDataList?.length ?? 0) == 0) {
          return const NoData(
            title: 'browse_now_watch_later',
            subTitle: 'watchlist_note',
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Wrap(
            spacing: Dimens.isBigScreen(context) ? 12 : 8,
            runSpacing: Dimens.isBigScreen(context) ? 16 : 10,
            alignment: WrapAlignment.start,
            children: List.generate(
              (watchlistProvider.watchlistDataList?.length ?? 0),
              (position) {
                return WebHoverCard(
                  cardW: Dimens.isBigScreen(context)
                      ? Dimens.widthPortOtherWeb
                      : Dimens.widthPortOther,
                  cardH: Dimens.isBigScreen(context)
                      ? Dimens.heightPortOtherWeb
                      : Dimens.heightPortOther,
                  borderRadius: Dimens.cardRadiusSmall,
                  imageUrl:
                      watchlistProvider.watchlistDataList?[position].thumbnail
                          ?.toString() ??
                      "",
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    await Utils.openDetails(
                      context: context,
                      videoId:
                          watchlistProvider.watchlistDataList?[position].id ??
                          0,
                      subVideoType:
                          watchlistProvider
                              .watchlistDataList?[position]
                              .subVideoType ??
                          0,
                      videoType:
                          watchlistProvider
                              .watchlistDataList?[position]
                              .videoType ??
                          0,
                      typeId:
                          watchlistProvider
                              .watchlistDataList?[position]
                              .typeId ??
                          0,
                      newPage: RoutesConstant.contentDetailsPage,
                      oldPage: widget.newPage ?? "",
                      reqText: Constant.userID ?? "",
                    );
                    await watchlistProvider.getWatchlist(1);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
