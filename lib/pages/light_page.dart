import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/stat_card.dart';

class LightPage extends StatelessWidget {
  const LightPage({super.key});

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
                      const Text('ENVIRONMENT',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      const Text('Light\nExposure',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.1)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.cyan, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          const Text('BLE', style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('💡', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ScoreCard(
                      title: 'CIRCADIAN\nSCORE',
                      value: 74,
                      maxValue: 100,
                      label: 'Good',
                      color: AppColors.orange,
                      subtitle: 'Rhythm alignment',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UVCard(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LightProgressCard(
                icon: '🔵',
                title: 'Blue\nLight',
                current: 3.2,
                max: 6.0,
                unit: 'h',
                limitLabel: '6h limit',
                percentLabel: '53% of safe limit',
                color: AppColors.purple,
                subtitle: "Today's exposure",
              ),
              const SizedBox(height: 12),
              _LightProgressCard(
                icon: '🟡',
                title: 'Sunlight',
                current: 1.1,
                max: 2.0,
                unit: 'h',
                limitLabel: '2h limit',
                percentLabel: '55% of limit',
                color: AppColors.orange,
                subtitle: 'Direct exposure today',
              ),
              const SizedBox(height: 16),
              _LightIntensityCard(),
              const SizedBox(height: 16),
              InfoBanner(
                emoji: '🌙',
                title: 'Circadian Alert',
                subtitle: 'Reduce blue light after 8pm for better sleep',
                color: AppColors.orange,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final String label;
  final Color color;
  final String subtitle;

  const _ScoreCard({
    required this.title,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          CircularGauge(
            value: value,
            maxValue: maxValue,
            color: color,
            strokeWidth: 8,
            size: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _UVCard extends StatelessWidget {
  const _UVCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Text('UV INDEX',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          CircularGauge(
            value: 6,
            maxValue: 11,
            color: AppColors.orange,
            strokeWidth: 8,
            size: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('6',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('High',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('⚠️', style: TextStyle(fontSize: 10)),
                SizedBox(width: 4),
                Text('Skin Burn Risk',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Protect in 25 min',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LightProgressCard extends StatelessWidget {
  final String icon;
  final String title;
  final double current;
  final double max;
  final String unit;
  final String limitLabel;
  final String percentLabel;
  final Color color;
  final String subtitle;

  const _LightProgressCard({
    required this.icon,
    required this.title,
    required this.current,
    required this.max,
    required this.unit,
    required this.limitLabel,
    required this.percentLabel,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / max).clamp(0.0, 1.0);
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
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Text('${current.toStringAsFixed(1)}$unit / $max$unit $limitLabel',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(percentLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightIntensityCard extends StatelessWidget {
  const _LightIntensityCard();

  @override
  Widget build(BuildContext context) {
    const hours = ['6am', '9am', '12pm', '3pm', '6pm', '9pm'];
    const sunVals = [0.1, 0.5, 0.9, 0.7, 0.4, 0.1];
    const blueVals = [0.05, 0.3, 0.55, 0.45, 0.6, 0.2];

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
              Text('Light Intensity',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('Today',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(hours.length, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 18,
                              height: 50 * sunVals[i],
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 50 * blueVals[i],
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(hours[i],
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: AppColors.orange, label: 'Sun'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.purple, label: 'Blue'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.textMuted, label: 'Indoor'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
