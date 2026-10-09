import 'package:flutter/material.dart';

import '../model/todo.dart';

class TaskSearchField extends StatelessWidget {
  const TaskSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search tasks',
      ),
    );
  }
}

class TaskFilterControl extends StatelessWidget {
  const TaskFilterControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TodoFilter>(
      segments: const [
        ButtonSegment(value: TodoFilter.all, label: Text('All')),
        ButtonSegment(value: TodoFilter.active, label: Text('Active')),
        ButtonSegment(value: TodoFilter.completed, label: Text('Completed')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class TaskComposer extends StatelessWidget {
  const TaskComposer({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('task-composer'),
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmitted,
            maxLength: 120,
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'Add a task',
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox.square(
          dimension: 52,
          child: IconButton.filled(
            tooltip: 'Add task',
            onPressed: () => onSubmitted(controller.text),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
