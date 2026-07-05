import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/theme_provider.dart'; // Adjust path if needed
import 'package:smart_wearables_app/data/session_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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

  final _ageCtrl    = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _selectedGender;
  bool _profileInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileInitialized) {
      final user = context.read<SessionStore>().currentUser;
      if (user != null) {
        _ageCtrl.text    = user.age?.toString() ?? '';
        _weightCtrl.text = user.weightKg?.toString() ?? '';
        _heightCtrl.text = user.heightCm?.toString() ?? '';
        _selectedGender  = user.gender;
      }
      _profileInitialized = true;
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final user = context.read<SessionStore>().currentUser;
    if (user != null) {
      context.read<SessionStore>().updateCurrentUser(
        name:     user.name,
        gender:   _selectedGender,
        age:      int.tryParse(_ageCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
        heightCm: double.tryParse(_heightCtrl.text),
      );
    }
  }

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
          _profileSection(),
          const SizedBox(height: 24),
          _appearanceSection(),
          const SizedBox(height: 24),
          _aboutSection(),
        ],
      ),
    );
  }

  Widget _profileSection() {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Profile'),
        const SizedBox(height: 6),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildProfileRow('Gender', DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  hint: const Text('Select'),
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 15, color: onSurfaceColor)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { _selectedGender = newValue; });
                    _saveProfile();
                  },
                ),
              )),
              Divider(height: 1, thickness: 1, color: dividerColor),
              _buildProfileInputRow('Age (Years)', _ageCtrl),
              Divider(height: 1, thickness: 1, color: dividerColor),
              _buildProfileInputRow('Weight (kg)', _weightCtrl),
              Divider(height: 1, thickness: 1, color: dividerColor),
              _buildProfileInputRow('Height (cm)', _heightCtrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInputRow(String label, TextEditingController controller) {
    return _buildProfileRow(label, SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Enter',
        ),
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
          _saveProfile();
        },
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
          _saveProfile();
        },
      ),
    ));
  }

  Widget _buildProfileRow(String label, Widget child) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurfaceColor)),
          child,
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
              Text('2.2.0 (Beta Version)', style: TextStyle(fontSize: 13, color: mutedText)),
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
