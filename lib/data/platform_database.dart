import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openDatabase() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase(
    path.join(supportDirectory.path, 'new_project_tasks.db'),
  );
}
