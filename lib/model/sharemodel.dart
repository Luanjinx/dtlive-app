// To parse this JSON data, do
// final shareModel = shareModelFromJson(jsonString);

import 'dart:convert';

ShareModel shareModelFromJson(String str) =>
    ShareModel.fromJson(json.decode(str));

String shareModelToJson(ShareModel data) => json.encode(data.toJson());

class ShareModel {
  String? newPage;
  String? videoTitle;
  int? videoId;
  int? videoType;
  int? subVideoType;
  int? typeId;

  ShareModel({
    required this.newPage,
    required this.videoTitle,
    required this.videoId,
    required this.videoType,
    required this.subVideoType,
    required this.typeId,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) => ShareModel(
        newPage: json["newpage"],
        videoTitle: json["videotitle"],
        videoId: json["videoid"],
        videoType: json["videotype"],
        subVideoType: json["subvideotype"],
        typeId: json["typeid"],
      );

  Map<String, dynamic> toJson() => {
        "newpage": newPage,
        "videotitle": videoTitle,
        "videoid": videoId,
        "videotype": videoType,
        "subvideotype": subVideoType,
        "typeid": typeId,
      };
}
