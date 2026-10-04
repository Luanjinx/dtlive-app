class CouponListModel {
  int? status;
  String? message;
  List<CouponListResult>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  CouponListModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  CouponListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['result'] != null) {
      result = <CouponListResult>[];
      json['result'].forEach((v) {
        result!.add(CouponListResult.fromJson(v));
      });
    }
    totalRows = json['total_rows'];
    totalPage = json['total_page'];
    currentPage = json['current_page'];
    morePage = json['more_page'];
  }
}

class CouponListResult {
  int? id;
  String? code;
  String? title;
  String? description;
  String? startDate;
  String? endDate;
  int? discountType;
  double? discountValue;
  int? applicableFor;
  int? packageId;
  int? usageLimit;
  int? usagePerUser;
  int? usedCount;
  int? isSingleUse;
  int? status;
  String? createdAt;
  String? updatedAt;

  CouponListResult({
    this.id,
    this.code,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
    this.applicableFor,
    this.packageId,
    this.usageLimit,
    this.usagePerUser,
    this.usedCount,
    this.isSingleUse,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  CouponListResult.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    title = json['title'];
    description = json['description'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    discountType = json['discount_type'];
    discountValue = (json['discount_value'] is int)
        ? (json['discount_value'] as int).toDouble()
        : json['discount_value'];
    applicableFor = json['applicable_for'];
    packageId = json['package_id'];
    usageLimit = json['usage_limit'];
    usagePerUser = json['usage_per_user'];
    usedCount = json['used_count'];
    isSingleUse = json['is_single_use'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
