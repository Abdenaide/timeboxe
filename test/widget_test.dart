import 'package:flutter_test/flutter_test.dart';
import 'package:timeboxe/app.dart';
import 'package:timeboxe/services/audio_service.dart';
import 'package:timeboxe/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('TimeBoxe App smoke test', (WidgetTester tester) async {
    // Set mock values for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    final storageService = StorageService();
    await storageService.init();

    final audioService = AudioService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      TimeBoxeApp(storageService: storageService, audioService: audioService),
    );

    // Verify that the title is present
    expect(find.text('TimeBoxe'), findsOneWidget);
  });
}
