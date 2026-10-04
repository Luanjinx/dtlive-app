import '../model/devicesyncmodel.dart';
import '../model/successmodel.dart';
import '../players/model/subtitlemodel.dart';
import '../webservice/apiservices.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class PlayerProvider extends ChangeNotifier {
  SuccessModel successModel = SuccessModel();
  DeviceSyncModel deviceSyncModel = DeviceSyncModel();
  SuccessModel videoViewSuccessModel = SuccessModel();

  bool loading = false, isDeviceAdded = false;
  String currentSubtitle = "";
  String currentQuality = "";

  void setCurrentSubtitle(String subtitleName) {
    currentSubtitle = subtitleName;
    notifyListeners();
  }

  void setCurrentQuality(String qualityName) {
    currentQuality = qualityName;
    notifyListeners();
  }

  double _progress = 0.0;

  double get progress => _progress;

  void setDecryptProgress(double newProgress) {
    _progress = newProgress;
    notifyListeners(); // Notify listeners of the change
  }

  Future<void> addRemoveDevice(dynamic watchType) async {
    printLog("addRemoveDevice watchType :=======> $watchType");
    loading = true;
    deviceSyncModel = await ApiService().addRemoveDeviceWatching(watchType);
    printLog("addRemoveDevice message :==> ${deviceSyncModel.message}");
    if (deviceSyncModel.status == 200) {
      isDeviceAdded = true;
    } else {
      isDeviceAdded = false;
    }
    printLog("addRemoveDevice isDeviceAdded :==> $isDeviceAdded");
    loading = false;
    notifyListeners();
  }

  Future<void> addVideoView(
      dynamic videoId, videoType, subVideoType, episodeId) async {
    printLog("addVideoView videoId :=======> $videoId");
    printLog("addVideoView videoType :=====> $videoType");
    printLog("addVideoView subVideoType :==> $subVideoType");
    printLog("addVideoView episodeId :=====> $episodeId");
    videoViewSuccessModel = await ApiService()
        .videoView(videoId, videoType, subVideoType, episodeId);
    printLog("addVideoView message :==> ${videoViewSuccessModel.message}");
    notifyListeners();
  }

  Future<void> addToContinue(
      dynamic videoId, episodeId, videoType, subVideoType, stopTime) async {
    printLog("addToContinue stopTime :======> $stopTime");
    printLog("addToContinue videoType :=====> $videoType");
    printLog("addToContinue subVideoType :==> $subVideoType");
    printLog("addToContinue videoId :=======> $videoId");
    successModel = await ApiService().addContinueWatching(
        videoId, episodeId, videoType, subVideoType, stopTime);
    printLog("addToContinue message :==> ${successModel.message}");
    notifyListeners();
  }

  Future<void> removeFromContinue(
      dynamic videoId, videoType, subVideoType) async {
    printLog("removeFromContinue videoType :=====> $videoType");
    printLog("removeFromContinue subVideoType :==> $subVideoType");
    printLog("removeFromContinue videoId :=======> $videoId");
    successModel = await ApiService()
        .removeContinueWatching(videoId, videoType, subVideoType);
    printLog("removeFromContinue message :==> ${successModel.message}");
    notifyListeners();
  }

  /* Manage controls */
  Subtitles? cSubtitleList;
  Duration? subtitlesPosition;
  bool subtitleOn = true;
  bool showSeekPopup = false;
  bool isForwardSeek = false;
  BoxFit currentFit = BoxFit.contain;

  /* Volume/Brightness START */
  bool isVolMuted = false;
  double volumeLevel = 0.5;
  double lastVolumeLevel = 0.5;
  double brightnessLevel = 0.5;
  bool showVolumeBar = false;
  bool showBrightnessBar = false;
  /* Volume/Brightness END */
  String? seekPopupText;

  Future showSeekPopupTexts(String text, bool isForward) async {
    seekPopupText = text;
    isForwardSeek = isForward;
    showSeekPopup = true;
    await Future.delayed(Duration(seconds: 1), () {
      seekPopupText = null;
      showSeekPopup = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future setSubtitles(List<Subtitle> newSubtitle) async {
    cSubtitleList = Subtitles(newSubtitle);
    notifyListeners();
  }

  Future setSubtitlePosition(Duration position) async {
    subtitlesPosition = position;
    notifyListeners();
  }

  Future changeBoxFit(BoxFit newFit) async {
    currentFit = newFit;
    notifyListeners();
  }

  Future setSubtitleState(bool subtitleStatus) async {
    subtitleOn = subtitleStatus;
    notifyListeners();
  }

  void notifyProvider() {
    notifyListeners();
  }

  void clearProvider() {
    printLog("<================ clearProvider ================>");
    successModel = SuccessModel();
    deviceSyncModel = DeviceSyncModel();
    videoViewSuccessModel = SuccessModel();
    currentSubtitle = "";
    loading = false;
    isDeviceAdded = false;

    cSubtitleList = null;
    subtitlesPosition = null;
    subtitleOn = true;
    showSeekPopup = false;
    isForwardSeek = false;
    currentFit = BoxFit.contain;

    isVolMuted = false;
    volumeLevel = 0.5;
    lastVolumeLevel = 0.5;
    brightnessLevel = 0.5;
    showVolumeBar = false;
    showBrightnessBar = false;
  }
}
