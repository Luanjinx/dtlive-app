import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';

import '../model/wallettransactionmodel.dart';
import '../provider/walletprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({super.key});

  @override
  State<WalletHistory> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends State<WalletHistory> {
  late WalletProvider walletProvider;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletProvider.clearTransactions();
      _loadData(1);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData(int page) async {
    _currentPage = page;
    await walletProvider.getWalletTransactions(page);
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange &&
        !(walletProvider.loadMore) &&
        (walletProvider.isMorePage ?? false)) {
      walletProvider.setLoadMore(true);
      _loadData(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: RoutesConstant.walletHistoryPage,
        oldPage: RoutesConstant.walletPage,
        reqText: '',
        newChild: _buildForWeb(),
      );
    }
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildPageBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: appBgColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: titleTextColor,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: MyText(
        color: colorPrimary,
        text: 'transaction_history',
        multilanguage: true,
        fontsizeNormal: 20,
        fontsizeWeb: 22,
        fontweight: FontWeight.bold,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
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
            text: "transaction_history",
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
          child: Center(child: _buildPageBody()),
        ),
      ],
    );
  }

  Widget _buildPageBody() {
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        if (provider.loading && provider.walletTransList.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimens.isBigScreen(context) ? 40 : 16,
            ),
            child: ShimmerUtils.buildWalletHistoryShimmer(context),
          );
        }
        return _buildContent(provider);
      },
    );
  }

  Widget _buildContent(WalletProvider provider) {
    if (provider.walletTransList.isEmpty) {
      return const NoData(title: 'no_transactions_found', subTitle: '');
    }

    final bool bigScreen = Dimens.isBigScreen(context);
    final double hPadding = bigScreen ? 40.0 : 16.0;
    final double maxWidth = bigScreen ? 720.0 : double.infinity;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
          horizontal: hPadding,
          vertical: bigScreen ? 16 : 12,
        ),
        itemCount:
            provider.walletTransList.length + (provider.loadMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == provider.walletTransList.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Utils.pageLoader(),
              ),
            );
          }
          return _buildItem(provider.walletTransList[index]);
        },
      ),
    );
  }

  Widget _buildItem(Result item) {
    final isCredit = (item.status ?? 0) == 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: secondaryBgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCredit
              ? colorPrimary.withValues(alpha: 0.18)
              : titleTextColor.withValues(alpha: 0.07),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isCredit
                  ? colorPrimary.withValues(alpha: 0.15)
                  : white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: .all(8),
            child: MyImage(imagePath: "ic_wallet3.png"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: titleTextColor,
                  text: item.description ?? '',
                  multilanguage: false,
                  fontsizeNormal: 14,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w600,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 4),
                MyText(
                  color: descTextColor,
                  text:
                      '${Locales.string(context, "txn_id")}: ${item.transactionId ?? ""}',
                  multilanguage: false,
                  fontsizeNormal: 11,
                  fontsizeWeb: 12,
                  fontweight: FontWeight.w400,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MyText(
            color: isCredit ? colorPrimary : titleTextColor,
            text:
                '${isCredit ? '+' : '-'}${Constant.currencySymbol}${item.amount ?? 0}',
            multilanguage: false,
            fontsizeNormal: 16,
            fontsizeWeb: 17,
            fontweight: FontWeight.bold,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.end,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }
}
