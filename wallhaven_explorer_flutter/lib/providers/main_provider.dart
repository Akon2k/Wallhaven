// // AkonDeV 06/2026

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/database/database_service.dart';
import '../core/services/configuration_service.dart';
import '../core/services/image_cache_service.dart';
import '../core/services/image_processor_service.dart';
import '../core/services/wallhaven_service.dart';
import '../models/app_config.dart';
import '../models/wallpaper.dart';

class MainState {
  final String title;
  final String searchQuery;
  final List<Wallpaper> wallpapers;
  final Wallpaper? selectedWallpaper;
  final String displayedImagePath;
  final List<Wallpaper> favoriteWallpapers;
  final List<String> searchHistory;
  final bool isFavorite;
  final bool isSlideshowActive;
  final bool isFullScreen;
  
  final int currentPage;
  final int maxPages;
  
  final bool categoriesGeneral;
  final bool categoriesAnime;
  final bool categoriesPeople;
  final bool puritySfw;
  final bool puritySketchy;
  final bool purityNsfw;
  final String selectedSorting;
  final String selectedOrder;

  final String selectedResizeResolution;
  final String selectedResizeMode;
  final bool isCropModeActive;

  final double downloadProgress;
  final bool isLoading;
  final String statusMessage;

  final int selectedTabIndex;
  final bool isGridViewActive;
  final bool isDetailsPanelOpen;
  final AppConfig appConfig;

  MainState({
    this.title = 'Wallhaven Explorer',
    this.searchQuery = '',
    this.wallpapers = const [],
    this.selectedWallpaper,
    this.displayedImagePath = '',
    this.favoriteWallpapers = const [],
    this.searchHistory = const [],
    this.isFavorite = false,
    this.isSlideshowActive = false,
    this.isFullScreen = false,
    this.currentPage = 1,
    this.maxPages = 1,
    this.categoriesGeneral = true,
    this.categoriesAnime = true,
    this.categoriesPeople = true,
    this.puritySfw = true,
    this.puritySketchy = false,
    this.purityNsfw = false,
    this.selectedSorting = 'relevance',
    this.selectedOrder = 'desc',
    this.selectedResizeResolution = '1080x1920',
    this.selectedResizeMode = 'SmartCropCentred',
    this.isCropModeActive = false,
    this.downloadProgress = 0.0,
    this.isLoading = false,
    this.statusMessage = 'Listo',
    this.selectedTabIndex = 0,
    this.isGridViewActive = true,
    this.isDetailsPanelOpen = true,
    AppConfig? appConfig,
  }) : appConfig = appConfig ?? AppConfig();

  MainState copyWith({
    String? title,
    String? searchQuery,
    List<Wallpaper>? wallpapers,
    Wallpaper? selectedWallpaper,
    String? displayedImagePath,
    List<Wallpaper>? favoriteWallpapers,
    List<String>? searchHistory,
    bool? isFavorite,
    bool? isSlideshowActive,
    bool? isFullScreen,
    int? currentPage,
    int? maxPages,
    bool? categoriesGeneral,
    bool? categoriesAnime,
    bool? categoriesPeople,
    bool? puritySfw,
    bool? puritySketchy,
    bool? purityNsfw,
    String? selectedSorting,
    String? selectedOrder,
    String? selectedResizeResolution,
    String? selectedResizeMode,
    bool? isCropModeActive,
    double? downloadProgress,
    bool? isLoading,
    String? statusMessage,
    int? selectedTabIndex,
    bool? isGridViewActive,
    bool? isDetailsPanelOpen,
    bool nullSelectedWallpaper = false,
    AppConfig? appConfig,
  }) {
    return MainState(
      title: title ?? this.title,
      searchQuery: searchQuery ?? this.searchQuery,
      wallpapers: wallpapers ?? this.wallpapers,
      selectedWallpaper: nullSelectedWallpaper ? null : (selectedWallpaper ?? this.selectedWallpaper),
      displayedImagePath: displayedImagePath ?? this.displayedImagePath,
      favoriteWallpapers: favoriteWallpapers ?? this.favoriteWallpapers,
      searchHistory: searchHistory ?? this.searchHistory,
      isFavorite: isFavorite ?? this.isFavorite,
      isSlideshowActive: isSlideshowActive ?? this.isSlideshowActive,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      currentPage: currentPage ?? this.currentPage,
      maxPages: maxPages ?? this.maxPages,
      categoriesGeneral: categoriesGeneral ?? this.categoriesGeneral,
      categoriesAnime: categoriesAnime ?? this.categoriesAnime,
      categoriesPeople: categoriesPeople ?? this.categoriesPeople,
      puritySfw: puritySfw ?? this.puritySfw,
      puritySketchy: puritySketchy ?? this.puritySketchy,
      purityNsfw: purityNsfw ?? this.purityNsfw,
      selectedSorting: selectedSorting ?? this.selectedSorting,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      selectedResizeResolution: selectedResizeResolution ?? this.selectedResizeResolution,
      selectedResizeMode: selectedResizeMode ?? this.selectedResizeMode,
      isCropModeActive: isCropModeActive ?? this.isCropModeActive,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isGridViewActive: isGridViewActive ?? this.isGridViewActive,
      isDetailsPanelOpen: isDetailsPanelOpen ?? this.isDetailsPanelOpen,
      appConfig: appConfig ?? this.appConfig,
    );
  }
}

