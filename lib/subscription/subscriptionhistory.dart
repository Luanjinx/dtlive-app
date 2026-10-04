import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../model/historymodel.dart';
import '../provider/subhistoryprovider.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class SubscriptionHistory extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const SubscriptionHistory({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<SubscriptionHistory> createState() => _SubscriptionHistoryState();
}

class _SubscriptionHistoryState extends State<SubscriptionHistory> {
  late SubHistoryProvider subHistoryProvider;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    subHistoryProvider = Provider.of<SubHistoryProvider>(
      context,
      listen: false,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNewData(0);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (subHistoryProvider.isMorePage ?? false)) {
      subHistoryProvider.setLoadMore(true);
      _fetchNewData(subHistoryProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchNewData(int? nextPage) async {
    await subHistoryProvider.getSubscriptionList((nextPage ?? 0) + 1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    subHistoryProvider.clearProvider();
    super.dispose();
  }

  bool _isExpired(Result item) {
    final exp = item.expiryDate ?? '';
    if (exp.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(exp));
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
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
    }
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, 'subscription_history', true),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(child: _buildContent()),
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
            text: "transactions",
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
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<SubHistoryProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return ShimmerUtils.buildHistoryShimmer(context, 10);
        }
        final items = provider.historyDataList ?? [];
        if (items.isEmpty) {
          return const NoData(
            title: 'no_transaction_title',
            subTitle: 'no_transaction_desc',
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
    final items = subHistoryProvider.historyDataList ?? [];
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
          items.length + (subHistoryProvider.loadMore ? 1 : 0),
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
    final items = subHistoryProvider.historyDataList ?? [];
    return SingleChildScrollView(
      controller: _scrollController,
      child: AlignedGridView.count(
        shrinkWrap: true,
        crossAxisCount: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 12,
        padding: const EdgeInsets.only(left: 15, right: 15),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length + (subHistoryProvider.loadMore ? 1 : 0),
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

  Widget _buildItem(Result item) {
    final bool expired = _isExpired(item);

    return Opacity(
      opacity: expired ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: secondaryBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expired
                ? titleTextColor.withValues(alpha: 0.1)
                : colorPrimary.withValues(alpha: 0.18),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: colorPrimary.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* Icon */
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: expired
                    ? titleTextColor.withValues(alpha: 0.07)
                    : colorPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              child: MyImage(imagePath: 'ic_movie.png'),
            ),
            const SizedBox(width: 12),

            /* Center details */
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    color: titleTextColor,
                    text: item.packageName ?? item.description ?? '',
                    multilanguage: false,
                    fontsizeNormal: 14,
                    fontsizeWeb: 16,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                  if ((item.transactionId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MyText(
                      color: descTextColor,
                      text:
                          '${Locales.string(context, "txn_id")}: ${item.transactionId}',
                      multilanguage: false,
                      fontsizeNormal: 11,
                      fontsizeWeb: 14,
                      fontweight: FontWeight.w400,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                  if ((item.createdAt ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MyText(
                      color: descTextColor,
                      text: _formatDate(item.createdAt!),
                      multilanguage: false,
                      fontsizeNormal: 11,
                      fontsizeWeb: 14,
                      fontweight: FontWeight.w400,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                  if ((item.expiryDate ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MyText(
                      color: expired ? descTextColor : colorPrimary,
                      text:
                          '${expired ? Locales.string(context, "expired_on") : Locales.string(context, "expire_on")}: ${_formatDate(item.expiryDate!)}',
                      multilanguage: false,
                      fontsizeNormal: 11,
                      fontsizeWeb: 14,
                      fontweight: FontWeight.w400,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                  if (item.transactionStatus != null || expired) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.transactionStatus != null)
                          _statusBadge(item.transactionStatus!),
                        if (expired)
                          _badge(color: descTextColor, labelKey: 'expired'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            /* Right: amount */
            MyText(
              color: expired ? descTextColor : colorPrimary,
              text: '${Constant.currencySymbol}${item.price ?? 0}',
              multilanguage: false,
              fontsizeNormal: 15,
              fontsizeWeb: 17,
              fontweight: FontWeight.bold,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.end,
              fontstyle: FontStyle.normal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(int status) {
    final Color color;
    final String labelKey;
    switch (status) {
      case 1:
        color = warningBG; // [TASK-1]
        labelKey = 'processing';
        break;
      case 2:
        color = colorPrimary;
        labelKey = 'success';
        break;
      case 3:
        color = redColor; // [TASK-1]
        labelKey = 'failed';
        break;
      default:
        return const SizedBox.shrink();
    }
    return _badge(color: color, labelKey: labelKey);
  }

  Widget _badge({required Color color, required String labelKey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.7),
      ),
      child: MyText(
        color: color,
        text: labelKey,
        multilanguage: true,
        fontsizeNormal: 10,
        fontsizeWeb: 14,
        fontweight: FontWeight.w600,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }
}

class TransactionStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color titleTextColor;
  final Color descTextColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const TransactionStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleTextColor,
    required this.descTextColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });
}
