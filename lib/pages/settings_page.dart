import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class SettingsPage extends StatefulWidget {
  final bool devMode;
  final ValueChanged<bool> onDevModeChanged;

  const SettingsPage({
    super.key,
    required this.devMode,
    required this.onDevModeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _themeIndex = 1; // 0=Light, 1=Dark, 2=Auto
  int _accentIndex = 0;
  bool _notifBlue = true;
  bool _notifNoise = true;
  bool _notifCircadian = false;
  bool _notifStep = true;

  static const _accentColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _profileCard(),
          const SizedBox(height: 24),
          _appearanceSection(),
          const SizedBox(height: 24),
          _notificationsSection(),
          const SizedBox(height: 24),
          _healthGoalsSection(),
          const SizedBox(height: 24),
          _developerSection(),
          const SizedBox(height: 24),
          _aboutSection(),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.border,
                child: const Text(
                  'AJ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
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
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Alex Johnson',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'BLE_SW Connected',
                    style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Appearance'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    CupertinoSlidingSegmentedControl<int>(
                      groupValue: _themeIndex,
                      onValueChanged: (v) => setState(() => _themeIndex = v ?? _themeIndex),
                      children: const {
                        0: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Light', style: TextStyle(fontSize: 12)),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Dark', style: TextStyle(fontSize: 12)),
                        ),
                        2: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Auto', style: TextStyle(fontSize: 12)),
                        ),
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Accent Color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    Row(
                      children: _accentColors.asMap().entries.map((e) {
                        final selected = e.key == _accentIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _accentIndex = e.key),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: AppColors.inactive, width: 2)
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
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

  Widget _notificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Notifications'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              _switchRow('Blue Light Alert', _notifBlue, (v) => setState(() => _notifBlue = v)),
              _switchRow('Noise Warning', _notifNoise, (v) => setState(() => _notifNoise = v)),
              _switchRow('Circadian Reminder', _notifCircadian, (v) => setState(() => _notifCircadian = v)),
              _switchRow('Step Goal Alert', _notifStep, (v) => setState(() => _notifStep = v), last: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.accent,
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _healthGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Health Goals'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              _chevronRow('Daily Steps', '10,000'),
              _chevronRow('Calorie Goal', '500 kcal'),
              _chevronRow('Noise Limit', '85 dB (WHO)', last: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chevronRow(String label, String value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.inactive),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _developerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Developer'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Developer Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        CupertinoSwitch(
                          value: widget.devMode,
                          onChanged: widget.onDevModeChanged,
                          activeTrackColor: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.devMode
                          ? 'Developer Dashboard is now visible in navigation'
                          : 'Enables real-time sensor data dashboard',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Firmware Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    Text('v1.2.4', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text('BLE Debug', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    ),
                    Text('View raw packets', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: AppColors.inactive),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('About'),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text('App Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    ),
                    Text('2.0.1 (Build 42)', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              _chevronRow('Privacy Policy', '', last: false),
              _chevronRow('Contact Support', '', last: true),
            ],
          ),
        ),
      ],
    );
  }
}
