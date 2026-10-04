// To parse this JSON data, do
// final razorpayOrderModel = razorpayOrderModelFromJson(jsonString);

import 'dart:convert';

RazorpayOrderModel razorpayOrderModelFromJson(String str) =>
    RazorpayOrderModel.fromJson(json.decode(str));

String razorpayOrderModelToJson(RazorpayOrderModel data) =>
    json.encode(data.toJson());

class RazorpayOrderModel {
  int? status;
  String? message;
  String? errors;
  Result? result;

  RazorpayOrderModel({this.status, this.message, this.errors, this.result});

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) =>
      RazorpayOrderModel(
        status: json["status"],
        message: json["message"],
        errors: json["errors"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "errors": errors,
    "result": result?.toJson(),
  };
}

class Result {
  dynamic amount;
  dynamic amountDue;
  dynamic amountPaid;
  int? attempts;
  int? createdAt;
  String? currency;
  String? entity;
  String? id;
  List<dynamic>? notes;
  dynamic offerId;
  String? receipt;
  String? status;

  Result({
    this.amount,
    this.amountDue,
    this.amountPaid,
    this.attempts,
    this.createdAt,
    this.currency,
    this.entity,
    this.id,
    this.notes,
    this.offerId,
    this.receipt,
    this.status,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    amount: json["amount"],
    amountDue: json["amount_due"],
    amountPaid: json["amount_paid"],
    attempts: json["attempts"],
    createdAt: json["created_at"],
    currency: json["currency"],
    entity: json["entity"],
    id: json["id"],
    notes: json["notes"] == null
        ? []
        : List<dynamic>.from(json["notes"]?.map((x) => x) ?? []),
    offerId: json["offer_id"],
    receipt: json["receipt"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "amount_due": amountDue,
    "amount_paid": amountPaid,
    "attempts": attempts,
    "created_at": createdAt,
    "currency": currency,
    "entity": entity,
    "id": id,
    "notes": notes == null
        ? []
        : List<dynamic>.from(notes?.map((x) => x) ?? []),
    "offer_id": offerId,
    "receipt": receipt,
    "status": status,
  };
}
