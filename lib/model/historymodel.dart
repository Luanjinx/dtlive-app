// To parse this JSON data, do
// final historyModel = historyModelFromJson(jsonString);

import 'dart:convert';

HistoryModel historyModelFromJson(String str) =>
    HistoryModel.fromJson(json.decode(str));

String historyModelToJson(HistoryModel data) => json.encode(data.toJson());

class HistoryModel {
  HistoryModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  factory HistoryModel.fromJson(Map<String, dynamic> json) => HistoryModel(
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
  };
}

class Result {
  int? id;
  int? userId;
  String? uniqueId;
  int? packageId;
  String? description;
  dynamic price;
  String? transactionId;
  String? expiryDate;
  int? status;
  String? date;
  String? createdAt;
  String? updatedAt;
  int? isDelete;
  int? isUpcoming;
  String? packageName;
  dynamic packagePrice;
  int? transactionStatus; // 1=Processing, 2=Success, 3=Failed
  int? paymentType; // 0=Online, 1=Wallet

  Result({
    this.id,
    this.userId,
    this.uniqueId,
    this.packageId,
    this.description,
    this.price,
    this.transactionId,
    this.expiryDate,
    this.status,
    this.date,
    this.createdAt,
    this.updatedAt,
    this.isDelete,
    this.isUpcoming,
    this.packageName,
    this.packagePrice,
    this.transactionStatus,
    this.paymentType,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    userId: json["user_id"],
    uniqueId: json["unique_id"],
    packageId: json["package_id"],
    description: json["description"],
    price: json["price"],
    transactionId: json["transaction_id"],
    expiryDate: json["expiry_date"],
    status: json["status"],
    date: json["date"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    isDelete: json["is_delete"],
    isUpcoming: json["is_upcoming"],
    packageName: json["package_name"],
    packagePrice: json["package_price"],
    transactionStatus: json["transaction_status"],
    paymentType: json["payment_type"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "unique_id": uniqueId,
    "package_id": packageId,
    "description": description,
    "price": price,
    "transaction_id": transactionId,
    "expiry_date": expiryDate,
    "status": status,
    "date": date,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "is_delete": isDelete,
    "is_upcoming": isUpcoming,
    "package_name": packageName,
    "package_price": packagePrice,
    "transaction_status": transactionStatus,
    "payment_type": paymentType,
  };
}
