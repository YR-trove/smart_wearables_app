import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/stat_card.dart';

class FitnessPage extends StatelessWidget {
  const FitnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GOOD MORNING',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      const Text('Fitness\nToday',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.1)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.cyan, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('BLE\nCONNECTED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.cyan,
                                fontWeight: FontWeight.bold,
                                height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: CircularGauge(
                  value: 7842,
                  maxValue: 10000,
                  color: AppColors.cyan,
                  trackColor: const Color(0xFF1E2A3A),
                  strokeWidth: 14,
                  size: 200,
                  startAngle: -220,
                  sweepAngle: 260,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('7,842',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const Text('STEPS',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('78% of goal',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  StatCard(emoji: '🔥', value: '342 kcal', label: 'Calories'),
                  SizedBox(width: 10),
                  StatCard(emoji: '📍', value: '5.8 km', label: 'Distance'),
                  SizedBox(width: 10),
                  StatCard(emoji: '⚡', value: '48 min', label: 'Active'),
                ],
              ),
              const SizedBox(height: 16),
              _WeeklyActivityCard(),
              const SizedBox(height: 16),
              InfoBanner(
                emoji: '🎯',
                title: '2,158 steps to daily goal',
                subtitle: '~18 min of brisk walking',
                color: AppColors.cyan,
                showArrow: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> days = const [
    {'label': 'M', 'height': 0.4},
    {'label': 'T', 'height': 0.6},
    {'label': 'W', 'height': 0.5},
    {'label': 'T', 'height': 0.75},
    {'label': 'F', 'height': 0.85, 'active': true},
    {'label': 'S', 'height': 0.2},
    {'label': 'S', 'height': 0.0},
  ];

  const _WeeklyActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Weekly Activity',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('This week',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((day) {
                final isActive = day['active'] == true;
                final frac = (day['height'] as double);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 24,
                          height: frac == 0 ? 4 : 60 * frac,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.cyan
                                : frac == 0
                                    ? AppColors.cardBorder
                                    : AppColors.cyan.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(day['label'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? AppColors.cyan
                                : AppColors.textSecondary)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
