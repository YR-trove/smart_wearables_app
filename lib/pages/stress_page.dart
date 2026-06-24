import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/session_store.dart'; 

class StressPage extends StatefulWidget {
  const StressPage({super.key});

  @override
  State<StressPage> createState() => _StressPageState();
}

class _StressPageState extends State<StressPage> {
  // Live State Tracking
  double _peakNoise = 0.0;
  double _accumulatedDosePct = 0.0;
  int _lastElapsedSeconds = 0;
  
  // Rolling buffer for the live audio visualizer (19 bars)
  final List<double> _waveHistory = List.filled(19, 10.0);

  // Hardcoded mock for the timeline (can be wired to a DB later)
  static const _timelineData = [
    ('8a', 45), ('10a', 55), ('12p', 68), ('2p', 94), ('4p', 72), ('6p', 65), ('8p', 50)
  ];

  String _getNoiseLabel(double spl) {
    if (spl < 50) return 'Quiet';
    if (spl < 70) return 'Moderate';
    if (spl < 85) return 'Loud';
    return 'Dangerous';
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${d.inHours}h ${twoDigits(d.inMinutes.remainder(60))}m";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionStore = context.watch<SessionStore>();
    final currentSpl = sessionStore.noiseDbSpl;
    final elapsedSeconds = sessionStore.elapsed.inSeconds;

    // Lock state mutation behind the 1-second tick check
    if (elapsedSeconds > _lastElapsedSeconds) {
      int deltaS = elapsedSeconds - _lastElapsedSeconds;

      if (currentSpl > _peakNoise) _peakNoise = currentSpl;

      for (int i = 0; i < _waveHistory.length - 1; i++) {
        _waveHistory[i] = _waveHistory[i + 1];
      }
      final jitterAmount = currentSpl > 40 ? 12 : 2;
      final jitter = (Random().nextDouble() - 0.5) * jitterAmount;
      _waveHistory.last = (currentSpl + jitter).clamp(10.0, 120.0);

      if (currentSpl >= 70) { 
        double safeTimeSeconds = (8 * 3600) / pow(2, (currentSpl - 85) / 3.0);
        _accumulatedDosePct += (deltaS / safeTimeSeconds);
      }
      _lastElapsedSeconds = elapsedSeconds;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _noiseHero(currentSpl, theme),
          const SizedBox(height: 20),
          _summarySection(sessionStore.elapsed, theme),
          const SizedBox(height: 20),
          _alertCards(currentSpl, theme),
          const SizedBox(height: 20),
          _earSafetySection(theme),
          const SizedBox(height: 20),
          _timelineSection(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Stress & Noise',
        style: TextStyle(
          fontSize: 17, 
          fontWeight: FontWeight.w600, 
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _noiseHero(double currentSpl, ThemeData theme) {
    return Column(
      children: [
        Text(
          '${currentSpl.toInt()} dB',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: currentSpl > 85 ? theme.colorScheme.error : theme.colorScheme.onSurface,
          ),
        ),
        Text(
          _getNoiseLabel(currentSpl),
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500, 
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _waveHistory.map((val) {
              return Container(
                width: 6,
                height: (val * 0.4).clamp(4.0, 48.0),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: val > 85 
                      ? theme.colorScheme.error 
                      : val > 70 
                          ? const Color(0xFFFF9800) 
                          : const Color(0xFF60A5FA),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _summarySection(Duration elapsed, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Session Summary"),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              _metricRow('Exposure', _formatDuration(elapsed), theme),
              const SizedBox(height: 12),
              _metricRow('Peak Noise', '${_peakNoise.toInt()} dB', theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alertCards(double currentSpl, ThemeData theme) {
    bool isLoud = currentSpl > 85;
    bool isFatigued = _accumulatedDosePct > 0.5;
    
    return Column(
      children: [
        AppCard(
          leftBorderColor: isFatigued ? const Color(0xFFFF9800) : theme.colorScheme.onSurface,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isFatigued ? Icons.warning_amber_rounded : Icons.info_outline, 
                color: isFatigued ? const Color(0xFFFF9800) : theme.colorScheme.onSurface, 
                size: 20
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accumulated Fatigue',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFatigued 
                        ? 'High noise dose detected. Consider resting your ears.'
                        : 'Acoustic dose is within healthy limits.',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          leftBorderColor: isLoud ? theme.colorScheme.error : theme.colorScheme.onSurface,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.monitor_heart_outlined, 
                color: isLoud ? theme.colorScheme.error : theme.colorScheme.onSurface, 
                size: 20
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Indicator',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoud 
                        ? 'Current noise correlates with elevated stress triggers.'
                        : 'Current environment supports calm physiological state.',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
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

  Widget _earSafetySection(ThemeData theme) {
    double displayPct = (_accumulatedDosePct * 100).clamp(0.0, 100.0);
    
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
                  Text('Session Dose', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                  Text('${displayPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 10),
              AppProgressBar(value: _accumulatedDosePct.clamp(0.0, 1.0)),
              const SizedBox(height: 8),
              Text(
                'Based on WHO daily allowance (85 dB / 8h)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Today's Timeline"),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _timelineData.map((d) {
                    final val = d.$2;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FractionallySizedBox(
                          heightFactor: val / 100,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: val > 80 ? const Color(0xFFFF9800) : const Color(0xFF60A5FA),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _timelineData.map((d) {
                  return Text(d.$1, style: TextStyle(fontSize: 10, color: theme.disabledColor));
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Internal Reusable UI Widgets (No external files needed)
// ============================================================================

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? leftBorderColor;

  const AppCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(16),
    this.leftBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        // Add optional left accent line for alerts
        boxShadow: leftBorderColor != null 
          ? [BoxShadow(color: leftBorderColor!, offset: const Offset(-4, 0))] 
          : null,
      ),
      child: child,
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  const AppProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = value > 0.85 ? theme.colorScheme.error : 
                  value > 0.5 ? const Color(0xFFFF9800) : 
                  const Color(0xFF66BB6A);
                  
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}