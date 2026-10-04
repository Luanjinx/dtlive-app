// To parse this JSON data, do
// final loginRegisterModel = loginRegisterModelFromJson(jsonString);

import 'dart:convert';

LoginRegisterModel profileModelFromJson(String str) =>
    LoginRegisterModel.fromJson(json.decode(str));

String profileModelToJson(LoginRegisterModel data) =>
    json.encode(data.toJson());

class LoginRegisterModel {
  int? status;
  String? message;
  List<Result>? result;

  LoginRegisterModel({
    this.status,
    this.message,
    this.result,
  });

  factory LoginRegisterModel.fromJson(Map<String, dynamic> json) =>
      LoginRegisterModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? []),
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
  String? fullName;
  String? userName;
  String? mobileNumber;
  String? email;
  String? password;
  String? image;
  int? status;
  int? type;
  String? expiryDate;
  dynamic deviceType;
  String? deviceId;
  String? deviceToken;
  int? parentControlStatus;
  String? parentControlPassword;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  String? referenceCode;

  Result({
    this.id,
    this.userName,
    this.fullName,
    this.mobileNumber,
    this.email,
    this.image,
    this.type,
    this.status,
    this.expiryDate,
    this.deviceType,
    this.deviceId,
    this.deviceToken,
    this.parentControlStatus,
    this.parentControlPassword,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.referenceCode,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        userName: json["user_name"],
        fullName: json["full_name"],
        mobileNumber: json["mobile_number"],
        email: json["email"],
        image: json["image"],
        type: json["type"],
        status: json["status"],
        expiryDate: json["expiry_date"],
        deviceType: json["device_type"],
        deviceId: json["device_id"],
        deviceToken: json["device_token"],
        parentControlStatus: json["parent_control_status"],
        parentControlPassword: json["parent_control_password"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        isBuy: json["is_buy"],
        referenceCode: json["reference_code"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_name": userName,
        "full_name": fullName,
        "mobile_number": mobileNumber,
        "email": email,
        "image": image,
        "type": type,
        "status": status,
        "expiry_date": expiryDate,
        "device_type": deviceType,
        "device_id": deviceId,
        "device_token": deviceToken,
        "parent_control_status": parentControlStatus,
        "parent_control_password": parentControlPassword,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "is_buy": isBuy,
        "reference_code": referenceCode,
      };
}
