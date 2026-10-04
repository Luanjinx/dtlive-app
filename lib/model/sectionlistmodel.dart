// To parse this JSON data, do
// final sectionListModel = sectionListModelFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';

SectionListModel sectionListModelFromJson(String str) =>
    SectionListModel.fromJson(json.decode(str));

String sectionListModelToJson(SectionListModel data) =>
    json.encode(data.toJson());

class SectionListModel {
  int? status;
  String? message;
  List<Result>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  SectionListModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory SectionListModel.fromJson(Map<String, dynamic> json) =>
      SectionListModel(
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
  int? sectionType;
  int? isHomeScreen;
  int? videoType;
  int? subVideoType;
  int? typeId;
  String? title;
  String? shortTitle;
  String? screenLayout;
  int? categoryId;
  int? languageId;
  int? channelId;
  String? contentIds;
  int? orderByUpload;
  int? orderByLike;
  int? orderByView;
  int? premiumVideo;
  int? rentVideo;
  int? noOfContent;
  int? viewAll;
  int? isTitle;
  int? sortable;
  int? status;
  String? createdAt;
  String? updatedAt;
  List<Datum>? data;
  ScrollController? scrollController;

  Result({
    this.id,
    this.sectionType,
    this.isHomeScreen,
    this.videoType,
    this.subVideoType,
    this.typeId,
    this.title,
    this.shortTitle,
    this.screenLayout,
    this.categoryId,
    this.languageId,
    this.channelId,
    this.contentIds,
    this.orderByUpload,
    this.orderByLike,
    this.orderByView,
    this.premiumVideo,
    this.rentVideo,
    this.noOfContent,
    this.viewAll,
    this.isTitle,
    this.sortable,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.data,
    this.scrollController,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    sectionType: json["section_type"],
    isHomeScreen: json["is_home_screen"],
    videoType: json["video_type"],
    subVideoType: json["sub_video_type"],
    typeId: json["type_id"],
    title: json["title"],
    shortTitle: json["short_title"],
    screenLayout: json["screen_layout"],
    categoryId: json["category_id"],
    languageId: json["language_id"],
    channelId: json["channel_id"],
    contentIds: json["content_ids"],
    orderByUpload: json["order_by_upload"],
    orderByLike: json["order_by_like"],
    orderByView: json["order_by_view"],
    premiumVideo: json["premium_video"],
    rentVideo: json["rent_video"],
    noOfContent: json["no_of_content"],
    viewAll: json["view_all"],
    isTitle: json["is_title"],
    sortable: json["sortable"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]?.map((x) => Datum.fromJson(x)) ?? []),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "section_type": sectionType,
    "is_home_screen": isHomeScreen,
    "video_type": videoType,
    "sub_video_type": subVideoType,
    "type_id": typeId,
    "title": title,
    "short_title": shortTitle,
    "screen_layout": screenLayout,
    "category_id": categoryId,
    "language_id": languageId,
    "channel_id": channelId,
    "content_ids": contentIds,
    "order_by_upload": orderByUpload,
    "order_by_like": orderByLike,
    "order_by_view": orderByView,
    "premium_video": premiumVideo,
    "rent_video": rentVideo,
    "no_of_content": noOfContent,
    "view_all": viewAll,
    "is_title": isTitle,
    "sortable": sortable,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "data": data == null
        ? []
        : List<dynamic>.from(data?.map((x) => x.toJson()) ?? []),
  };
}

class Datum {
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
  String? description;
  String? videoUploadType;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  String? videoExtension;
  int? videoDuration;
  String? trailerType;
  String? trailerUrl;
  String? subtitleType;
  String? subtitleLang1;
  String? subtitle1;
  String? subtitleLang2;
  String? subtitle2;
  String? subtitleLang3;
  String? subtitle3;
  String? releaseDate;
  int? isPremium;
  int? isTitle;
  int? isDownload;
  int? totalView;
  String? androidProductPackage;
  String? iosProductPackage;
  String? webPriceId;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? isRent;
  dynamic price;
  int? rentDay;
  int? rentPriceId;
  int? isBuy;
  int? rentBuy;
  int? isBookmark;
  int? stopTime;
  String? categoryName;
  String? image;
  String? portraitImg;
  String? landscapeImg;
  int? isUserDownload;
  Episode? episode;
  int? storageType;
  int? sortOrder;
  int? videoStorageType;
  int? trailerStorageType;
  int? subtitleStorageType;

