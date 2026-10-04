// To parse this JSON data, do
// final subscriptionModel = subscriptionModelFromJson(jsonString);

import 'dart:convert';

SubscriptionModel subscriptionModelFromJson(String str) =>
    SubscriptionModel.fromJson(json.decode(str));

String subscriptionModelToJson(SubscriptionModel data) =>
    json.encode(data.toJson());

class SubscriptionModel {
  int? status;
  String? message;
  List<Result>? result;

  SubscriptionModel({this.status, this.message, this.result});

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
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
  int? id;
  String? name;
  dynamic price;
  String? time;
  String? type;
  String? typeId;
  String? androidProductPackage;
  String? iosProductPackage;
  String? webPriceId;
  List<Datum>? data;
  int? isBuy;
  int? isActivePlan;

  Result({
    this.id,
    this.name,
    this.price,
    this.time,
    this.type,
    this.typeId,
    this.androidProductPackage,
    this.iosProductPackage,
    this.webPriceId,
    this.data,
    this.isBuy,
    this.isActivePlan,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    name: json["name"],
    price: json["price"],
    time: json["time"],
    type: json["type"],
    typeId: json["type_id"],
    androidProductPackage: json["android_product_package"],
    iosProductPackage: json["ios_product_package"],
    webPriceId: json["web_price_id"],
    data: List<Datum>.from(json["data"]?.map((x) => Datum.fromJson(x)) ?? []),
    isBuy: json["is_buy"],
    isActivePlan: json["is_active_plan"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "price": price,
    "time": time,
    "type": type,
    "type_id": typeId,
    "android_product_package": androidProductPackage,
    "ios_product_package": iosProductPackage,
    "web_price_id": webPriceId,
    "data": data == null
        ? []
        : List<dynamic>.from(data?.map((x) => x.toJson()) ?? []),
    "is_buy": isBuy,
    "is_active_plan": isActivePlan,
  };
}

class Datum {
  int? id;
  int? packageId;
  String? packageKey;
  String? packageValue;
  String? createdAt;
  String? updatedAt;

  Datum({
    this.id,
    this.packageId,
    this.packageKey,
    this.packageValue,
    this.createdAt,
    this.updatedAt,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    packageId: json["package_id"],
    packageKey: json["package_key"],
    packageValue: json["package_value"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "package_id": packageId,
    "package_key": packageKey,
    "package_value": packageValue,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
