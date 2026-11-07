import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_config.dart';
import '../providers/presets_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/config_slider.dart';
import 'timer_screen.dart';

class ConfigScreen extends StatefulWidget {
  final WorkoutConfig? initialConfig;
  final int? presetIndex;

  const ConfigScreen({super.key, this.initialConfig, this.presetIndex});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late int _rounds;
  late int _roundDuration;
  late int _restDuration;
  late int _prepDuration;
  late int _warningSeconds;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig ?? WorkoutConfig.boxePadrao;
    _rounds = config.rounds;
    _roundDuration = config.roundDurationSeconds;
    _restDuration = config.restDurationSeconds;
    _prepDuration = config.prepDurationSeconds;
    _warningSeconds = config.warningSeconds;

    // Set initial name based on whether it is new or editing
    _nameController = TextEditingController(
      text: widget.presetIndex != null
          ? config.name
          : (widget.initialConfig != null
                ? '${config.name} (Cópia)'
                : 'Meu Treino'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  WorkoutConfig get _currentConfig => WorkoutConfig(
    name: _nameController.text.trim().isEmpty
        ? 'Sem Nome'
        : _nameController.text.trim(),
    rounds: _rounds,
    roundDurationSeconds: _roundDuration,
    restDurationSeconds: _restDuration,
    prepDurationSeconds: _prepDuration,
    warningSeconds: _warningSeconds,
  );

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatTotalTime() {
    return _currentConfig.totalDurationFormatted;
  }

  void _startWorkout() {
    final config = _currentConfig;
    context.read<PresetsProvider>().saveLastConfig(config);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TimerScreen(config: config),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _savePresetDirectly() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um nome para o treino.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final preset = _currentConfig;
    final provider = context.read<PresetsProvider>();

    if (widget.presetIndex != null) {
      provider.updatePreset(widget.presetIndex!, preset);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Treino "$name" atualizado com sucesso!'),
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
        ),
      );
    } else {
      provider.addPreset(preset);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "$name" criado com sucesso!'),
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
        ),
      );
    }
    Navigator.pop(context);
  }

  void _deletePreset() {
    if (widget.presetIndex == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Treino?'),
        content: Text(
          'Tem certeza que deseja excluir o treino "${_nameController.text.trim()}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final dialogNavigator = Navigator.of(ctx);
              await context.read<PresetsProvider>().removePreset(
                widget.presetIndex!,
              );
              if (!mounted) return;
              dialogNavigator.pop(); // Close dialog
              navigator.pop(); // Close config screen
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Treino excluído!'),
                  backgroundColor: AppColors.error.withValues(alpha: 0.9),
                ),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.presetIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Treino' : 'Configurar Treino'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: _deletePreset,
              tooltip: 'Excluir Treino',
            ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.save_rounded : Icons.bookmark_add_outlined,
            ),
            onPressed: _savePresetDirectly,
            tooltip: isEditing ? 'Salvar Alterações' : 'Salvar Preset',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Workout Name Field
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Treino',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppColors.divider.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rounds
                  ConfigSlider(
                    label: 'Rounds',
                    valueLabel: '$_rounds',
                    value: _rounds.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    icon: Icons.repeat,
                    onChanged: (v) => setState(() => _rounds = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Round Duration
                  ConfigSlider(
                    label: 'Tempo do Round',
                    valueLabel: _formatDuration(_roundDuration),
                    value: _roundDuration.toDouble(),
                    min: 30,
                    max: 600,
                    divisions: 38,
                    icon: Icons.timer,
                    onChanged: (v) {
                      // Snap to 15-second increments
                      setState(() => _roundDuration = (v / 15).round() * 15);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Rest Duration
                  ConfigSlider(
                    label: 'Tempo de Descanso',
                    valueLabel: _formatDuration(_restDuration),
                    value: _restDuration.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    icon: Icons.pause_circle_outline,
                    onChanged: (v) {
                      setState(() => _restDuration = (v / 10).round() * 10);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Prep Duration
                  ConfigSlider(
                    label: 'Preparação',
                    valueLabel: '${_prepDuration}s',
                    value: _prepDuration.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 6,
                    icon: Icons.hourglass_top,
                    onChanged: (v) {
                      setState(() => _prepDuration = (v / 5).round() * 5);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Warning
                  ConfigSlider(
                    label: 'Aviso Final',
                    valueLabel: '${_warningSeconds}s',
                    value: _warningSeconds.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 6,
                    icon: Icons.warning_amber_rounded,
                    onChanged: (v) {
                      setState(() => _warningSeconds = (v / 5).round() * 5);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Resumo do Treino',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Rounds',
                              value: '$_rounds',
                              color: AppColors.primary,
                            ),
                            _SummaryItem(
                              label: 'Round',
                              value: _formatDuration(_roundDuration),
                              color: AppColors.roundColor,
                            ),
                            _SummaryItem(
                              label: 'Descanso',
                              value: _formatDuration(_restDuration),
                              color: AppColors.restColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tempo total: ${_formatTotalTime()}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Start button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciar Treino',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
