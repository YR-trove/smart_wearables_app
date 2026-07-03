import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';

// ---------------------------------------------------------------------------
// LightPage
// ---------------------------------------------------------------------------
class LightPage extends StatefulWidget {
  const LightPage({super.key});

  @override
  State<LightPage> createState() => _LightPageState();
}

class _LightPageState extends State<LightPage> {
  // Tracks blue-light night exposure in seconds (only while night + threshold)
  // This mirrors the accumulation in SessionStore but exposed here for the
  // circle widget's display.
  bool _blueLightWarningShown = false;

  /// Returns the display colour for the Environment Class circle.
  Color _envClassColor(LightExposureClass cls) {
    switch (cls) {
      case LightExposureClass.outdoor:
        return const Color(0xFF66BB6A); // green  – outdoor/sunlight
      case LightExposureClass.bright:
        return const Color(0xFFFFCA28); // amber  – bright indoor
      case LightExposureClass.indoor:
        return const Color(0xFF42A5F5); // blue   – normal indoor
      case LightExposureClass.dim:
        return const Color(0xFF78909C); // grey-blue – dim
      case LightExposureClass.dark:
        return const Color(0xFF455A64); // dark-grey  – dark
    }
  }

  /// Returns the foreground colour for the blue-light circle,
  /// scaling from calm blue to red as ratio grows.
  Color _blueClearRatioColor(int ratio) {
    if (ratio < 3000) return const Color(0xFF42A5F5);  // calm blue
    if (ratio < 6000) return const Color(0xFF5C6BC0); // indigo
    if (ratio < 8200) return const Color(0xFFFF9800); // orange
    return const Color(0xFFEF5350);                       // red
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;

    // ── Pull latest live light packet ────────────────────────────────────────
    final latestLight    = store.latestLight;
    final envClass       = latestLight?.exposureClass ?? LightExposureClass.dark;
    final blueClearRatio = latestLight?.blueClearRatio ?? 0;

    // ── Night blue-light accumulator from SessionStore ──────────────────────
    final nightBlueSecs = store.nightBlueLightSeconds;
    const int nightBlueLimitSecs = 3600; // 60 minutes // TODO: update the time threshold

    
    // Show one-time popup when 60 min threshold is reached
    if (nightBlueSecs >= nightBlueLimitSecs && !_blueLightWarningShown) {
      _blueLightWarningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Blue Light Warning'),
            content: const Text(
              'You have accumulated 60 minutes of blue-light exposure at night. '
              'Consider dimming your environment to protect your sleep quality.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      });
    }
    // Reset gate if exposure drops back below limit (e.g. new session)
    if (nightBlueSecs < nightBlueLimitSecs) _blueLightWarningShown = false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Light Environment',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Environment Class card (replaces Circadian Rhythm Score) ──
            _EnvironmentClassCard(
              envClass:  envClass,
              color:     _envClassColor(envClass),
            ),
            const SizedBox(height: 12),

            // ── 2. Night Blue-Light Exposure circle ──────────────────────────
            _LightCard(
              icon:      Icons.nights_stay_rounded,
              iconColor: const Color(0xFF5C6BC0),
              title:     'Night Blue Light Exposure',
              children: [
                _BlueLightNightCircle(
                  nightBlueSecs:   nightBlueSecs,
                  limitSecs:       nightBlueLimitSecs,
                  blueClearRatio:  blueClearRatio,
                  ratioColor:      _blueClearRatioColor(blueClearRatio),
                ),
              ],
            ),
            const SizedBox(height: 12), 
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

// ---------------------------------------------------------------------------
// EnvironmentClassCard — replaces _CircadianScoreCard
// Circle colour matches the current LightExposureClass from BLE.
// ---------------------------------------------------------------------------
class _EnvironmentClassCard extends StatelessWidget {
  final LightExposureClass envClass;
  final Color              color;

  const _EnvironmentClassCard({
    required this.envClass,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Environment Class',
            style: TextStyle(
              color:    theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value:           1.0, // full ring; colour carries meaning
                    strokeWidth:     10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor:      AlwaysStoppedAnimation<Color>(color),
                    strokeCap:       StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      envClass.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:      color,
                        fontSize:   20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      _iconFor(envClass),
                      color: color,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Current light environment detected from sensor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LightExposureClass cls) {
    switch (cls) {
      case LightExposureClass.outdoor:
        return Icons.wb_sunny_rounded;
      case LightExposureClass.bright:
        return Icons.light_mode_rounded;
      case LightExposureClass.indoor:
        return Icons.home_rounded;
      case LightExposureClass.dim:
        return Icons.nightlight_round;
      case LightExposureClass.dark:
        return Icons.bedtime_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// BlueLightNightCircle
// Circle fills up to 60 min of qualifying blue-light night exposure.
// Ratio is shown in the middle. Pop-up is handled by the parent.
// ---------------------------------------------------------------------------
class _BlueLightNightCircle extends StatelessWidget {
  final int   nightBlueSecs;
  final int   limitSecs;
  final int   blueClearRatio;
  final Color ratioColor;

  const _BlueLightNightCircle({
    required this.nightBlueSecs,
    required this.limitSecs,
    required this.blueClearRatio,
    required this.ratioColor,
  });

  String _formatExposure(int secs) {
    if (secs < 60) return '${secs}s';
    return '${secs ~/ 60}m ${secs % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final progress = (nightBlueSecs / limitSecs).clamp(0.0, 1.0);

    return Column(
      children: [
        // ── Circle ────────────────────────────────────────────────────────
        Center(
          child: SizedBox(
            width:  140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value:           progress,
                    strokeWidth:     10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor:      AlwaysStoppedAnimation<Color>(ratioColor),
                    strokeCap:       StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$blueClearRatio',
                      style: TextStyle(
                        color:      ratioColor,
                        fontSize:   36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'blue/clear ratio',
                      style: TextStyle(
                        color:    theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Caption ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // Condition note: only counts at night when blue-light
              // intensity exceeds an arbitrary threshold
              'Night exposure (after 19:00)',
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            Text(
              _formatExposure(nightBlueSecs),
              style: TextStyle(
                  color: ratioColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value:           progress,
            minHeight:       6,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            valueColor:      AlwaysStoppedAnimation<Color>(ratioColor),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Limit: 60 min for healthy sleep',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card, metric row, exposure bar
// ---------------------------------------------------------------------------
class _LightCard extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final List<Widget> children;

  const _LightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color:      theme.colorScheme.onSurfaceVariant,
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
