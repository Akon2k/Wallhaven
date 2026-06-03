// // AkonDeV 06/2026

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  final Dio _dio;

  ImageCacheService(this._dio);

  Future<String> getCachedImagePath(String id, String url) async {
    // // AkonDeV 06/2026
    final appDir = await getApplicationSupportDirectory();
    final cacheFolder = p.join(appDir.path, 'Cache');

    final cacheDir = Directory(cacheFolder);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    String extension = p.extension(url);
    if (extension.isEmpty) extension = '.jpg';
    final localPath = p.join(cacheFolder, '$id$extension');

    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }

    try {
      await _dio.download(url, localPath);
      return localPath;
    } catch (e) {
      throw HttpException('Fallo al descargar en caché local: $e');
    }
  }

  Future<void> clearCache() async {
    // // AkonDeV 06/2026
    final appDir = await getApplicationSupportDirectory();
    final cacheFolder = p.join(appDir.path, 'Cache');
    final cacheDir = Directory(cacheFolder);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
