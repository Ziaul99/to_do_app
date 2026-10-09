import 'package:flutter/material.dart';
import 'package:new_project/constants/colors.dart';
import 'package:new_project/model/todo.dart';

class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final TodoTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isDone,
            onChanged: (_) => onToggle(),
            semanticLabel:
                'Mark ${task.text} as ${task.isDone ? 'active' : 'completed'}',
          ),
          Expanded(
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  task.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.isDone ? AppColors.muted : AppColors.ink,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete ${task.text}',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.danger,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
