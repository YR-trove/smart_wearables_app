import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/session_store.dart';
import '../data/models/live_packets.dart';

class StressPage extends StatefulWidget {
  const StressPage({super.key});

  @override
  State<StressPage> createState() => _StressPageState();
}

class _StressPageState extends State<StressPage> {
  // ── Live state ─────────────────────────────────────────────────────────────
  double _accumulatedDosePct = 0.0;
  int    _lastElapsedSeconds = 0;

  // Rolling buffer for live audio visualiser (19 bars)
  final List<double> _waveHistory = List.filled(19, 10.0);

  // ── Noise classification helpers ───────────────────────────────────────────

  /// Label shown beneath the dB value — derived from AudioEnvClass.
  String _envLabel(AudioEnvClass cls) => cls.label;

  /// Accent colour that scales with the noise class.
  Color _noiseColor(AudioEnvClass cls, ThemeData theme) {
    switch (cls) {
      case AudioEnvClass.veryQuiet:
      case AudioEnvClass.quiet:
        return const Color(0xFF66BB6A);   // green
      case AudioEnvClass.moderate:
      case AudioEnvClass.lively:
        return const Color(0xFF42A5F5);   // blue
      case AudioEnvClass.noisy:
        return const Color(0xFFFF9800);   // orange
      case AudioEnvClass.veryNoisy:
        return const Color(0xFFEF5350);   // red
      case AudioEnvClass.highExposure:
        return theme.colorScheme.error;   // error (deepest red)
      case AudioEnvClass.unavailable:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  /// Height fraction for the waveform bars — dotted-line effect via spacing.
  /// Realistic mapping: quiet → short, loud → tall, same range as spec.
  double _barHeightFor(double db) => (db * 0.4).clamp(4.0, 48.0);



  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final sessionStore = context.watch<SessionStore>();

    // ── Pull live BLE data from the latest Mic packet via SessionStore ───────
    // store.latestLaeqDb   → LiveMicPacket.laeqDb (laeq_x10 / 10.0)
    // store.latestEnvLabel → LiveMicPacket.envClass.label
    final double       currentSpl = sessionStore.latestLaeqDb;
    final AudioEnvClass currentEnv =
        sessionStore.latestUnifiedPacket?.audioClass ?? AudioEnvClass.unavailable;
    final Color        noiseColor = _noiseColor(currentEnv, theme);

    final elapsedSeconds = sessionStore.elapsed.inSeconds;

    // ── Per-second update logic ───────────────────────────────────────────────
    if (elapsedSeconds > _lastElapsedSeconds) {
      final int deltaS = elapsedSeconds - _lastElapsedSeconds;



      // Advance the waveform buffer
      for (int i = 0; i < _waveHistory.length - 1; i++) {
        _waveHistory[i] = _waveHistory[i + 1];
      }
      // Add realistic jitter proportional to noise level
      final jitterAmount = currentSpl > 40 ? 8 : 2;
      final jitter = (Random().nextDouble() - 0.5) * jitterAmount;
      _waveHistory.last = (currentSpl + jitter).clamp(10.0, 120.0);



      // Accumulated acoustic dose (NIOSH / WHO model)
      if (currentSpl >= 70) {
        final double safeTimeSecs =
            (8.0 * 3600.0) / pow(2.0, (currentSpl - 85.0) / 3.0);
        _accumulatedDosePct += (deltaS / safeTimeSecs);
      }

      _lastElapsedSeconds = elapsedSeconds;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _noiseHero(currentSpl, currentEnv, noiseColor, theme),
          const SizedBox(height: 20),
          // ── Safety limit moved directly below session summary ────────────
          _earSafetySection(theme),
          const SizedBox(height: 20),
          _alertCards(currentSpl, currentEnv, theme, sessionStore),
        ],
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Stress & Noise',
        style: TextStyle(
          fontSize:   17,
          fontWeight: FontWeight.w600,
          color:      theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ── Noise hero ───────────────────────────────────────────────────────────────
  Widget _noiseHero(
    double       currentSpl,
    AudioEnvClass currentEnv,
    Color        noiseColor,
    ThemeData    theme,
  ) {
    return Column(
      children: [
        // dB value from laeq_x10
        Text(
          '${currentSpl.toStringAsFixed(1)} dB',
          style: TextStyle(
            fontSize:   42,
            fontWeight: FontWeight.bold,
            color:      noiseColor,
          ),
        ),
        // Class label from envClass
        Text(
          _envLabel(currentEnv),
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w500,
            color:      noiseColor.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 16),
        // Waveform — dotted-line style via tight spacing + round caps
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _waveHistory.map((val) {
              final barColor = _noiseColor(
                // Map back to a class for bar colour consistency
                _dbToEnvClass(val),
                theme,
              );
              return Container(
                width:  4,
                height: _barHeightFor(val),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color:        barColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }



  // ── Ear safety limit ─────────────────────────────────────────────────────────
  Widget _earSafetySection(ThemeData theme) {
    final double displayPct = (_accumulatedDosePct * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Ear Safety Limit'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session Dose',
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w500,
                      color:      theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${displayPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 15,
                      color:    theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppProgressBar(
                  value: _accumulatedDosePct.clamp(0.0, 1.0)),
              const SizedBox(height: 8),
              Text(
                'Based on WHO daily allowance (85 dB / 8 h)',
                style: TextStyle(
                    fontSize: 12,
                    color:    theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notification / alert cards ───────────────────────────────────────────────
  // Focus card: based on current lightClass
  // Stress card: based on current envClass (NOISY or above triggers warning).
  Widget _alertCards(
    double        currentSpl,
    AudioEnvClass currentEnv,
    ThemeData     theme,
    SessionStore  sessionStore,
  ) {
    final LightExposureClass currentLight =
        sessionStore.latestUnifiedPacket?.lightClass ?? LightExposureClass.dark;
    
    // Focus Index state logic
    String focusState = 'Bad';
    Color focusColor = theme.colorScheme.error;
    String focusMsg = 'High light intensity detected. This may reduce focus.';
    IconData focusIcon = Icons.warning_amber_rounded;
    
    if (currentLight == LightExposureClass.dark || currentLight == LightExposureClass.dim) {
      focusState = 'Good';
      focusColor = const Color(0xFF66BB6A); // green
      focusMsg = 'Low light exposure. Ideal for maintaining good focus.';
      focusIcon = Icons.check_circle_outline;
    } else if (currentLight == LightExposureClass.moderate) {
      focusState = 'Optimal';
      focusColor = const Color(0xFF42A5F5); // blue
      focusMsg = 'Moderate light exposure. Optimal conditions for focus.';
      focusIcon = Icons.info_outline;
    }

    // Stress Index state logic
    String stressState = 'Bad';
    Color stressColor = theme.colorScheme.error;
    String stressMsg = 'Current noise level is detrimental to concentration.';
    IconData stressIcon = Icons.monitor_heart_outlined;
    
    if (currentEnv == AudioEnvClass.veryQuiet || currentEnv == AudioEnvClass.quiet) {
      stressState = 'Good';
      stressColor = const Color(0xFF66BB6A);
      stressMsg = 'Quiet environment supports a calm physiological state.';
      stressIcon = Icons.check_circle_outline;
    } else if (currentEnv == AudioEnvClass.moderate || currentEnv == AudioEnvClass.lively || currentEnv == AudioEnvClass.noisy) {
      stressState = 'Optimal';
      stressColor = const Color(0xFF42A5F5);
      stressMsg = 'Moderate noise level provides optimal stimulation without excessive stress.';
      stressIcon = Icons.info_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Concentration Meter'),
        const SizedBox(height: 6),
        // ── Focus Index ──────────────────────────────────────────
        AppCard(
          leftBorderColor: focusColor,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                focusIcon,
                color: focusColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Index: $focusState',
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w500,
                          color:      theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      focusMsg,
                      style: TextStyle(
                          fontSize: 13,
                          color:    theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Stress Index ──────────────────────────────────────────────────
        AppCard(
          leftBorderColor: stressColor,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                stressIcon,
                color: stressColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Index: $stressState',
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w500,
                          color:      theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stressMsg,
                      style: TextStyle(
                          fontSize: 13,
                          color:    theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  /// Derive an AudioEnvClass from a raw dB value for waveform bar colouring.
  AudioEnvClass _dbToEnvClass(double db) {
    if (db < 35) return AudioEnvClass.veryQuiet;
    if (db < 45) return AudioEnvClass.quiet;
    if (db < 55) return AudioEnvClass.moderate;
    if (db < 65) return AudioEnvClass.lively;
    if (db < 75) return AudioEnvClass.noisy;
    if (db < 85) return AudioEnvClass.veryNoisy;
    return AudioEnvClass.highExposure;
  }
}

// ============================================================================
// Reusable UI widgets
// ============================================================================

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize:    12,
        fontWeight:  FontWeight.bold,
        color:       Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget               child;
  final EdgeInsetsGeometry   padding;
  final Color?               leftBorderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding         = const EdgeInsets.all(16),
    this.leftBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: leftBorderColor != null
            ? [BoxShadow(color: leftBorderColor!, offset: const Offset(-4, 0))]
            : null,
      ),
      child: child,
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  const AppProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = value > 0.85
        ? theme.colorScheme.error
        : value > 0.5
            ? const Color(0xFFFF9800)
            : const Color(0xFF66BB6A);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value:           value,
        minHeight:       8,
        backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
        valueColor:      AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
