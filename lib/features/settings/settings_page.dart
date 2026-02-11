import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ThemeMode selected;
  final void Function(ThemeMode) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.selected,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Choose Theme", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),

        _themeTile(context, title: "Light ☀️", mode: ThemeMode.light),
        const SizedBox(height: 10),

        _themeTile(context, title: "Dark 🌙", mode: ThemeMode.dark),
        const SizedBox(height: 10),

        _themeTile(context, title: "System ⚙️", mode: ThemeMode.system),
      ],
    );
  }

  Widget _themeTile(BuildContext context, {required String title, required ThemeMode mode}) {
    final isSelected = selected == mode;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(title),
        trailing: isSelected ? const Icon(Icons.check) : null,
        onTap: () => onThemeChanged(mode),
      ),
    );
  }
}
