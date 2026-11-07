import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/presets_provider.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

class TimeBoxeApp extends StatelessWidget {
  final StorageService storageService;
  final AudioService audioService;

  const TimeBoxeApp({
    super.key,
    required this.storageService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AudioService>.value(value: audioService),
        ChangeNotifierProvider<PresetsProvider>(
          create: (context) => PresetsProvider(storageService),
        ),
      ],
      child: MaterialApp(
        title: 'TimeBoxe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
