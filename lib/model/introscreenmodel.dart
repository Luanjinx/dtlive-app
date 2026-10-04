// To parse this JSON data, do
// final introScreenModel = introScreenModelFromJson(jsonString);

import 'dart:convert';

IntroScreenModel introScreenModelFromJson(String str) =>
    IntroScreenModel.fromJson(json.decode(str));

String introScreenModelToJson(IntroScreenModel data) =>
    json.encode(data.toJson());

class IntroScreenModel {
  int? status;
  String? message;
  List<Result>? result;

  IntroScreenModel({
    this.status,
    this.message,
    this.result,
  });

  factory IntroScreenModel.fromJson(Map<String, dynamic> json) =>
      IntroScreenModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(json["result"]?.map((x) => Result.fromJson(x))),
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
  String? title;
  String? image;
  int? status;
  String? createdAt;
  String? updatedAt;

  Result({
    this.id,
    this.title,
    this.image,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        title: json["title"],
        image: json["image"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "image": image,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
