// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/theme_provider.dart'; // Adjust path if needed
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
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
    final cardColor = Theme.of(context).cardColor;
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                child: Text(
                  'AJ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                    // Dynamic border so it matches the card background (dark or light)
                    border: Border.all(color: cardColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alex Johnson',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'BLE_SW Connected',
                    style: TextStyle(fontSize: 13, color: mutedText, fontWeight: FontWeight.w500),
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
    final themeProvider = context.watch<ThemeProvider>();
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

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
                    Text('Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    CupertinoSlidingSegmentedControl<int>(
                      groupValue: themeProvider.themeIndex,
                      onValueChanged: (v) {
                        if (v != null) context.read<ThemeProvider>().setThemeMode(v);
                      },
                      children: const {
                        0: Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('Light', style: TextStyle(fontSize: 12))),
                        1: Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('Dark', style: TextStyle(fontSize: 12))),
                        2: Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('Auto', style: TextStyle(fontSize: 12))),
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Accent Color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    Row(
                      children: _accentColors.map((color) {
                        final selected = color.value == themeProvider.accentColor.value;
                        return GestureDetector(
                          onTap: () => context.read<ThemeProvider>().setAccentColor(color),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
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
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, thickness: 1, color: dividerColor),
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
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              ),
              Text(value, style: TextStyle(fontSize: 14, color: mutedText)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: mutedText),
            ],
          ),
        ),
        if (!last) Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  Widget _developerSection() {
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

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
                        Text('Developer Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                        CupertinoSwitch(
                          value: widget.devMode,
                          onChanged: widget.onDevModeChanged,
                          activeTrackColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.devMode
                          ? 'Developer Dashboard is now visible in navigation'
                          : 'Enables real-time sensor data dashboard',
                      style: TextStyle(fontSize: 13, color: mutedText),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Firmware Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    Text('v1.2.4', style: TextStyle(fontSize: 14, color: mutedText)),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('BLE Debug', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    Text('View raw packets', style: TextStyle(fontSize: 14, color: mutedText)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: mutedText),
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
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

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
                  children: [
                    Expanded(
                      child: Text('App Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    Text('2.0.1 (Build 42)', style: TextStyle(fontSize: 13, color: mutedText)),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              _chevronRow('Privacy Policy', '', last: false),
              _chevronRow('Contact Support', '', last: true),
            ],
          ),
        ),
      ],
    );
  }
}