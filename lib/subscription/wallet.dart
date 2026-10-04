import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/wallettransactionmodel.dart' show WalletTabItem;
import '../pages/referandearnhistory.dart';
import '../provider/profileprovider.dart';
import '../provider/walletprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import 'mypurchaselist.dart';
import 'subscriptionhistory.dart';
import 'wallethistory.dart';

enum _WalletTab { package, wallet, rent, referral }

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  late WalletProvider walletProvider;
  final _amountController = TextEditingController();
  _WalletTab _selectedTab = _WalletTab.package;

  String get _selectedTabKey =>
      _selectedTab.name; // 'package','wallet','rent','referral'

  @override
  void initState() {
    super.initState();
    walletProvider = Provider.of<WalletProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletProvider.clearTabItems();
      walletProvider.loadTabItems(_selectedTabKey, 1);
    });
  }

  void _onTabSelected(_WalletTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    walletProvider.clearTabItems();
    walletProvider.loadTabItems(tab.name, 1);
  }

  @override
  void dispose() {
    _amountController.dispose();
    LoadingOverlay().hide();
    walletProvider.clearProvider();
    super.dispose();
  }

  bool _checkExpiry(String expDate) {
    return DateTime.now().isBefore(DateTime.parse(expDate));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: RoutesConstant.walletPage,
        oldPage: RoutesConstant.homePage,
        reqText: '',
        newChild: Center(
          child: Column(
            children: [
              SizedBox(height: Dimens.homeTabHeight + 30),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(left: 20, right: 20),
                alignment: Alignment.center,
                child: MyText(
                  color: colorPrimary,
                  text: "wallet",
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
              _buildWalletContent(),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildWalletContent()),
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
        text: 'wallet',
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

  Widget _buildWalletContent() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double hPadding = bigScreen ? 40.0 : 16.0;
    final double maxWidth = (Dimens.isWeb(context))
        ? (MediaQuery.of(context).size.width * 0.5)
        : (Dimens.isTablet(context)
              ? (MediaQuery.of(context).size.width * 0.7)
              : MediaQuery.of(context).size.width);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: hPadding,
          vertical: bigScreen ? 24 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(),
            const SizedBox(height: 28),
            _buildRecentTransactionsHeader(),
            const SizedBox(height: 14),
            _buildTabsRow(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: 0.1),
                    blurRadius: 50,
                    spreadRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: _buildTransactionList(),
            ),
          ],
        ),
      ),
    );
  }

  /* ── Wallet Card ─────────────────────────────────────────── */
  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(15, 5, 15, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPrimary, colorPrimaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.5),
            blurRadius: 23,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildBalanceInfo()),
              const SizedBox(width: 8),
              MyImage(imagePath: 'ic_wallet2.png', width: 90, height: 90),
            ],
          ),
          const SizedBox(height: 20),
          _buildAddMoneyButton(),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          color: gray,
          text: 'total_balance',
          multilanguage: true,
          fontsizeNormal: 14,
          fontsizeWeb: 16,
          fontweight: FontWeight.w500,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, _) {
            if (profileProvider.loading) {
              return Container(
                height: 30,
                width: 30,
                margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Center(
                  child: CircularProgressIndicator(
                    color: colorAccent,
                    padding: .zero,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final walletAmount =
                profileProvider.profileModel.result?[0].walletAmount ?? 0;
            return Container(
              margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: MyText(
                color: black,
                text: '${Constant.currencySymbol}$walletAmount',
                multilanguage: false,
                fontsizeNormal: 33,
                fontsizeWeb: 36,
                fontweight: FontWeight.bold,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddMoneyButton() {
    return FittedBox(
      child: Material(
        color: white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showAddMoneySheet(context),
          child: Container(
            height: 30,
            padding: EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: MyText(
              color: appBgColor,
              text: 'add_money',
              multilanguage: true,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              fontweight: FontWeight.w500,
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

  /* ── Tabs Row ────────────────────────────────────────────── */
  Widget _buildTabsRow() {
    return Row(
      children: _WalletTab.values.map((tab) {
        final bool selected = _selectedTab == tab;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: tab != _WalletTab.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => _onTabSelected(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: Dimens.isWeb(context) ? 50 : 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? white : transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? white
                        : titleTextColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: MyText(
                  color: selected ? appBgColor : titleTextColor,
                  text: tab.name,
                  multilanguage: true,
                  fontsizeNormal: 13,
                  fontsizeWeb: 15,
                  fontweight: selected ? FontWeight.w700 : FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /* ── Recent Transactions ─────────────────────────────────── */
  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          color: titleTextColor,
          text: 'recent_transactions',
          multilanguage: true,
          fontsizeNormal: 16,
          fontsizeWeb: 18,
          fontweight: FontWeight.w600,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _navigateToViewAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: MyText(
              color: colorPrimary,
              text: 'view_all',
              multilanguage: true,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              fontweight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.end,
              fontstyle: FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.tabLoading) {
          return ShimmerUtils.buildWalletHistoryShimmer(context);
        }
        if (provider.tabItems.isEmpty) {
          return const NoData(title: 'no_transactions_found', subTitle: '');
        }
        final items = provider.tabItems.take(5).toList();
        return ListView.separated(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildTransactionItem(items[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(WalletTabItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: secondaryBgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCredit
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
              color: item.isCredit
                  ? colorPrimary.withValues(alpha: 0.15)
                  : white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: .all(8),
            child: MyImage(imagePath: item.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  color: titleTextColor,
                  text: item.title,
                  multilanguage: false,
                  fontsizeNormal: 14,
                  fontsizeWeb: 16,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 4),
                MyText(
                  color: descTextColor,
                  text: (item.txnId.isNotEmpty)
                      ? '${Locales.string(context, "txn_id")}: ${item.txnId}'
                      : item.referralCode,
                  multilanguage: false,
                  fontsizeNormal: 11,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w400,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 4),
                MyText(
                  color: titleTextColor.withValues(alpha: 0.85),
                  text: item.date.isNotEmpty
                      ? DateFormat(
                          "dd MMM yyyy",
                        ).format(DateTime.parse(item.date))
                      : "",
                  multilanguage: false,
                  fontsizeNormal: 11,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w400,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 4),
                if (item.expDate.isNotEmpty)
                  MyText(
                    color: colorPrimary,
                    text:
                        "${_checkExpiry(item.expDate) ? Locales.string(context, "expire_on") : Locales.string(context, "expired_on")} : ${DateFormat("dd MMM yyyy").format(DateTime.parse(item.expDate))}",
                    multilanguage: false,
                    fontsizeNormal: 11,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w400,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                if (item.transactionStatus != null ||
                    item.paymentType != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.transactionStatus != null)
                        _buildStatusBadge(item.transactionStatus!),
                      if (item.paymentType != null)
                        _buildPaymentTypeBadge(item.paymentType!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          MyText(
            color: item.isCredit ? colorPrimary : titleTextColor,
            text:
                '${item.isCredit ? '+' : '-'}${Constant.currencySymbol}${item.amount}',
            multilanguage: false,
            fontsizeNormal: 16,
            fontsizeWeb: 18,
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

  /* ── View All navigation (tab-aware) ─────────────────────── */
  void _navigateToViewAll() {
    switch (_selectedTab) {
      case _WalletTab.package:
        if (kIsWeb) {
          context.go(
            '/${RoutesConstant.subsHistoryPage}',
            extra: RoutesConstant.walletPage,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionHistory(
                newPage: null,
                oldPage: null,
                reqText: '',
              ),
            ),
          );
        }
        break;
      case _WalletTab.wallet:
        if (kIsWeb) {
          context.go(
            '/${RoutesConstant.walletHistoryPage}',
            extra: RoutesConstant.walletPage,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletHistory()),
          );
        }
        break;
      case _WalletTab.rent:
        if (kIsWeb) {
          context.go(
            '/${RoutesConstant.rentPurchasePage}',
            extra: RoutesConstant.walletPage,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MyPurchaselist(newPage: null, oldPage: null, reqText: ''),
            ),
          );
        }
        break;
      case _WalletTab.referral:
        if (kIsWeb) {
          context.go(
            '/${RoutesConstant.referEarnHistoryPage}',
            extra: RoutesConstant.walletPage,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReferEarnHistory()),
          );
        }
        break;
    }
  }

  Widget _buildStatusBadge(int status) {
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

  Widget _buildPaymentTypeBadge(int paymentType) {
    final String labelKey = paymentType == 1
        ? 'wallet_payment'
        : 'online_payment';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: descTextColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: descTextColor.withValues(alpha: 0.3),
          width: 0.7,
        ),
      ),
      child: MyText(
        color: descTextColor,
        text: labelKey,
        multilanguage: true,
        fontsizeNormal: 10,
        fontsizeWeb: 14,
        fontweight: FontWeight.w500,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  /* ── Add Money Bottom Sheet ──────────────────────────────── */
  void _showAddMoneySheet(BuildContext context) {
    _amountController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: secondaryBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: descTextColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              MyText(
                color: titleTextColor,
                text: 'add_money',
                multilanguage: true,
                fontsizeNormal: 18,
                fontsizeWeb: 20,
                fontweight: FontWeight.bold,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: titleTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: Constant.currencySymbol.isNotEmpty
                      ? '${Constant.currencySymbol} '
                      : '',
                  prefixStyle: const TextStyle(
                    color: colorPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: Locales.string(ctx, 'amount_hint'),
                  hintStyle: TextStyle(
                    color: descTextColor.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: appBgColor,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: colorPrimary,
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: colorPrimary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final amtStr = _amountController.text.trim();
                    final amt = int.tryParse(amtStr) ?? 0;
                    if (amt <= 0) {
                      Utils.showSnackbar(
                        ctx,
                        'info',
                        'enter_valid_amount',
                        true,
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    _proceedAddMoney(amt.toString());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: Utils.setGradLTRBGWithBorder(
                      colorPrimary,
                      colorPrimaryDark,
                      transparent,
                      12,
                      0,
                    ),
                    alignment: Alignment.center,
                    child: MyText(
                      color: appBgColor,
                      text: 'proceed',
                      multilanguage: true,
                      fontsizeNormal: 16,
                      fontsizeWeb: 18,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _proceedAddMoney(String amount) {
    if (Constant.userID == null) {
      Utils.showSnackbar(context, 'fail', 'please_login_first', false);
      return;
    }
    if (kIsWeb) {
      context.go(
        '/${RoutesConstant.paymentPage}',
        extra: {
          'paytype': 'wallet_topup',
          'newpage': RoutesConstant.paymentPage,
          'producerid': '',
          'itemid': '0',
          'price': amount,
          'title': 'Wallet Topup',
          'typeid': '',
          'videotype': '',
          'subvideotype': '',
          'productpackage': '',
          'currency': Constant.currency,
        },
      );
    } else {
      Utils.openWalletTopup(context: context, amount: amount);
    }
  }
}
