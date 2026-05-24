import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/stat_card.dart';

class NoisePage extends StatelessWidget {
  const NoisePage({super.key});

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
                    children: const [
                      Text('ACOUSTIC &\nSTRESS',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.4)),
                      SizedBox(height: 2),
                      Text('Noise Tracking',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
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
                      const Text('🎧', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _LiveLevelCard(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StressScoreCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _FreqBandsCard()),
                ],
              ),
              const SizedBox(height: 16),
              _NoiseHistoryCard(),
              const SizedBox(height: 16),
              InfoBanner(
                emoji: '⚠️',
                title: 'Prolonged Noise Alert',
                subtitle: '2.4h in loud environment — consider a break',
                color: AppColors.orange,
              ),
              const SizedBox(height: 12),
              InfoBanner(
                emoji: '🧠',
                title: 'Stress Elevated',
                subtitle: 'Noise stress affecting cognitive load',
                color: AppColors.purple,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveLevelCard extends StatelessWidget {
  const _LiveLevelCard();

  @override
  Widget build(BuildContext context) {
    const barHeights = [0.4, 0.6, 0.5, 0.8, 0.55, 0.7, 0.45, 0.9, 0.6, 0.75, 0.5, 0.65, 0.4, 0.7, 0.85, 0.5, 0.6, 0.45, 0.8, 0.55];
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('LIVE\nLEVEL',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                ),
                child: const Text('Loud',
                    style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text('78',
                  style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(width: 4),
              Text('dB',
                  style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              Spacer(),
              Text('Safe limit: 85 dB',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: barHeights.map((h) {
                return Container(
                  width: 10,
                  height: 50 * h,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0 dB', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('100 dB', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.78,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StressScoreCard extends StatelessWidget {
  const _StressScoreCard();

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
          const Text('STRESS\nSCORE',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          CircularGauge(
            value: 62,
            maxValue: 100,
            color: AppColors.yellow,
            strokeWidth: 8,
            size: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('62',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('Medium',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Noise-induced',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FreqBandsCard extends StatelessWidget {
  const _FreqBandsCard();

  @override
  Widget build(BuildContext context) {
    const bands = [
      {'label': '20-250Hz', 'pct': 0.45, 'pctLabel': '45%', 'color': AppColors.purple},
      {'label': '250Hz-4kHz', 'pct': 0.72, 'pctLabel': '72%', 'color': AppColors.orange},
      {'label': '4-20kHz', 'pct': 0.38, 'pctLabel': '38%', 'color': AppColors.cyan},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FREQ.\nBANDS',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...bands.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['label'] as String,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                      Text(b['pctLabel'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              color: b['color'] as Color,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: b['pct'] as double,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(b['color'] as Color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NoiseHistoryCard extends StatelessWidget {
  const _NoiseHistoryCard();

  @override
  Widget build(BuildContext context) {
    const times = ['7am', '8am', '9am', '10am', '11am', 'Now'];
    const vals = [0.4, 0.65, 0.78, 0.7, 0.85, 0.78];

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
              Text('Noise History',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('2.4h exposure',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(times.length, (i) {
                final isNow = times[i] == 'Now';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 28,
                          height: 55 * vals[i],
                          decoration: BoxDecoration(
                            color: isNow
                                ? AppColors.orange
                                : AppColors.orange.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(times[i],
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                            color: isNow
                                ? AppColors.orange
                                : AppColors.textSecondary)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
