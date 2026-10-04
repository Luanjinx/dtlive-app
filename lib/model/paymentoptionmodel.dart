// To parse this JSON data, do
// final paymentOptionModel = paymentOptionModelFromJson(jsonString);

import 'dart:convert';

PaymentOptionModel paymentOptionModelFromJson(String str) =>
    PaymentOptionModel.fromJson(json.decode(str));

String paymentOptionModelToJson(PaymentOptionModel data) =>
    json.encode(data.toJson());

class PaymentOptionModel {
  PaymentOptionModel({
    this.status,
    this.message,
    this.result,
  });

  int? status;
  String? message;
  Result? result;

  factory PaymentOptionModel.fromJson(Map<String, dynamic> json) =>
      PaymentOptionModel(
        status: json["status"],
        message: json["message"],
        result: Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null ? {} : result?.toJson() ?? {},
      };
}

class Result {
  Result({
    this.inAppPurchage,
    this.paypal,
    this.razorpay,
    this.flutterWave,
    this.payUMoney,
    this.payTm,
    this.stripe,
    this.paystack,
    this.instamojo,
    this.cash,
  });

  PaymentGatewayData? inAppPurchage;
  PaymentGatewayData? paypal;
  PaymentGatewayData? razorpay;
  PaymentGatewayData? flutterWave;
  PaymentGatewayData? payUMoney;
  PaymentGatewayData? payTm;
  PaymentGatewayData? stripe;
  PaymentGatewayData? paystack;
  PaymentGatewayData? instamojo;
  PaymentGatewayData? cash;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        inAppPurchage: json["inapppurchage"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["inapppurchage"]),
        paypal: json["paypal"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["paypal"]),
        razorpay: json["razorpay"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["razorpay"]),
        flutterWave: json["flutterwave"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["flutterwave"]),
        payUMoney: json["payumoney"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["payumoney"]),
        payTm: json["paytm"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["paytm"]),
        stripe: json["stripe"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["stripe"]),
        paystack: json["paystack"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["paystack"]),
        instamojo: json["instamojo"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["instamojo"]),
        cash: json["cash"] == null
            ? PaymentGatewayData.fromJson({})
            : PaymentGatewayData.fromJson(json["cash"]),
      );

  Map<String, dynamic> toJson() => {
        "inapppurchage":
            inAppPurchage == null ? {} : inAppPurchage?.toJson() ?? {},
        "paypal": paypal == null ? {} : paypal?.toJson() ?? {},
        "razorpay": razorpay == null ? {} : razorpay?.toJson() ?? {},
        "flutterwave": flutterWave == null ? {} : flutterWave?.toJson() ?? {},
        "payumoney": payUMoney == null ? {} : payUMoney?.toJson() ?? {},
        "paytm": payTm == null ? {} : payTm?.toJson() ?? {},
        "stripe": stripe == null ? {} : stripe?.toJson() ?? {},
        "paystack": paystack == null ? {} : paystack?.toJson() ?? {},
        "instamojo": instamojo == null ? {} : instamojo?.toJson() ?? {},
        "cash": cash == null ? {} : cash?.toJson() ?? {},
      };
}

class PaymentGatewayData {
  PaymentGatewayData({
    this.id,
    this.name,
    this.visibility,
    this.isLive,
    this.key1,
    this.key2,
    this.key3,
    this.key4,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  String? name;
  String? visibility;
  String? isLive;
  String? key1;
  String? key2;
  String? key3;
  String? key4;
  String? createdAt;
  String? updatedAt;

  factory PaymentGatewayData.fromJson(Map<String, dynamic> json) =>
      PaymentGatewayData(
        id: json["id"],
        name: json["name"],
        visibility: json["visibility"],
        isLive: json["is_live"],
        key1: json["key_1"],
        key2: json["key_2"],
        key3: json["key_3"],
        key4: json["key_4"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "visibility": visibility,
        "is_live": isLive,
        "key_1": key1,
        "key_2": key2,
        "key_3": key3,
        "key_4": key4,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
