import 'dart:convert';

class WorkoutConfig {
  final String name;
  final int rounds;
  final int roundDurationSeconds;
  final int restDurationSeconds;
  final int prepDurationSeconds;
  final int warningSeconds;

  const WorkoutConfig({
    required this.name,
    required this.rounds,
    required this.roundDurationSeconds,
    required this.restDurationSeconds,
    this.prepDurationSeconds = 10,
    this.warningSeconds = 10,
  });

  // Calculated properties
  int get totalDurationSeconds {
    return prepDurationSeconds +
        (rounds * roundDurationSeconds) +
        ((rounds - 1) * restDurationSeconds);
  }

  String get totalDurationFormatted {
    final total = totalDurationSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
    return '${minutes}min ${seconds.toString().padLeft(2, '0')}s';
  }

  String get roundDurationFormatted => _formatTime(roundDurationSeconds);
  String get restDurationFormatted => _formatTime(restDurationSeconds);
  String get prepDurationFormatted => _formatTime(prepDurationSeconds);

  static String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rounds': rounds,
      'roundDurationSeconds': roundDurationSeconds,
      'restDurationSeconds': restDurationSeconds,
      'prepDurationSeconds': prepDurationSeconds,
      'warningSeconds': warningSeconds,
    };
  }

  factory WorkoutConfig.fromJson(Map<String, dynamic> json) {
    final roundDurationSeconds =
        (json['roundDurationSeconds'] as int?)?.clamp(1, 3600) ?? 180;
    final warningSeconds = ((json['warningSeconds'] as int?) ?? 10).clamp(
      0,
      roundDurationSeconds,
    );
    return WorkoutConfig(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Treino',
      rounds: (json['rounds'] as int?)?.clamp(1, 99) ?? 3,
      roundDurationSeconds: roundDurationSeconds,
      restDurationSeconds:
          (json['restDurationSeconds'] as int?)?.clamp(0, 3600) ?? 60,
      prepDurationSeconds:
          (json['prepDurationSeconds'] as int?)?.clamp(0, 3600) ?? 10,
      warningSeconds: warningSeconds,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory WorkoutConfig.fromJsonString(String jsonString) {
    return WorkoutConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  WorkoutConfig copyWith({
    String? name,
    int? rounds,
    int? roundDurationSeconds,
    int? restDurationSeconds,
    int? prepDurationSeconds,
    int? warningSeconds,
  }) {
    return WorkoutConfig(
      name: name ?? this.name,
      rounds: rounds ?? this.rounds,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      prepDurationSeconds: prepDurationSeconds ?? this.prepDurationSeconds,
      warningSeconds: warningSeconds ?? this.warningSeconds,
    );
  }

  // Default presets
  static const WorkoutConfig boxePadrao = WorkoutConfig(
    name: 'Boxe Padrão',
    rounds: 3,
    roundDurationSeconds: 180,
    restDurationSeconds: 60,
    prepDurationSeconds: 10,
    warningSeconds: 10,
  );

  static const WorkoutConfig muayThai = WorkoutConfig(
    name: 'Muay Thai',
    rounds: 5,
    roundDurationSeconds: 180,
    restDurationSeconds: 120,
    prepDurationSeconds: 10,
    warningSeconds: 10,
  );

  static const WorkoutConfig hiitBoxing = WorkoutConfig(
    name: 'HIIT Boxing',
    rounds: 8,
    roundDurationSeconds: 30,
    restDurationSeconds: 15,
    prepDurationSeconds: 5,
    warningSeconds: 5,
  );

  static const WorkoutConfig shadowBoxing = WorkoutConfig(
    name: 'Shadow Boxing',
    rounds: 6,
    roundDurationSeconds: 120,
    restDurationSeconds: 30,
    prepDurationSeconds: 10,
    warningSeconds: 10,
  );

  static const List<WorkoutConfig> defaultPresets = [
    boxePadrao,
    muayThai,
    hiitBoxing,
    shadowBoxing,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutConfig &&
        other.name == name &&
        other.rounds == rounds &&
        other.roundDurationSeconds == roundDurationSeconds &&
        other.restDurationSeconds == restDurationSeconds &&
        other.prepDurationSeconds == prepDurationSeconds &&
        other.warningSeconds == warningSeconds;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      rounds,
      roundDurationSeconds,
      restDurationSeconds,
      prepDurationSeconds,
      warningSeconds,
    );
  }
}
