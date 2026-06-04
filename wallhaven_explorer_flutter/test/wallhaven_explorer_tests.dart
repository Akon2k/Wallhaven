// // AkonDeV 06/2026

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:wallhaven_explorer_flutter/models/wallpaper.dart';
import 'package:wallhaven_explorer_flutter/models/app_config.dart';
import 'package:wallhaven_explorer_flutter/core/database/database_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/configuration_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/image_processor_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/wallhaven_service.dart';
import 'package:wallhaven_explorer_flutter/core/services/image_cache_service.dart';
import 'package:wallhaven_explorer_flutter/providers/main_provider.dart';

// Mocks simples para pruebas unitarias de integración
class MockWallhavenService extends WallhavenService {
  MockWallhavenService() : super(null as dynamic);

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
      'wallpapers': [Wallpaper(id: '1', url: 'url1', path: 'path1', resolution: '1920x1080', category: 'general', tags: [], uploader: 'user1', shortUrl: 'short1')],
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
  MockImageCacheService() : super(null as dynamic);

  @override
  Future<String> getCachedImagePath(String id, String url) async {
    return 'cached_path.jpg';
  }

  @override
  Future<void> clearCache() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Base de Datos SQLite (sqlite3)', () {
    late DatabaseService dbService;
    late String tempDbPath;

    setUp(() async {
      // Usar base de datos en memoria para máxima velocidad y aislamiento
      tempDbPath = ':memory:';
      dbService = DatabaseService(customPath: tempDbPath);
      await dbService.initializeDatabase();
    });

    tearDown(() {
      dbService.close();
    });

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
      expect(list[0].id, equals('w2')); // El último guardado primero
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

  group('Pruebas de Configuración', () {
    test('Cargar configuración crea por defecto si no existe', () async {
      final service = ConfigurationService(customPath: 'non_existent_config.json');
      final config = await service.loadConfig();

      expect(config, isNotNull);
      expect(config.defaultResizeSize, equals('1080x1920'));
      expect(config.theme, equals('Dark'));
      
      // Limpieza
      final file = File('non_existent_config.json');
      if (await file.exists()) await file.delete();
    });

    test('Actualizar configuración persiste los datos y actualiza el estado', () async {
      // // AkonDeV 06/2026
      final configService = ConfigurationService(customPath: 'test_config_update.json');
      final notifier = MainNotifier(
        whService: MockWallhavenService(),
        imgService: MockImageProcessorService(),
        dbService: DatabaseService(customPath: ':memory:'),
        configService: configService,
        imageCacheService: MockImageCacheService(),
      );

      // Esperar a que _init se ejecute asíncronamente
      await Future.delayed(const Duration(milliseconds: 50));

      final newConfig = AppConfig(
        apiKey: 'new_api_key_123',
        downloadDirectory: 'C:/TestDownload',
        mobileDirectory: 'C:/TestMobile',
        defaultResizeSize: '1440x2560',
        theme: 'Light',
      );

      await notifier.updateSettings(newConfig);

      expect(notifier.state.appConfig.apiKey, equals('new_api_key_123'));
      expect(notifier.state.appConfig.downloadDirectory, equals('C:/TestDownload'));
      expect(notifier.state.appConfig.mobileDirectory, equals('C:/TestMobile'));
      expect(notifier.state.appConfig.defaultResizeSize, equals('1440x2560'));
      expect(notifier.state.appConfig.theme, equals('Light'));

      // Verificar que se haya guardado en el archivo
      final reloadedConfig = await configService.loadConfig();
      expect(reloadedConfig.apiKey, equals('new_api_key_123'));

      // Limpieza
      final file = File('test_config_update.json');
      if (await file.exists()) await file.delete();
    });
  });

  group('Pruebas de Integración y ViewModel (MainNotifier)', () {
    test('Slideshow activa y desactiva bucle de temporizador', () {
      final notifier = MainNotifier(
        whService: MockWallhavenService(),
        imgService: MockImageProcessorService(),
        dbService: DatabaseService(customPath: ':memory:'),
        configService: ConfigurationService(customPath: ':memory:config.json'),
        imageCacheService: MockImageCacheService(),
      );

      expect(notifier.state.isSlideshowActive, isFalse);
      
      notifier.toggleSlideshow();
      expect(notifier.state.isSlideshowActive, isTrue);

      notifier.toggleSlideshow();
      expect(notifier.state.isSlideshowActive, isFalse);
    });

    test('Navegación contextual Siguiente/Anterior en resultados', () async {
      final notifier = MainNotifier(
        whService: MockWallhavenService(),
        imgService: MockImageProcessorService(),
        dbService: DatabaseService(customPath: ':memory:'),
        configService: ConfigurationService(customPath: ':memory:config.json'),
        imageCacheService: MockImageCacheService(),
      );

      final w1 = Wallpaper(id: 'w1', url: 'u1', path: 'p1', resolution: '1920x1080', category: 'gen', tags: [], uploader: 'u', shortUrl: 's');
      final w2 = Wallpaper(id: 'w2', url: 'u2', path: 'p2', resolution: '1920x1080', category: 'gen', tags: [], uploader: 'u', shortUrl: 's');

      notifier.state = notifier.state.copyWith(
        wallpapers: [w1, w2],
        selectedTabIndex: 0,
      );
      await notifier.updateSelectedWallpaper(w1);

      expect(notifier.canNavigateNext(), isTrue);
      expect(notifier.canNavigatePrevious(), isFalse);

      notifier.navigateNext();
      expect(notifier.state.selectedWallpaper?.id, equals('w2'));
    });
  });
}
