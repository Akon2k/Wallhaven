// // AkonDeV 06/2026

class AppConfig {
  String apiKey;
  String downloadDirectory;
  String mobileDirectory;
  String defaultResizeSize;
  String theme;

  AppConfig({
    this.apiKey = '',
    this.downloadDirectory = '',
    this.mobileDirectory = '',
    this.defaultResizeSize = '1080x1920',
    this.theme = 'Dark',
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiKey: json['apiKey']?.toString() ?? '',
      downloadDirectory: json['downloadDirectory']?.toString() ?? '',
      mobileDirectory: json['mobileDirectory']?.toString() ?? '',
      defaultResizeSize: json['defaultResizeSize']?.toString() ?? '1080x1920',
      theme: json['theme']?.toString() ?? 'Dark',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'downloadDirectory': downloadDirectory,
      'mobileDirectory': mobileDirectory,
      'defaultResizeSize': defaultResizeSize,
      'theme': theme,
    };
  }
}
