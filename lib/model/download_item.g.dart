// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadItemAdapter extends TypeAdapter<DownloadItem> {
  @override
  final int typeId = 0;

  @override
  DownloadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadItem(
      id: fields[0] as int?,
      securityKey: fields[1] as String?,
      securityIVKey: fields[2] as String?,
      name: fields[3] as String?,
      description: fields[4] as String?,
      videoUrl: fields[5] as String?,
      savedDir: fields[6] as String?,
      savedFile: fields[7] as String?,
      videoType: fields[8] as int?,
      subVideoType: fields[9] as int?,
      typeId: fields[10] as int?,
      isPremium: fields[11] as int?,
      isBuy: fields[12] as int?,
      isRent: fields[13] as int?,
      rentBuy: fields[14] as int?,
      rentPrice: fields[15] as int?,
      isDownload: fields[16] as int?,
      videoDuration: fields[17] as int?,
      stopTime: fields[18] as int?,
      videoUploadType: fields[19] as String?,
      trailerUploadType: fields[20] as String?,
      trailerUrl: fields[21] as String?,
      releaseYear: fields[22] as String?,
      landscapeImg: fields[23] as String?,
      thumbnailImg: fields[24] as String?,
      session: (fields[25] as List?)?.cast<SessionItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadItem obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.securityKey)
      ..writeByte(2)
      ..write(obj.securityIVKey)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.videoUrl)
      ..writeByte(6)
      ..write(obj.savedDir)
      ..writeByte(7)
      ..write(obj.savedFile)
      ..writeByte(8)
      ..write(obj.videoType)
      ..writeByte(9)
      ..write(obj.subVideoType)
      ..writeByte(10)
      ..write(obj.typeId)
      ..writeByte(11)
      ..write(obj.isPremium)
      ..writeByte(12)
      ..write(obj.isBuy)
      ..writeByte(13)
      ..write(obj.isRent)
      ..writeByte(14)
      ..write(obj.rentBuy)
      ..writeByte(15)
      ..write(obj.rentPrice)
      ..writeByte(16)
      ..write(obj.isDownload)
      ..writeByte(17)
      ..write(obj.videoDuration)
      ..writeByte(18)
      ..write(obj.stopTime)
      ..writeByte(19)
      ..write(obj.videoUploadType)
      ..writeByte(20)
      ..write(obj.trailerUploadType)
      ..writeByte(21)
      ..write(obj.trailerUrl)
      ..writeByte(22)
      ..write(obj.releaseYear)
      ..writeByte(23)
      ..write(obj.landscapeImg)
      ..writeByte(24)
      ..write(obj.thumbnailImg)
      ..writeByte(25)
      ..write(obj.session);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionItemAdapter extends TypeAdapter<SessionItem> {
  @override
  final int typeId = 1;

  @override
  SessionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionItem(
      id: fields[0] as int?,
      showId: fields[1] as int?,
      sessionPosition: fields[2] as int?,
      name: fields[3] as String?,
      status: fields[4] as int?,
      isDownload: fields[5] as int?,
      episode: (fields[6] as List?)?.cast<EpisodeItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, SessionItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.showId)
      ..writeByte(2)
      ..write(obj.sessionPosition)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.isDownload)
      ..writeByte(6)
      ..write(obj.episode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EpisodeItemAdapter extends TypeAdapter<EpisodeItem> {
  @override
  final int typeId = 2;

  @override
  EpisodeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeItem(
      id: fields[0] as int?,
      showId: fields[1] as int?,
      sessionId: fields[2] as int?,
      thumbnail: fields[3] as String?,
      landscape: fields[4] as String?,
      videoUploadType: fields[5] as String?,
      typeId: fields[37] as int?,
      videoType: fields[6] as dynamic,
      subVideoType: fields[7] as dynamic,
      videoExtension: fields[8] as String?,
      videoDuration: fields[9] as int?,
      isPremium: fields[10] as int?,
      name: fields[36] as String?,
      description: fields[11] as String?,
      status: fields[12] as int?,
      video320: fields[13] as String?,
      video480: fields[14] as String?,
      video720: fields[15] as String?,
      video1080: fields[16] as String?,
      securityKey: fields[17] as String?,
      securityIVKey: fields[18] as String?,
      savedDir: fields[19] as String?,
      savedFile: fields[20] as String?,
      subtitleType: fields[21] as String?,
      subtitleLang1: fields[22] as String?,
      subtitleLang2: fields[23] as String?,
      subtitleLang3: fields[24] as String?,
      subtitle1: fields[25] as String?,
      subtitle2: fields[26] as String?,
      subtitle3: fields[27] as String?,
      isDownloaded: fields[28] as int?,
      isBookmark: fields[29] as int?,
      rentBuy: fields[30] as int?,
      isRent: fields[31] as int?,
      rentPrice: fields[32] as int?,
      isBuy: fields[33] as int?,
      categoryName: fields[34] as String?,
      stopTime: fields[35] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeItem obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.showId)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.thumbnail)
      ..writeByte(4)
      ..write(obj.landscape)
      ..writeByte(5)
      ..write(obj.videoUploadType)
      ..writeByte(6)
      ..write(obj.videoType)
      ..writeByte(7)
      ..write(obj.subVideoType)
      ..writeByte(8)
      ..write(obj.videoExtension)
      ..writeByte(9)
      ..write(obj.videoDuration)
      ..writeByte(10)
      ..write(obj.isPremium)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.video320)
      ..writeByte(14)
      ..write(obj.video480)
      ..writeByte(15)
      ..write(obj.video720)
      ..writeByte(16)
      ..write(obj.video1080)
      ..writeByte(17)
      ..write(obj.securityKey)
      ..writeByte(18)
      ..write(obj.securityIVKey)
      ..writeByte(19)
      ..write(obj.savedDir)
      ..writeByte(20)
      ..write(obj.savedFile)
      ..writeByte(21)
      ..write(obj.subtitleType)
      ..writeByte(22)
      ..write(obj.subtitleLang1)
      ..writeByte(23)
      ..write(obj.subtitleLang2)
      ..writeByte(24)
      ..write(obj.subtitleLang3)
      ..writeByte(25)
      ..write(obj.subtitle1)
      ..writeByte(26)
      ..write(obj.subtitle2)
      ..writeByte(27)
      ..write(obj.subtitle3)
      ..writeByte(28)
      ..write(obj.isDownloaded)
      ..writeByte(29)
      ..write(obj.isBookmark)
      ..writeByte(30)
      ..write(obj.rentBuy)
      ..writeByte(31)
      ..write(obj.isRent)
      ..writeByte(32)
      ..write(obj.rentPrice)
      ..writeByte(33)
      ..write(obj.isBuy)
      ..writeByte(34)
      ..write(obj.categoryName)
      ..writeByte(35)
      ..write(obj.stopTime)
      ..writeByte(36)
      ..write(obj.name)
      ..writeByte(37)
      ..write(obj.typeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