class MainNotifier extends Notifier<MainState> {
  // // AkonDeV 06/2026
  Timer? _slideshowTimer;

  @override
  MainState build() {
    ref.onDispose(() => _slideshowTimer?.cancel());
    Future.microtask(_init);
    return MainState();
  }

  // Acceso lazy a servicios via ref (Riverpod 3.x)
  WallhavenService get _wallhavenService => ref.read(whServiceProvider);
  ImageProcessorService get _imageProcessorService => ref.read(imgProcessorServiceProvider);
  DatabaseService get _databaseService => ref.read(dbServiceProvider);
  ConfigurationService get _configService => ref.read(configServiceProvider);
  ImageCacheService get _imageCacheService => ref.read(cacheServiceProvider);

  Future<void> _init() async {
    // // AkonDeV 06/2026
    await _databaseService.initializeDatabase();
    final config = await _configService.loadConfig();
    state = state.copyWith(appConfig: config);
    await loadFavorites();
    await loadHistory();
    await getRandomWallpaper();
  }

  Future<void> updateSettings(AppConfig newConfig) async {
    // // AkonDeV 06/2026
    state = state.copyWith(appConfig: newConfig);
    await _configService.saveConfig(newConfig);
    state = state.copyWith(statusMessage: 'Configuración guardada exitosamente.');
  }

  List<Wallpaper> getActiveNavigationList() {
    // // AkonDeV 06/2026
    if (state.selectedTabIndex == 1) {
      return state.favoriteWallpapers;
    }
    return state.wallpapers;
  }

  String get imagePositionText {
    // // AkonDeV 06/2026
    final list = getActiveNavigationList();
    if (list.isEmpty || state.selectedWallpaper == null) return 'Sin imágenes';
    int index = list.indexOf(state.selectedWallpaper!) + 1;
    if (index <= 0) return 'Sin imágenes';
    return 'Imagen $index de ${list.length}';
  }

  Future<void> updateSelectedWallpaper(Wallpaper? wp) async {
    // // AkonDeV 06/2026
    if (wp == null) {
      state = state.copyWith(
        displayedImagePath: '',
        isFavorite: false,
        nullSelectedWallpaper: true,
      );
      return;
    }

    state = state.copyWith(
      selectedWallpaper: wp,
      isLoading: true,
      statusMessage: 'Cargando imagen...',
    );

    try {
      final localPath = await _imageCacheService.getCachedImagePath(wp.id, wp.path);
      if (!ref.mounted) return; // Guard Riverpod 3.x
      final isFav = await _databaseService.isFavorite(wp.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        displayedImagePath: localPath,
        isFavorite: isFav,
        statusMessage: 'Mostrando wallpaper ID: ${wp.id}',
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      final isFav = await _databaseService.isFavorite(wp.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        displayedImagePath: wp.path,
        isFavorite: isFav,
        statusMessage: 'Error al cachear; mostrando imagen remota.',
        isLoading: false,
      );
    }
  }

  Future<void> searchNewQuery() async {
    // // AkonDeV 06/2026
    state = state.copyWith(currentPage: 1);
    await executeSearch();
  }

  Future<void> executeSearch() async {
    // // AkonDeV 06/2026
    state = state.copyWith(isLoading: true, statusMessage: 'Buscando wallpapers...', downloadProgress: 0);

    try {
      final config = await _configService.loadConfig();
      if (!ref.mounted) return;
      _wallhavenService.apiKey = config.apiKey;

      final categories = '${state.categoriesGeneral ? 1 : 0}${state.categoriesAnime ? 1 : 0}${state.categoriesPeople ? 1 : 0}';
      final purity = '${state.puritySfw ? 1 : 0}${state.puritySketchy ? 1 : 0}${state.purityNsfw ? 1 : 0}';

      final result = await _wallhavenService.searchWallpapers(
        query: state.searchQuery,
        categories: categories,
        purity: purity,
        sorting: state.selectedSorting,
        order: state.selectedOrder,
        ratios: state.selectedSorting == 'random' ? '16x9,16x10,21x9' : '',
        page: state.currentPage,
      );
      if (!ref.mounted) return;

      final List<Wallpaper> list = result['wallpapers'];
      final int lastPage = result['lastPage'];

      state = state.copyWith(
        wallpapers: list,
        maxPages: lastPage,
      );

      if (list.isNotEmpty) {
        await updateSelectedWallpaper(list.first);
        if (!ref.mounted) return;
        state = state.copyWith(
          statusMessage: 'Encontrados ${list.length} elementos. Página ${state.currentPage} de $lastPage',
        );
      } else {
        state = state.copyWith(
          nullSelectedWallpaper: true,
          statusMessage: 'No se encontraron resultados.',
        );
      }

      await _databaseService.saveSearchHistory(state.searchQuery, '{}');
      if (!ref.mounted) return;
      await loadHistory();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        statusMessage: 'Error al conectar con Wallhaven.',
        isLoading: false,
      );
    }
  }

