import 'package:flutter/material.dart';
import 'package:new_project/constants/app_theme.dart';
import 'package:new_project/data/task_storage.dart';
import 'package:new_project/screens/todo_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.storage});

  final TaskStorage? storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-do list',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: TodoHomeScreen(storage: storage),
    );
  }
}
