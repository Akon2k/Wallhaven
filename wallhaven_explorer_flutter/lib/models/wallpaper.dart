// // AkonDeV 06/2026

class Wallpaper {
  final String id;
  final String url;
  final String path;
  final String resolution;
  final String category;
  final List<String> tags;
  final String uploader;
  final String shortUrl;

  Wallpaper({
    required this.id,
    required this.url,
    required this.path,
    required this.resolution,
    required this.category,
    required this.tags,
    required this.uploader,
    required this.shortUrl,
  });

  String get thumbnailUrl => (id.length >= 2)
      ? 'https://th.wallhaven.cc/lg/${id.substring(0, 2)}/$id.jpg'
      : path;

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    var tagsList = <String>[];
    if (json['tags'] != null && json['tags'] is List) {
      for (var t in json['tags']) {
        if (t['name'] != null) {
          tagsList.add(t['name'].toString());
        }
      }
    }

    String user = '';
    if (json['uploader'] != null) {
      if (json['uploader'] is Map && json['uploader']['username'] != null) {
        user = json['uploader']['username'].toString();
      } else if (json['uploader'] is String) {
        user = json['uploader'].toString();
      }
    }

    return Wallpaper(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: tagsList,
      uploader: user,
      shortUrl: json['short_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'path': path,
      'resolution': resolution,
      'category': category,
      'uploader': uploader,
      'short_url': shortUrl,
      'tags': tags.map((t) => {'name': t}).toList(),
    };
  }
}
