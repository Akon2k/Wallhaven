// // AkonDeV 06/2026

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_explorer_flutter/models/wallpaper.dart';
import 'package:wallhaven_explorer_flutter/models/app_config.dart';
import 'package:wallhaven_explorer_flutter/core/database/database_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/configuration_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/image_processor_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/wallhaven_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/image_cache_service.dart';
import 'package:wallhaven_explorer_flutter/providers/main_provider.dart';

// Mocks (Riverpod 3.x — inyección via ProviderContainer overrides)
class MockWallhavenService extends WallhavenService {
  MockWallhavenService() : super(Dio());

  @override
  Future<Map<String, dynamic>> searchWallpapers({
    required String query,
    required String categories,
    required String purity,
    required String sorting,
    required String order,
    required String ratios,
    required int page,
  }) async {
    return {
      'wallpapers': [
        Wallpaper(id: 'w1', url: 'url1', path: 'path1', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user1', shortUrl: 'short1'),
        Wallpaper(id: 'w2', url: 'url2', path: 'path2', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user2', shortUrl: 'short2'),
      ],
      'lastPage': 5,
    };
  }

  @override
  Future<Wallpaper> getWallpaperDetails(String id) async {
    return Wallpaper(id: id, url: 'url', path: 'path', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user', shortUrl: 'short');
  }

  @override
  Future<void> downloadFile(String url, String destinationPath, {void Function(double progress)? onProgress}) async {}
}

class MockImageProcessorService extends ImageProcessorService {
  @override
  Future<void> processMobileResize({
    required String sourcePath,
    required String targetPath,
    required int targetWidth,
    required int targetHeight,
    required ResizeMode mode,
  }) async {}
}

class MockImageCacheService extends ImageCacheService {
  MockImageCacheService() : super(Dio());

  @override
  Future<String> getCachedImagePath(String id, String url) async {
    return url; // No descarga en tests; retorna URL como path
  }

  @override
  Future<void> clearCache() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper: ProviderContainer con servicios mockeados
  ProviderContainer buildContainer({
    String dbPath = ':memory:',
    String configPath = ':memory:config.json',
  }) {
    return ProviderContainer(overrides: [
      whServiceProvider.overrideWith((ref) => MockWallhavenService()),
      imgProcessorServiceProvider.overrideWith((ref) => MockImageProcessorService()),
      dbServiceProvider.overrideWith((ref) => DatabaseService(customPath: dbPath)),
      configServiceProvider.overrideWith((ref) => ConfigurationService(customPath: configPath)),
      cacheServiceProvider.overrideWith((ref) => MockImageCacheService()),
    ]);
  }

  // ──────────────────────────────────────────────────────────
  group('Pruebas de Base de Datos SQLite (sqlite3)', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService(customPath: ':memory:');
      await dbService.initializeDatabase();
    });

    tearDown(() => dbService.close());

    test('Guardar favorito e isFavorite retorna correcto', () async {
      final wp = Wallpaper(id: 'test_wp', url: 'url', path: 'path', resolution: '1920x1080', category: 'general', tags: ['t1'], uploader: 'AkonDeV', shortUrl: 'short');
      expect(await dbService.isFavorite(wp.id), isFalse);
      await dbService.saveFavorite(wp);
      expect(await dbService.isFavorite(wp.id), isTrue);
    });

    test('Obtener favoritos retorna elementos ordenados', () async {
      final wp1 = Wallpaper(id: 'w1', url: 'u1', path: 'p1', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user', shortUrl: 'short');
      final wp2 = Wallpaper(id: 'w2', url: 'u2', path: 'p2', resolution: '2560x1440', category: 'general', tags: [], uploader: 'user', shortUrl: 'short');
      await dbService.saveFavorite(wp1);
      await Future.delayed(const Duration(milliseconds: 50));
      await dbService.saveFavorite(wp2);
      final list = await dbService.getFavorites();
      expect(list.length, equals(2));
      expect(list[0].id, equals('w2')); // Último guardado primero
      expect(list[1].id, equals('w1'));
    });

    test('Eliminar favorito limpia correctamente', () async {
      final wp = Wallpaper(id: 'w1', url: 'u1', path: 'p1', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user', shortUrl: 'short');
      await dbService.saveFavorite(wp);
      expect(await dbService.isFavorite(wp.id), isTrue);
      await dbService.removeFavorite(wp.id);
      expect(await dbService.isFavorite(wp.id), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────
  group('Pruebas de Configuración', () {
    test('Cargar configuración crea por defecto si no existe', () async {
      final service = ConfigurationService(customPath: 'non_existent_config.json');
      final config = await service.loadConfig();
      expect(config, isNotNull);
      expect(config.defaultResizeSize, equals('1080x1920'));
      expect(config.theme, equals('Dark'));
      final file = File('non_existent_config.json');
      if (await file.exists()) await file.delete();
    });

    test('Actualizar configuración persiste los datos y actualiza el estado', () async {
      // // AkonDeV 06/2026
      final testConfigService = ConfigurationService(customPath: 'test_config_update.json');
      final container = ProviderContainer(overrides: [
        whServiceProvider.overrideWith((ref) => MockWallhavenService()),
        imgProcessorServiceProvider.overrideWith((ref) => MockImageProcessorService()),
        dbServiceProvider.overrideWith((ref) => DatabaseService(customPath: ':memory:')),
        configServiceProvider.overrideWith((ref) => testConfigService),
        cacheServiceProvider.overrideWith((ref) => MockImageCacheService()),
      ]);
      addTearDown(container.dispose);

      container.read(mainProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(mainProvider.notifier);
      final newConfig = AppConfig(
        apiKey: 'new_api_key_123',
        downloadDirectory: 'C:/TestDownload',
        mobileDirectory: 'C:/TestMobile',
        defaultResizeSize: '1440x2560',
        theme: 'Light',
      );
      await notifier.updateSettings(newConfig);

      expect(container.read(mainProvider).appConfig.apiKey, equals('new_api_key_123'));
      expect(container.read(mainProvider).appConfig.downloadDirectory, equals('C:/TestDownload'));
      expect(container.read(mainProvider).appConfig.defaultResizeSize, equals('1440x2560'));
      expect(container.read(mainProvider).appConfig.theme, equals('Light'));

      final reloadedConfig = await testConfigService.loadConfig();
      expect(reloadedConfig.apiKey, equals('new_api_key_123'));

      final file = File('test_config_update.json');
      if (await file.exists()) await file.delete();
    });
  });

  // ──────────────────────────────────────────────────────────
  group('Pruebas de Integración y ViewModel (MainNotifier)', () {
    test('Slideshow activa y desactiva bucle de temporizador', () async {
      // // AkonDeV 06/2026
      final container = buildContainer();
      addTearDown(container.dispose);
      container.read(mainProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(mainProvider.notifier);
      expect(container.read(mainProvider).isSlideshowActive, isFalse);
      notifier.toggleSlideshow();
      expect(container.read(mainProvider).isSlideshowActive, isTrue);
      notifier.toggleSlideshow();
      expect(container.read(mainProvider).isSlideshowActive, isFalse);
    });

    test('Navegación contextual Siguiente/Anterior en resultados', () async {
      // // AkonDeV 06/2026
      final container = buildContainer();
      addTearDown(container.dispose);
      container.read(mainProvider);
      // Esperar a que _init complete y cargue los 2 wallpapers del mock
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container.read(mainProvider.notifier);
      final wallpapers = container.read(mainProvider).wallpapers;
      expect(wallpapers.length, equals(2));

      await notifier.updateSelectedWallpaper(wallpapers.first);
      expect(notifier.canNavigateNext(), isTrue);
      expect(notifier.canNavigatePrevious(), isFalse);

      notifier.navigateNext();
      expect(container.read(mainProvider).selectedWallpaper?.id, equals('w2'));
    });
  });
}
