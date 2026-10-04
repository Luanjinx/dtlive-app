import 'dart:convert';

WalletTransactionModel walletTransactionModelFromJson(String str) =>
    WalletTransactionModel.fromJson(json.decode(str));

String walletTransactionModelToJson(WalletTransactionModel data) =>
    json.encode(data.toJson());

class WalletTransactionModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  WalletTransactionModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) =>
      WalletTransactionModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? [],
              ),
        totalRows: json["total_rows"],
        totalPage: json["total_page"],
        currentPage: json["current_page"],
        morePage: json["more_page"],
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null
        ? []
        : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
    "total_rows": totalRows,
    "total_page": totalPage,
    "current_page": currentPage,
    "more_page": morePage,
  };
}

class Result {
  int? id;
  int? userId;
  dynamic amount;
  String? transactionId;
  String? description;
  int? status;
  String? createdAt;
  String? updatedAt;

  Result({
    this.id,
    this.userId,
    this.amount,
    this.transactionId,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    userId: json["user_id"],
    amount: json["amount"],
    transactionId: json["transaction_id"],
    description: json["description"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "amount": amount,
    "transaction_id": transactionId,
    "description": description,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}

/// Unified display model used by the 4 wallet tabs
class WalletTabItem {
  final String icon;
  final String title;
  final String txnId;
  final String referralCode;
  final String amount;
  final String date;
  final String expDate;
  final bool isCredit;
  final int? transactionStatus; // 1=Processing, 2=Success, 3=Failed (package tab)
  final int? paymentType; // 0=Online, 1=Wallet (package tab)

  const WalletTabItem({
    required this.icon,
    required this.title,
    required this.txnId,
    required this.referralCode,
    required this.amount,
    required this.date,
    required this.expDate,
    required this.isCredit,
    this.transactionStatus,
    this.paymentType,
  });
}

/// Response model for add_wallet_amount API
class AddWalletAmountModel {
  int? status;
  String? message;
  int? walletAmount;

  AddWalletAmountModel({this.status, this.message, this.walletAmount});

  factory AddWalletAmountModel.fromJson(Map<String, dynamic> json) =>
      AddWalletAmountModel(
        status: json["status"],
        message: json["message"],
        walletAmount: json["wallet_amount"],
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "wallet_amount": walletAmount,
  };
}
