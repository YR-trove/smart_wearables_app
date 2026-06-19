import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/data/session_store.dart';

// ---------------------------------------------------------------------------
// FitnessPage
// ---------------------------------------------------------------------------
class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _activityLabel(int state) {
    switch (state) {
      case 1:
        return 'Walking';
      case 2:
        return 'Running';
      default:
        return 'Idle';
    }
  }

  IconData _activityIcon(int state) {
    switch (state) {
      case 1:
        return Icons.directions_walk_rounded;
      case 2:
        return Icons.directions_run_rounded;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  Color _activityColor(int state) {
    switch (state) {
      case 1:
        return const Color(0xFF43A047); // green
      case 2:
        return const Color(0xFFE53935); // red
      default:
        return const Color(0xFF1E88E5); // blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final theme = Theme.of(context);
    final elapsed = store.elapsed;
    
    final primaryText = theme.colorScheme.onSurface;
    final mutedText = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Fitness',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(
                _activityIcon(store.activityState),
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                _activityLabel(store.activityState),
                style: const TextStyle(color: Colors.white, fontSize: 12), // Keep white for contrast on colored badge
              ),
              backgroundColor: _activityColor(store.activityState),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              child: _BigStatTile(
                icon: Icons.timer_rounded,
                iconColor: const Color(0xFFFF9800),
                label: 'Session Time',
                value: _formatDuration(elapsed),
                unit: '',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SectionCard(
                    child: _BigStatTile(
                      icon: Icons.directions_walk_rounded,
                      iconColor: const Color(0xFF26C6DA),
                      label: 'Steps',
                      value: store.currentSteps.toString(),
                      unit: 'steps',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SectionCard(
                    child: _BigStatTile(
                      icon: Icons.route_rounded,
                      iconColor: const Color(0xFF66BB6A),
                      label: 'Distance',
                      value: store.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF5350), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Calories Burned',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        store.totalKcal.toStringAsFixed(1),
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'kcal',
                          style: TextStyle(color: mutedText, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BurnBar(kcal: store.totalKcal, goalKcal: 500),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: Color(0xFFAB47BC), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Weekly Steps',
                        style: TextStyle(color: mutedText, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _WeeklyStepsChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _BigStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _BigStatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BurnBar extends StatelessWidget {
  final double kcal;
  final double goalKcal;
  const _BurnBar({required this.kcal, required this.goalKcal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (kcal / goalKcal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF5350)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% of ${goalKcal.toInt()} kcal goal',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _WeeklyStepsChart extends StatelessWidget {
  const _WeeklyStepsChart();

  @override
  Widget build(BuildContext context) {
    const maxSteps = 12000.0;
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<SessionStore>().sessionDao.weeklyStepSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(height: 120, child: Center(child: Text('No data for this week', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))));
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((row) {
              final int steps = row['max_steps'] as int;
              final String dayStr = row['day_of_week'] as String;
              final double frac = (steps / maxSteps).clamp(0.0, 1.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: frac * 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary, // Dynamically use the theme accent
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dayStr, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}