// To parse this JSON data, do
// final channelModel = channelModelFromJson(jsonString);

import 'dart:convert';

ChannelModel channelModelFromJson(String str) =>
    ChannelModel.fromJson(json.decode(str));

String channelModelToJson(ChannelModel data) => json.encode(data.toJson());

class ChannelModel {
  int? status;
  String? message;
  List<Result>? result;

  ChannelModel({
    this.status,
    this.message,
    this.result,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) => ChannelModel(
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
  String? name;
  String? portraitImg;
  String? landscapeImg;
  int? producerId;
  int? isTitle;
  int? status;
  String? createdAt;
  String? updatedAt;

  Result({
    this.id,
    this.name,
    this.portraitImg,
    this.landscapeImg,
    this.producerId,
    this.isTitle,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        name: json["name"],
        portraitImg: json["portrait_img"],
        landscapeImg: json["landscape_img"],
        producerId: json["producer_id"],
        isTitle: json["is_title"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "portrait_img": portraitImg,
        "landscape_img": landscapeImg,
        "producer_id": producerId,
        "is_title": isTitle,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
