import 'package:flutter/material.dart';
import '../app_theme.dart';

class StressPage extends StatelessWidget {
  const StressPage({super.key});

  static const _waveHeights = [40, 60, 45, 80, 50, 65, 35, 90, 55, 70, 40, 60, 45, 80, 50, 65, 40, 55, 85];
  static const _timelineData = [
    ('8a', 45), ('10a', 55), ('12p', 68), ('2p', 94), ('4p', 72), ('6p', 65), ('8p', 50)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _noiseHero(),
          const SizedBox(height: 20),
          _summarySection(),
          const SizedBox(height: 20),
          _alertCards(),
          const SizedBox(height: 20),
          _earSafetySection(),
          const SizedBox(height: 20),
          _timelineSection(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: const Text(
        'Stress & Noise',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }

  Widget _noiseHero() {
    return Column(
      children: [
        const Text(
          '68 dB',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Text(
          'Moderate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _waveHeights.map((h) {
              return Container(
                width: 6,
                height: h * 0.48,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: h > 75 ? AppColors.warning : const Color(0xFF60A5FA),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _summarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Today's Summary"),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              CardRow(label: 'Exposure', value: '4h 22m'),
              CardRow(label: 'Peak Noise', value: '94 dB at 2:15 PM', showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alertCards() {
    return Column(
      children: [
        AppCard(
          leftBorderColor: AppColors.warning,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Prolonged Noise Warning',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2h 10m in >70 dB, Mild hearing fatigue',
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
          leftBorderColor: AppColors.danger,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.monitor_heart_outlined, color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Stress Indicator',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'High noise correlated with elevated stress',
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

  Widget _earSafetySection() {
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
                children: const [
                  Text('Daily Dose', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  Text('62%', style: TextStyle(fontSize: 15, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              const AppProgressBar(value: 0.62),
              const SizedBox(height: 8),
              const Text(
                '62% of safe limit (WHO 85 dB / 8h)',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineSection() {
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
