// // AkonDeV 06/2026

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/main_provider.dart';
import '../models/wallpaper.dart';
import '../models/app_config.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  late TransformationController _transformationController;
  final GlobalKey _viewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // // AkonDeV 06/2026
    final state = ref.watch(mainProvider);
    final notifier = ref.read(mainProvider.notifier);

    // Escuchar cambios del wallpaper para reiniciar la vista de transformación
    ref.listen<Wallpaper?>(
      mainProvider.select((s) => s.selectedWallpaper),
      (previous, next) {
        if (previous?.id != next?.id) {
          _transformationController.value = Matrix4.identity();
        }
      },
    );

    // Ajustar visibilidad general según modo pantalla completa
    final bool showPanels = !state.isFullScreen;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Row(
        children: [
          // 1. Barra de Navegación Lateral Izquierda
          if (showPanels) _buildLeftNavBar(context, state, notifier),

          // 2. Cuerpo Principal
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Tab Content (Grilla, Favoritos, Historial)
                      Expanded(
                        child: IndexedStack(
                          index: state.selectedTabIndex,
                          children: [
                            _buildSearchTab(context, state, notifier),
                            _buildFavoritesTab(context, state, notifier),
                            _buildHistoryTab(context, state, notifier),
                          ],
                        ),
                      ),

                      // 3. Barra de Detalles Derecha
                      if (showPanels && state.isDetailsPanelOpen)
                        _buildDetailsPanel(context, state, notifier),
                    ],
                  ),
                ),

                // Barra de Estado inferior (si no está en pantalla completa)
                if (showPanels) _buildStatusBar(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Barra de Navegación Lateral
  Widget _buildLeftNavBar(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Container(
      width: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF15151A),
        border: Border(right: BorderSide(color: Color(0xFF25252D), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNavIcon(
            icon: Icons.search,
            label: 'Buscar',
            isSelected: state.selectedTabIndex == 0,
            onTap: () => notifier.setSelectedTabIndex(0),
          ),
          _buildNavIcon(
            icon: Icons.star,
            label: 'Favoritos',
            isSelected: state.selectedTabIndex == 1,
            onTap: () => notifier.setSelectedTabIndex(1),
          ),
          _buildNavIcon(
            icon: Icons.history,
            label: 'Historial',
            isSelected: state.selectedTabIndex == 2,
            onTap: () => notifier.setSelectedTabIndex(2),
          ),
          const Spacer(),
          _buildNavIcon(
            icon: Icons.settings,
            label: 'Ajustes',
            isSelected: false,
            onTap: () => _showSettingsDialog(context, state, notifier),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // // AkonDeV 06/2026
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        width: 70,
        color: isSelected ? const Color(0xFF20202B) : Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                child: Container(
                  width: 4,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? const Color(0xFF7C4DFF) : const Color(0xFF8E8E93), size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pestaña 0: Búsqueda y Resultados
  Widget _buildSearchTab(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    final bool showFilters = !state.isFullScreen;

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          // Barra de filtros superior
          if (showFilters) _buildSearchHeader(state, notifier),

          // Área Central Dividida (Grilla y Visor)
          Expanded(
            child: Row(
              children: [
                // Grilla de miniaturas
                if (state.isGridViewActive && !state.isFullScreen)
                  Expanded(
                    flex: 4,
                    child: _buildWallpaperGrid(state.wallpapers, state, notifier),
                  ),

                // Separador
                if (state.isGridViewActive && !state.isFullScreen)
                  const SizedBox(width: 12),

                // Visor de Imagen
                Expanded(
                  flex: 6,
                  child: _buildInteractiveViewer(state, notifier),
                ),
              ],
            ),
          ),

          // Paginación inferior
          if (showFilters) const SizedBox(height: 12),
          if (showFilters) _buildPaginator(state, notifier),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D2D37)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: TextEditingController(text: state.searchQuery)
                      ..selection = TextSelection.fromPosition(TextPosition(offset: state.searchQuery.length)),
                    onChanged: notifier.setSearchQuery,
                    onSubmitted: (_) => notifier.searchNewQuery(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar fondos de pantalla...',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      fillColor: const Color(0xFF121214),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF3D3D4C)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: state.isLoading ? null : () => notifier.searchNewQuery(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  minimumSize: const Size(100, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Buscar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Categorías: ', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold)),
              _buildCheckbox('General', state.categoriesGeneral, (val) => notifier.updateCategories(gen: val)),
              _buildCheckbox('Anime', state.categoriesAnime, (val) => notifier.updateCategories(anime: val)),
              _buildCheckbox('People', state.categoriesPeople, (val) => notifier.updateCategories(people: val)),
              const SizedBox(width: 15),
              const Text('Pureza: ', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold)),
              _buildCheckbox('SFW', state.puritySfw, (val) => notifier.updatePurity(sfw: val)),
              _buildCheckbox('Sketchy', state.puritySketchy, (val) => notifier.updatePurity(sketchy: val)),
              _buildCheckbox('NSFW', state.purityNsfw, (val) => notifier.updatePurity(nsfw: val)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    // // AkonDeV 06/2026
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF7C4DFF),
          checkColor: Colors.white,
          side: const BorderSide(color: Color(0xFF8E8E93)),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  // Grilla de Tarjetas
  Widget _buildWallpaperGrid(List<Wallpaper> list, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D2D37)),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final wp = list[index];
          final bool isSelected = state.selectedWallpaper?.id == wp.id;

          return GestureDetector(
            onTap: () => notifier.updateSelectedWallpaper(wp),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00B0FF) : const Color(0xFF2A2A35),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(wp.thumbnailUrl, fit: BoxFit.cover),
                    // Sombreado gradiente
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Text(
                        wp.resolution,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F42C1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          wp.category.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Visor Interactivo
  Widget _buildInteractiveViewer(MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D2D37)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barra de Herramientas Superior del Visor
          Container(
            color: const Color(0xFF18181C),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                const Spacer(),
                // Alternar Grilla
                IconButton(
                  icon: const Icon(Icons.grid_view, color: Colors.white, size: 18),
                  tooltip: 'Mostrar/Ocultar Grilla',
                  onPressed: () => notifier.toggleGridView(),
                ),
                // Alternar Info
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  tooltip: 'Mostrar/Ocultar Info',
                  onPressed: () => notifier.toggleDetailsPanel(),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  tooltip: 'Copiar URL',
                  onPressed: () => notifier.copyUrlToClipboard(),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                  tooltip: 'Ver en Web',
                  onPressed: () => notifier.openInBrowser(),
                ),
                IconButton(
                  icon: const Icon(Icons.casino, color: Colors.purpleAccent, size: 18),
                  tooltip: 'Aleatorio',
                  onPressed: () => notifier.getRandomWallpaper(),
                ),
                // Slideshow
                IconButton(
                  icon: Icon(
                    state.isSlideshowActive ? Icons.pause : Icons.play_arrow,
                    color: state.isSlideshowActive ? Colors.redAccent : Colors.greenAccent,
                    size: 18,
                  ),
                  tooltip: 'Slideshow',
                  onPressed: () => notifier.toggleSlideshow(),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.blueAccent, size: 18),
                  tooltip: 'Pantalla Completa',
                  onPressed: () => notifier.setFullScreen(!state.isFullScreen),
                ),
              ],
            ),
          ),

          // Pantalla del Visor Principal (InteractiveViewer para Zoom/Pan nativo y Recorte Manual)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double wContainer = constraints.maxWidth;
                final double hContainer = constraints.maxHeight;

                // Calcular el tamaño inicial de la imagen (BoxFit.contain)
                final parts = state.selectedWallpaper?.resolution.split('x') ?? ['1920', '1080'];
                final double originalWidth = double.tryParse(parts[0]) ?? 1920.0;
                final double originalHeight = double.tryParse(parts[1]) ?? 1080.0;

                final double imageRatio = originalWidth / originalHeight;
                final double containerRatio = wContainer / hContainer;

                double wRender;
                double hRender;
                if (imageRatio > containerRatio) {
                  wRender = wContainer;
                  hRender = wContainer / imageRatio;
                } else {
                  hRender = hContainer;
                  wRender = hContainer * imageRatio;
                }

                // Relación de aspecto del visor del móvil
                final resParts = state.selectedResizeResolution.split('x');
                double targetWidth = 1080.0;
                double targetHeight = 1920.0;
                if (resParts.length == 2) {
                  targetWidth = double.tryParse(resParts[0]) ?? 1080.0;
                  targetHeight = double.tryParse(resParts[1]) ?? 1920.0;
                }
                final double targetRatio = targetWidth / targetHeight;

                // Calcular tamaño de la guía móvil
                double hFrame = hContainer * 0.85;
                double wFrame = hFrame * targetRatio;
                if (wFrame > wContainer * 0.85) {
                  wFrame = wContainer * 0.85;
                  hFrame = wFrame / targetRatio;
                }
                final Size frameSize = Size(wFrame, hFrame);

                return Container(
                  key: _viewerKey,
                  color: const Color(0xFF121214),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (state.displayedImagePath.isNotEmpty)
                        InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.1,
                          maxScale: 10.0,
                          child: SizedBox(
                            width: wContainer,
                            height: hContainer,
                            child: Center(
                              child: SizedBox(
                                width: wRender,
                                height: hRender,
                                child: state.displayedImagePath.startsWith('http')
                                    ? Image.network(state.displayedImagePath, fit: BoxFit.fill)
                                    : Image.file(File(state.displayedImagePath), fit: BoxFit.fill),
                              ),
                            ),
                          ),
                        ),

                      // Overlay de guía móvil con notch y regla de tercios
                      if (state.isCropModeActive && state.displayedImagePath.isNotEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(wContainer, hContainer),
                            painter: CropOverlayPainter(frameSize),
                          ),
                        ),

                      // Banner informativo premium
                      if (state.isCropModeActive && state.displayedImagePath.isNotEmpty)
                        Positioned(
                          top: 15,
                          left: 15,
                          right: 15,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.crop, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Recorte Manual: Ubica la imagen dentro de la guía móvil',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Skeleton Loading
                      if (state.isLoading)
                        const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF7C4DFF)))),
                    ],
                  ),
                );
              },
            ),
          ),

          // Barra de Navegación inferior interna
          Container(
            color: const Color(0xFF18181C),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page, color: Colors.white),
                  onPressed: notifier.canNavigateFirst() ? () => notifier.navigateFirst() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: notifier.canNavigatePrevious() ? () => notifier.navigatePrevious() : null,
                ),
                const SizedBox(width: 10),
                Text(
                  notifier.imagePositionText,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: notifier.canNavigateNext() ? () => notifier.navigateNext() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, color: Colors.white),
                  onPressed: notifier.canNavigateLast() ? () => notifier.navigateLast() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Paginador de Páginas
  Widget _buildPaginator(MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: state.currentPage > 1 ? () => notifier.goToPreviousPage() : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E2E38)),
          child: const Text('◀◀ Pág. Anterior', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 20),
        Text(
          'Página ${state.currentPage} de ${state.maxPages}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: state.currentPage < state.maxPages ? () => notifier.goToNextPage() : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E2E38)),
          child: const Text('Pág. Siguiente ▶▶', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // Pestaña 1: Favoritos
  Widget _buildFavoritesTab(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MIS FAVORITOS', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: _buildWallpaperGrid(state.favoriteWallpapers, state, notifier),
          ),
        ],
      ),
    );
  }

  // Pestaña 2: Historial
  Widget _buildHistoryTab(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BÚSQUEDAS RECIENTES', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D2D37)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.searchHistory.length,
                itemBuilder: (context, index) {
                  final item = state.searchHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.search, color: Color(0xFF7C4DFF)),
                    title: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      notifier.searchQueryFromHistory(item);
                      notifier.setSelectedTabIndex(0);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Panel de Detalles Derecho
  Widget _buildDetailsPanel(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    final wp = state.selectedWallpaper;

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24),
        border: Border(left: BorderSide(color: Color(0xFF2D2D37), width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('DETALLE DE IMAGEN', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => notifier.toggleDetailsPanel(),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Miniatura
            if (wp != null)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF33333C)),
                  image: DecorationImage(
                    image: NetworkImage(wp.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 15),

            // Tarjeta de información
            if (wp != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121214),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2D2D37)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${wp.id}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Resolución: ${wp.resolution}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Categoría: ${wp.category}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Autor: ${wp.uploader}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 15),

            // Favorito e Impl
            if (wp != null)
              ElevatedButton.icon(
                onPressed: () => notifier.toggleFavorite(),
                icon: Icon(
                  state.isFavorite ? Icons.star : Icons.star_border,
                  color: state.isFavorite ? const Color(0xFFFFC107) : const Color(0xFF8E8E93), // Gold for favorite, silver/grey otherwise
                  size: 18,
                ),
                label: Text(
                  state.isFavorite ? 'Quitar de Favoritos' : 'Añadir a Favoritos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isFavorite ? const Color(0xFF2A241F) : const Color(0xFF25252D), // Subtle amber-dark tint when favorite, neutral dark otherwise
                  minimumSize: const Size(double.infinity, 40),
                  side: BorderSide(
                    color: state.isFavorite ? const Color(0xFF8C6D23) : const Color(0xFF3D3D4C), // Gold/Amber border when active
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            const SizedBox(height: 10),

            if (wp != null)
              ElevatedButton.icon(
                onPressed: () => notifier.downloadOriginal(),
                icon: const Icon(Icons.download, color: Color(0xFF2ECC71), size: 18), // Emerald green icon (soft accent)
                label: const Text(
                  'Descargar Original',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25252D), // Neutral dark
                  minimumSize: const Size(double.infinity, 40),
                  side: const BorderSide(color: Color(0xFF3D3D4C), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            const SizedBox(height: 20),

            // Redimensionador móvil
            if (wp != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121214),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2D2D37)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REDIMENSIONAR MÓVIL', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Resolución:', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 10)),
                    const SizedBox(height: 4),
                    _buildDropdown(
                      value: state.selectedResizeResolution,
                      items: ['1080x1920', '1440x2560', '720x1280'],
                      onChanged: (val) => notifier.updateResizeResolution(val!),
                    ),
                    const SizedBox(height: 12),
                    const Text('Modo de Ajuste:', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 10)),
                    const SizedBox(height: 4),
                    _buildDropdown(
                      value: state.selectedResizeMode,
                      items: ['SmartCropCentred', 'LetterboxBlack', 'ScaleMaintainAspect', 'ManualCrop'],
                      onChanged: (val) => notifier.updateResizeMode(val!),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () => _handleCreateMobileVersion(state, notifier),
                      icon: const Icon(Icons.crop, color: Colors.white, size: 16),
                      label: const Text(
                        'Crear Versión Móvil',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3F47), // Neutral dark slate primary action button
                        minimumSize: const Size(double.infinity, 42),
                        side: const BorderSide(color: Color(0xFF505662), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => notifier.openMobileDirectory(),
                      icon: const Icon(Icons.folder_open, color: Color(0xFFAAAAAA), size: 16),
                      label: const Text(
                        'Abrir Carpeta de Destino',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25252D), // Neutral secondary action button
                        minimumSize: const Size(double.infinity, 40),
                        side: const BorderSide(color: Color(0xFF3D3D4C), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // // AkonDeV 06/2026
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3D3D4C)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Barra de Estado
  Widget _buildStatusBar(MainState state) {
    // // AkonDeV 06/2026
    return Container(
      color: const Color(0xFF18181C),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.statusMessage,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
            ),
          ),
          if (state.downloadProgress > 0 && state.downloadProgress < 100)
            Text(
              'Descarga: ${state.downloadProgress.toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, MainState state, MainNotifier notifier) {
    // // AkonDeV 06/2026
    final apiKeyController = TextEditingController(text: state.appConfig.apiKey);
    final downloadDirController = TextEditingController(text: state.appConfig.downloadDirectory);
    final mobileDirController = TextEditingController(text: state.appConfig.mobileDirectory);
    String selectedResize = state.appConfig.defaultResizeSize;
    String selectedTheme = state.appConfig.theme;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D37)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings, color: Color(0xFF7C4DFF), size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'CONFIGURACIÓN MAESTRA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF2D2D37)),
                      const SizedBox(height: 16),
                      const Text(
                        'WALLHAVEN API KEY',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: apiKeyController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Pega tu API Key de Wallhaven aquí...',
                          hintStyle: const TextStyle(color: Color(0xFF555566)),
                          fillColor: const Color(0xFF0F0F12),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF3D3D4C)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'CARPETA DE DESCARGAS',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: downloadDirController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ruta absoluta (Ej: C:/Downloads/Wallhaven)',
                                hintStyle: const TextStyle(color: Color(0xFF555566)),
                                fillColor: const Color(0xFF0F0F12),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF3D3D4C)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final String? selectedDirectory = await FilePicker.getDirectoryPath();
                              if (selectedDirectory != null) {
                                downloadDirController.text = selectedDirectory;
                              }
                            },
                            icon: const Icon(Icons.folder_open, size: 16, color: Colors.white),
                            label: const Text('Examinar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2D37),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'CARPETA REESCALADO MÓVIL',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mobileDirController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ruta absoluta (Ej: C:/Downloads/WallhavenMobile)',
                                hintStyle: const TextStyle(color: Color(0xFF555566)),
                                fillColor: const Color(0xFF0F0F12),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF3D3D4C)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final String? selectedDirectory = await FilePicker.getDirectoryPath();
                              if (selectedDirectory != null) {
                                mobileDirController.text = selectedDirectory;
                              }
                            },
                            icon: const Icon(Icons.folder_open, size: 16, color: Colors.white),
                            label: const Text('Examinar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2D37),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RESOLUCIÓN MÓVIL DEFECTO',
                                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF3D3D4C)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedResize,
                                      dropdownColor: const Color(0xFF0F0F12),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      isExpanded: true,
                                      items: ['1080x1920', '1440x2560', '720x1280'].map((i) {
                                        return DropdownMenuItem(value: i, child: Text(i));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => selectedResize = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TEMA VISUAL',
                                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF3D3D4C)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedTheme,
                                      dropdownColor: const Color(0xFF0F0F12),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      isExpanded: true,
                                      items: ['Dark', 'Light'].map((i) {
                                        return DropdownMenuItem(value: i, child: Text(i));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => selectedTheme = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8E8E93))),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final newConfig = AppConfig(
                                apiKey: apiKeyController.text.trim(),
                                downloadDirectory: downloadDirController.text.trim(),
                                mobileDirectory: mobileDirController.text.trim(),
                                defaultResizeSize: selectedResize,
                                theme: selectedTheme,
                              );
                              await notifier.updateSettings(newConfig);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Guardar Ajustes',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCreateMobileVersion(MainState state, MainNotifier notifier) {
    final wp = state.selectedWallpaper;
    if (wp == null) return;

    if (!state.isCropModeActive) {
      notifier.createMobileVersion();
      return;
    }

    final renderBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      notifier.createMobileVersion();
      return;
    }

    final double wContainer = renderBox.size.width;
    final double hContainer = renderBox.size.height;

    // 1. Obtener la resolución original de la imagen
    final parts = wp.resolution.split('x');
    if (parts.length != 2) {
      notifier.createMobileVersion();
      return;
    }
    final double originalWidth = double.tryParse(parts[0]) ?? 1920.0;
    final double originalHeight = double.tryParse(parts[1]) ?? 1080.0;

    // 2. Obtener la resolución de reescalado objetivo (ej. '1080x1920')
    final resParts = state.selectedResizeResolution.split('x');
    double targetWidth = 1080.0;
    double targetHeight = 1920.0;
    if (resParts.length == 2) {
      targetWidth = double.tryParse(resParts[0]) ?? 1080.0;
      targetHeight = double.tryParse(resParts[1]) ?? 1920.0;
    }

    // Aspect ratio del visor móvil
    final double targetRatio = targetWidth / targetHeight;

    // 3. Calcular tamaño del marco de recorte en la pantalla (viewport lógico)
    double hFrame = hContainer * 0.85;
    double wFrame = hFrame * targetRatio;

    if (wFrame > wContainer * 0.85) {
      wFrame = wContainer * 0.85;
      hFrame = wFrame / targetRatio;
    }

    // 4. Calcular el tamaño de la imagen renderizada al inicio (BoxFit.contain)
    final double imageRatio = originalWidth / originalHeight;
    final double containerRatio = wContainer / hContainer;

    double wRender;
    double hRender;
    if (imageRatio > containerRatio) {
      wRender = wContainer;
      hRender = wContainer / imageRatio;
    } else {
      hRender = hContainer;
      wRender = hContainer * imageRatio;
    }

    // Offset de la imagen inicial dentro del contenedor
    final double xImgOffset = (wContainer - wRender) / 2;
    final double yImgOffset = (hContainer - hRender) / 2;

    // Posición del marco de recorte en coordenadas locales del contenedor
    final double xTl = (wContainer - wFrame) / 2;
    final double yTl = (hContainer - hFrame) / 2;

    // 5. Extraer escala y traducciones de la matriz de transformación (storage column-major)
    final Matrix4 matrix = _transformationController.value;
    final double sVal = matrix.storage[0];  // Escala X (m11)
    final double xVal = matrix.storage[12]; // Traslación X (tx)
    final double yVal = matrix.storage[13]; // Traslación Y (ty)

    // 6. Mapear coordenadas lógicas al espacio de la imagen renderizada
    final double xCropRendered = (xTl - xVal) / sVal - xImgOffset;
    final double yCropRendered = (yTl - yVal) / sVal - yImgOffset;
    final double wCropRendered = wFrame / sVal;
    final double hCropRendered = hFrame / sVal;

    // 7. Mapear coordenadas al espacio de la imagen física original
    final double rx = originalWidth / wRender;
    final double ry = originalHeight / hRender;

    int cropX = (xCropRendered * rx).round();
    int cropY = (yCropRendered * ry).round();
    int cropWidth = (wCropRendered * rx).round();
    int cropHeight = (hCropRendered * ry).round();

    // 8. Validar límites y restringir al tamaño original de la imagen
    if (cropX < 0) {
      cropWidth += cropX;
      cropX = 0;
    }
    if (cropY < 0) {
      cropHeight += cropY;
      cropY = 0;
    }
    if (cropX + cropWidth > originalWidth) {
      cropWidth = (originalWidth - cropX).round();
    }
    if (cropY + cropHeight > originalHeight) {
      cropHeight = (originalHeight - cropY).round();
    }

    // Si por algún zoom extremo el tamaño es inválido, usar por defecto
    if (cropWidth <= 0 || cropHeight <= 0) {
      notifier.createMobileVersion();
      return;
    }

    notifier.createMobileVersion(
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Size frameSize;

  CropOverlayPainter(this.frameSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Camino exterior (todo el visor)
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Camino interior (el hueco transparente del móvil)
    final double left = (size.width - frameSize.width) / 2;
    final double top = (size.height - frameSize.height) / 2;
    final innerRect = Rect.fromLTWH(left, top, frameSize.width, frameSize.height);
    final innerPath = Path()..addRect(innerRect);

    // Combinar restando el interior al exterior para crear el hueco
    final combinedPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(combinedPath, paint);

    // Borde de la guía del teléfono
    final borderPaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(innerRect, borderPaint);

    // Notch del teléfono
    final notchRect = Rect.fromLTWH(size.width / 2 - 35, top + 6, 70, 14);
    final notchPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(notchRect, const Radius.circular(7)), notchPaint);

    // Cuadrícula interior (regla de los tercios)
    final guidePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Guías verticales
    canvas.drawLine(Offset(left + frameSize.width / 3, top), Offset(left + frameSize.width / 3, top + frameSize.height), guidePaint);
    canvas.drawLine(Offset(left + 2 * frameSize.width / 3, top), Offset(left + 2 * frameSize.width / 3, top + frameSize.height), guidePaint);

    // Guías horizontales
    canvas.drawLine(Offset(left, top + frameSize.height / 3), Offset(left + frameSize.width, top + frameSize.height / 3), guidePaint);
    canvas.drawLine(Offset(left, top + 2 * frameSize.height / 3), Offset(left + frameSize.width, top + 2 * frameSize.height / 3), guidePaint);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) => oldDelegate.frameSize != frameSize;
}
