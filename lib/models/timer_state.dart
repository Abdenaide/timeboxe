enum TimerPhase { preparation, round, rest, warning, finished }

extension TimerPhaseExtension on TimerPhase {
  String get label {
    switch (this) {
      case TimerPhase.preparation:
        return 'PREPARE-SE';
      case TimerPhase.round:
        return 'ROUND';
      case TimerPhase.rest:
        return 'DESCANSO';
      case TimerPhase.warning:
        return 'ROUND';
      case TimerPhase.finished:
        return 'FINALIZADO';
    }
  }

  String get phaseKey {
    switch (this) {
      case TimerPhase.preparation:
        return 'preparation';
      case TimerPhase.round:
        return 'round';
      case TimerPhase.rest:
        return 'rest';
      case TimerPhase.warning:
        return 'warning';
      case TimerPhase.finished:
        return 'finished';
    }
  }
}
