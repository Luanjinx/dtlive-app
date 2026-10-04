// To parse this JSON data, do
// final deviceSyncModel = deviceSyncModelFromJson(jsonString);

import 'dart:convert';

DeviceSyncModel deviceSyncModelFromJson(String str) =>
    DeviceSyncModel.fromJson(json.decode(str));

String deviceSyncModelToJson(DeviceSyncModel data) =>
    json.encode(data.toJson());

class DeviceSyncModel {
  int? status;
  String? message;
  List<Result>? result;

  DeviceSyncModel({
    this.status,
    this.message,
    this.result,
  });

  factory DeviceSyncModel.fromJson(Map<String, dynamic> json) =>
      DeviceSyncModel(
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
  int? userId;
  String? deviceName;
  int? deviceType;
  String? deviceId;
  String? deviceToken;
  int? kidsMode;
  int? status;
  String? createdAt;
  String? updatedAt;

  Result({
    this.id,
    this.userId,
    this.deviceName,
    this.deviceType,
    this.deviceId,
    this.deviceToken,
    this.kidsMode,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        userId: json["user_id"],
        deviceName: json["device_name"],
        deviceType: json["device_type"],
        deviceId: json["device_id"],
        deviceToken: json["device_token"],
        kidsMode: json["kids_mode"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "device_name": deviceName,
        "device_type": deviceType,
        "device_id": deviceId,
        "device_token": deviceToken,
        "kids_mode": kidsMode,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
