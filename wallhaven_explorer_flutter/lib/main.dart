import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'views/main_view.dart';
import 'providers/main_provider.dart';

void main() async {
  // // AkonDeV 06/2026
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de gestor de ventanas nativas en Escritorio
  try {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 780),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Wallhaven Explorer Premium',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (_) {
    // Si falla en dispositivos móviles donde window_manager no es compatible
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainProvider);
    final bool isDark = state.appConfig.theme != 'Light';

    return MaterialApp(
      title: 'Wallhaven Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: const Color(0xFF7C4DFF),
        colorScheme: isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF7C4DFF),
                secondary: Color(0xFF00B0FF),
                surface: Color(0xFF1E1E24),
              )
            : const ColorScheme.light(
                primary: Color(0xFF7C4DFF),
                secondary: Color(0xFF00B0FF),
                surface: Color(0xFFF5F5FA),
              ),
        useMaterial3: true,
      ),
      home: const MainView(),
    );
  }
}

