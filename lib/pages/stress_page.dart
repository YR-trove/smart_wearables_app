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
  double _peakNoise         = 0.0; // max dB reached in the session
  double _accumulatedDosePct = 0.0;
  int    _lastElapsedSeconds = 0;

  // Duration spent in LOUD / Very Loud classes (counted by session summary)
  Duration _loudExposure = Duration.zero;

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

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inHours}h ${two(d.inMinutes.remainder(60))}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final sessionStore = context.watch<SessionStore>();

    // ── Pull live BLE data from the latest Mic packet via SessionStore ───────
    // store.latestLaeqDb   → LiveMicPacket.laeqDb (laeq_x10 / 10.0)
    // store.latestEnvLabel → LiveMicPacket.envClass.label
    final double       currentSpl = sessionStore.latestLaeqDb;
    final AudioEnvClass currentEnv =
        sessionStore.latestMic?.envClass ?? AudioEnvClass.unavailable;
    final Color        noiseColor = _noiseColor(currentEnv, theme);

    final elapsedSeconds = sessionStore.elapsed.inSeconds;

    // ── Per-second update logic ───────────────────────────────────────────────
    if (elapsedSeconds > _lastElapsedSeconds) {
      final int deltaS = elapsedSeconds - _lastElapsedSeconds;

      // Update peak noise with the actual max dB
      if (currentSpl > _peakNoise) _peakNoise = currentSpl;

      // Advance the waveform buffer
      for (int i = 0; i < _waveHistory.length - 1; i++) {
        _waveHistory[i] = _waveHistory[i + 1];
      }
      // Add realistic jitter proportional to noise level
      final jitterAmount = currentSpl > 40 ? 8 : 2;
      final jitter = (Random().nextDouble() - 0.5) * jitterAmount;
      _waveHistory.last = (currentSpl + jitter).clamp(10.0, 120.0);

      // Session-summary loud-time counter: only NOISY or VERY NOISY / HIGH
      // TODO: adjust which classes count as "harmful"
      if (currentEnv == AudioEnvClass.noisy ||
          currentEnv == AudioEnvClass.veryNoisy ||
          currentEnv == AudioEnvClass.highExposure) {
        _loudExposure += Duration(seconds: deltaS);
      }

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
          _summarySection(theme),
          const SizedBox(height: 20),
          // ── Safety limit moved directly below session summary ────────────
          _earSafetySection(theme),
          const SizedBox(height: 20),
          _alertCards(currentSpl, currentEnv, theme),
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

  // ── Session summary ──────────────────────────────────────────────────────────
  // Exposure time counts only seconds spent in NOISY / VERY NOISY / HIGH class.
  // Peak noise = highest dB value reached.
  Widget _summarySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Session Summary'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              _metricRow(
                'Loud Exposure',
                _formatDuration(_loudExposure),
                theme,
              ),
              const SizedBox(height: 12),
              _metricRow(
                'Peak Noise',
                '${_peakNoise.toStringAsFixed(1)} dB',
                theme,
              ),
            ],
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
  // Fatigue card: based on accumulated dose.
  // Stress card: based on current envClass (NOISY or above triggers warning).
  Widget _alertCards(
    double        currentSpl,
    AudioEnvClass currentEnv,
    ThemeData     theme,
  ) {
    final bool isHighDose = _accumulatedDosePct > 0.5;

    // Stressful = NOISY, VERY NOISY, or HIGH EXPOSURE // TODO: refine the definition of "healthy" vs "stressful"
    final bool isStressful = currentEnv == AudioEnvClass.noisy ||
        currentEnv == AudioEnvClass.veryNoisy ||
        currentEnv == AudioEnvClass.highExposure;

    return Column(
      children: [
        // ── Accumulated fatigue ──────────────────────────────────────────
        AppCard(
          leftBorderColor:
              isHighDose ? const Color(0xFFFF9800) : theme.colorScheme.onSurface,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isHighDose
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: isHighDose
                    ? const Color(0xFFFF9800)
                    : theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accumulated Fatigue',
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w500,
                          color:      theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHighDose
                          ? 'High noise dose detected. Consider resting your ears.'
                          : 'Acoustic dose is within healthy limits.',
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

        // ── Stress indicator — aligned to current envClass ────────────────
        AppCard(
          leftBorderColor: isStressful
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: isStressful
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Indicator',
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w500,
                          color:      theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isStressful
                          ? 'Current noise level (${currentSpl.toStringAsFixed(1)} dB, ${currentEnv.label}) '
                              'may elevate physiological stress.'
                          : 'Current environment (${currentEnv.label}) supports a calm physiological state.',
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

  // ── Metric row helper ────────────────────────────────────────────────────────
  Widget _metricRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color:      theme.colorScheme.onSurface,
            fontSize:   14,
            fontWeight: FontWeight.w600,
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
