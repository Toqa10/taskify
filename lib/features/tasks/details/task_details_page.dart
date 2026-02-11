import 'package:flutter/material.dart';
import '../../../core/task_store.dart';

class TaskDetailsPage extends StatelessWidget {
  final TaskStore store;
  final TaskItem task;

  const TaskDetailsPage({
    super.key,
    required this.store,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final dueText = task.dueDate == null
        ? "No due date"
        : "${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Edit",
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditSheet(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(task.isDone ? Icons.check_circle : Icons.circle_outlined, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            _infoTile(context, "Category", task.category.label, Icons.category),
            _infoTile(context, "Priority", task.priority.label, Icons.flag),
            _infoTile(context, "Due Date", dueText, Icons.calendar_month),
            _infoTile(context, "Status", task.isDone ? "Done ✅" : "Pending ⏳", Icons.timelapse),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await store.toggleDone(task.id, !task.isDone);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: Icon(task.isDone ? Icons.undo : Icons.check),
                    label: Text(task.isDone ? "Undo Done" : "Mark Done"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await store.deleteTask(task.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: task.title);
    Priority selectedPriority = task.priority;
    Category selectedCategory = task.category;
    DateTime? selectedDue = task.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
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
                  Text("Edit Task", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
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
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: Category.values
                              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                              .toList(),
                          onChanged: (v) => setLocal(() => selectedCategory = v ?? selectedCategory),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<Priority>(
                          value: selectedPriority,
                          decoration: const InputDecoration(
                            labelText: "Priority",
                            border: OutlineInputBorder(),
                          ),
                          items: Priority.values
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                              .toList(),
                          onChanged: (v) => setLocal(() => selectedPriority = v ?? selectedPriority),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 5),
                              initialDate: selectedDue ?? now,
                            );
                            if (picked != null) setLocal(() => selectedDue = picked);
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: Text(selectedDue == null
                              ? "Pick Due Date"
                              : "${selectedDue!.year}-${selectedDue!.month.toString().padLeft(2, '0')}-${selectedDue!.day.toString().padLeft(2, '0')}"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setLocal(() => selectedDue = null),
                        child: const Text("Clear"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await store.updateTask(
                          id: task.id,
                          title: titleCtrl.text,
                          priority: selectedPriority,
                          category: selectedCategory,
                          dueDate: selectedDue,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
