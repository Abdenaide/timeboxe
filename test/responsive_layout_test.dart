import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:timeboxe/models/workout_config.dart';
import 'package:timeboxe/providers/presets_provider.dart';
import 'package:timeboxe/screens/home_screen.dart';
import 'package:timeboxe/screens/timer_screen.dart';
import 'package:timeboxe/services/audio_service.dart';
import 'package:timeboxe/services/storage_service.dart';
import 'package:timeboxe/theme/app_theme.dart';

class _FakeWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

const _phonePortraitSmall = Size(320, 568);
const _phonePortrait = Size(390, 844);
const _phoneLandscape = Size(640, 360);
const _tabletPortrait = Size(800, 1280);

void main() {
  setUpAll(() {
    WakelockPlusPlatformInterface.instance = _FakeWakelock();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<PresetsProvider> buildProvider() async {
    final storage = StorageService();
    await storage.init();
    final provider = PresetsProvider(storage);
    await provider.loadPresets();
    return provider;
  }

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = await buildProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<PresetsProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpTimer(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final audio = AudioService();

    await tester.pumpWidget(
      Provider<AudioService>.value(
        value: audio,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TimerScreen(config: WorkoutConfig.boxePadrao),
        ),
      ),
    );

    // Let the post-frame auto-start and a few ticks run.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
  }

  group('HomeScreen fits on phones', () {
    for (final size in [
      _phonePortraitSmall,
      _phonePortrait,
      _phoneLandscape,
      _tabletPortrait,
    ]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpHome(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('TimeBoxe'), findsOneWidget);
      });
    }
  });

  group('TimerScreen fits on phones', () {
    for (final size in [
      _phonePortraitSmall,
      _phonePortrait,
      _phoneLandscape,
      _tabletPortrait,
    ]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpTimer(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('Boxe Padrão'), findsOneWidget);

        // Dispose the periodic timer.
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  testWidgets('round indicator adapts to many rounds', (tester) async {
    tester.view.physicalSize = _phonePortraitSmall;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final audio = AudioService();
    const config = WorkoutConfig(
      name: '30 Rounds',
      rounds: 30,
      roundDurationSeconds: 60,
      restDurationSeconds: 30,
    );

    await tester.pumpWidget(
      Provider<AudioService>.value(
        value: audio,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TimerScreen(config: config),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
