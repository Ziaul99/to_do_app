import 'package:sembast/sembast.dart';

import 'platform_database.dart'
    if (dart.library.js_interop) 'platform_database_web.dart'
    as platform;

abstract interface class TaskStorage {
  Future<String?> readTasks();
  Future<void> writeTasks(String value);
  Future<String?> readProfileImage();
  Future<void> writeProfileImage(String value);
}

class LocalTaskStorage implements TaskStorage {
  LocalTaskStorage({Future<Database> Function()? openDatabase})
    : _openDatabase = openDatabase ?? platform.openDatabase;

  final Future<Database> Function() _openDatabase;
  Future<Database>? _database;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory
      .store('app_state');

  Future<Database> get _db => _database ??= _openDatabase();

  @override
  Future<String?> readTasks() => _readValue('tasks');

  @override
  Future<void> writeTasks(String value) => _writeValue('tasks', value);

  @override
  Future<String?> readProfileImage() => _readValue('profile_image');

  @override
  Future<void> writeProfileImage(String value) =>
      _writeValue('profile_image', value);

  Future<String?> _readValue(String key) async {
    final database = await _db;
    final state = await _store.record('state').get(database);
    final value = state?[key];
    return value is String ? value : null;
  }

  Future<void> _writeValue(String key, String value) async {
    final database = await _db;
    await database.transaction((transaction) async {
      final record = _store.record('state');
      final state = await record.get(transaction) ?? <String, Object?>{};
      await record.put(transaction, {...state, key: value});
    });
  }
}
