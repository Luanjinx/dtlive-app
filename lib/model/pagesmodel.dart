// To parse this JSON data, do
// final pagesModel = pagesModelFromJson(jsonString);

import 'dart:convert';

PagesModel pagesModelFromJson(String str) =>
    PagesModel.fromJson(json.decode(str));

String pagesModelToJson(PagesModel data) => json.encode(data.toJson());

class PagesModel {
  int? status;
  String? message;
  List<Result>? result;

  PagesModel({
    this.status,
    this.message,
    this.result,
  });

  factory PagesModel.fromJson(Map<String, dynamic> json) => PagesModel(
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
  String? title;
  String? pageName;
  String? url;
  String? icon;
  String? pageSubtitle;

  Result({
    this.title,
    this.pageName,
    this.url,
    this.icon,
    this.pageSubtitle,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        title: json["title"],
        pageName: json["page_name"],
        url: json["url"],
        icon: json["icon"],
        pageSubtitle: json["page_subtitle"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "page_name": pageName,
        "url": url,
        "icon": icon,
        "page_subtitle": pageSubtitle,
      };
}
