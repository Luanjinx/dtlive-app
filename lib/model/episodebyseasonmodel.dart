// To parse this JSON data, do
// final episodeBySeasonModel = episodeBySeasonModelFromJson(jsonString);

import 'dart:convert';

EpisodeBySeasonModel episodeBySeasonModelFromJson(String str) =>
    EpisodeBySeasonModel.fromJson(json.decode(str));

String episodeBySeasonModelToJson(EpisodeBySeasonModel data) =>
    json.encode(data.toJson());

class EpisodeBySeasonModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  EpisodeBySeasonModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory EpisodeBySeasonModel.fromJson(Map<String, dynamic> json) =>
      EpisodeBySeasonModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? null
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? []),
        totalRows: json["total_rows"],
        totalPage: json["total_page"],
        currentPage: json["current_page"],
        morePage: json["more_page"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null
            ? null
            : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
        "total_rows": totalRows,
        "total_page": totalPage,
        "current_page": currentPage,
        "more_page": morePage,
      };
}

class Result {
  int? id;
  int? showId;
  int? seasonId;
  String? name;
  String? thumbnail;
  String? landscape;
  String? description;
  String? videoUploadType;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  String? videoExtension;
  int? videoDuration;
  int? stopTime;
  String? subtitleType;
  String? subtitleLang1;
  String? subtitle1;
  String? subtitleLang2;
  String? subtitle2;
  String? subtitleLang3;
  String? subtitle3;
  int? isPremium;
  int? isTitle;
  int? isDownload;
  int? totalView;
  int? sortable;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  int? isRent;
  int? rentBuy;

  Result({
    this.id,
    this.showId,
    this.seasonId,
    this.name,
    this.thumbnail,
    this.landscape,
    this.description,
    this.videoUploadType,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.videoExtension,
    this.videoDuration,
    this.stopTime,
    this.subtitleType,
    this.subtitleLang1,
    this.subtitle1,
    this.subtitleLang2,
    this.subtitle2,
    this.subtitleLang3,
    this.subtitle3,
    this.isPremium,
    this.isTitle,
    this.isDownload,
    this.totalView,
    this.sortable,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.isRent,
    this.rentBuy,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        showId: json["show_id"],
        seasonId: json["season_id"],
        name: json["name"],
        thumbnail: json["thumbnail"],
        landscape: json["landscape"],
        description: json["description"],
        videoUploadType: json["video_upload_type"],
        video320: json["video_320"],
        video480: json["video_480"],
        video720: json["video_720"],
        video1080: json["video_1080"],
        videoExtension: json["video_extension"],
        videoDuration: json["video_duration"],
        stopTime: json["stop_time"],
        subtitleType: json["subtitle_type"],
        subtitleLang1: json["subtitle_lang_1"],
        subtitle1: json["subtitle_1"],
        subtitleLang2: json["subtitle_lang_2"],
        subtitle2: json["subtitle_2"],
        subtitleLang3: json["subtitle_lang_3"],
        subtitle3: json["subtitle_3"],
        isPremium: json["is_premium"],
        isTitle: json["is_title"],
        isDownload: json["is_download"],
        totalView: json["total_view"],
        sortable: json["sortable"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        isBuy: json["is_buy"],
        isRent: json["is_rent"],
        rentBuy: json["rent_buy"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "show_id": showId,
        "season_id": seasonId,
        "name": name,
        "thumbnail": thumbnail,
        "landscape": landscape,
        "description": description,
        "video_upload_type": videoUploadType,
        "video_320": video320,
        "video_480": video480,
        "video_720": video720,
        "video_1080": video1080,
        "video_extension": videoExtension,
        "video_duration": videoDuration,
        "stop_time": stopTime,
        "subtitle_type": subtitleType,
        "subtitle_lang_1": subtitleLang1,
        "subtitle_1": subtitle1,
        "subtitle_lang_2": subtitleLang2,
        "subtitle_2": subtitle2,
        "subtitle_lang_3": subtitleLang3,
        "subtitle_3": subtitle3,
        "is_premium": isPremium,
        "is_title": isTitle,
        "is_download": isDownload,
        "total_view": totalView,
        "sortable": sortable,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "is_buy": isBuy,
        "is_rent": isRent,
        "rent_buy": rentBuy,
      };
}
