import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/workout_config.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/circular_timer.dart';
import '../widgets/control_button.dart';
import '../widgets/round_indicator.dart';

class TimerScreen extends StatefulWidget {
  final WorkoutConfig config;

  const TimerScreen({super.key, required this.config});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  late TimerProvider _timerProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enable wakelock to keep screen on during workout
    WakelockPlus.enable();

    // Configure the timer
    final audioService = context.read<AudioService>();
    _timerProvider = TimerProvider(audioService);
    _timerProvider.configure(widget.config);

    // Auto-start workout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timerProvider.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when the app goes to background so the deadline-based timer
    // doesn't run unchecked while suspended.
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _timerProvider.isRunning) {
      _timerProvider.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Disable wakelock when leaving the screen
    WakelockPlus.disable();
    _timerProvider.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.preparation:
        return AppColors.prepColor.withValues(alpha: 0.03);
      case TimerPhase.round:
        return AppColors.roundColor.withValues(alpha: 0.03);
      case TimerPhase.warning:
        return AppColors.warningColor.withValues(alpha: 0.05);
      case TimerPhase.rest:
        return AppColors.restColor.withValues(alpha: 0.03);
      case TimerPhase.finished:
        return AppColors.finishedColor.withValues(alpha: 0.03);
    }
  }

  void _confirmExit(TimerProvider provider) {
    final wasRunning = provider.isRunning;
    if (wasRunning) {
      provider.pause();
    }
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do Treino?'),
        content: const Text('O progresso atual será perdido.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (wasRunning && mounted) {
                provider.resume();
              }
            },
            child: Text(
              'Continuar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(TimerProvider provider) {
    final wasRunning = provider.isRunning;
    if (wasRunning) {
      provider.pause();
    }
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar Treino?'),
        content: const Text('O treino voltará ao início.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (wasRunning && mounted) {
                provider.resume();
              }
            },
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.stop();
              provider.start();
            },
            child: const Text(
              'Reiniciar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    TimerProvider provider,
    Color phaseColor,
  ) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _confirmExit(provider),
          ),
          Expanded(
            child: Text(
              widget.config.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: Icon(
              provider.audioService.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                provider.audioService.toggleMute();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIndicator(BuildContext context, TimerProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ROUND',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        RoundIndicator(
          totalRounds: widget.config.rounds,
          currentRound: provider.currentRound,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    TimerProvider provider,
    Color phaseColor, {
    bool compact = false,
  }) {
    final secondarySize = compact ? 48.0 : 64.0;
    final primarySize = compact ? 60.0 : 80.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        ControlButton(
          icon: Icons.stop_rounded,
          label: 'Parar',
          color: AppColors.error,
          size: secondarySize,
          onPressed: () => _confirmRestart(provider),
        ),

        // Play/Pause button
        ControlButton(
          icon: provider.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: provider.isRunning ? 'Pausar' : 'Iniciar',
          isPrimary: true,
          color: phaseColor,
          size: primarySize,
          onPressed: () {
            HapticFeedback.selectionClick();
            provider.togglePause();
          },
        ),

        // Skip button
        ControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Pular',
          color: AppColors.textSecondary,
          size: secondarySize,
          onPressed: () {
            HapticFeedback.selectionClick();
            provider.skipToNext();
          },
        ),
      ],
    );
  }

  Widget _buildFinishedButton(BuildContext context, TimerProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text('Voltar ao Início'),
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    TimerProvider provider,
    Color phaseColor,
  ) {
    return Column(
      children: [
        _buildTopBar(context, provider, phaseColor),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CircularTimer(
                progress: provider.progress,
                timeText: provider.timeDisplay,
                phaseLabel: provider.phaseLabel,
                phaseSubLabel: provider.phaseSubLabel,
                phaseColor: phaseColor,
                isWarning: provider.isInWarning,
                isRunning: provider.isRunning,
              ),
            ),
          ),
        ),
        if (!provider.isFinished) ...[
          _buildRoundIndicator(context, provider),
          const SizedBox(height: 16),
        ],
        if (provider.isFinished)
          _buildFinishedButton(context, provider)
        else
          _buildControls(context, provider, phaseColor),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    TimerProvider provider,
    Color phaseColor,
  ) {
    return Column(
      children: [
        _buildTopBar(context, provider, phaseColor),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CircularTimer(
                      progress: provider.progress,
                      timeText: provider.timeDisplay,
                      phaseLabel: provider.phaseLabel,
                      phaseSubLabel: provider.phaseSubLabel,
                      phaseColor: phaseColor,
                      isWarning: provider.isInWarning,
                      isRunning: provider.isRunning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!provider.isFinished) ...[
                            _buildRoundIndicator(context, provider),
                            const SizedBox(height: 24),
                          ],
                          if (provider.isFinished)
                            _buildFinishedButton(context, provider)
                          else
                            _buildControls(
                              context,
                              provider,
                              phaseColor,
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerProvider>.value(
      value: _timerProvider,
      child: Consumer<TimerProvider>(
        builder: (context, provider, child) {
          final phaseColor = AppColors.getPhaseColor(provider.currentPhaseKey);

          return PopScope(
            // The system back button must ask for confirmation like the
            // on-screen back arrow.
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _confirmExit(provider);
            },
            child: Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                color: _getBackgroundColor(provider.phase),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isLandscape =
                            constraints.maxWidth > constraints.maxHeight;
                        return isLandscape
                            ? _buildLandscape(context, provider, phaseColor)
                            : _buildPortrait(context, provider, phaseColor);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
