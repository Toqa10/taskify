import 'package:flutter/material.dart';
import '../../core/task_store.dart';
import 'details/task_details_page.dart';

enum StatusFilter { all, pending, done }
enum SortBy { newest, dueDate, priority }

class TasksPage extends StatefulWidget {
  final TaskStore store;
  const TasksPage({super.key, required this.store});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();

  StatusFilter _status = StatusFilter.all;
  Priority? _priority; // null => any
  SortBy _sortBy = SortBy.newest;

  late final TabController _tab;
  Category? _categoryFilter; // null means all (but we’ll set from tab)

  // add form
  final TextEditingController _title = TextEditingController();
  Priority _newPriority = Priority.medium;
  Category _newCategory = Category.study;
  DateTime? _newDueDate;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() {
          _categoryFilter = switch (_tab.index) {
            0 => null, // All
            1 => Category.study,
            2 => Category.work,
            3 => Category.personal,
            _ => null,
          };
        });
      }
    });
    _categoryFilter = null;
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    _title.dispose();
    super.dispose();
  }

  List<TaskItem> _filteredTasks(List<TaskItem> tasks) {
    final q = _search.text.trim().toLowerCase();

    final result = tasks.where((t) {
      final matchesQuery = q.isEmpty || t.title.toLowerCase().contains(q);

      final matchesStatus = switch (_status) {
        StatusFilter.all => true,
        StatusFilter.pending => !t.isDone,
        StatusFilter.done => t.isDone,
      };

      final matchesPriority = _priority == null || t.priority == _priority;

      final matchesCategory = _categoryFilter == null || t.category == _categoryFilter;

      return matchesQuery && matchesStatus && matchesPriority && matchesCategory;
    }).toList();

    result.sort((a, b) {
      switch (_sortBy) {
        case SortBy.newest:
          return b.createdAt.compareTo(a.createdAt);

        case SortBy.dueDate:
          final ad = a.dueDate ?? DateTime(9999);
          final bd = b.dueDate ?? DateTime(9999);
          return ad.compareTo(bd);

        case SortBy.priority:
          int rank(Priority p) => p == Priority.high ? 0 : p == Priority.medium ? 1 : 2;
          return rank(a.priority).compareTo(rank(b.priority));
      }
    });

    return result;
  }

  void _openAddSheet() {
    _title.clear();
    _newPriority = Priority.medium;
    _newCategory = Category.study;
    _newDueDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Task", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _newCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: Category.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _newCategory = v ?? Category.study),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Priority>(
                      value: _newPriority,
                      decoration: const InputDecoration(
                        labelText: "Priority",
                        border: OutlineInputBorder(),
                      ),
                      items: Priority.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _newPriority = v ?? Priority.medium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) setState(() => _newDueDate = picked);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(_newDueDate == null
                    ? "Pick Due Date"
                    : "${_newDueDate!.year}-${_newDueDate!.month.toString().padLeft(2, '0')}-${_newDueDate!.day.toString().padLeft(2, '0')}"),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await widget.store.addTask(
                      title: _title.text,
                      priority: _newPriority,
                      category: _newCategory,
                      dueDate: _newDueDate,
                    );
                    if (mounted) Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Task added ✅")),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _priorityBg(Priority p) {
    switch (p) {
      case Priority.low:
        return Colors.greenAccent.withOpacity(0.18);
      case Priority.medium:
        return Colors.orangeAccent.withOpacity(0.18);
      case Priority.high:
        return Colors.redAccent.withOpacity(0.18);
    }
  }

  IconData _priorityIcon(Priority p) {
    switch (p) {
      case Priority.low:
        return Icons.low_priority;
      case Priority.medium:
        return Icons.flag_outlined;
      case Priority.high:
        return Icons.priority_high;
    }
  }

  IconData _categoryIcon(Category c) {
    switch (c) {
      case Category.study:
        return Icons.school;
      case Category.work:
        return Icons.work_outline;
      case Category.personal:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final tasks = _filteredTasks(widget.store.tasks);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddSheet,
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Search tasks...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Tabs
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  ),
                  child: TabBar(
                    controller: _tab,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    tabs: const [
                      Tab(text: "All"),
                      Tab(text: "Study"),
                      Tab(text: "Work"),
                      Tab(text: "Personal"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Sort
                DropdownButtonFormField<SortBy>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: "Sort By",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: SortBy.newest, child: Text("Newest")),
                    DropdownMenuItem(value: SortBy.dueDate, child: Text("Due Date")),
                    DropdownMenuItem(value: SortBy.priority, child: Text("Priority")),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? SortBy.newest),
                ),

                const SizedBox(height: 12),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip("All", _status == StatusFilter.all, () => setState(() => _status = StatusFilter.all)),
                      _chip("Pending", _status == StatusFilter.pending, () => setState(() => _status = StatusFilter.pending)),
                      _chip("Done", _status == StatusFilter.done, () => setState(() => _status = StatusFilter.done)),
                      const SizedBox(width: 8),
                      _chip("Any Priority", _priority == null, () => setState(() => _priority = null)),
                      _chip("High", _priority == Priority.high, () => setState(() => _priority = Priority.high)),
                      _chip("Medium", _priority == Priority.medium, () => setState(() => _priority = Priority.medium)),
                      _chip("Low", _priority == Priority.low, () => setState(() => _priority = Priority.low)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // List
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                    child: Text("No tasks match 👀", style: Theme.of(context).textTheme.titleMedium),
                  )
                      : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final t = tasks[index];
                      final due = t.dueDate == null
                          ? "No due date"
                          : "${t.dueDate!.year}-${t.dueDate!.month.toString().padLeft(2, '0')}-${t.dueDate!.day.toString().padLeft(2, '0')}";

                      // ✅ simple animation per item (scale + fade)
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.96, end: 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(scale: value, child: child),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _priorityBg(t.priority),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 240),
                                  pageBuilder: (_, __, ___) => TaskDetailsPage(store: widget.store, task: t),
                                  transitionsBuilder: (_, anim, __, child) {
                                    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
                                    return FadeTransition(
                                      opacity: curved,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.06),
                                          end: Offset.zero,
                                        ).animate(curved),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_priorityIcon(t.priority)),
                                const SizedBox(height: 6),
                                Icon(_categoryIcon(t.category), size: 18),
                              ],
                            ),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: t.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text("Category: ${t.category.label} • Priority: ${t.priority.label} • Due: $due"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: t.isDone,
                                  onChanged: (v) async {
                                    await widget.store.toggleDone(t.id, v ?? false);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(v == true ? "Marked done ✅" : "Marked pending ⏳")),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await widget.store.deleteTask(t.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Task deleted 🗑️")),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),
                Text("© Taskify", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? Colors.deepPurple.withOpacity(0.25) : Colors.transparent,
            border: Border.all(color: Colors.white10),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
