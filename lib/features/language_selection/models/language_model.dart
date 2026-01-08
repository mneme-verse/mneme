import 'package:equatable/equatable.dart';

/// License information for a language database.
class LicenseModel extends Equatable {
  const LicenseModel({
    required this.text,
    required this.url,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      text: json['text'] as String,
      url: json['url'] as String,
    );
  }

  final String text;
  final String url;

  @override
  List<Object?> get props => [text, url];
}

/// Represents a downloadable language database.
class LanguageModel extends Equatable {
  const LanguageModel({
    required this.code,
    required this.name,
    required this.license,
    required this.size,
    required this.hash,
    required this.version,
  });

  factory LanguageModel.fromJson(
    String code,
    Map<String, dynamic> json,
    String name,
  ) {
    return LanguageModel(
      code: code,
      name: name,
      license: LicenseModel.fromJson(json['license'] as Map<String, dynamic>),
      size: json['size'] as int,
      hash: json['hash'] as String,
      version: json['version'] as String,
    );
  }

  final String code;
  final String name;
  final LicenseModel license;
  final int size;
  final String hash;
  final String version;

  @override
  List<Object?> get props => [code, name, license, size, hash, version];
}
