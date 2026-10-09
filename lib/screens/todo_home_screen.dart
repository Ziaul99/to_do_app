import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:new_project/constants/colors.dart';
import 'package:new_project/data/task_storage.dart';
import 'package:new_project/model/todo.dart';
import 'package:new_project/widgets/task_controls.dart';
import 'package:new_project/widgets/todo_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key, this.storage});

  final TaskStorage? storage;

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  late final TaskStorage _storage = widget.storage ?? LocalTaskStorage();
  final TextEditingController _taskController = TextEditingController();

  List<TodoTask> _tasks = [];
  List<TodoTask> _visibleTasks = [];
  Uint8List? _profileImage;
  String _searchQuery = '';
  TodoFilter _selectedFilter = TodoFilter.all;
  bool _isLoading = true;
  String? _loadError;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final databaseTasks = await _storage.readTasks();
      final legacyTasks = preferences.getString('saved_todos_list');
      final tasksJson = databaseTasks ?? legacyTasks;
      final databaseImage = await _storage.readProfileImage();
      final legacyImage = preferences.getString('profile_image_data');
      final imageData = databaseImage ?? legacyImage;
      var loadedTasks = <TodoTask>[];

      if (tasksJson != null) {
        final Object? decodedData = jsonDecode(tasksJson);
        if (decodedData is! List) {
          throw const FormatException('Saved tasks are not a list.');
        }
        loadedTasks = decodedData
            .whereType<Map<String, dynamic>>()
            .map(TodoTask.fromMap)
            .toList();
      }

      if (databaseTasks == null && legacyTasks != null) {
        await _storage.writeTasks(legacyTasks);
        await preferences.remove('saved_todos_list');
      }
      if (databaseImage == null && legacyImage != null) {
        await _storage.writeProfileImage(legacyImage);
        await preferences.remove('profile_image_data');
      }

      Uint8List? loadedImage;
      if (imageData != null && imageData.isNotEmpty) {
        try {
          loadedImage = base64Decode(imageData);
        } on FormatException {
          loadedImage = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _tasks = loadedTasks;
        _profileImage = loadedImage;
        _refreshVisibleTasks();
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Your saved tasks could not be loaded.';
      });
    }
  }

  void _refreshVisibleTasks() {
    _visibleTasks = _tasks.where((task) {
      final matchesSearch = task.text.toLowerCase().contains(_searchQuery);
      final matchesFilter = switch (_selectedFilter) {
        TodoFilter.all => true,
        TodoFilter.active => !task.isDone,
        TodoFilter.completed => task.isDone,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _saveTasks() {
    final tasksJson = jsonEncode(_tasks.map((task) => task.toMap()).toList());
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _storage.writeTasks(tasksJson);
      } catch (_) {
        _showMessage('Could not save your changes. Please try again.');
      }
    });
    return _saveQueue;
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
          ),
        ],
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        _showMessage('Choose an image smaller than 2 MB.');
        return;
      }
      await _storage.writeProfileImage(base64Encode(bytes));
      if (!mounted) return;
      setState(() => _profileImage = bytes);
    } catch (_) {
      _showMessage('Could not update the profile picture.');
    }
  }

  void _addTask(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      _showMessage('Enter a task first.');
      return;
    }

    setState(() {
      _tasks.insert(
        0,
        TodoTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
        ),
      );
      _refreshVisibleTasks();
    });
    _taskController.clear();
    _saveTasks();
  }

  void _toggleTask(TodoTask task) {
    setState(() {
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index == -1) return;
      _tasks[index] = task.copyWith(isDone: !task.isDone);
      _refreshVisibleTasks();
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
      _refreshVisibleTasks();
    });
    _saveTasks();
  }

  Future<void> _confirmClearCompleted() async {
    final completedCount = _tasks.where((task) => task.isDone).length;
    if (completedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Clear completed tasks?'),
        content: Text(
          'This will permanently remove $completedCount completed '
          '${completedCount == 1 ? 'task' : 'tasks'}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear completed'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _tasks.removeWhere((task) => task.isDone);
      _refreshVisibleTasks();
    });
    await _saveTasks();
    _showMessage('Completed tasks cleared.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((task) => task.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text('To-do list'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Choose profile picture',
            onPressed: _pickProfileImage,
            icon: CircleAvatar(
              radius: 18,
              foregroundImage: _profileImage == null
                  ? null
                  : MemoryImage(_profileImage!),
              backgroundColor: AppColors.primarySoft,
              child: _profileImage == null
                  ? const Icon(Icons.person_outline, size: 21)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildLoadError()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TaskSearchField(
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query.trim().toLowerCase();
                              _refreshVisibleTasks();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My tasks',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount of ${_tasks.length} completed',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (completedCount > 0)
                              Tooltip(
                                message: 'Clear completed tasks',
                                child: TextButton.icon(
                                  onPressed: _confirmClearCompleted,
                                  icon: const Icon(
                                    Icons.cleaning_services_outlined,
                                  ),
                                  label: const Text('Clear completed'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TaskFilterControl(
                          selected: _selectedFilter,
                          onChanged: (filter) {
                            setState(() {
                              _selectedFilter = filter;
                              _refreshVisibleTasks();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _visibleTasks.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  key: const Key('task-list'),
                                  padding: const EdgeInsets.only(top: 6),
                                  itemCount: _visibleTasks.length,
                                  itemBuilder: (context, index) {
                                    final task = _visibleTasks[index];
                                    return TodoItem(
                                      task: task,
                                      onToggle: () => _toggleTask(task),
                                      onDelete: () => _deleteTask(task.id),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading || _loadError != null
          ? null
          : AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 78,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                        child: TaskComposer(
                          controller: _taskController,
                          onSubmitted: _addTask,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadSavedData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isEmpty = _tasks.isEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty ? Icons.edit_note : Icons.filter_alt_off_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            isEmpty ? 'A clear list, a fresh start.' : 'No matching tasks.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
          ),
          if (isEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Add your first task below.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
