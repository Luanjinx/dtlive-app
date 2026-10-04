// To parse this JSON data, do
// final shortFilmsModel = shortFilmsModelFromJson(jsonString);

import 'dart:convert';

ClipsModel shortFilmsModelFromJson(String str) =>
    ClipsModel.fromJson(json.decode(str));

String shortFilmsModelToJson(ClipsModel data) => json.encode(data.toJson());

class ClipsModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  ClipsModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory ClipsModel.fromJson(Map<String, dynamic> json) => ClipsModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
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
            ? []
            : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
        "total_rows": totalRows,
        "total_page": totalPage,
        "current_page": currentPage,
        "more_page": morePage,
      };
}

class Result {
  int? id;
  int? typeId;
  int? videoType;
  int? producerId;
  String? categoryId;
  String? languageId;
  String? castId;
  String? name;
  int? storageType;
  String? thumbnail;
  int? trailerStorageType;
  String? trailerType;
  String? trailerUrl;
  String? description;
  int? isTitle;
  int? isComment;
  int? isLike;
  int? totalView;
  int? totalLike;
  int? totalComment;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  int? isBookmark;
  int? isUserLike;
  String? categoryName;

  Result({
    this.id,
    this.typeId,
    this.videoType,
    this.producerId,
    this.categoryId,
    this.languageId,
    this.castId,
    this.name,
    this.storageType,
    this.thumbnail,
    this.trailerStorageType,
    this.trailerType,
    this.trailerUrl,
    this.description,
    this.isTitle,
    this.isComment,
    this.isLike,
    this.totalView,
    this.totalLike,
    this.totalComment,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.isBookmark,
    this.isUserLike,
    this.categoryName,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        typeId: json["type_id"],
        videoType: json["video_type"],
        producerId: json["producer_id"],
        categoryId: json["category_id"],
        languageId: json["language_id"],
        castId: json["cast_id"],
        name: json["name"],
        storageType: json["storage_type"],
        thumbnail: json["thumbnail"],
        trailerStorageType: json["trailer_storage_type"],
        trailerType: json["trailer_type"],
        trailerUrl: json["trailer_url"],
        description: json["description"],
        isTitle: json["is_title"],
        isComment: json["is_comment"],
        isLike: json["is_like"],
        totalView: json["total_view"],
        totalLike: json["total_like"],
        totalComment: json["total_comment"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        isBuy: json["is_buy"],
        isBookmark: json["is_bookmark"],
        isUserLike: json["is_user_like"],
        categoryName: json["category_name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type_id": typeId,
        "video_type": videoType,
        "producer_id": producerId,
        "category_id": categoryId,
        "language_id": languageId,
        "cast_id": castId,
        "name": name,
        "storage_type": storageType,
        "thumbnail": thumbnail,
        "trailer_storage_type": trailerStorageType,
        "trailer_type": trailerType,
        "trailer_url": trailerUrl,
        "description": description,
        "is_title": isTitle,
        "is_comment": isComment,
        "is_like": isLike,
        "total_view": totalView,
        "total_like": totalLike,
        "total_comment": totalComment,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "is_buy": isBuy,
        "is_bookmark": isBookmark,
        "is_user_like": isUserLike,
        "category_name": categoryName,
      };
}
