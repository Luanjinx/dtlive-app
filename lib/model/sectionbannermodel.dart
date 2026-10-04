// To parse this JSON data, do
//
//     final sectionBannerModel = sectionBannerModelFromJson(jsonString);

import 'dart:convert';

SectionBannerModel sectionBannerModelFromJson(String str) =>
    SectionBannerModel.fromJson(json.decode(str));

String sectionBannerModelToJson(SectionBannerModel data) =>
    json.encode(data.toJson());

class SectionBannerModel {
  int? status;
  String? message;
  List<Result>? result;

  SectionBannerModel({this.status, this.message, this.result});

  factory SectionBannerModel.fromJson(Map<String, dynamic> json) =>
      SectionBannerModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? [],
              ),
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
  int? typeId;
  int? videoType;
  int? subVideoType;
  int? channelId;
  int? producerId;
  String? categoryId;
  String? languageId;
  String? castId;
  String? name;
  String? thumbnail;
  String? landscape;
  String? trailerType;
  String? trailerUrl;
  int? trailerStorageType;
  String? description;
  String? releaseDate;
  int? isPremium;
  int? isTitle;
  int? isComment;
  int? isLike;
  int? totalView;
  int? totalLike;
  int? isRent;
  dynamic price;
  int? rentDay;
  int? rentPriceId;
  String? androidProductPackage;
  String? iosProductPackage;
  String? webPriceId;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isBuy;
  int? rentBuy;
  int? isBookmark;
  int? totalLanguage;
  String? categoryName;
  String? videoUploadType;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  int? storageType;
  String? videoExtension;
  int? videoDuration;
  String? subtitleType;
  String? subtitleLang1;
  String? subtitle1;
  String? subtitleLang2;
  String? subtitle2;
  String? subtitleLang3;
  String? subtitle3;
  int? isDownload;

  Result({
    this.id,
    this.typeId,
    this.videoType,
    this.subVideoType,
    this.channelId,
    this.producerId,
    this.categoryId,
    this.languageId,
    this.castId,
    this.name,
    this.thumbnail,
    this.landscape,
    this.trailerType,
    this.trailerUrl,
    this.trailerStorageType,
    this.description,
    this.releaseDate,
    this.isPremium,
    this.isTitle,
    this.isComment,
    this.isLike,
    this.totalView,
    this.totalLike,
    this.isRent,
    this.price,
    this.rentDay,
    this.rentPriceId,
    this.androidProductPackage,
    this.iosProductPackage,
    this.webPriceId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isBuy,
    this.rentBuy,
    this.isBookmark,
    this.totalLanguage,
    this.categoryName,
    this.videoUploadType,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.storageType,
    this.videoExtension,
    this.videoDuration,
    this.subtitleType,
    this.subtitleLang1,
    this.subtitle1,
    this.subtitleLang2,
    this.subtitle2,
    this.subtitleLang3,
    this.subtitle3,
    this.isDownload,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    typeId: json["type_id"],
    videoType: json["video_type"],
    subVideoType: json["sub_video_type"],
    channelId: json["channel_id"],
    producerId: json["producer_id"],
    categoryId: json["category_id"],
    languageId: json["language_id"],
    castId: json["cast_id"],
    name: json["name"],
    thumbnail: json["thumbnail"],
    landscape: json["landscape"],
    trailerType: json["trailer_type"],
    trailerUrl: json["trailer_url"],
    trailerStorageType: json["trailer_storage_type"],
    description: json["description"],
    releaseDate: json["release_date"],
    isPremium: json["is_premium"],
    isTitle: json["is_title"],
    isComment: json["is_comment"],
    isLike: json["is_like"],
    totalView: json["total_view"],
    totalLike: json["total_like"],
    isRent: json["is_rent"],
    price: json["price"],
    rentDay: json["rent_day"],
    rentPriceId: json["rent_price_id"],
    androidProductPackage: json["android_product_package"],
    iosProductPackage: json["ios_product_package"],
    webPriceId: json["web_price_id"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    isBuy: json["is_buy"],
    rentBuy: json["rent_buy"],
    isBookmark: json["is_bookmark"],
    totalLanguage: json["total_language"],
    categoryName: json["category_name"],
    videoUploadType: json["video_upload_type"],
    video320: json["video_320"],
    video480: json["video_480"],
    video720: json["video_720"],
    video1080: json["video_1080"],
    storageType: json["storage_type"],
    videoExtension: json["video_extension"],
    videoDuration: json["video_duration"],
    subtitleType: json["subtitle_type"],
    subtitleLang1: json["subtitle_lang_1"],
    subtitle1: json["subtitle_1"],
    subtitleLang2: json["subtitle_lang_2"],
    subtitle2: json["subtitle_2"],
    subtitleLang3: json["subtitle_lang_3"],
    subtitle3: json["subtitle_3"],
    isDownload: json["is_download"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type_id": typeId,
    "video_type": videoType,
    "sub_video_type": subVideoType,
    "channel_id": channelId,
    "producer_id": producerId,
    "category_id": categoryId,
    "language_id": languageId,
    "cast_id": castId,
    "name": name,
    "thumbnail": thumbnail,
    "landscape": landscape,
    "trailer_type": trailerType,
    "trailer_url": trailerUrl,
    "trailer_storage_type": trailerStorageType,
    "description": description,
    "release_date": releaseDate,
    "is_premium": isPremium,
    "is_title": isTitle,
    "total_view": totalView,
    "is_rent": isRent,
    "price": price,
    "rent_day": rentDay,
    "rent_price_id": rentPriceId,
    "android_product_package": androidProductPackage,
    "ios_product_package": iosProductPackage,
    "web_price_id": webPriceId,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "is_buy": isBuy,
    "rent_buy": rentBuy,
    "is_bookmark": isBookmark,
    "total_language": totalLanguage,
    "category_name": categoryName,
    "video_upload_type": videoUploadType,
    "video_320": video320,
    "video_480": video480,
    "video_720": video720,
    "video_1080": video1080,
    "storage_type": storageType,
    "video_extension": videoExtension,
    "video_duration": videoDuration,
    "subtitle_type": subtitleType,
    "subtitle_lang_1": subtitleLang1,
    "subtitle_1": subtitle1,
    "subtitle_lang_2": subtitleLang2,
    "subtitle_2": subtitle2,
    "subtitle_lang_3": subtitleLang3,
    "subtitle_3": subtitle3,
    "is_download": isDownload,
  };
}
