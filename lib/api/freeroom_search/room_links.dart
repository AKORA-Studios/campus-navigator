import 'dart:convert';

class RoomLinks {
  final List<ResultsRaum> resultsRaum;
  final List<ResultsGeb> resultsGeb;

  RoomLinks({
    required this.resultsRaum,
    required this.resultsGeb,
  });

  factory RoomLinks.fromRawJson(String str) =>
      RoomLinks.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RoomLinks.fromJson(Map<String, dynamic> json) => RoomLinks(
        resultsRaum: List<ResultsRaum>.from(
            json["results_raum"].map((x) => ResultsRaum.fromJson(x))),
        resultsGeb: List<ResultsGeb>.from(
            json["results_geb"].map((x) => ResultsGeb.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "results_raum": List<dynamic>.from(resultsRaum.map((x) => x.toJson())),
        "results_geb": List<dynamic>.from(resultsGeb.map((x) => x.toJson())),
      };
}

class ResultsGeb {
  final String gebude;
  final String url;

  ResultsGeb({
    required this.gebude,
    required this.url,
  });

  factory ResultsGeb.fromRawJson(String str) =>
      ResultsGeb.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ResultsGeb.fromJson(Map<String, dynamic> json) => ResultsGeb(
        gebude: json["gebäude"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "gebäude": gebude,
        "url": url,
      };
}

class ResultsRaum {
  final String raum;
  final String url;

  ResultsRaum({
    required this.raum,
    required this.url,
  });

  factory ResultsRaum.fromRawJson(String str) =>
      ResultsRaum.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ResultsRaum.fromJson(Map<String, dynamic> json) => ResultsRaum(
        raum: json["raum"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "raum": raum,
        "url": url,
      };
}
