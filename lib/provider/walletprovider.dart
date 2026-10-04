import 'package:flutter/material.dart';

import '../model/wallettransactionmodel.dart' as wallettrans;
import '../utils/utils.dart';
import '../webservice/apiservices.dart';

class WalletProvider extends ChangeNotifier {
  wallettrans.WalletTransactionModel transactionModel =
      wallettrans.WalletTransactionModel();
  List<wallettrans.Result> walletTransList = [];

  bool loading = false;
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  /* ── Wallet Transactions (used by WalletHistory) ─────────── */
  Future<void> getWalletTransactions(int pageNo) async {
    if (pageNo == 1) {
      walletTransList = [];
    }
    loading = true;
    notifyListeners();
    transactionModel = wallettrans.WalletTransactionModel();
    try {
      transactionModel = await ApiService().getWalletTransactions(pageNo);
      if (transactionModel.status == 200) {
        setPagination(
          transactionModel.totalRows,
          transactionModel.totalPage,
          transactionModel.currentPage,
          transactionModel.morePage,
        );
        if (transactionModel.result != null &&
            (transactionModel.result?.length ?? 0) > 0) {
          for (var i = 0; i < (transactionModel.result?.length ?? 0); i++) {
            walletTransList.add(
              transactionModel.result?[i] ?? wallettrans.Result(),
            );
          }
          // Deduplicate by id
          final Map<int, wallettrans.Result> map = {};
          for (final item in walletTransList) {
            map[item.id ?? 0] = item;
          }
          walletTransList = map.values.toList();
          setLoadMore(false);
        }
      }
    } on Exception catch (e) {
      printLog("getWalletTransactions Exception :=> $e");
    }
    loading = false;
    notifyListeners();
  }

  /* ── Tab Items (used by Wallet page tabs) ─────────────────── */
  List<wallettrans.WalletTabItem> tabItems = [];
  bool tabLoading = false;

  Future<void> loadTabItems(String tabKey, int pageNo) async {
    if (pageNo == 1) {
      tabItems.clear();
      tabItems = [];
    }
    tabLoading = true;
    notifyListeners();

    try {
      if (tabKey == 'package') {
        final model = await ApiService().subscriptionList(pageNo);
        if (model.status == 200 &&
            model.result != null &&
            (model.result?.isNotEmpty ?? false)) {
          tabItems.addAll(
            model.result!.map(
              (e) => wallettrans.WalletTabItem(
                icon: 'ic_movie.png',
                title: e.packageName ?? e.description ?? '',
                txnId: e.transactionId ?? '',
                referralCode: '',
                amount: '${e.price ?? 0}',
                date: '${e.createdAt ?? 0}',
                expDate: '${e.expiryDate ?? 0}',
                isCredit: false,
                transactionStatus: e.transactionStatus,
                paymentType: e.paymentType,
              ),
            ),
          );
        }
      } else if (tabKey == 'wallet') {
        final model = await ApiService().getWalletTransactions(pageNo);
        if (model.status == 200 &&
            model.result != null &&
            (model.result?.isNotEmpty ?? false)) {
          tabItems.addAll(
            model.result!.map(
              (e) => wallettrans.WalletTabItem(
                icon: 'ic_wallet3.png',
                title: e.description ?? '',
                txnId: e.transactionId ?? '',
                referralCode: '',
                amount: '${e.amount ?? 0}',
                date: '${e.createdAt ?? 0}',
                expDate: '',
                isCredit: (e.status ?? 0) == 1,
              ),
            ),
          );
        }
      } else if (tabKey == 'rent') {
        final model = await ApiService().userRentContentList(pageNo);
        if (model.status == 200 &&
            model.result != null &&
            (model.result?.isNotEmpty ?? false)) {
          tabItems.addAll(
            model.result!.map(
              (e) => wallettrans.WalletTabItem(
                icon: 'ic_rent_movie.png',
                title: e.name ?? '',
                txnId: '${e.id ?? ''}',
                referralCode: '',
                amount: '${e.price ?? 0}',
                date: '${e.rentCreatedAt ?? 0}',
                expDate: '${e.rentExpiryDate ?? 0}',
                isCredit: false,
              ),
            ),
          );
        }
      } else if (tabKey == 'referral') {
        final model = await ApiService().getReferEarnHistory(pageNo);
        if (model.status == 200 &&
            model.result != null &&
            (model.result?.isNotEmpty ?? false)) {
          tabItems.addAll(
            model.result!.map(
              (e) => wallettrans.WalletTabItem(
                icon: 'ic_gift2.png',
                title: e.displayName,
                txnId: '',
                referralCode: e.referenceCode ?? '',
                amount: '${e.parentEarn ?? 0}',
                date: '${e.createdAt ?? 0}',
                expDate: '',
                isCredit: (e.parentEarn ?? 0) > 0,
              ),
            ),
          );
        }
      }
    } on Exception catch (e) {
      printLog("loadTabItems Exception :=> $e");
    }
    tabLoading = false;
    notifyListeners();
  }

  void clearTabItems() {
    tabItems = [];
    tabLoading = false;
  }

  /* ── Pagination ────────────────────────────────────────────── */
  void setLoadMore(bool value) {
    loadMore = value;
    notifyListeners();
  }

  void setPagination(
    int? totalRows,
    int? totalPage,
    int? currentPage,
    bool? morePage,
  ) {
    this.currentPage = currentPage;
    this.totalRows = totalRows;
    this.totalPage = totalPage;
    isMorePage = morePage;
    notifyListeners();
  }

  /* ── Reset ──────────────────────────────────────────────────── */
  void clearTransactions() {
    transactionModel = wallettrans.WalletTransactionModel();
    walletTransList.clear();
    loadMore = false;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    isMorePage = null;
  }

  void clearProvider() {
    clearTransactions();
    clearTabItems();
    loading = false;
  }
}
