// // AkonDeV 06/2026

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

enum ResizeMode {
  SmartCropCentred,
  LetterboxBlack,
  ScaleMaintainAspect,
}

class ImageProcessorService {
  Future<void> processMobileResize({
    required String sourcePath,
    required String targetPath,
    required int targetWidth,
    required int targetHeight,
    required ResizeMode mode,
  }) async {
    // // AkonDeV 06/2026
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Archivo de origen no encontrado', sourcePath);
    }

    final bytes = await sourceFile.readAsBytes();
    final sourceImage = img.decodeImage(bytes);
    if (sourceImage == null) {
      throw const FormatException('Fallo al decodificar la imagen de origen.');
    }

    final srcWidth = sourceImage.width;
    final srcHeight = sourceImage.height;

    img.Image resultImage;

    switch (mode) {
      case ResizeMode.SmartCropCentred:
        final double srcRatio = srcWidth / srcHeight;
        final double targetRatio = targetWidth / targetHeight;

        int cropX = 0;
        int cropY = 0;
        int cropWidth = srcWidth;
        int cropHeight = srcHeight;

        if (srcRatio > targetRatio) {
          // El origen es más ancho: recortamos laterales
          cropWidth = (srcHeight * targetRatio).round();
          cropX = ((srcWidth - cropWidth) / 2).round();
        } else if (srcRatio < targetRatio) {
          // El origen es más alto: recortamos arriba/abajo
          cropHeight = (srcWidth / targetRatio).round();
          cropY = ((srcHeight - cropHeight) / 2).round();
        }

        // 1. Recortar
        final cropped = img.copyCrop(
          sourceImage,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        // 2. Redimensionar
        resultImage = img.copyResize(
          cropped,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.cubic,
        );
        break;

      case ResizeMode.LetterboxBlack:
        // Crear lienzo negro
        final canvas = img.Image(width: targetWidth, height: targetHeight);
        canvas.clear(img.ColorRgb8(0, 0, 0)); // Rellenar de negro

        final double scale = min(targetWidth / srcWidth, targetHeight / srcHeight);
        final int newWidth = (srcWidth * scale).round();
        final int newHeight = (srcHeight * scale).round();

        // Redimensionar imagen original para encajar
        final resized = img.copyResize(
          sourceImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Centrar en el lienzo negro
        final int destX = ((targetWidth - newWidth) / 2).round();
        final int destY = ((targetHeight - newHeight) / 2).round();

        // Compositar / Dibujar en el lienzo
        img.compositeImage(
          canvas,
          resized,
          dstX: destX,
          dstY: destY,
        );
        resultImage = canvas;
        break;

      case ResizeMode.ScaleMaintainAspect:
        final double scale = min(targetWidth / srcWidth, targetHeight / srcHeight);
        final int newWidth = (srcWidth * scale).round();
        final int newHeight = (srcHeight * scale).round();

        resultImage = img.copyResize(
          sourceImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
        break;
    }

    // Guardar imagen resultante
    final targetFile = File(targetPath);
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    final String ext = pPathExtension(targetPath).toLowerCase();
    List<int> encodedBytes;
    if (ext == '.png') {
      encodedBytes = img.encodePng(resultImage);
    } else {
      encodedBytes = img.encodeJpg(resultImage, quality: 90);
    }

    await targetFile.writeAsBytes(encodedBytes);
  }

  // Utilidad simple para extraer extensión sin depender del paquete 'path' en todos lados
  String pPathExtension(String path) {
    final int idx = path.lastIndexOf('.');
    return idx == -1 ? '' : path.substring(idx);
  }
}