  Future<void> goToNextPage() async {
    // // AkonDeV 06/2026
    if (state.currentPage < state.maxPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      await executeSearch();
    }
  }

  Future<void> goToPreviousPage() async {
    // // AkonDeV 06/2026
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      await executeSearch();
    }
  }

  bool canNavigateNext() {
    // // AkonDeV 06/2026
    if (state.selectedWallpaper == null) return false;
    final list = getActiveNavigationList();
    if (list.isEmpty) return false;
    final idx = list.indexOf(state.selectedWallpaper!);
    return idx >= 0 && idx < list.length - 1;
  }

  bool canNavigatePrevious() {
    // // AkonDeV 06/2026
    if (state.selectedWallpaper == null) return false;
    final list = getActiveNavigationList();
    if (list.isEmpty) return false;
    final idx = list.indexOf(state.selectedWallpaper!);
    return idx > 0;
  }

  bool canNavigateFirst() {
    // // AkonDeV 06/2026
    return canNavigatePrevious();
  }

  bool canNavigateLast() {
    // // AkonDeV 06/2026
    return canNavigateNext();
  }

  void navigateNext() {
    // // AkonDeV 06/2026
    if (!canNavigateNext()) return;
    final list = getActiveNavigationList();
    final idx = list.indexOf(state.selectedWallpaper!);
    updateSelectedWallpaper(list[idx + 1]);
  }

  void navigatePrevious() {
    // // AkonDeV 06/2026
    if (!canNavigatePrevious()) return;
    final list = getActiveNavigationList();
    final idx = list.indexOf(state.selectedWallpaper!);
    updateSelectedWallpaper(list[idx - 1]);
  }

  void navigateFirst() {
    // // AkonDeV 06/2026
    final list = getActiveNavigationList();
    if (list.isNotEmpty) {
      updateSelectedWallpaper(list.first);
    }
  }

  void navigateLast() {
    // // AkonDeV 06/2026
    final list = getActiveNavigationList();
    if (list.isNotEmpty) {
      updateSelectedWallpaper(list.last);
    }
  }

  Future<void> downloadOriginal() async {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;
    if (wp == null) return;

    state = state.copyWith(isLoading: true, statusMessage: 'Descargando original...', downloadProgress: 0);

    try {
      final config = await _configService.loadConfig();
      String targetFolder = config.downloadDirectory;
      if (targetFolder.isEmpty) {
        final picDir = await getTemporaryDirectory(); // Fallback temporal en Flutter
        targetFolder = p.join(picDir.path, 'WallhavenDownloads');
      }

      final ext = p.extension(wp.path).isEmpty ? '.jpg' : p.extension(wp.path);
      final targetPath = p.join(targetFolder, '${wp.id}$ext');

      if (await File(targetPath).exists()) {
        state = state.copyWith(statusMessage: 'El archivo ya existe localmente.', isLoading: false);
        return;
      }

      await _wallhavenService.downloadFile(
        wp.path,
        targetPath,
        onProgress: (prog) => state = state.copyWith(downloadProgress: prog),
      );

      state = state.copyWith(
        statusMessage: 'Descarga finalizada con éxito en: $targetPath',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(statusMessage: 'Fallo en la descarga de archivos.', isLoading: false);
    }
  }

  Future<void> createMobileVersion({
    int? cropX,
    int? cropY,
    int? cropWidth,
    int? cropHeight,
  }) async {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;
    if (wp == null) return;

    state = state.copyWith(isLoading: true, statusMessage: 'Iniciando procesamiento móvil...', downloadProgress: 0);

    try {
      final config = await _configService.loadConfig();
      final sourcePath = await _imageCacheService.getCachedImagePath(wp.id, wp.path);

      if (!await File(sourcePath).exists()) {
        state = state.copyWith(statusMessage: 'No se pudo obtener la imagen origen local.', isLoading: false);
        return;
      }

      int width = 1080;
      int height = 1920;
      final res = state.selectedResizeResolution;
      final parts = res.split('x');
      if (parts.length == 2) {
        width = int.tryParse(parts[0]) ?? 1080;
        height = int.tryParse(parts[1]) ?? 1920;
      }

      String targetFolder = config.mobileDirectory;
      if (targetFolder.isEmpty) {
        final picDir = await getTemporaryDirectory();
        targetFolder = p.join(picDir.path, 'WallhavenMobile');
      }

      final ext = p.extension(wp.path).isEmpty ? '.jpg' : p.extension(wp.path);

      if (cropX != null && cropY != null && cropWidth != null && cropHeight != null) {
        // Modo de recorte manual
        final targetPath = p.join(targetFolder, '${wp.id}_${width}x${height}_manual$ext');
        state = state.copyWith(statusMessage: 'Recortando y redimensionando imagen manualmente...');
        await _imageProcessorService.processCustomCrop(
          sourcePath: sourcePath,
          targetPath: targetPath,
          targetWidth: width,
          targetHeight: height,
          cropX: cropX,
          cropY: cropY,
          cropWidth: cropWidth,
          cropHeight: cropHeight,
        );
        state = state.copyWith(
          statusMessage: 'Versión móvil recortada guardada en: $targetPath',
          isLoading: false,
        );
      } else {
        // Modo de redimensionamiento automático
        ResizeMode mode = ResizeMode.smartCropCentred;
        if (state.selectedResizeMode == 'LetterboxBlack') {
          mode = ResizeMode.letterboxBlack;
        } else if (state.selectedResizeMode == 'ScaleMaintainAspect') {
          mode = ResizeMode.scaleMaintainAspect;
        }
        final targetPath = p.join(targetFolder, '${wp.id}_${width}x${height}_${mode.name}$ext');
        state = state.copyWith(statusMessage: 'Procesando y redimensionando imagen...');
        await _imageProcessorService.processMobileResize(
          sourcePath: sourcePath,
          targetPath: targetPath,
          targetWidth: width,
          targetHeight: height,
          mode: mode,
        );
        state = state.copyWith(
          statusMessage: 'Versión móvil guardada con éxito en: $targetPath',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(statusMessage: 'Fallo al procesar la imagen móvil.', isLoading: false);
    }
  }

  Future<void> toggleFavorite() async {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;
    if (wp == null) return;

    try {
      if (state.isFavorite) {
        await _databaseService.removeFavorite(wp.id);
        state = state.copyWith(isFavorite: false, statusMessage: 'Eliminado de favoritos.');
      } else {
        await _databaseService.saveFavorite(wp);
        state = state.copyWith(isFavorite: true, statusMessage: 'Añadido a favoritos.');
      }
      await loadFavorites();
    } catch (e) {
      state = state.copyWith(statusMessage: 'Error al actualizar favoritos.');
    }
  }

  Future<void> loadFavorites() async {
    // // AkonDeV 06/2026
    try {
      final list = await _databaseService.getFavorites();
      state = state.copyWith(favoriteWallpapers: list);
    } catch (_) {}
  }

  Future<void> loadHistory() async {
    // // AkonDeV 06/2026
    try {
      final history = await _databaseService.getSearchHistory(20);
      final list = history.map((item) => item['queryText'] as String).toList();
      state = state.copyWith(searchHistory: list);
    } catch (_) {}
  }

  Future<void> searchQueryFromHistory(String query) async {
    // // AkonDeV 06/2026
    if (query.isEmpty) return;
    state = state.copyWith(searchQuery: query, currentPage: 1);
    await executeSearch();
  }

  void toggleSlideshow() {
    // // AkonDeV 06/2026
    if (state.isSlideshowActive) {
      state = state.copyWith(isSlideshowActive: false, statusMessage: 'Slideshow pausado.');
      _slideshowTimer?.cancel();
      _slideshowTimer = null;
    } else {
      state = state.copyWith(isSlideshowActive: true, statusMessage: 'Slideshow iniciado.');
      _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        final list = state.wallpapers;
        final wp = state.selectedWallpaper;
        if (list.isEmpty || wp == null) return;

        final idx = list.indexOf(wp);
        if (idx < list.length - 1) {
          updateSelectedWallpaper(list[idx + 1]);
        } else {
          if (state.currentPage < state.maxPages) {
            state = state.copyWith(currentPage: state.currentPage + 1);
            await executeSearch();
          } else {
            updateSelectedWallpaper(list.first);
          }
        }
      });
    }
  }

  Future<void> getRandomWallpaper() async {
    // // AkonDeV 06/2026
    state = state.copyWith(
      selectedSorting: 'random',
      searchQuery: '',
      currentPage: 1,
    );
    await executeSearch();
  }

  Future<void> copyUrlToClipboard() async {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;
    if (wp == null) return;
    await Clipboard.setData(ClipboardData(text: wp.url));
    state = state.copyWith(statusMessage: 'URL copiada al portapapeles.');
  }

  Future<void> openInBrowser() async {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;
    if (wp == null || wp.url.isEmpty) return;
    final uri = Uri.parse(wp.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      state = state.copyWith(statusMessage: 'Abriendo en el navegador...');
    } else {
      state = state.copyWith(statusMessage: 'No se pudo abrir el navegador.');
    }
  }

  void toggleGridView() {
    // // AkonDeV 06/2026
    state = state.copyWith(isGridViewActive: !state.isGridViewActive);
  }

  void toggleDetailsPanel() {
    // // AkonDeV 06/2026
    state = state.copyWith(isDetailsPanelOpen: !state.isDetailsPanelOpen);
  }

  void setSelectedTabIndex(int idx) {
    // // AkonDeV 06/2026
    state = state.copyWith(selectedTabIndex: idx);
  }

  void setSearchQuery(String q) {
    // // AkonDeV 06/2026
    state = state.copyWith(searchQuery: q);
  }

  void updateCategories({bool? gen, bool? anime, bool? people}) {
    // // AkonDeV 06/2026
    state = state.copyWith(
      categoriesGeneral: gen ?? state.categoriesGeneral,
      categoriesAnime: anime ?? state.categoriesAnime,
      categoriesPeople: people ?? state.categoriesPeople,
    );
  }

  void updatePurity({bool? sfw, bool? sketchy, bool? nsfw}) {
    // // AkonDeV 06/2026
    state = state.copyWith(
      puritySfw: sfw ?? state.puritySfw,
      puritySketchy: sketchy ?? state.puritySketchy,
      purityNsfw: nsfw ?? state.purityNsfw,
    );
  }

  void updateSorting(String val) {
    // // AkonDeV 06/2026
    state = state.copyWith(selectedSorting: val);
  }

  void updateOrder(String val) {
    // // AkonDeV 06/2026
    state = state.copyWith(selectedOrder: val);
  }

  void updateResizeResolution(String val) {
    // // AkonDeV 06/2026
    state = state.copyWith(selectedResizeResolution: val);
  }

  void updateResizeMode(String val) {
    // // AkonDeV 06/2026
    state = state.copyWith(
      selectedResizeMode: val,
      isCropModeActive: val == 'ManualCrop',
    );
  }

  void setFullScreen(bool val) {
    // // AkonDeV 06/2026
    state = state.copyWith(isFullScreen: val);
  }

}

// Providers globales para inyección (Riverpod 3.x)
final dioProvider = Provider<Dio>((ref) => Dio());

final configServiceProvider = Provider<ConfigurationService>((ref) => ConfigurationService());

final dbServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final whServiceProvider = Provider<WallhavenService>((ref) {
  final dio = ref.watch(dioProvider);
  return WallhavenService(dio);
});

final imgProcessorServiceProvider = Provider<ImageProcessorService>((ref) => ImageProcessorService());

final cacheServiceProvider = Provider<ImageCacheService>((ref) {
  final dio = ref.watch(dioProvider);
  return ImageCacheService(dio);
});

// NotifierProvider reemplaza StateNotifierProvider en Riverpod 3.x
final mainProvider = NotifierProvider<MainNotifier, MainState>(
  MainNotifier.new,
);
