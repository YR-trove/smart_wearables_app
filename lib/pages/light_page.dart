import 'package:flutter/material.dart';
import '../app_theme.dart';

class LightPage extends StatelessWidget {
  const LightPage({super.key});

  static const _hourlyData = [20, 45, 70, 85, 90, 75, 60, 50, 55, 40, 30, 15, 10];
  static const _hours = ['8', '9', '10', '11', '12', '1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _blueLightSection(),
          const SizedBox(height: 20),
          _sunlightSection(),
          const SizedBox(height: 20),
          _circadianSection(),
          const SizedBox(height: 20),
          _timelineSection(),
          const SizedBox(height: 20),
          _accumulatedSection(),
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
        'Light Exposure',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _blueLightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Blue Light'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    RingGauge(value: 0.58, size: 68, strokeWidth: 7),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '2h 34m',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            "Today's exposure",
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Moderate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Blue fraction', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text('42%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const AppProgressBar(value: 0.42),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sunlightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Sunlight'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Sun Exposure',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1h 12m',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        RingGauge(
                          value: 0.30,
                          size: 56,
                          strokeWidth: 6,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'UV Index 3',
                          style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Skin Burn Risk: Low',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '45 min protection remaining',
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
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

  Widget _circadianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Circadian Rhythm'),
        const SizedBox(height: 6),
        AppCard(
          leftBorderColor: AppColors.warning,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Disruption Risk: Elevated',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your circadian dose is above the recommended threshold for this time of day.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Reduce blue after 9 PM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blue light intensity by hour',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_hourlyData.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: _hourlyData[i] / 100,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF60A5FA),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _hours[i],
                              style: const TextStyle(fontSize: 7, color: AppColors.inactive),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('8 AM', style: TextStyle(fontSize: 10, color: AppColors.inactive)),
                  Text('8 PM', style: TextStyle(fontSize: 10, color: AppColors.inactive)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accumulatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Accumulated Dose'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Blue Exposure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        Text('48,320 units', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AppProgressBar(value: 0.64),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Circadian Dose', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        Text('21,044 units', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AppProgressBar(value: 0.42, color: AppColors.warning),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
