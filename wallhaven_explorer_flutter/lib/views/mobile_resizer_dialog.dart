import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallpaper.dart';
import '../providers/main_provider.dart';

class PhonePreset {
  final String name;
  final int width;
  final int height;

  const PhonePreset(this.name, this.width, this.height);
}

const List<PhonePreset> phonePresets = [
  PhonePreset('iPhone 15 Pro Max', 1290, 2796),
  PhonePreset('iPhone 15 / 14 Pro', 1179, 2556),
  PhonePreset('Samsung Galaxy S23/S24 Ultra', 1440, 3088),
  PhonePreset('Google Pixel 8 Pro', 1344, 2992),
  PhonePreset('Estándar Full HD (16:9)', 1080, 1920),
  PhonePreset('Personalizado', 0, 0),
];

class MobileResizerDialog extends ConsumerStatefulWidget {
  final Wallpaper wallpaper;

  const MobileResizerDialog({super.key, required this.wallpaper});

  @override
  ConsumerState<MobileResizerDialog> createState() => _MobileResizerDialogState();
}

class _MobileResizerDialogState extends ConsumerState<MobileResizerDialog> {
  final GlobalKey _viewerKey = GlobalKey();

  PhonePreset _selectedPreset = phonePresets[4]; // Estándar Full HD por defecto
  final TextEditingController _widthController = TextEditingController(text: '1080');
  final TextEditingController _heightController = TextEditingController(text: '1920');

  int _activeWidth = 1080;
  int _activeHeight = 1920;
  bool _isSaving = false;

  // Coordenadas de scroll de la imagen respecto al marco del móvil
  // -1.0 indica que deben inicializarse y centrarse en el build
  double _currentScrollX = -1.0;
  double _currentScrollY = -1.0;

