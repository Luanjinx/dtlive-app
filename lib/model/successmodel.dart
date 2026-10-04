// To parse this JSON data, do
// final successModel = successModelFromJson(jsonString);

import 'dart:convert';

SuccessModel successModelFromJson(String str) =>
    SuccessModel.fromJson(json.decode(str));

String successModelToJson(SuccessModel data) => json.encode(data.toJson());

class SuccessModel {
  int? status;
  String? message;
  List<Result>? result;

  SuccessModel({this.status, this.message, this.result});

  factory SuccessModel.fromJson(Map<String, dynamic> json) => SuccessModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null
        ? []
        : List<Result>.from(
            json["result"]?.map((x) => Result.fromJson(x)) ?? [],
          ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null
        ? []
        : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
  };
}

class Result {
  String? uniqueId;
  int? userId;
  int? packageId;
  String? transactionId;
  dynamic price;
  String? description;
  String? expiryDate;
  int? transactionStatus;
  int? status;
  String? updatedAt;
  String? createdAt;
  int? id;

  Result({
    this.uniqueId,
    this.userId,
    this.packageId,
    this.transactionId,
    this.price,
    this.description,
    this.expiryDate,
    this.transactionStatus,
    this.status,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    uniqueId: json["unique_id"],
    userId: json["user_id"],
    packageId: json["package_id"],
    transactionId: json["transaction_id"],
    price: json["price"],
    description: json["description"],
    expiryDate: json["expiry_date"],
    transactionStatus: json["transaction_status"],
    status: json["status"],
    updatedAt: json["updated_at"],
    createdAt: json["created_at"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "unique_id": uniqueId,
    "user_id": userId,
    "package_id": packageId,
    "transaction_id": transactionId,
    "price": price,
    "description": description,
    "expiry_date": expiryDate,
    "transaction_status": transactionStatus,
    "status": status,
    "updated_at": updatedAt,
    "created_at": createdAt,
    "id": id,
  };
}
