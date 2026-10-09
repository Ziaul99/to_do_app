// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/data/task_storage.dart';
import 'package:new_project/main.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTaskStorage implements TaskStorage {
  String? tasks;
  String? profileImage;

  @override
  Future<String?> readTasks() async => tasks;

  @override
  Future<void> writeTasks(String value) async => tasks = value;

  @override
  Future<String?> readProfileImage() async => profileImage;

  @override
  Future<void> writeProfileImage(String value) async => profileImage = value;
}

void main() {
  test('local storage persists both task and profile values', () async {
    final database = await databaseFactoryMemory.openDatabase('task-storage');
    final storage = LocalTaskStorage(openDatabase: () async => database);

    await storage.writeTasks('[{"id":"1","text":"Saved task"}]');
    await storage.writeProfileImage('encoded-image');

    expect(await storage.readTasks(), contains('Saved task'));
    expect(await storage.readProfileImage(), 'encoded-image');
    await database.close();
  });

  testWidgets('app opens empty and supports the task workflow', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = MemoryTaskStorage();
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('My tasks'), findsOneWidget);
    expect(find.text('A clear list, a fresh start.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-composer')),
      'Plan launch',
    );
    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();
    expect(storage.tasks, contains('Plan launch'));
    expect(find.text('No matching tasks.'), findsNothing);
    final taskList = tester.widget<ListView>(
      find.byKey(const Key('task-list')),
    );
    expect(
      (taskList.childrenDelegate as SliverChildBuilderDelegate).childCount,
      1,
    );
    expect(
      tester.getSize(find.byKey(const Key('task-list'))).height,
      greaterThan(0),
    );
    expect(find.text('Plan launch'), findsOneWidget);

    await tester.tap(find.text('Plan launch'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Plan launch'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear completed tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Clear completed tasks?'), findsOneWidget);
    expect(find.text('Plan launch'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Plan launch'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear completed tasks'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Clear completed'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A clear list, a fresh start.'), findsOneWidget);
  });

  testWidgets('task composer remains visible above the onscreen keyboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MyApp(storage: MemoryTaskStorage()));
    await tester.pumpAndSettle();

    final composerRect = tester.getRect(find.byKey(const Key('task-composer')));
    expect(composerRect.bottom, lessThanOrEqualTo(844 - 300));
  });

  testWidgets('database tasks take precedence over old preference data', (
    WidgetTester tester,
  ) async {
    final storage = MemoryTaskStorage();
    storage.tasks = '[{"id":"42","text":"Saved task","isDone":false}]';
    SharedPreferences.setMockInitialValues({
      'saved_todos_list': '[{"id":"old","text":"Legacy task"}]',
    });
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Saved task'), findsOneWidget);
    expect(storage.tasks, contains('Saved task'));
  });

  testWidgets('app migrates tasks saved by earlier versions', (
    WidgetTester tester,
  ) async {
    final storage = MemoryTaskStorage();
    SharedPreferences.setMockInitialValues({
      'saved_todos_list': '[{"id":"old","text":"Legacy task"}]',
    });
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Legacy task'), findsOneWidget);
    expect(storage.tasks, contains('Legacy task'));
    expect(
      (await SharedPreferences.getInstance()).getString('saved_todos_list'),
      isNull,
    );
  });
}
