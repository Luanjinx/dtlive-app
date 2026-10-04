import 'dart:convert';

ReferEarnHistoryModel referEarnHistoryModelFromJson(String str) =>
    ReferEarnHistoryModel.fromJson(json.decode(str));

String referEarnHistoryModelToJson(ReferEarnHistoryModel data) =>
    json.encode(data.toJson());

class ReferEarnHistoryModel {
  int? status;
  String? message;
  List<ReferEarnItem>? result;
  int? totalRows;
  int? totalPage;
  int? currentPage;
  bool? morePage;

  ReferEarnHistoryModel({
    this.status,
    this.message,
    this.result,
    this.totalRows,
    this.totalPage,
    this.currentPage,
    this.morePage,
  });

  factory ReferEarnHistoryModel.fromJson(Map<String, dynamic> json) =>
      ReferEarnHistoryModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<ReferEarnItem>.from(
                json["result"]?.map((x) => ReferEarnItem.fromJson(x)) ?? [],
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

class ReferEarnItem {
  int? id;
  String? referenceCode;
  int? parentUserId;
  int? childUserId;
  int? parentEarn;
  int? childEarn;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? childUserName;
  String? childFullName;
  String? childEmail;
  String? childMobileNumber;

  ReferEarnItem({
    this.id,
    this.referenceCode,
    this.parentUserId,
    this.childUserId,
    this.parentEarn,
    this.childEarn,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.childUserName,
    this.childFullName,
    this.childEmail,
    this.childMobileNumber,
  });

  factory ReferEarnItem.fromJson(Map<String, dynamic> json) => ReferEarnItem(
    id: json["id"],
    referenceCode: json["reference_code"],
    parentUserId: json["parent_user_id"],
    childUserId: json["child_user_id"],
    parentEarn: json["parent_earn"],
    childEarn: json["child_earn"],
    status: json["status"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    childUserName: json["child_user_name"],
    childFullName: json["child_full_name"],
    childEmail: json["child_email"],
    childMobileNumber: json["child_mobile_number"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "reference_code": referenceCode,
    "parent_user_id": parentUserId,
    "child_user_id": childUserId,
    "parent_earn": parentEarn,
    "child_earn": childEarn,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "child_user_name": childUserName,
    "child_full_name": childFullName,
    "child_email": childEmail,
    "child_mobile_number": childMobileNumber,
  };

  /// Returns the best available display name for the referred user.
  String get displayName {
    if (childUserName != null && childUserName!.trim().isNotEmpty) {
      return childUserName!.trim();
    }
    if (childFullName != null && childFullName!.trim().isNotEmpty) {
      return childFullName!.trim();
    }
    if (childMobileNumber != null && childMobileNumber!.trim().isNotEmpty) {
      return childMobileNumber!.trim();
    }
    return "—";
  }

  /// Returns a single uppercase character for the circular avatar.
  /// Priority: first letter (A–Z) → first digit → "#"
  String get avatarChar {
    final name = displayName;
    for (final rune in name.runes) {
      final c = String.fromCharCode(rune);
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) return c.toUpperCase();
    }
    for (final rune in name.runes) {
      final c = String.fromCharCode(rune);
      if (RegExp(r'[0-9]').hasMatch(c)) return c;
    }
    return '#';
  }
}
