import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/theme_provider.dart'; // Adjust path if needed

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
  static const _accentColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w600, 
            color: theme.colorScheme.onSurface
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _appearanceSection(),
          const SizedBox(height: 24),
          _developerSection(),
          const SizedBox(height: 24),
          _aboutSection(),
        ],
      ),
    );
  }

  Widget _appearanceSection() {
    final themeProvider = context.watch<ThemeProvider>();
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Appearance'),
        const SizedBox(height: 6),
        AppCard(
          padding: EdgeInsets.zero, // Padding handled inside the rows
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurfaceColor)),
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
                    Text('Accent Color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurfaceColor)),
                    Row(
                      children: _accentColors.map((color) {
                        final selected = color == themeProvider.accentColor;
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
                                  ? Border.all(color: onSurfaceColor, width: 2)
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

  Widget _developerSection() {
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Developer'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Developer Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurfaceColor)),
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
                    ? 'Dashboard is visible. Firmware sending metrics Raw Packets.'
                    : 'Enables 20Hz Raw Sensor Dashboard.',
                style: TextStyle(fontSize: 13, color: mutedText, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutSection() {
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('About'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('App Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurfaceColor)),
              Text('2.1.0 (Alpha Version)', style: TextStyle(fontSize: 13, color: mutedText)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Internal Reusable UI Widgets 
// ============================================================================

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}