import 'package:flutter/material.dart';
import '../app_theme.dart';

class FitnessPage extends StatelessWidget {
  const FitnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStepRing(),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 20),
            const SectionLabel('Activity'),
            const SizedBox(height: 6),
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            _buildHeartRateCard(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hello, Alex',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Thursday, Oct 24',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.border,
              child: const Text(
                'AJ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepRing() {
    const steps = 8432;
    const goal = 10000;
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RingGauge(
              value: steps / goal,
              size: 200,
              strokeWidth: 14,
              color: AppColors.accent,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '8,432',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'STEPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '/ 10,000 goal',
                  style: TextStyle(fontSize: 12, color: AppColors.inactive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.local_fire_department_rounded, '487', 'kcal', const Color(0xFFF97316))),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.timer_outlined, '34', 'min', AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.place_outlined, '4.2', 'km', AppColors.success)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String unit, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: appCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = [
      ('M', 0.40),
      ('T', 0.65),
      ('W', 0.85),
      ('T', 0.45),
      ('F', 0.90),
      ('S', 0.30),
      ('S', 0.84),
    ];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.asMap().entries.map((e) {
            final isToday = e.key == 6;
            final day = e.value.$1;
            final pct = e.value.$2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.accent : const Color(0xFF93C5FD),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.accent : AppColors.inactive,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text(
                        '72',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('bpm', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'REST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
