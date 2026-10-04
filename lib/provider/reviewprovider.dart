import 'package:yourappname/model/successmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';

import '../model/reviewmodel.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../webservice/apiservices.dart';

class ReviewProvider extends ChangeNotifier {
  SuccessModel successModel = SuccessModel();
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isSubmitting = false;
  String? errorMessage;

  double avgRating = 0.0;
  int totalReviews = 0;
  RatingBreakdownModel? ratingBreakdown;
  UserReviewModel? userReview;
  List<ReviewItemModel> reviewsList = [];
  int currentPage = 1;
  bool morePage = false;
  int totalRows = 0;

  int selectedRating = 0;
  String reviewText = '';

  Future<void> fetchReviews({
    required int videoId,
    required int videoType,
    required int subVideoType,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      reviewsList = [];
      currentPage = 1;
      morePage = false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService().getReview(
        videoId,
        videoType,
        subVideoType,
        1,
      );
      printLog('fetchReviews status :==> ${result.status}');
      printLog('fetchReviews message :=> ${result.message}');
      if (result.status == 200) {
        avgRating = result.avgRating;
        totalReviews = result.totalReviews;
        totalRows = result.totalRows;
        ratingBreakdown = result.ratingBreakdown;
        userReview = result.userReview;
        reviewsList = result.reviews;
        currentPage = result.currentPage;
        morePage = result.morePage;
        if (userReview != null) prefillUserReview();
      } else {
        errorMessage = result.message;
      }
    } catch (e) {
      printLog('fetchReviews error: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReviews({
    required int videoId,
    required int videoType,
    required int subVideoType,
  }) async {
    if (isLoadingMore || !morePage) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await ApiService().getReview(
        videoId,
        videoType,
        subVideoType,
        currentPage + 1,
      );
      if (result.status == 200) {
        final existingIds = reviewsList.map((r) => r.id).toSet();
        final newItems = result.reviews
            .where((r) => !existingIds.contains(r.id))
            .toList();
        reviewsList.addAll(newItems);
        currentPage = result.currentPage;
        morePage = result.morePage;
        totalRows = result.totalRows;
      }
    } catch (e) {
      printLog('loadMoreReviews error: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> submitReview({
    required int videoId,
    required int videoType,
    required int subVideoType,
    required BuildContext context,
  }) async {
    if (selectedRating == 0) {
      Utils.showToast(Locales.string(context, 'tap_a_star_to_rate'));
      return;
    }
    if (Constant.userID == null) return;
    isSubmitting = true;
    notifyListeners();
    successModel = SuccessModel();
    try {
      successModel = await ApiService().addReview(
        videoId,
        videoType,
        subVideoType,
        selectedRating,
        reviewText,
      );
      if (!context.mounted) return;
      if (successModel.status == 200) {
        Utils.showToast(
          successModel.message ??
              Locales.string(context, 'review_submit_success'),
        );
        await fetchReviews(
          videoId: videoId,
          videoType: videoType,
          subVideoType: subVideoType,
          isRefresh: true,
        );
      } else {
        Utils.showToast(
          successModel.message ??
              Locales.string(context, 'something_went_wrong'),
        );
      }
    } catch (e) {
      printLog('submitReview error: $e');
      if (!context.mounted) return;
      Utils.showToast(Locales.string(context, 'something_went_wrong'));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void setSelectedRating(int rating) {
    selectedRating = rating;
    notifyListeners();
  }

  void setReviewText(String text) {
    reviewText = text;
    notifyListeners();
  }

  void prefillUserReview() {
    if (userReview == null) return;
    selectedRating = userReview?.rating ?? 0;
    reviewText = userReview?.reviewText ?? '';
    notifyListeners();
  }

  void resetInputState() {
    selectedRating = 0;
    reviewText = '';
    notifyListeners();
  }
}
