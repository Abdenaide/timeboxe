import 'package:flutter/foundation.dart';
import '../models/workout_config.dart';
import '../services/storage_service.dart';

class PresetsProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<WorkoutConfig> _presets = [];
  bool _isLoaded = false;

  PresetsProvider(this._storageService);

  List<WorkoutConfig> get presets => _presets;
  bool get isLoaded => _isLoaded;

  Future<void> loadPresets() async {
    _presets = await _storageService.loadPresets();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addPreset(WorkoutConfig preset) async {
    _presets.add(preset);
    await _storageService.savePresets(_presets);
    notifyListeners();
  }

  Future<void> removePreset(int index) async {
    if (index >= 0 && index < _presets.length) {
      _presets.removeAt(index);
      await _storageService.savePresets(_presets);
      notifyListeners();
    }
  }

  Future<void> updatePreset(int index, WorkoutConfig preset) async {
    if (index >= 0 && index < _presets.length) {
      _presets[index] = preset;
      await _storageService.savePresets(_presets);
      notifyListeners();
    }
  }

  Future<void> saveLastConfig(WorkoutConfig config) async {
    await _storageService.saveLastConfig(config);
  }

  Future<WorkoutConfig?> getLastConfig() async {
    return await _storageService.loadLastConfig();
  }
}
