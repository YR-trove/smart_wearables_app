import 'package:flutter/material.dart';
import '../theme.dart';
import 'developer_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDark = true;
  bool _developerMode = false;
  bool _allNotifications = true;
  bool _circadianAlerts = true;
  bool _noiseAlerts = true;
  bool _uvAlerts = true;

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
              const SizedBox(height: 4),
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _UserCard(),
              const SizedBox(height: 20),
              _SectionLabel('APPEARANCE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDark = true),
                      child: _ThemeOption(label: 'Dark', selected: _isDark, dark: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDark = false),
                      child: _ThemeOption(label: 'Light', selected: !_isDark, dark: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _ToggleRow(
                    icon: '🔧',
                    iconBg: AppColors.purple,
                    title: 'Developer Mode',
                    subtitle: 'Real-time MCU data visualization',
                    value: _developerMode,
                    onChanged: (v) {
                      setState(() => _developerMode = v);
                      if (v) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DeveloperPage()),
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('CONNECTED DEVICE'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('👁️', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('SmartEye Pro v1',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('MAC: E4:5F:01:A2:9C:3B',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.circle, color: AppColors.green, size: 8),
                              SizedBox(width: 4),
                              Text('Connected',
                                  style: TextStyle(
                                      color: AppColors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('RSSI –62 dBm',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Re-pair Device',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Forget Device',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('ALERTS'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _ToggleRow(
                    icon: '🔔',
                    title: 'All Notifications',
                    value: _allNotifications,
                    onChanged: (v) => setState(() => _allNotifications = v),
                  ),
                  _Divider(),
                  _ToggleRow(
                    icon: '🌙',
                    title: 'Circadian Rhythm Alerts',
                    value: _circadianAlerts,
                    onChanged: (v) => setState(() => _circadianAlerts = v),
                  ),
                  _Divider(),
                  _ToggleRow(
                    icon: '⚠️',
                    title: 'Noise & Stress Alerts',
                    value: _noiseAlerts,
                    onChanged: (v) => setState(() => _noiseAlerts = v),
                  ),
                  _Divider(),
                  _ToggleRow(
                    icon: '🌞',
                    title: 'UV & Skin Risk Alerts',
                    value: _uvAlerts,
                    onChanged: (v) => setState(() => _uvAlerts = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alex Johnson',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const Text('alex@email.com',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Pro Member',
                          style: TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FW v2.1.4',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

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
        children: children,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    this.iconBg,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (iconBg != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg!.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          )
        else
          Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.cyan,
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.cardBorder,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;

  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.cyan : AppColors.cardBorder,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            width: 60,
            decoration: BoxDecoration(
              color: dark ? AppColors.cardBorder : const Color(0xFFCDD5E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: dark ? AppColors.textMuted : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: dark ? AppColors.textPrimary : const Color(0xFF1A202C),
                      fontWeight: FontWeight.w600)),
              if (selected)
                const Icon(Icons.check_circle,
                    color: AppColors.cyan, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: AppColors.cardBorder, height: 1),
    );
  }
}
