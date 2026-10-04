import 'package:hive/hive.dart';

part 'download_item.g.dart';

@HiveType(typeId: 0)
class DownloadItem extends HiveObject {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final String? securityKey;
  @HiveField(2)
  final String? securityIVKey;
  @HiveField(3)
  final String? name;
  @HiveField(4)
  final String? description;
  @HiveField(5)
  final String? videoUrl;
  @HiveField(6)
  final String? savedDir;
  @HiveField(7)
  final String? savedFile;
  @HiveField(8)
  final int? videoType;
  @HiveField(9)
  final int? subVideoType;
  @HiveField(10)
  final int? typeId;
  @HiveField(11)
  final int? isPremium;
  @HiveField(12)
  final int? isBuy;
  @HiveField(13)
  final int? isRent;
  @HiveField(14)
  final int? rentBuy;
  @HiveField(15)
  final int? rentPrice;
  @HiveField(16)
  final int? isDownload;
  @HiveField(17)
  final int? videoDuration;
  @HiveField(18)
  final int? stopTime;
  @HiveField(19)
  final String? videoUploadType;
  @HiveField(20)
  final String? trailerUploadType;
  @HiveField(21)
  final String? trailerUrl;
  @HiveField(22)
  final String? releaseYear;
  @HiveField(23)
  final String? landscapeImg;
  @HiveField(24)
  final String? thumbnailImg;
  @HiveField(25)
  List<SessionItem>? session;

