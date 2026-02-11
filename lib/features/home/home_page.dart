import 'package:flutter/material.dart';
import '../../core/task_store.dart';

class HomePage extends StatelessWidget {
  final TaskStore store;
  const HomePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final upcoming = store.tasks
            .where((t) => !t.isDone && t.dueDate != null)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        final top3 = upcoming.take(3).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(store: store),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(title: "Total", value: "${store.total}", icon: Icons.list_alt)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: "Done", value: "${store.done}", icon: Icons.check_circle)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: "Pending", value: "${store.pending}", icon: Icons.pending_actions)),
                ],
              ),
              const SizedBox(height: 18),

              Text("Upcoming", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),

              if (top3.isEmpty)
                Text("No upcoming tasks 👌", style: Theme.of(context).textTheme.bodyMedium)
              else
                ...top3.map((t) => _TaskMiniCard(task: t)),

              const SizedBox(height: 18),
              Center(
                child: Text(
                  "© Taskify — Built with Flutter 💙",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final TaskStore store;
  const _Header({required this.store});

  @override
  Widget build(BuildContext context) {
    final percent = (store.progress * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.92),
            Theme.of(context).colorScheme.secondary.withOpacity(0.78),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hello Toqa 👋",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Let’s finish your tasks today ✨",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Text("Progress: $percent%", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: store.progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _TaskMiniCard extends StatelessWidget {
  final TaskItem task;
  const _TaskMiniCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate!;
    final dueText = "${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(_priorityIcon(task.priority)),
        title: Text(task.title),
        subtitle: Text("Priority: ${task.priority.label} • Due: $dueText"),
      ),
    );
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
}