  @override
  void initState() {
    super.initState();
    _updateActiveDimensions();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateActiveDimensions() {
    if (_selectedPreset.name != 'Personalizado') {
      _activeWidth = _selectedPreset.width;
      _activeHeight = _selectedPreset.height;
    } else {
      _activeWidth = int.tryParse(_widthController.text) ?? 1080;
      _activeHeight = int.tryParse(_heightController.text) ?? 1920;
      if (_activeWidth <= 0) _activeWidth = 1080;
      if (_activeHeight <= 0) _activeHeight = 1920;
    }
    // Forzar reinicio de coordenadas al cambiar dimensiones
    _currentScrollX = -1.0;
    _currentScrollY = -1.0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainProvider);
    final bool isLight = state.appConfig.theme == 'Light';

    // Paleta de colores condicional
    final Color dialogBg = isLight ? const Color(0xFFF4F4F6) : const Color(0xFF15151A);
    final Color panelBg = isLight ? Colors.white : const Color(0xFF18181C);
    final Color borderCol = isLight ? const Color(0xFFE2E2E6) : const Color(0xFF25252D);
    final Color cardBg = isLight ? const Color(0xFFECECEF) : const Color(0xFF0F0F12);
    final Color inputBg = isLight ? const Color(0xFFECECEF) : const Color(0xFF202026);
    final Color dropdownMenuBg = isLight ? Colors.white : const Color(0xFF15151A);
    final Color textColor = isLight ? Colors.black87 : Colors.white;
    final Color subTextColor = isLight ? Colors.black54 : const Color(0xFFAAAAAA);
    final Color btnCancelBg = isLight ? const Color(0xFFECECEF) : const Color(0xFF25252D);
    final Color btnCancelBorder = isLight ? const Color(0xFFD3D3D9) : const Color(0xFF2D2D37);
    final Color buttonSaveBg = isLight ? const Color(0xFFD0D3D9) : const Color(0xFF3A3F47);
    final Color buttonSaveBorder = isLight ? const Color(0xFFB0B4BC) : const Color(0xFF505662);

    // Calcular la relación de aspecto del móvil
    final double targetRatio = _activeWidth / _activeHeight;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 1000,
        height: 650,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            // 1. Lado Izquierdo: Editor Interactivo con Desplazamiento Restringido
            Expanded(
              flex: 7,
              child: Container(
                color: isLight ? const Color(0xFFE9E9EC) : const Color(0xFF0F0F12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double wContainer = constraints.maxWidth;
                        final double hContainer = constraints.maxHeight;

                        // Parsear la resolución original del wallpaper
                        final parts = widget.wallpaper.resolution.split('x');
                        final double originalWidth = double.tryParse(parts.first) ?? 1920.0;
                        final double originalHeight = double.tryParse(parts.last) ?? 1080.0;

                        // BoxFit.contain de la imagen original
                        final double imageRatio = originalWidth / originalHeight;

                        // Calcular el tamaño del marco del teléfono en pantalla
                        double hFrame = hContainer * 0.82;
                        double wFrame = hFrame * targetRatio;
                        if (wFrame > wContainer * 0.82) {
                          wFrame = wContainer * 0.82;
                          hFrame = wFrame / targetRatio;
                        }
                        final Size frameSize = Size(wFrame, hFrame);

                        // Determinar eje de movimiento según relación de aspecto
                        double wRender;
                        double hRender;
                        final bool isHorizontalScroll = imageRatio > targetRatio;

                        if (isHorizontalScroll) {
                          hRender = hFrame;
                          wRender = hRender * imageRatio;
                        } else {
                          wRender = wFrame;
                          hRender = wRender / imageRatio;
                        }

                        // Inicializar scroll centrado
                        if (_currentScrollX == -1.0 && _currentScrollY == -1.0) {
                          if (isHorizontalScroll) {
                            _currentScrollX = (wRender - wFrame) / 2;
                            _currentScrollY = 0.0;
                          } else {
                            _currentScrollX = 0.0;
                            _currentScrollY = (hRender - hFrame) / 2;
                          }
                        }

                        // Validar y limitar scrolls
                        final double maxScrollX = (wRender - wFrame).clamp(0.0, double.infinity);
                        final double maxScrollY = (hRender - hFrame).clamp(0.0, double.infinity);
                        _currentScrollX = _currentScrollX.clamp(0.0, maxScrollX);
                        _currentScrollY = _currentScrollY.clamp(0.0, maxScrollY);

                        // Posiciones
                        final double xFrame = (wContainer - wFrame) / 2;
                        final double yFrame = (hContainer - hFrame) / 2;

                        final double xImage = xFrame - _currentScrollX;
                        final double yImage = yFrame - _currentScrollY;

                        final String imagePath = state.displayedImagePath;

                        Widget imageWidget(double opacityValue) {
                          if (imagePath.isEmpty) return const SizedBox.shrink();
                          return Opacity(
                            opacity: opacityValue,
                            child: SizedBox(
                              width: wRender,
                              height: hRender,
                              child: imagePath.startsWith('http')
                                  ? Image.network(imagePath, fit: BoxFit.fill)
                                  : Image.file(File(imagePath), fit: BoxFit.fill),
                            ),
                          );
                        }

                        return GestureDetector(
                          onPanUpdate: _isSaving ? null : (details) {
                            setState(() {
                              if (isHorizontalScroll) {
                                _currentScrollX = (_currentScrollX - details.delta.dx).clamp(0.0, maxScrollX);
                              } else {
                                _currentScrollY = (_currentScrollY - details.delta.dy).clamp(0.0, maxScrollY);
                              }
                            });
                          },
                          child: Stack(
                            key: _viewerKey,
                            fit: StackFit.expand,
                            children: [
                              // Fondo de la imagen oscurecido (30% opacidad)
                              if (imagePath.isNotEmpty)
                                Positioned(
                                  left: xImage,
                                  top: yImage,
                                  child: imageWidget(0.30),
                                ),

                              // Máscara opaca del teléfono
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(wContainer, hContainer),
                                  painter: CropOverlayPainter(frameSize),
                                ),
                              ),

                              // Imagen nítida encuadrada dentro de la guía (ClipRect)
                              if (imagePath.isNotEmpty)
                                Positioned(
                                  left: xFrame,
                                  top: yFrame,
                                  width: wFrame,
                                  height: hFrame,
                                  child: ClipRect(
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: -_currentScrollX,
                                          top: -_currentScrollY,
                                          child: imageWidget(1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Instrucciones de Ajuste Restringido
                    Positioned(
                      top: 15,
                      left: 15,
                      right: 15,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isLight ? Colors.white : const Color(0xFF1E1E24)).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horizontal_circle_outlined, color: Color(0xFF00B0FF), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Arrastra lateralmente para elegir el encuadre exacto del wallpaper',
                                  style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Cargador superior
                    if (_isSaving || state.isLoading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Lado Derecho: Panel de Configuración
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: panelBg,
                border: Border(left: BorderSide(color: borderCol, width: 1)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.crop, color: Color(0xFF7C4DFF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'REESCALADOR MÓVIL',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: subTextColor, size: 18),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(color: borderCol, height: 24),
                  
                  // Preset Dropdown
                  Text(
                    'DISPOSITIVO / PRESET:',
                    style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderCol),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PhonePreset>(
                        value: _selectedPreset,
                        dropdownColor: dropdownMenuBg,
                        style: TextStyle(color: textColor, fontSize: 12),
                        isExpanded: true,
                        items: phonePresets.map((p) {
                          return DropdownMenuItem<PhonePreset>(
                            value: p,
                            child: Text(
                              p.name == 'Personalizado' ? p.name : '${p.name} (${p.width}x${p.height})',
                            ),
                          );
                        }).toList(),
                        onChanged: _isSaving ? null : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPreset = val;
                              _updateActiveDimensions();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Custom Dimensions
                  if (_selectedPreset.name == 'Personalizado') ...[
                    Text(
                      'MEDIDAS PERSONALIZADAS (px):',
                      style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor, fontSize: 13),
                            onChanged: (_) => setState(_updateActiveDimensions),
                            decoration: InputDecoration(
                              labelText: 'Ancho',
                              labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                              fillColor: inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor, fontSize: 13),
                            onChanged: (_) => setState(_updateActiveDimensions),
                            decoration: InputDecoration(
                              labelText: 'Alto',
                              labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                              fillColor: inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Detalle Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INFO DE RESOLUCIÓN', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Original: ${widget.wallpaper.resolution}', style: TextStyle(color: subTextColor, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('Destino: ${_activeWidth}x$_activeHeight px', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Ratio: ${targetRatio.toStringAsFixed(3)} (Vertical)', style: TextStyle(color: subTextColor, fontSize: 11)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botones de acción
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveResizedImage,
                    icon: Icon(Icons.check, color: isLight ? Colors.black87 : Colors.white, size: 16),
                    label: Text(
                      'Aplicar Ajuste y Guardar',
                      style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonSaveBg,
                      minimumSize: const Size(double.infinity, 42),
                      side: BorderSide(color: buttonSaveBorder, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      minimumSize: const Size(double.infinity, 40),
                      side: BorderSide(color: btnCancelBorder, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      backgroundColor: btnCancelBg,
                    ),
                    child: Text('Cancelar', style: TextStyle(color: subTextColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResizedImage() async {
    final notifier = ref.read(mainProvider.notifier);

    setState(() {
      _isSaving = true;
    });

    try {
      final renderBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        throw Exception('No se pudo encontrar el render de la imagen.');
      }

      final double wContainer = renderBox.size.width;
      final double hContainer = renderBox.size.height;

      // 1. Resolución original de la imagen
      final parts = widget.wallpaper.resolution.split('x');
      final double originalWidth = double.tryParse(parts.first) ?? 1920.0;
      final double originalHeight = double.tryParse(parts.last) ?? 1080.0;

      // 2. Aspect ratio del visor móvil
      final double targetRatio = _activeWidth / _activeHeight;

      // 3. Tamaño del marco de recorte en pantalla (viewport lógico)
      double hFrame = hContainer * 0.82;
      double wFrame = hFrame * targetRatio;
      if (wFrame > wContainer * 0.82) {
        wFrame = wContainer * 0.82;
        hFrame = wFrame / targetRatio;
      }

      // 4. Dimensiones de la imagen renderizada (restringida al marco)
      final double imageRatio = originalWidth / originalHeight;
      double wRender;
      double hRender;
      final bool isHorizontalScroll = imageRatio > targetRatio;

      if (isHorizontalScroll) {
        hRender = hFrame;
        wRender = hRender * imageRatio;
      } else {
        wRender = wFrame;
        hRender = wRender / imageRatio;
      }

      // 5. Calcular escala de render a físico
      final double scale = isHorizontalScroll 
          ? originalHeight / hRender 
          : originalWidth / wRender;

      // 6. Calcular coordenadas físicas del recorte en base a los scrolls restringidos
      int cropX = 0;
      int cropY = 0;
      int cropWidth = originalWidth.round();
      int cropHeight = originalHeight.round();

      if (isHorizontalScroll) {
        cropX = (_currentScrollX * scale).round();
        cropY = 0;
        cropWidth = (wFrame * scale).round();
        cropHeight = originalHeight.round();
      } else {
        cropX = 0;
        cropY = (_currentScrollY * scale).round();
        cropWidth = originalWidth.round();
        cropHeight = (hFrame * scale).round();
      }

      // 7. Validar límites y restringir al tamaño original
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

      // Validar dimensiones resultantes
      if (cropWidth <= 0 || cropHeight <= 0) {
        throw Exception('El encuadre seleccionado no es válido. Reajusta la imagen e intenta de nuevo.');
      }

      // Configurar estado en el notifier
      notifier.updateResizeResolution('${_activeWidth}x$_activeHeight');
      notifier.updateResizeMode('ManualCrop');

      // Crear la versión móvil
      await notifier.createMobileVersion(
        cropX: cropX,
        cropY: cropY,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Versión móvil creada con éxito!'),
            backgroundColor: const Color(0xFF7C4DFF),
            action: SnackBarAction(
              label: 'Abrir Carpeta',
              textColor: Colors.white,
              onPressed: () => notifier.openMobileDirectory(),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class CropOverlayPainter extends CustomPainter {
  final Size frameSize;

  CropOverlayPainter(this.frameSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.70)
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

    // Borde de la guía del teléfono (color azul cielo tecnológico)
    final borderPaint = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(innerRect, borderPaint);

    // Notch del teléfono simulado
    final double notchWidth = frameSize.width * 0.40 > 70 ? 70.0 : frameSize.width * 0.40;
    final notchRect = Rect.fromLTWH(size.width / 2 - notchWidth / 2, top + 6, notchWidth, 14);
    final notchPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(notchRect, const Radius.circular(7)), notchPaint);

    // Cuadrícula interior (regla de los tercios)
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
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
