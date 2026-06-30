import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/data/session_store.dart';
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
  // static const _timelineData = [
  //   ('8a', 45), ('10a', 55), ('12p', 68), ('2p', 94), ('4p', 72), ('6p', 65), ('8p', 50)
  // ];

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
    final currentSpl = sessionStore.latestNoiseDbSpl;
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
          _noiseHero(currentSpl, themestore),
          const SizedBox(height: 20),
          _summarySection(sessionStore.elapsed, themestore),
          const SizedBox(height: 20),
          _alertCards(currentSpl, themestore),
          const SizedBox(height: 20),
          _earSafetySection(themestore),
          const SizedBox(height: 20),
          // _timelineSection(theme),
          // const SizedBox(height: 8),
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
      title: const Text(
        //'Stress & Noise',
        'Concentration Mode',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }

  Widget _noiseHero(double currentSpl, ThemeData theme) {
    return Column(
      children: [
        Text(
          '${store.colorTemp.toStringAsFixed(0)} K', // realtime color temp
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: currentSpl > 85 ? theme.colorScheme.error : theme.colorScheme.onSurface,
          ),
        ),
        Text(
          store.focusConditionLight, // text from light treshold filter
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.muted),
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
        const SectionLabel("Concentration Summary"),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              CardRow(label: 'Concentration Info', value: store.focusConditionAudio),
              CardRow(label: 'Current Noise', value: '${store.currentDb} dB', showDivider: false),
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
                isFatigued ? Icons.directions_walk : Icons.info_outline, 
                color: isFatigued ? const Color(0xFFFF9800) : theme.colorScheme.onSurface, 
                size: 20
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Walking Speed Analysis',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.currentSpeedKmh.toStringAsFixed(1)} km/h: ${store.focusConditionWalkingSpeed}', // realtime speed and corresponding info
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                Icons.hotel_class_outlined, 
                color: isLoud ? theme.colorScheme.error : theme.colorScheme.onSurface, 
                size: 20
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Brain Regeneration Status',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.currentSteps} steps: ${store.focusConditionBreak}', // realtime steps and corresponding info
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
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

  Widget _earSafetySection(SessionStore store) {
    // percentage of in total 3000 steps
    final stepProgress = (store.currentSteps / 3000).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Activity Progress'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Break Step Limit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  Text('${(stepProgress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 15, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              AppProgressBar(value: stepProgress),
              const SizedBox(height: 8),
              const Text(
                '${store.currentSteps} of 3000 steps for ideal focus regeneration',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _timelineSection(ThemeData theme) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const SectionLabel("Today's Timeline"),
  //       const SizedBox(height: 6),
  //       AppCard(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           children: [
  //             SizedBox(
  //               height: 80,
  //               child: Row(
  //                 crossAxisAlignment: CrossAxisAlignment.end,
  //                 children: _timelineData.map((d) {
  //                   final val = d.$2;
  //                   return Expanded(
  //                     child: Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 4),
  //                       child: FractionallySizedBox(
  //                         heightFactor: val / 100,
  //                         alignment: Alignment.bottomCenter,
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             color: val > 80 ? const Color(0xFFFF9800) : const Color(0xFF60A5FA),
  //                             borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: _timelineData.map((d) {
  //                 return Text(d.$1, style: TextStyle(fontSize: 10, color: theme.disabledColor));
  //               }).toList(),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _metricRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SectionLabel("Today's Focus Timeline"),
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
                              color: val > 80 ? AppColors.warning : const Color(0xFF60A5FA),
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
                  return Text(d.$1, style: const TextStyle(fontSize: 10, color: AppColors.inactive));
                }).toList(),
              ),
            ],
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