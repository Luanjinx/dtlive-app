import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/commentmodel.dart' as comments;
import '../model/contentdetailmodel.dart' as details;
import '../model/clipepisodesmodel.dart' as shortsepisode;
import '../model/clipsmodel.dart' as shorts;
import '../model/successmodel.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';

class ClipsProvider extends ChangeNotifier {
  shorts.ClipsModel shortFilmsModel = shorts.ClipsModel();
  shortsepisode.ClipEpisodesModel shortFilmEpisodeModel =
      shortsepisode.ClipEpisodesModel();
  details.ContentDetailModel contentDetailModel = details.ContentDetailModel();
  comments.CommentModel commentModel = comments.CommentModel();
  comments.CommentModel commentReplyModel = comments.CommentModel();
  SuccessModel successModel = SuccessModel();

  List<shorts.Result>? shortFilmsList = [];
  List<comments.Result>? commentList = [];
  List<comments.Result>? commentRepliesList = [];

  bool loading = false,
      loadingComment = false,
      loadingReply = false,
      loadingEpi = false,
      isDialogOpen = false,
      sending = false,
      wantToEdit = false,
      sendingEdited = false;
  int commentPos = -1;
  comments.CommentDialogEnum currentDialogPage =
      comments.CommentDialogEnum.comments;
  int? selectedCommentIndex;

  /* For All Shorts */
  int? _currentClickShortsId;

  /* For Season wise Short's episodes */
  int? _currentSeasonId, _currentShortsId;

  /* For Short's Details */
  int? _currentTypeId;
  int? _currentVideoType;
  int? _currentVideoId;
  int? _currentSubVideoType;

  int seasonPos = 0;

  /* Post Pagination */
  bool loadMore = false;
  int? totalRows, totalPage, currentPage;
  bool? isMorePage;

  /* Comment Pagination */
  bool loadCommentMore = false;
  int? totalCommentRows, totalCommentPage, currentCommentPage;
  bool? isCommentMorePage;

  /* Reply Comment Pagination */
  bool loadReplyMore = false;
  int? totalReplyRows, totalReplyPage, currentReplyPage;
  bool? isReplyMorePage;

