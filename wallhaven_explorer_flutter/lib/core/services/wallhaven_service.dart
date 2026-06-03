// // AkonDeV 06/2026

import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/wallpaper.dart';

class WallhavenService {
  final Dio _dio;
  String apiKey = '';

  WallhavenService(this._dio);

  Future<Map<String, dynamic>> searchWallpapers({
    required String query,
    required String categories,
    required String purity,
    required String sorting,
    required String order,
    required String ratios,
    required int page,
  }) async {
    // // AkonDeV 06/2026
    final queryParams = {
      'q': query,
      'categories': categories,
      'purity': purity,
      'sorting': sorting,
      'order': order,
      'page': page,
    };

    if (apiKey.isNotEmpty) {
      queryParams['apikey'] = apiKey;
    }
    if (ratios.isNotEmpty) {
      queryParams['ratios'] = ratios;
    }

    try {
      final response = await _dio.get(
        'https://wallhaven.cc/api/v1/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final list = <Wallpaper>[];
        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            list.add(Wallpaper.fromJson(item));
          }
        }

        int lastPage = 1;
        if (data['meta'] != null && data['meta']['last_page'] != null) {
          lastPage = data['meta']['last_page'] as int;
        }

        return {
          'wallpapers': list,
          'lastPage': lastPage,
        };
      } else {
        throw HttpException('Error de conexión con Wallhaven: ${response.statusCode}');
      }
    } catch (e) {
      throw HttpException('Error de red: $e');
    }
  }

  Future<Wallpaper> getWallpaperDetails(String id) async {
    // // AkonDeV 06/2026
    final queryParams = <String, dynamic>{};
    if (apiKey.isNotEmpty) {
      queryParams['apikey'] = apiKey;
    }

    try {
      final response = await _dio.get(
        'https://wallhaven.cc/api/v1/w/$id',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return Wallpaper.fromJson(data);
        }
        throw const HttpException('No se encontraron detalles de la imagen.');
      } else {
        throw HttpException('Error de Wallhaven: ${response.statusCode}');
      }
    } catch (e) {
      throw HttpException('Fallo al obtener detalles del wallpaper: $e');
    }
  }

  Future<void> downloadFile(
    String url,
    String destinationPath, {
    void Function(double progress)? onProgress,
  }) async {
    // // AkonDeV 06/2026
    try {
      final file = File(destinationPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await _dio.download(
        url,
        destinationPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total * 100);
          }
        },
      );
    } catch (e) {
      throw HttpException('Fallo al descargar el archivo: $e');
    }
  }
}
