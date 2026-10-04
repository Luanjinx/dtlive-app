// To parse this JSON data, do
// final commentModel = commentModelFromJson(jsonString);

import 'dart:convert';

CommentModel commentModelFromJson(String str) =>
    CommentModel.fromJson(json.decode(str));

String commentModelToJson(CommentModel data) => json.encode(data.toJson());

class CommentModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  CommentModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
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
  int? commentId;
  int? userId;
  int? videoType;
  int? subVideoType;
  int? videoId;
  String? comment;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? userName;
  String? userImage;
  int? isReply;
  int? totalReply;

  Result({
    this.id,
    this.commentId,
    this.userId,
    this.videoType,
    this.subVideoType,
    this.videoId,
    this.comment,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userImage,
    this.isReply,
    this.totalReply,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        commentId: json["comment_id"],
        userId: json["user_id"],
        videoType: json["video_type"],
        subVideoType: json["sub_video_type"],
        videoId: json["video_id"],
        comment: json["comment"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        userName: json["user_name"],
        userImage: json["user_image"],
        isReply: json["is_reply"],
        totalReply: json["total_reply"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "comment_id": commentId,
        "user_id": userId,
        "video_type": videoType,
        "sub_video_type": subVideoType,
        "video_id": videoId,
        "comment": comment,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "user_name": userName,
        "user_image": userImage,
        "is_reply": isReply,
        "total_reply": totalReply,
      };
}

enum CommentDialogEnum { comments, replies }