  Datum({
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
    this.description,
    this.videoUploadType,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.videoExtension,
    this.videoDuration,
    this.trailerType,
    this.trailerUrl,
    this.subtitleType,
    this.subtitleLang1,
    this.subtitle1,
    this.subtitleLang2,
    this.subtitle2,
    this.subtitleLang3,
    this.subtitle3,
    this.releaseDate,
    this.isPremium,
    this.isTitle,
    this.isDownload,
    this.totalView,
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
    this.stopTime,
    this.categoryName,
    this.image,
    this.portraitImg,
    this.landscapeImg,
    this.isUserDownload,
    this.episode,
    this.storageType,
    this.sortOrder,
    this.subtitleStorageType,
    this.videoStorageType,
    this.trailerStorageType,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
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
    description: json["description"],
    videoUploadType: json["video_upload_type"],
    video320: json["video_320"],
    video480: json["video_480"],
    video720: json["video_720"],
    video1080: json["video_1080"],
    videoExtension: json["video_extension"],
    videoDuration: json["video_duration"],
    trailerType: json["trailer_type"],
    trailerUrl: json["trailer_url"],
    subtitleType: json["subtitle_type"],
    subtitleLang1: json["subtitle_lang_1"],
    subtitle1: json["subtitle_1"],
    subtitleLang2: json["subtitle_lang_2"],
    subtitle2: json["subtitle_2"],
    subtitleLang3: json["subtitle_lang_3"],
    subtitle3: json["subtitle_3"],
    releaseDate: json["release_date"],
    isPremium: json["is_premium"],
    isTitle: json["is_title"],
    isDownload: json["is_download"],
    totalView: json["total_view"],
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
    stopTime: json["stop_time"],
    categoryName: json["category_name"],
    image: json["image"],
    portraitImg: json["portrait_img"],
    landscapeImg: json["landscape_img"],
    episode: json["episode"] == null ? null : Episode.fromJson(json["episode"]),
    storageType: json["storage_type"],
    sortOrder: json["sort_order"],
    trailerStorageType: json["trailer_storage_type"],
    videoStorageType: json["video_storage_type"],
    subtitleStorageType: json["subtitle_storage_type"],
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
    "description": description,
    "video_upload_type": videoUploadType,
    "video_320": video320,
    "video_480": video480,
    "video_720": video720,
    "video_1080": video1080,
    "video_extension": videoExtension,
    "video_duration": videoDuration,
    "trailer_type": trailerType,
    "trailer_url": trailerUrl,
    "subtitle_type": subtitleType,
    "subtitle_lang_1": subtitleLang1,
    "subtitle_1": subtitle1,
    "subtitle_lang_2": subtitleLang2,
    "subtitle_2": subtitle2,
    "subtitle_lang_3": subtitleLang3,
    "subtitle_3": subtitle3,
    "release_date": releaseDate,
    "is_premium": isPremium,
    "is_title": isTitle,
    "is_download": isDownload,
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
    "stop_time": stopTime,
    "category_name": categoryName,
    "image": image,
    "portrait_img": portraitImg,
    "landscape_img": landscapeImg,
    "storage_type": storageType,
    "episode": episode == null ? {} : episode?.toJson(),
    "sort_order": sortOrder,
    "trailer_storage_type": trailerStorageType,
    "video_storage_type": videoStorageType,
    "subtitle_storage_type": subtitleStorageType,
  };
}

class Episode {
  int? id;
  int? showId;
  int? seasonId;
  String? name;
  int? storageType;
  String? thumbnail;
  String? landscape;
  String? description;
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
  int? isTitle;
  int? isDownload;
  int? totalView;
  int? sortable;
  int? status;
  String? createdAt;
  String? updatedAt;

  Episode({
    this.id,
    this.showId,
    this.seasonId,
    this.name,
    this.storageType,
    this.thumbnail,
    this.landscape,
    this.description,
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
    this.isTitle,
    this.isDownload,
    this.totalView,
    this.sortable,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json["id"],
    showId: json["show_id"],
    seasonId: json["season_id"],
    name: json["name"],
    storageType: json["storage_type"],
    thumbnail: json["thumbnail"],
    landscape: json["landscape"],
    description: json["description"],
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
    isTitle: json["is_title"],
    isDownload: json["is_download"],
    totalView: json["total_view"],
    sortable: json["sortable"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "show_id": showId,
    "season_id": seasonId,
    "name": name,
    "storage_type": storageType,
    "thumbnail": thumbnail,
    "landscape": landscape,
    "description": description,
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
    "is_title": isTitle,
    "is_download": isDownload,
    "total_view": totalView,
    "sortable": sortable,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
