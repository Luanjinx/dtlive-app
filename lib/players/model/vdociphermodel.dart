// To parse this JSON data, do
// final vdoCipherModel = vdoCipherModelFromJson(jsonString);

import 'dart:convert';

VdoCipherModel vdoCipherModelFromJson(String str) =>
    VdoCipherModel.fromJson(json.decode(str));

String vdoCipherModelToJson(VdoCipherModel data) => json.encode(data.toJson());

class VdoCipherModel {
  int? status;
  String? message;
  Result? result;

  VdoCipherModel({
    this.status,
    this.message,
    this.result,
  });

  factory VdoCipherModel.fromJson(Map<String, dynamic> json) => VdoCipherModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null ? {} : result?.toJson(),
      };
}

class Result {
  String? otp;
  String? playbackInfo;
  String? message;

  Result({
    this.otp,
    this.playbackInfo,
    this.message,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        otp: json["otp"],
        playbackInfo: json["playbackInfo"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "otp": otp,
        "playbackInfo": playbackInfo,
        "message": message,
      };
}
