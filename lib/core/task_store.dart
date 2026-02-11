import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return "Low";
      case Priority.medium:
        return "Medium";
      case Priority.high:
        return "High";
    }
  }

  static Priority fromString(String v) {
    return Priority.values.firstWhere(
          (e) => e.name == v,
      orElse: () => Priority.medium,
    );
  }
}

enum Category { study, work, personal }

extension CategoryX on Category {
  String get label {
    switch (this) {
      case Category.study:
        return "Study";
      case Category.work:
        return "Work";
      case Category.personal:
        return "Personal";
    }
  }

  static Category fromString(String v) {
    return Category.values.firstWhere(
          (e) => e.name == v,
      orElse: () => Category.study,
    );
  }
}

class TaskItem {
  final String id;
  String title; // 👈 editable
  bool isDone;
  Priority priority;
  Category category;
  DateTime createdAt;
  DateTime? dueDate;

  TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.dueDate,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "title": title,
    "isDone": isDone,
    "priority": priority.name,
    "category": category.name,
    "createdAt": createdAt.toIso8601String(),
    "dueDate": dueDate?.toIso8601String(),
  };

  static TaskItem fromMap(Map<String, dynamic> m) {
    return TaskItem(
      id: m["id"] as String,
      title: m["title"] as String,
      isDone: (m["isDone"] as bool?) ?? false,
      priority: PriorityX.fromString((m["priority"] as String?) ?? "medium"),
      category: CategoryX.fromString((m["category"] as String?) ?? "study"),
      createdAt: DateTime.parse(m["createdAt"] as String),
      dueDate: m["dueDate"] == null ? null : DateTime.parse(m["dueDate"] as String),
    );
  }
}

class TaskStore extends ChangeNotifier {
  static const _prefsKey = "taskify_tasks_v2"; // 👈 bump version

  bool _ready = false;
  bool get ready => _ready;

  final List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  int get total => _tasks.length;
  int get done => _tasks.where((t) => t.isDone).length;
  int get pending => total - done;
  double get progress => total == 0 ? 0 : done / total;

  Future<void> init() async {
    await _load();
    _ready = true;
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw == null || raw.trim().isEmpty) {
      _tasks.addAll([
        TaskItem(
          id: _newId(),
          title: "Study Dart OOP",
          priority: Priority.high,
          category: Category.study,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        TaskItem(
          id: _newId(),
          title: "Practice Flutter UI",
          priority: Priority.medium,
          category: Category.study,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 3)),
        ),
        TaskItem(
          id: _newId(),
          title: "Build Todo App",
          priority: Priority.low,
          category: Category.work,
          createdAt: DateTime.now(),
        ),
      ]);
      await _save();
      return;
    }

    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _tasks
      ..clear()
      ..addAll(list.map(TaskItem.fromMap));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> addTask({
    required String title,
    Priority priority = Priority.medium,
    Category category = Category.study,
    DateTime? dueDate,
  }) async {
    final t = title.trim();
    if (t.isEmpty) return;

    _tasks.insert(
      0,
      TaskItem(
        id: _newId(),
        title: t,
        priority: priority,
        category: category,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      ),
    );

    await _save();
    notifyListeners();
  }

  Future<void> toggleDone(String id, bool value) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx].isDone = value;
    await _save();
    notifyListeners();
  }

  Future<void> updateTask({
    required String id,
    String? title,
    Priority? priority,
    Category? category,
    DateTime? dueDate,
  }) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final task = _tasks[idx];

    if (title != null) {
      final t = title.trim();
      if (t.isNotEmpty) task.title = t;
    }
    if (priority != null) task.priority = priority;
    if (category != null) task.category = category;
    task.dueDate = dueDate;

    await _save();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _tasks.clear();
    await _save();
    notifyListeners();
  }
}
