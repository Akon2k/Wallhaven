// // AkonDeV 06/2026

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/app_config.dart';

class ConfigurationService {
  final String? _customPath;

  ConfigurationService({String? customPath}) : _customPath = customPath;

  Future<String> _getConfigFilePath() async {
    // // AkonDeV 06/2026
    if (_customPath != null) return _customPath!;
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'config.json');
  }

  Future<AppConfig> loadConfig() async {
    // // AkonDeV 06/2026
    try {
      final path = await _getConfigFilePath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return AppConfig.fromJson(json);
      }
    } catch (_) {}

    // Retornar configuración por defecto
    final appConfig = AppConfig();
    await saveConfig(appConfig);
    return appConfig;
  }

  Future<void> saveConfig(AppConfig config) async {
    // // AkonDeV 06/2026
    final path = await _getConfigFilePath();
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final jsonStr = jsonEncode(config.toJson());
    await file.writeAsString(jsonStr);
  }
}