  bool get isLoading => loading;
  bool get isEpiLoading => loadingEpi;

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  /* ShortFilms Data START ************* */
  Future<void> getAllShorts(
    dynamic shortsId,
    pageNo, {
    bool forceRefresh = false,
  }) async {
    printLog("getAllShorts userID :=====> ${Constant.userID}");
    printLog("getAllShorts shortsId :=1=> $shortsId");
    printLog("getAllShorts pageNo :=====> $pageNo");

    // Skip reloading if same video request
    if (!forceRefresh &&
        _currentClickShortsId == shortsId &&
        currentPage == pageNo) {
      printLog("Skipping reload, same getAllShorts requested.");
      loading = false;
      notifyListeners();
      return;
    }

    // Update current params
    _currentClickShortsId = shortsId;

    loading = true;
    if (pageNo == 1) notifyListeners();
    try {
      shortFilmsModel = await ApiService().getShortsList(
        (pageNo == 1) ? shortsId : 0,
        pageNo,
      );

      if (shortFilmsModel.status == 200) {
        setPagination(
          shortFilmsModel.totalRows,
          shortFilmsModel.totalPage,
          shortFilmsModel.currentPage,
          shortFilmsModel.morePage,
        );
        if (shortFilmsModel.result != null &&
            (shortFilmsModel.result?.length ?? 0) > 0) {
          printLog(
            "getAllShorts shortsId :=2=> ${shortFilmsModel.result?[0].id}",
          );
          if (pageNo == 1) {
            // Reset for fresh load
            shortFilmsList?.clear();
            shortFilmsList = [];
          }
          // Add results
          shortFilmsList?.addAll(shortFilmsModel.result ?? []);

          final Map<String, shorts.Result> postMap = {};
          shortFilmsList?.forEach((item) {
            final key = '${item.id}-${item.typeId}-${item.videoType}';
            postMap[key] = item;
          });
          shortFilmsList = postMap.values.toList();

          if (pageNo == 1 && shortsId != null && shortsId != 0) {
            final idx = shortFilmsList?.indexWhere(
              (item) => item.id == shortsId,
            );
            if (idx != null && idx >= 0) {
              final selectedItem = shortFilmsList!.removeAt(idx);
              shortFilmsList?.insert(0, selectedItem);
            }
          }
          printLog("getAllShorts shortsId :=3=> ${shortFilmsList?[0].id}");

          setLoadMore(false);
          printLog("getAllShorts length :===> ${shortFilmsList?.length}");
        }
        printLog("getAllShorts status :===> ${shortFilmsModel.status}");
        printLog("getAllShorts message :==> ${shortFilmsModel.message}");
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setLoadMore(bool loadMore) {
    printLog("setLoadMore loadMore :=> $loadMore");
    this.loadMore = loadMore;
    notifyListeners();
  }

  void setPagination(
    int? totalRows,
    int? totalPage,
    int? currentPage,
    bool? morePage,
  ) {
    printLog("setPagination currentPage :==> $currentPage");
    printLog("setPagination totalRows :====> $totalRows");
    printLog("setPagination totalPage :====> $totalPage");
    printLog("setPagination morePage :=====> $morePage");
    this.currentPage = currentPage;
    this.totalRows = totalRows;
    this.totalPage = totalPage;
    isMorePage = morePage;
    notifyListeners();
  }
  /* *************** ShortFilms Data END */

  /* ShortFilms Details START ************* */
  Future<void> getShortsDetails(
    dynamic typeId,
    videoType,
    videoId,
    subVideoType, {
    bool forceRefresh = false,
  }) async {
    printLog("getShortsDetails typeId :========> $typeId");
    printLog("getShortsDetails videoType :=====> $videoType");
    printLog("getShortsDetails videoId :=======> $videoId");
    printLog("getShortsDetails subVideoType :==> $subVideoType");
    // Skip reloading if same video request
    if (!forceRefresh &&
        _currentTypeId == typeId &&
        _currentVideoType == videoType &&
        _currentVideoId == videoId &&
        _currentSubVideoType == subVideoType) {
      printLog("Skipping reload, same video details requested.");
      loadingEpi = false;
      notifyListeners();
      return;
    }

    // Update current params
    _currentTypeId = typeId;
    _currentVideoType = videoType;
    _currentVideoId = videoId;
    _currentSubVideoType = subVideoType;

    loadingEpi = true;
    notifyListeners();
    try {
      contentDetailModel = await ApiService().contentDetails(
        typeId,
        videoType,
        videoId,
        subVideoType,
      );
      printLog("getContentDetails status :===> ${contentDetailModel.status}");
      printLog("getContentDetails message :==> ${contentDetailModel.message}");
    } finally {
      loadingEpi = false;
      notifyListeners();
    }
  }

  Future<void> setSeason(int position) async {
    printLog("setSeason ===> $position");
    seasonPos = position;
    notifyListeners();
  }
  /* *************** ShortFilms Details END */

  /* ShortFilms Episode Data START ************* */
  void setEpiLoading(bool isLoading) {
    loadingEpi = isLoading;
    notifyListeners();
  }

  Future<void> getEpisodesBySeason(
    dynamic shortsId,
    seasonId,
    pageNo, {
    bool forceRefresh = false,
  }) async {
    printLog("getEpisodesBySeason userID :=====> ${Constant.userID}");
    printLog("getEpisodesBySeason shortsId :===> $shortsId");
    printLog("getEpisodesBySeason seasonId :===> $seasonId");
    printLog("getEpisodesBySeason pageNo :=====> $pageNo");

    // Skip reloading if same video request
    if (!forceRefresh &&
        _currentSeasonId == seasonId &&
        _currentShortsId == shortsId &&
        currentPage == pageNo) {
      printLog("Skipping reload, same video details requested.");
      loadingEpi = false;
      notifyListeners();
      return;
    }

    // Update current params
    _currentSeasonId = seasonId;
    _currentShortsId = shortsId;

    loadingEpi = true;
    notifyListeners();

    try {
      shortFilmEpisodeModel = await ApiService().shortsEpisodeBySeason(
        seasonId,
        shortsId,
        pageNo,
      );
      printLog(
        "getEpisodesBySeason status :===> ${shortFilmEpisodeModel.status}",
      );
      printLog(
        "getEpisodesBySeason message :==> ${shortFilmEpisodeModel.message}",
      );
      printLog(
        "getEpisodesBySeason length :===> ${shortFilmEpisodeModel.result?.length}",
      );
    } finally {
      loadingEpi = false;
      notifyListeners();
    }
  }
  /* *************** ShortFilms Episode Data END */

  /* ********* Like/Dislike START ********* */
  Future<void> setLikeDislike(
    BuildContext context, {
    required position,
    required subVideoType,
    required videoType,
    required videoId,
  }) async {
    if (kIsWeb) {
      if ((contentDetailModel.result?[0].isUserLike ?? 0) == 0) {
        contentDetailModel.result?[0].isUserLike = 1;
        contentDetailModel.result?[0].totalLike =
            (contentDetailModel.result?[0].totalLike ?? 0) + 1;
      } else {
        contentDetailModel.result?[0].isUserLike = 0;
        if ((contentDetailModel.result?[0].totalLike ?? 0) > 0) {
          contentDetailModel.result?[0].totalLike =
              (contentDetailModel.result?[0].totalLike ?? 0) - 1;
        }
      }
    } else {
      if ((shortFilmsModel.result?[position].isUserLike ?? 0) == 0) {
        shortFilmsModel.result?[position].isUserLike = 1;
        shortFilmsModel.result?[position].totalLike =
            (shortFilmsModel.result?[position].totalLike ?? 0) + 1;
      } else {
        shortFilmsModel.result?[position].isUserLike = 0;
        if ((shortFilmsModel.result?[position].totalLike ?? 0) > 0) {
          shortFilmsModel.result?[position].totalLike =
              (shortFilmsModel.result?[position].totalLike ?? 0) - 1;
        }
      }
    }
    notifyListeners();
    addRemoveLike(subVideoType, videoType, videoId);
  }

  Future<void> addRemoveLike(dynamic subVideoType, videoType, videoId) async {
    printLog("addRemoveLike subVideoType :==> $subVideoType");
    printLog("addRemoveLike videoType :=====> $videoType");
    printLog("addRemoveLike videoId :=======> $videoId");
    successModel = await ApiService().addRemoveLike(
      subVideoType,
      videoType,
      videoId,
    );
    printLog("addRemoveLike status :===> ${successModel.status}");
    printLog("addRemoveLike message :==> ${successModel.message}");
  }
  /* ********* Like/Dislike END ********* */

  /* ********* Bookmark ADD/REMOVE START ********* */
  Future<void> setBookmark(
    BuildContext context, {
    required position,
    required subVideoType,
    required videoType,
    required videoId,
  }) async {
    if (kIsWeb) {
      if ((contentDetailModel.result?[0].isBookmark ?? 0) == 0) {
        contentDetailModel.result?[0].isBookmark = 1;
      } else {
        contentDetailModel.result?[0].isBookmark = 0;
      }
    } else {
      if ((shortFilmsModel.result?[position].isBookmark ?? 0) == 0) {
        shortFilmsModel.result?[position].isBookmark = 1;
      } else {
        shortFilmsModel.result?[position].isBookmark = 0;
      }
    }
    notifyListeners();
    getAddBookMark(subVideoType, videoType, videoId);
  }

  Future<void> getAddBookMark(dynamic subVideoType, videoType, videoId) async {
    printLog("getAddBookMark subVideoType :==> $subVideoType");
    printLog("getAddBookMark videoType :=====> $videoType");
    printLog("getAddBookMark videoId :=======> $videoId");
    successModel = await ApiService().addRemoveBookmark(
      subVideoType,
      videoType,
      videoId,
    );
    printLog("getAddBookMark status :===> ${successModel.status}");
    printLog("getAddBookMark message :==> ${successModel.message}");
  }
  /* ********* Bookmark ADD/REMOVE END ********* */

  /* ********* Comments ADD/REMOVE START ********* */
  void updateCommentCount(int position, int count) {
    if (kIsWeb) {
      contentDetailModel.result?[0].totalComment = count;
    } else {
      shortFilmsList?[position].totalComment = count;
    }
    notifyListeners();
  }

  void setDialogType({
    required int position,
    required comments.CommentDialogEnum dialogType,
  }) {
    selectedCommentIndex = position;
    currentDialogPage = dialogType;
    notifyListeners();
  }

  void setDialogState(bool isOpen) {
    printLog("isOpen ==> $isOpen");
    isDialogOpen = isOpen;
    notifyListeners();
  }

  Future<void> getComments(
    dynamic videoId,
    videoType,
    subVideoType,
    pageNo,
  ) async {
    printLog("getComments videoId :=======> $videoId");
    printLog("getComments videoType :=====> $videoType");
    printLog("getComments subVideoType :==> $subVideoType");
    printLog("getComments pageNo :========> $pageNo");
    loadingComment = true;
    try {
      commentModel = await ApiService().getComment(
        videoId,
        videoType,
        subVideoType,
        pageNo,
      );

      printLog("getComments status :===> ${commentModel.status}");
      printLog("getComments message :==> ${commentModel.message}");

      if (commentModel.status == 200) {
        setCommentPagination(
          commentModel.totalRows,
          commentModel.totalPage,
          commentModel.currentPage,
          commentModel.morePage,
        );
        if (commentModel.result != null &&
            (commentModel.result?.length ?? 0) > 0) {
          printLog("getComments commentId :=2=> ${commentModel.result?[0].id}");
          if (pageNo == 1) {
            // Reset for fresh load
            commentList?.clear();
            commentList = [];
          }
          // Add results
          commentList?.addAll(commentModel.result ?? []);

          final Map<String, comments.Result> postMap = {};
          commentList?.forEach((item) {
            final key = '${item.id}-${item.commentId}';
            postMap[key] = item;
          });
          commentList = postMap.values.toList();

          setCommentLoadMore(false);
          printLog("getComments length :===> ${commentList?.length}");
        }
      }
    } finally {
      loadingComment = false;
      notifyListeners();
    }
  }

  void setCommentLoadMore(bool loadMore) {
    printLog("setCommentLoadMore loadMore :=> $loadMore");
    loadCommentMore = loadMore;
    notifyListeners();
  }

  void setCommentPagination(
    int? totalRows,
    int? totalPage,
    int? currentPage,
    bool? morePage,
  ) {
    printLog("setCommentPagination currentPage :==> $currentPage");
    printLog("setCommentPagination totalRows :====> $totalRows");
    printLog("setCommentPagination totalPage :====> $totalPage");
    printLog("setCommentPagination morePage :=====> $morePage");
    currentCommentPage = currentPage;
    totalCommentRows = totalRows;
    totalCommentPage = totalPage;
    isCommentMorePage = morePage;
    notifyListeners();
  }

  Future<void> getReplyComments(dynamic commentId, pageNo) async {
    printLog("getReplyComments commentId :===> $commentId");
    printLog("getReplyComments pageNo :======> $pageNo");
    loadingReply = true;
    try {
      commentReplyModel = await ApiService().getReplyComment(commentId, pageNo);

      printLog("getReplyComments status :===> ${commentReplyModel.status}");
      printLog("getReplyComments message :==> ${commentReplyModel.message}");

      if (commentReplyModel.status == 200) {
        setReplyPagination(
          commentReplyModel.totalRows,
          commentReplyModel.totalPage,
          commentReplyModel.currentPage,
          commentReplyModel.morePage,
        );
        if (commentReplyModel.result != null &&
            (commentReplyModel.result?.length ?? 0) > 0) {
          printLog(
            "getReplyComments commentId :=2=> ${commentReplyModel.result?[0].id}",
          );
          if (pageNo == 1) {
            // Reset for fresh load
            commentRepliesList?.clear();
            commentRepliesList = [];
          }
          // Add results
          commentRepliesList?.addAll(commentReplyModel.result ?? []);

          final Map<String, comments.Result> postMap = {};
          commentRepliesList?.forEach((item) {
            final key = '${item.id}-${item.commentId}';
            postMap[key] = item;
          });
          commentRepliesList = postMap.values.toList();

          setReplyLoadMore(false);
          printLog(
            "getReplyComments length :===> ${commentRepliesList?.length}",
          );
        }
      }
    } finally {
      loadingReply = false;
      notifyListeners();
    }
  }

  void setReplyLoadMore(bool loadMore) {
    printLog("setReplyLoadMore loadMore :=> $loadMore");
    loadReplyMore = loadMore;
    notifyListeners();
  }

  void setReplyPagination(
    int? totalRows,
    int? totalPage,
    int? currentPage,
    bool? morePage,
  ) {
    printLog("setReplyPagination currentPage :==> $currentPage");
    printLog("setReplyPagination totalRows :====> $totalRows");
    printLog("setReplyPagination totalPage :====> $totalPage");
    printLog("setReplyPagination morePage :=====> $morePage");
    currentReplyPage = currentPage;
    totalReplyRows = totalRows;
    totalReplyPage = totalPage;
    isReplyMorePage = morePage;
    notifyListeners();
  }

  Future<void> addComments(
    dynamic comment,
    mainCommentId,
    contentId,
    videoType,
    subVideoType,
  ) async {
    printLog("addComments comment :======> $comment");
    printLog("addComments mainCommentId => $mainCommentId");
    printLog("addComments contentId :====> $contentId");
    printLog("addComments videoType :====> $videoType");
    printLog("addComments subVideoType :=> $subVideoType");
    setSendingComment(true);
    successModel = await ApiService().addComment(
      comment,
      mainCommentId,
      contentId,
      videoType,
      subVideoType,
    );
    printLog("addComments status :===> ${successModel.status}");
    printLog("addComments message :==> ${successModel.message}");
    if (mainCommentId != 0) {
      await getReplyComments(mainCommentId, currentCommentPage);
    } else {
      await getComments(contentId, videoType, subVideoType, currentCommentPage);
    }
    setSendingComment(false);
  }

  void setSendingComment(bool isSending) {
    printLog("isSending ==> $isSending");
    sending = isSending;
    notifyListeners();
  }

  void wantToEditedComment(bool isEditing, int position) {
    printLog("isEditing ==> $isEditing");
    commentPos = position;
    wantToEdit = isEditing;
    notifyListeners();
  }

  Future<void> editComments(
    int position,
    videoId,
    videoType,
    subVideoType,
    comment,
    commentId,
  ) async {
    printLog("editComments comment :==> $comment");
    setSendingEditedComment(true);
    successModel = await ApiService().editComment(comment, commentId);
    printLog("editComments status :===> ${successModel.status}");
    printLog("editComments message :==> ${successModel.message}");
    await getComments(videoId, videoType, subVideoType, currentCommentPage);
    setSendingEditedComment(false);
    wantToEditedComment(false, position);
  }

  void setSendingEditedComment(bool isSending) {
    printLog("isSending ==> $isSending");
    sendingEdited = isSending;
    notifyListeners();
  }

  Future<void> deleteComments(
    int position,
    dynamic videoId,
    videoType,
    subVideoType,
    commentId,
    toUserId,
  ) async {
    printLog("deleteComments commentId :====> $commentId");
    printLog("deleteComments videoId :======> $videoId");
    printLog("deleteComments videoType :====> $videoType");
    printLog("deleteComments subVideoType :=> $subVideoType");
    printLog("deleteComments toUserId :=====> $toUserId");
    commentList?.removeAt(position);
    notifyListeners();
    successModel = await ApiService().deleteComment(commentId);
    printLog("deleteComments status :===> ${successModel.status}");
    printLog("deleteComments message :==> ${successModel.message}");
    // await getComments(postId);
  }

  void resetCommentData() {
    printLog("================== resetCommentData ==================");
    // commentModel = CommentModel();
    sending = false;
    sendingEdited = false;
    wantToEdit = false;
  }
  /* ********** Comments ADD/REMOVE END ********** */

  /* video_id: Short's Id, 
     video_type: Short's VideoType, 
     sub_video_type: 3 (for Episode), 
     episode_id: Short's Episode Id */
  Future<void> addViewCount(dynamic videoId, videoType, episodeId) async {
    printLog("addViewCount videoId :=======> $videoId");
    printLog("addViewCount videoType :=====> $videoType");
    printLog("addViewCount episodeId :=====> $episodeId");
    successModel = SuccessModel();
    successModel = await ApiService().videoView(
      videoId,
      videoType,
      3,
      episodeId,
    );
    printLog("addViewCount message :==> ${successModel.message}");
    notifyListeners();
  }

  Future notifyProvider() async {
    notifyListeners();
  }

  void clearProvider() {
    printLog("=========== clearProvider ===========");
    loading = false;
    loadingEpi = false;
    shortFilmsList?.clear();
    shortFilmsList = [];
    contentDetailModel = details.ContentDetailModel();
    shortFilmEpisodeModel = shortsepisode.ClipEpisodesModel();
    shortFilmsModel = shorts.ClipsModel();
    commentModel = comments.CommentModel();
    commentReplyModel = comments.CommentModel();
    commentList?.clear();
    commentList = [];
    commentRepliesList?.clear();
    commentRepliesList = [];
    successModel = SuccessModel();
  }
}
