# 🥊 TimeBoxe

Aplicativo **Flutter** de timer de treino de boxe e artes marciais. Ele controla rounds, descansos e tempo de preparação com avisos sonoros, mantém presets de treino e funciona totalmente offline.

## O que o aplicativo faz

- **Timer de intervalos (round timer)** com fases de:
  - preparação;
  - round;
  - aviso final (warning);
  - descanso;
  - treino concluído.
- **Presets prontos**:
  - Boxe Padrão — 3 rounds de 3 min, 1 min de descanso;
  - Muay Thai — 5 rounds de 3 min, 2 min de descanso;
  - HIIT Boxing — 8 rounds de 30 s, 15 s de descanso;
  - Shadow Boxing — 6 rounds de 2 min, 30 s de descanso.
- **Criação e edição de presets personalizados**: nome, número de rounds, duração do round, descanso, preparação e segundos de aviso.
- **Sinais sonoros** gerados em tempo real pelo app:
  - sino no início do round;
  - buzina no fim do round;
  - bipes de aviso nos segundos finais;
  - sino duplo ao concluir o treino.
- **Vibração** sincronizada com os sons em Android/iOS.
- **Controle total durante o treino**: iniciar, pausar, retomar, pular fase, reiniciar e sair (com confirmação).
- **Mantém a tela ligada** durante o treino (`wakelock_plus`).
- **Pausa automática** quando o app vai para segundo plano.
- **Persistência local** dos presets e da última configuração usada (`shared_preferences`).
- **Atalho de treino rápido** usando a última configuração.
- **Funciona offline**: fontes incluídas no projeto e sons gerados localmente, sem downloads em tempo de execução.
- Interface escura, responsiva e com animações.

## Tecnologias

- **Flutter** / **Dart** (SDK `^3.12.2`)
- **Provider** — gerenciamento de estado
- **shared_preferences** — persistência local
- **audioplayers** — reprodução dos sons
- **wakelock_plus** — manter a tela ligada
- **google_fonts** — fontes Inter e Orbitron empacotadas localmente

## Como rodar

```bash
flutter pub get
flutter run
```

Para gerar um APK Android:

```bash
flutter build apk --release
```

Para executar os testes:

```bash
flutter test
```

## Estrutura

```
lib/
  main.dart                    # inicialização, fontes e modo edge-to-edge
  app.dart                     # MaterialApp e providers
  models/
    workout_config.dart        # configuração do treino e presets padrão
    timer_state.dart           # fases do timer
  providers/
    presets_provider.dart      # estado dos presets
    timer_provider.dart        # lógica do cronômetro e transição de fases
  screens/
    home_screen.dart           # tela inicial com presets
    config_screen.dart         # criação/edição de treinos
    timer_screen.dart          # tela de treino em andamento
  services/
    audio_service.dart         # geração de tons WAV e sinais sonoros
    storage_service.dart       # persistência com SharedPreferences
  theme/
    app_colors.dart
    app_theme.dart
  widgets/
    circular_timer.dart
    round_indicator.dart
    config_slider.dart
    preset_card.dart
    control_button.dart
assets/
  google_fonts/                # fontes usadas offline
  audio/                       # reservado para áudios (os sons são gerados em código)
test/                          # testes de widget e de layout responsivo
```

## Como o timer funciona

- O tempo de cada fase é controlado por um `deadline` (`DateTime`), não por contagem incremental, evitando atrasos acumulados.
- O `TimerProvider` dispara atualizações a cada 100 ms e notifica a interface.
- Ao terminar um round, o app decide entre ir para o descanso ou finalizar o treino (se era o último round).
- Os sons são sintetizados como WAV PCM em memória, sem depender de arquivos externos.

## Personalização

- **Novos presets:** use a tela de configuração do próprio app.
- **Presets padrão:** edite `WorkoutConfig.defaultPresets` em `lib/models/workout_config.dart`.
- **Cores e tema:** edite `lib/theme/app_colors.dart` e `lib/theme/app_theme.dart`.
- **Sons:** ajuste frequências, durações e volumes em `lib/services/audio_service.dart`.

## Observações

- O diretório `build/` e `.dart_tool/` são artefatos de compilação e não devem ser versionados.
- Este repositório contém **apenas o aplicativo Flutter**. O SDK do Flutter não é versionado junto.
- O app não requer permissão de internet: as fontes são locais e os sons são gerados em tempo de execução.
