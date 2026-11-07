import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The fonts are bundled in assets/google_fonts, so the app must not try to
  // download them at runtime (offline-first and no INTERNET permission needed).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Draw behind the system bars (edge-to-edge) with light icons, since the
  // whole app uses a dark theme.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioService();

  runApp(
    TimeBoxeApp(storageService: storageService, audioService: audioService),
  );
}
