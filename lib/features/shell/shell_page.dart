import 'package:flutter/material.dart';
import '../../core/task_store.dart';
import '../home/home_page.dart';
import '../tasks/tasks_page.dart';
import '../settings/settings_page.dart';

class ShellPage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;

  const ShellPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  final TaskStore store = TaskStore();

  @override
  void initState() {
    super.initState();
    store.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: store),
      TasksPage(store: store),
      SettingsPage(
        selected: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    final titles = ["Home", "Tasks", "Settings"];

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_index]),
            centerTitle: true,
          ),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: "Home"),
              NavigationDestination(icon: Icon(Icons.checklist), label: "Tasks"),
              NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
            ],
          ),
        );
      },
    );
  }
}
