import 'package:flutter/material.dart';
import 'features/shell/shell_page.dart';

class TaskifyApp extends StatefulWidget {
  const TaskifyApp({super.key});

  @override
  State<TaskifyApp> createState() => _TaskifyAppState();
}

class _TaskifyAppState extends State<TaskifyApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _mode,
      home: ShellPage(
        themeMode: _mode,
        onThemeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}
