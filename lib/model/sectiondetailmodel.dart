// To parse this JSON data, do
// final sectionDetailModel = sectionDetailModelFromJson(jsonString);

import 'dart:convert';

SectionDetailModel sectionDetailModelFromJson(String str) =>
    SectionDetailModel.fromJson(json.decode(str));

String sectionDetailModelToJson(SectionDetailModel data) =>
    json.encode(data.toJson());

class SectionDetailModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  SectionDetailModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory SectionDetailModel.fromJson(Map<String, dynamic> json) =>
      SectionDetailModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? [],
              ),
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
  int? channelId;
  int? producerId;
  String? categoryId;
  String? languageId;
  String? castId;
  String? name;
  int? storageType;
  String? thumbnail;
  String? landscape;
  int? trailerStorageType;
  String? trailerType;
  String? trailerUrl;
  String? description;
  String? releaseDate;
  int? isTitle;
  int? isComment;
  int? isLike;
  int? isRent;
  dynamic price;
  int? rentDay;
  int? totalView;
  int? totalLike;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? rentPriceId;
  String? androidProductPackage;
  String? iosProductPackage;
  String? webPriceId;
  int? isBuy;
  int? rentBuy;
  String? rentExpiryDate;
  int? isBookmark;
  int? subVideoType;
  int? stopTime;
  int? videoStorageType;
  String? videoUploadType;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  String? videoExtension;
  int? videoDuration;
  int? subtitleStorageType;
  String? subtitleType;
  String? subtitleLang1;
  String? subtitle1;
  String? subtitleLang2;
  String? subtitle2;
  String? subtitleLang3;
  String? subtitle3;
  int? isPremium;
  int? isDownload;
  String? portraitImg;
  String? landscapeImg;
  String? image;
  int? sortOrder;

  Result({
    this.id,
    this.typeId,
    this.videoType,
    this.channelId,
    this.producerId,
    this.categoryId,
    this.languageId,
    this.castId,
    this.name,
    this.storageType,
    this.thumbnail,
    this.landscape,
    this.trailerStorageType,
    this.trailerType,
    this.trailerUrl,
    this.description,
    this.releaseDate,
    this.isTitle,
    this.isComment,
    this.isLike,
    this.isRent,
    this.price,
    this.rentDay,
    this.totalView,
    this.totalLike,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.rentPriceId,
    this.androidProductPackage,
    this.iosProductPackage,
    this.webPriceId,
    this.isBuy,
    this.rentBuy,
    this.rentExpiryDate,
    this.isBookmark,
    this.subVideoType,
    this.stopTime,
    this.videoStorageType,
    this.videoUploadType,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.videoExtension,
    this.videoDuration,
    this.subtitleStorageType,
    this.subtitleType,
    this.subtitleLang1,
    this.subtitle1,
    this.subtitleLang2,
    this.subtitle2,
    this.subtitleLang3,
    this.subtitle3,
    this.isPremium,
    this.isDownload,
    this.portraitImg,
    this.landscapeImg,
    this.image,
    this.sortOrder,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    typeId: json["type_id"],
    videoType: json["video_type"],
    channelId: json["channel_id"],
    producerId: json["producer_id"],
    categoryId: json["category_id"],
    languageId: json["language_id"],
    castId: json["cast_id"],
    name: json["name"],
    storageType: json["storage_type"],
    thumbnail: json["thumbnail"],
    landscape: json["landscape"],
    trailerStorageType: json["trailer_storage_type"],
    trailerType: json["trailer_type"],
    trailerUrl: json["trailer_url"],
    description: json["description"],
    releaseDate: json["release_date"],
    isTitle: json["is_title"],
    isComment: json["is_comment"],
    isLike: json["is_like"],
    isRent: json["is_rent"],
    price: json["price"],
    rentDay: json["rent_day"],
    totalView: json["total_view"],
    totalLike: json["total_like"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    rentPriceId: json["rent_price_id"],
    androidProductPackage: json["android_product_package"],
    iosProductPackage: json["ios_product_package"],
    webPriceId: json["web_price_id"],
    isBuy: json["is_buy"],
    rentBuy: json["rent_buy"],
    rentExpiryDate: json["rent_expiry_date"],
    isBookmark: json["is_bookmark"],
    subVideoType: json["sub_video_type"],
    stopTime: json["stop_time"],
    videoStorageType: json["video_storage_type"],
    videoUploadType: json["video_upload_type"],
    video320: json["video_320"],
    video480: json["video_480"],
    video720: json["video_720"],
    video1080: json["video_1080"],
    videoExtension: json["video_extension"],
    videoDuration: json["video_duration"],
    subtitleStorageType: json["subtitle_storage_type"],
    subtitleType: json["subtitle_type"],
    subtitleLang1: json["subtitle_lang_1"],
    subtitle1: json["subtitle_1"],
    subtitleLang2: json["subtitle_lang_2"],
    subtitle2: json["subtitle_2"],
    subtitleLang3: json["subtitle_lang_3"],
    subtitle3: json["subtitle_3"],
    isPremium: json["is_premium"],
    isDownload: json["is_download"],
    portraitImg: json["portrait_img"],
    landscapeImg: json["landscape_img"],
    image: json["image"],
    sortOrder: json["sort_order"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type_id": typeId,
    "video_type": videoType,
    "channel_id": channelId,
    "producer_id": producerId,
    "category_id": categoryId,
    "language_id": languageId,
    "cast_id": castId,
    "name": name,
    "storage_type": storageType,
    "thumbnail": thumbnail,
    "landscape": landscape,
    "trailer_storage_type": trailerStorageType,
    "trailer_type": trailerType,
    "trailer_url": trailerUrl,
    "description": description,
    "release_date": releaseDate,
    "is_title": isTitle,
    "is_comment": isComment,
    "is_like": isLike,
    "is_rent": isRent,
    "price": price,
    "rent_day": rentDay,
    "total_view": totalView,
    "total_like": totalLike,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "rent_price_id": rentPriceId,
    "android_product_package": androidProductPackage,
    "ios_product_package": iosProductPackage,
    "web_price_id": webPriceId,
    "is_buy": isBuy,
    "rent_buy": rentBuy,
    "rent_expiry_date": rentExpiryDate,
    "is_bookmark": isBookmark,
    "sub_video_type": subVideoType,
    "stop_time": stopTime,
    "video_storage_type": videoStorageType,
    "video_upload_type": videoUploadType,
    "video_320": video320,
    "video_480": video480,
    "video_720": video720,
    "video_1080": video1080,
    "video_extension": videoExtension,
    "video_duration": videoDuration,
    "subtitle_storage_type": subtitleStorageType,
    "subtitle_type": subtitleType,
    "subtitle_lang_1": subtitleLang1,
    "subtitle_1": subtitle1,
    "subtitle_lang_2": subtitleLang2,
    "subtitle_2": subtitle2,
    "subtitle_lang_3": subtitleLang3,
    "subtitle_3": subtitle3,
    "is_premium": isPremium,
    "is_download": isDownload,
    "portrait_img": portraitImg,
    "landscape_img": landscapeImg,
    "image": image,
    "sort_order": sortOrder,
  };
}
