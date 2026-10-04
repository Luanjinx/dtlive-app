import 'dart:convert';

ReviewPageResultModel reviewPageResultModelFromJson(String str) =>
    ReviewPageResultModel.fromJson(json.decode(str));

class ReviewItemModel {
  int? id;
  int? userId;
  int? videoType;
  int? videoId;
  int? rating;
  String? reviewText;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? userName;
  String? userImage;

  ReviewItemModel({
    this.id,
    this.userId,
    this.videoType,
    this.videoId,
    this.rating,
    this.reviewText,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userImage,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) =>
      ReviewItemModel(
        id: json['id'],
        userId: json['user_id'],
        videoType: json['video_type'],
        videoId: json['video_id'],
        rating: json['rating'],
        reviewText: json['review_text'],
        status: json['status'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        userName: json['user_name'],
        userImage: json['user_image'],
      );
}

class UserReviewModel {
  int? id;
  int? rating;
  String? reviewText;
  int? status;
  String? statusLabel;
  String? createdAt;

  UserReviewModel({
    this.id,
    this.rating,
    this.reviewText,
    this.status,
    this.statusLabel,
    this.createdAt,
  });

  factory UserReviewModel.fromJson(Map<String, dynamic> json) =>
      UserReviewModel(
        id: json['id'],
        rating: json['rating'],
        reviewText: json['review_text'],
        status: json['status'],
        statusLabel: json['status_label'],
        createdAt: json['created_at'],
      );
}

class RatingBreakdownModel {
  int one;
  int two;
  int three;
  int four;
  int five;

  RatingBreakdownModel({
    this.one = 0,
    this.two = 0,
    this.three = 0,
    this.four = 0,
    this.five = 0,
  });

  factory RatingBreakdownModel.fromJson(Map<String, dynamic> json) =>
      RatingBreakdownModel(
        one: (json['1'] as num?)?.toInt() ?? 0,
        two: (json['2'] as num?)?.toInt() ?? 0,
        three: (json['3'] as num?)?.toInt() ?? 0,
        four: (json['4'] as num?)?.toInt() ?? 0,
        five: (json['5'] as num?)?.toInt() ?? 0,
      );
}

class ReviewPageResultModel {
  int status;
  String message;
  double avgRating;
  int totalReviews;
  RatingBreakdownModel? ratingBreakdown;
  UserReviewModel? userReview;
  List<ReviewItemModel> reviews;
  int totalRows;
  int totalPage;
  int currentPage;
  bool morePage;

  ReviewPageResultModel({
    this.status = 0,
    this.message = '',
    this.avgRating = 0.0,
    this.totalReviews = 0,
    this.ratingBreakdown,
    this.userReview,
    this.reviews = const [],
    this.totalRows = 0,
    this.totalPage = 1,
    this.currentPage = 1,
    this.morePage = false,
  });

  factory ReviewPageResultModel.fromJson(Map<String, dynamic> json) {
    // Guard: PHP serializes empty associative arrays as [] on web (JSArray),
    // so treat any non-Map value for 'result' as an empty map.
    final raw = json['result'];
    final result = (raw is Map)
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final reviewsRaw = result['reviews'];
    final breakdownRaw = result['rating_breakdown'];
    final userReviewRaw = result['user_review'];

    return ReviewPageResultModel(
      status: (json['status'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      avgRating: (result['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (result['total_reviews'] as num?)?.toInt() ?? 0,
      // breakdownRaw can be [] (empty PHP array) — only parse when it's a Map
      ratingBreakdown: (breakdownRaw is Map)
          ? RatingBreakdownModel.fromJson(
              Map<String, dynamic>.from(breakdownRaw),
            )
          : null,
      // userReviewRaw can be [] (empty PHP array) — only parse when it's a Map
      userReview: (userReviewRaw is Map)
          ? UserReviewModel.fromJson(Map<String, dynamic>.from(userReviewRaw))
          : null,
      reviews: (reviewsRaw is List)
          ? reviewsRaw
                .whereType<Map>()
                .map(
                  (e) => ReviewItemModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      totalRows:
          (result['total_rows'] as num?)?.toInt() ??
          (json['total_rows'] as num?)?.toInt() ??
          0,
      totalPage:
          (result['total_page'] as num?)?.toInt() ??
          (json['total_page'] as num?)?.toInt() ??
          1,
      currentPage:
          (result['current_page'] as num?)?.toInt() ??
          (json['current_page'] as num?)?.toInt() ??
          1,
      morePage: result['more_page'] == true || json['more_page'] == true,
    );
  }
}