  DownloadItem({
    this.id,
    this.securityKey,
    this.securityIVKey,
    this.name,
    this.description,
    this.videoUrl,
    this.savedDir,
    this.savedFile,
    this.videoType,
    this.subVideoType,
    this.typeId,
    this.isPremium,
    this.isBuy,
    this.isRent,
    this.rentBuy,
    this.rentPrice,
    this.isDownload,
    this.videoDuration,
    this.stopTime,
    this.videoUploadType,
    this.trailerUploadType,
    this.trailerUrl,
    this.releaseYear,
    this.landscapeImg,
    this.thumbnailImg,
    this.session,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json["id"],
        securityKey: json["securityKey"],
        securityIVKey: json["securityIVKey"],
        name: json["name"],
        description: json["description"],
        videoUrl: json["videoUrl"],
        savedDir: json["savedDir"],
        savedFile: json["savedFile"],
        videoType: json["videoType"],
        subVideoType: json["subVideoType"],
        typeId: json["typeId"],
        isPremium: json["isPremium"],
        isBuy: json["isBuy"],
        isRent: json["isRent"],
        rentBuy: json["rentBuy"],
        rentPrice: json["rentPrice"],
        isDownload: json["isDownload"],
        videoDuration: json["videoDuration"],
        stopTime: json["stopTime"],
        videoUploadType: json["videoUploadType"],
        trailerUploadType: json["trailerUploadType"],
        trailerUrl: json["trailerUrl"],
        releaseYear: json["releaseYear"],
        landscapeImg: json["landscapeImg"],
        thumbnailImg: json["thumbnailImg"],
        session: List<SessionItem>.from(
            json["session"].map((x) => SessionItem.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "securityKey": securityKey,
        "securityIVKey": securityIVKey,
        "description": description,
        "videoUrl": videoUrl,
        "savedDir": savedDir,
        "savedFile": savedFile,
        "videoType": videoType,
        "subVideoType": subVideoType,
        "typeId": typeId,
        "isPremium": isPremium,
        "isBuy": isBuy,
        "isRent": isRent,
        "rentBuy": rentBuy,
        "rentPrice": rentPrice,
        "isDownload": isDownload,
        "videoDuration": videoDuration,
        "stopTime": stopTime,
        "videoUploadType": videoUploadType,
        "trailerUploadType": trailerUploadType,
        "trailerUrl": trailerUrl,
        "releaseYear": releaseYear,
        "landscapeImg": landscapeImg,
        "thumbnailImg": thumbnailImg,
        "session": List<dynamic>.from(session?.map((x) => x.toJson()) ?? []),
      };
}

@HiveType(typeId: 1)
class SessionItem {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final int? showId;
  @HiveField(2)
  final int? sessionPosition;
  @HiveField(3)
  final String? name;
  @HiveField(4)
  final int? status;
  @HiveField(5)
  final int? isDownload;
  @HiveField(6)
  List<EpisodeItem>? episode;

  SessionItem({
    this.id,
    this.showId,
    this.sessionPosition,
    this.name,
    this.status,
    this.isDownload,
    this.episode,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) => SessionItem(
        id: json["id"],
        showId: json["show_id"],
        sessionPosition: json["sessionPosition"],
        name: json["name"],
        status: json["status"],
        isDownload: json["is_download"],
        episode: List<EpisodeItem>.from(
            json["episode"]?.map((x) => EpisodeItem.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "show_id": showId,
        "sessionPosition": sessionPosition,
        "name": name,
        "status": status,
        "is_download": isDownload,
        "episode": List<dynamic>.from(episode?.map((x) => x.toJson()) ?? []),
      };
}

@HiveType(typeId: 2)
class EpisodeItem {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final int? showId;
  @HiveField(2)
  final int? sessionId;
  @HiveField(3)
  final String? thumbnail;
  @HiveField(4)
  final String? landscape;
  @HiveField(5)
  final String? videoUploadType;
  @HiveField(6)
  final dynamic videoType;
  @HiveField(7)
  final dynamic subVideoType;
  @HiveField(8)
  final String? videoExtension;
  @HiveField(9)
  final int? videoDuration;
  @HiveField(10)
  final int? isPremium;
  @HiveField(11)
  final String? description;
  @HiveField(12)
  final int? status;
  @HiveField(13)
  final String? video320;
  @HiveField(14)
  final String? video480;
  @HiveField(15)
  final String? video720;
  @HiveField(16)
  final String? video1080;
  @HiveField(17)
  final String? securityKey;
  @HiveField(18)
  final String? securityIVKey;
  @HiveField(19)
  final String? savedDir;
  @HiveField(20)
  final String? savedFile;
  @HiveField(21)
  final String? subtitleType;
  @HiveField(22)
  final String? subtitleLang1;
  @HiveField(23)
  final String? subtitleLang2;
  @HiveField(24)
  final String? subtitleLang3;
  @HiveField(25)
  final String? subtitle1;
  @HiveField(26)
  final String? subtitle2;
  @HiveField(27)
  final String? subtitle3;
  @HiveField(28)
  final int? isDownloaded;
  @HiveField(29)
  final int? isBookmark;
  @HiveField(30)
  final int? rentBuy;
  @HiveField(31)
  final int? isRent;
  @HiveField(32)
  final int? rentPrice;
  @HiveField(33)
  final int? isBuy;
  @HiveField(34)
  final String? categoryName;
  @HiveField(35)
  final int? stopTime;
  @HiveField(36)
  final String? name;
  @HiveField(37)
  final int? typeId;

  EpisodeItem({
    this.id,
    this.showId,
    this.sessionId,
    this.thumbnail,
    this.landscape,
    this.videoUploadType,
    this.typeId,
    this.videoType,
    this.subVideoType,
    this.videoExtension,
    this.videoDuration,
    this.isPremium,
    this.name,
    this.description,
    this.status,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.securityKey,
    this.securityIVKey,
    this.savedDir,
    this.savedFile,
    this.subtitleType,
    this.subtitleLang1,
    this.subtitleLang2,
    this.subtitleLang3,
    this.subtitle1,
    this.subtitle2,
    this.subtitle3,
    this.isDownloaded,
    this.isBookmark,
    this.rentBuy,
    this.isRent,
    this.rentPrice,
    this.isBuy,
    this.categoryName,
    this.stopTime,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) => EpisodeItem(
        id: json["id"],
        showId: json["show_id"],
        sessionId: json["session_id"],
        thumbnail: json["thumbnail"],
        landscape: json["landscape"],
        videoUploadType: json["video_upload_type"],
        typeId: json["type_id"],
        videoType: json["video_type"],
        subVideoType: json["sub_video_type"],
        videoExtension: json["video_extension"],
        videoDuration: json["video_duration"],
        isPremium: json["is_premium"],
        name: json["name"],
        description: json["description"],
        status: json["status"],
        video320: json["video_320"],
        video480: json["video_480"],
        video720: json["video_720"],
        video1080: json["video_1080"],
        securityKey: json["securityKey"],
        securityIVKey: json["securityIVKey"],
        savedDir: json["savedDir"],
        savedFile: json["savedFile"],
        subtitleType: json["subtitle_type"],
        subtitleLang1: json["subtitle_lang_1"],
        subtitleLang2: json["subtitle_lang_2"],
        subtitleLang3: json["subtitle_lang_3"],
        subtitle1: json["subtitle_1"],
        subtitle2: json["subtitle_2"],
        subtitle3: json["subtitle_3"],
        isDownloaded: json["is_download"],
        isBookmark: json["is_bookmark"],
        rentBuy: json["rent_buy"],
        isRent: json["is_rent"],
        rentPrice: json["rent_price"],
        isBuy: json["is_buy"],
        categoryName: json["category_name"],
        stopTime: json["stop_time"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "show_id": showId,
        "session_id": sessionId,
        "thumbnail": thumbnail,
        "landscape": landscape,
        "video_upload_type": videoUploadType,
        "type_id": typeId,
        "video_type": videoType,
        "sub_video_type": subVideoType,
        "video_extension": videoExtension,
        "video_duration": videoDuration,
        "is_premium": isPremium,
        "name": name,
        "description": description,
        "status": status,
        "video_320": video320,
        "video_480": video480,
        "video_720": video720,
        "video_1080": video1080,
        "securityKey": securityKey,
        "securityIVKey": securityIVKey,
        "savedDir": savedDir,
        "savedFile": savedFile,
        "subtitle_type": subtitleType,
        "subtitle_lang_1": subtitleLang1,
        "subtitle_lang_2": subtitleLang2,
        "subtitle_lang_3": subtitleLang3,
        "subtitle_1": subtitle1,
        "subtitle_2": subtitle2,
        "subtitle_3": subtitle3,
        "is_download": isDownloaded,
        "is_bookmark": isBookmark,
        "rent_buy": rentBuy,
        "is_rent": isRent,
        "rent_price": rentPrice,
        "is_buy": isBuy,
        "category_name": categoryName,
        "stop_time": stopTime,
      };
}
