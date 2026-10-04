// To parse this JSON data, do
// final profileModel = profileModelFromJson(jsonString);

import 'dart:convert';

ProfileModel profileModelFromJson(String str) =>
    ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
  int? status;
  String? message;
  List<Result>? result;

  ProfileModel({this.status, this.message, this.result});

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
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
  String? userName;
  String? fullName;
  String? email;
  String? mobileNumber;
  int? storageType;
  int? imageType;
  String? image;
  int? type;
  int? parentControlStatus;
  String? parentControlPassword;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  String? packageName;
  String? expiryDate;
  String? referenceCode;
  dynamic walletAmount;
  List<UpcomingPackage>? upcomingPackage;

  Result({
    this.id,
    this.userName,
    this.fullName,
    this.email,
    this.mobileNumber,
    this.storageType,
    this.imageType,
    this.image,
    this.type,
    this.parentControlStatus,
    this.parentControlPassword,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.packageName,
    this.expiryDate,
    this.referenceCode,
    this.walletAmount,
    this.upcomingPackage,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    userName: json["user_name"],
    fullName: json["full_name"],
    email: json["email"],
    mobileNumber: json["mobile_number"],
    storageType: json["storage_type"],
    imageType: json["image_type"],
    image: json["image"],
    type: json["type"],
    parentControlStatus: json["parent_control_status"],
    parentControlPassword: json["parent_control_password"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    isBuy: json["is_buy"],
    packageName: json["package_name"],
    expiryDate: json["expiry_date"],
    referenceCode: json["reference_code"],
    walletAmount: json["wallet_amount"],
    upcomingPackage: json["upcoming_package"] == null
        ? []
        : List<UpcomingPackage>.from(
            json["upcoming_package"]?.map((x) => UpcomingPackage.fromJson(x)) ??
                [],
          ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_name": userName,
    "full_name": fullName,
    "email": email,
    "mobile_number": mobileNumber,
    "storage_type": storageType,
    "image_type": imageType,
    "image": image,
    "type": type,
    "parent_control_status": parentControlStatus,
    "parent_control_password": parentControlPassword,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "is_buy": isBuy,
    "package_name": packageName,
    "expiry_date": expiryDate,
    "reference_code": referenceCode,
    "wallet_amount": walletAmount,
    "upcoming_package": upcomingPackage == null
        ? []
        : List<dynamic>.from(upcomingPackage?.map((x) => x.toJson()) ?? []),
  };
}

class UpcomingPackage {
  int? id;
  String? name;
  dynamic price;
  String? type;
  String? time;
  String? watchOnLaptopTv;
  int? adsFreeContent;
  int? noOfDeviceSync;
  String? androidProductPackage;
  String? iosProductPackage;
  String? webProductPackage;
  int? status;
  String? createdAt;
  String? updatedAt;

  UpcomingPackage({
    this.id,
    this.name,
    this.price,
    this.type,
    this.time,
    this.watchOnLaptopTv,
    this.adsFreeContent,
    this.noOfDeviceSync,
    this.androidProductPackage,
    this.iosProductPackage,
    this.webProductPackage,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UpcomingPackage.fromJson(Map<String, dynamic> json) =>
      UpcomingPackage(
        id: json["id"],
        name: json["name"],
        price: json["price"],
        type: json["type"],
        time: json["time"],
        watchOnLaptopTv: json["watch_on_laptop_tv"],
        adsFreeContent: json["ads_free_content"],
        noOfDeviceSync: json["no_of_device_sync"],
        androidProductPackage: json["android_product_package"],
        iosProductPackage: json["ios_product_package"],
        webProductPackage: json["web_product_package"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "price": price,
    "type": type,
    "time": time,
    "watch_on_laptop_tv": watchOnLaptopTv,
    "ads_free_content": adsFreeContent,
    "no_of_device_sync": noOfDeviceSync,
    "android_product_package": androidProductPackage,
    "ios_product_package": iosProductPackage,
    "web_product_package": webProductPackage,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
