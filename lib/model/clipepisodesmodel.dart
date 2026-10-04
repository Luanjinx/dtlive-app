// To parse this JSON data, do
// final shortFilmEpisodeModel = shortFilmEpisodeModelFromJson(jsonString);

import 'dart:convert';

ClipEpisodesModel shortFilmEpisodeModelFromJson(String str) =>
    ClipEpisodesModel.fromJson(json.decode(str));

String shortFilmEpisodeModelToJson(ClipEpisodesModel data) =>
    json.encode(data.toJson());

class ClipEpisodesModel {
  int? status;
  String? message;
  List<Result>? result;

  ClipEpisodesModel({
    this.status,
    this.message,
    this.result,
  });

  factory ClipEpisodesModel.fromJson(Map<String, dynamic> json) =>
      ClipEpisodesModel(
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
  int? showId;
  int? seasonId;
  String? name;
  int? storageType;
  String? thumbnail;
  String? description;
  int? videoStorageType;
  String? videoUploadType;
  String? video320;
  int? videoDuration;
  int? isPremium;
  int? isTitle;
  int? isComment;
  int? isLike;
  int? totalView;
  int? totalLike;
  int? sortOrder;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  int? isUserLike;

  Result({
    this.id,
    this.showId,
    this.seasonId,
    this.name,
    this.storageType,
    this.thumbnail,
    this.description,
    this.videoStorageType,
    this.videoUploadType,
    this.video320,
    this.videoDuration,
    this.isPremium,
    this.isTitle,
    this.isComment,
    this.isLike,
    this.totalView,
    this.totalLike,
    this.sortOrder,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.isUserLike,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        showId: json["show_id"],
        seasonId: json["season_id"],
        name: json["name"],
        storageType: json["storage_type"],
        thumbnail: json["thumbnail"],
        description: json["description"],
        videoStorageType: json["video_storage_type"],
        videoUploadType: json["video_upload_type"],
        video320: json["video_320"],
        videoDuration: json["video_duration"],
        isPremium: json["is_premium"],
        isTitle: json["is_title"],
        isComment: json["is_comment"],
        isLike: json["is_like"],
        totalView: json["total_view"],
        totalLike: json["total_like"],
        sortOrder: json["sort_order"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        isBuy: json["is_buy"],
        isUserLike: json["is_user_like"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "show_id": showId,
        "season_id": seasonId,
        "name": name,
        "storage_type": storageType,
        "thumbnail": thumbnail,
        "description": description,
        "video_storage_type": videoStorageType,
        "video_upload_type": videoUploadType,
        "video_320": video320,
        "video_duration": videoDuration,
        "is_premium": isPremium,
        "is_title": isTitle,
        "is_comment": isComment,
        "is_like": isLike,
        "total_view": totalView,
        "total_like": totalLike,
        "sort_order": sortOrder,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "is_buy": isBuy,
        "is_user_like": isUserLike,
      };
}
