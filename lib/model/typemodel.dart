// To parse this JSON data, do
// final typeModel = typeModelFromJson(jsonString);

import 'dart:convert';

TypeModel typeModelFromJson(String str) => TypeModel.fromJson(json.decode(str));

String typeModelsearchTypeModelToJson(TypeModel data) =>
    json.encode(data.toJson());

class TypeModel {
  TypeModel({
    this.result,
  });

  List<Result>? result = [];

  factory TypeModel.fromJson(Map<String, dynamic> json) => TypeModel(
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "result": result != null
            ? List<dynamic>.from(result?.map((x) => x.toJson()) ?? [])
            : [],
      };
}

class Result {
  Result({
    this.id,
    this.name,
    this.type,
    this.isHome,
  });

  int? id;
  String? name;
  int? type;
  int? isHome;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        isHome: json["isHome"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "isHome": isHome,
      };
}
