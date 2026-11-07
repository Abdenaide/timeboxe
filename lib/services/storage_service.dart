import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_config.dart';

class StorageService {
  static const String _presetsKey = 'workout_presets';
  static const String _lastConfigKey = 'last_workout_config';
  static const String _isFirstRunKey = 'is_first_run';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureDefaultPresets();
  }

  Future<void> _ensureDefaultPresets() async {
    final isFirstRun = _prefs.getBool(_isFirstRunKey) ?? true;
    if (isFirstRun) {
      await savePresets(WorkoutConfig.defaultPresets);
      await _prefs.setBool(_isFirstRunKey, false);
    }
  }

  // Presets
  Future<List<WorkoutConfig>> loadPresets() async {
    final String? jsonString = _prefs.getString(_presetsKey);
    if (jsonString == null) return WorkoutConfig.defaultPresets;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WorkoutConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return WorkoutConfig.defaultPresets;
    }
  }

  Future<void> savePresets(List<WorkoutConfig> presets) async {
    final jsonList = presets.map((p) => p.toJson()).toList();
    await _prefs.setString(_presetsKey, jsonEncode(jsonList));
  }

  Future<void> addPreset(WorkoutConfig preset) async {
    final presets = await loadPresets();
    presets.add(preset);
    await savePresets(presets);
  }

  Future<void> removePreset(int index) async {
    final presets = await loadPresets();
    if (index >= 0 && index < presets.length) {
      presets.removeAt(index);
      await savePresets(presets);
    }
  }

  Future<void> updatePreset(int index, WorkoutConfig preset) async {
    final presets = await loadPresets();
    if (index >= 0 && index < presets.length) {
      presets[index] = preset;
      await savePresets(presets);
    }
  }

  // Last config
  Future<void> saveLastConfig(WorkoutConfig config) async {
    await _prefs.setString(_lastConfigKey, config.toJsonString());
  }

  Future<WorkoutConfig?> loadLastConfig() async {
    final String? jsonString = _prefs.getString(_lastConfigKey);
    if (jsonString == null) return null;

    try {
      return WorkoutConfig.fromJsonString(jsonString);
    } catch (e) {
      return null;
    }
  }
}
