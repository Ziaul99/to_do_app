enum TodoFilter { all, active, completed }

class TodoTask {
  const TodoTask({required this.id, required this.text, this.isDone = false});

  final String id;
  final String text;
  final bool isDone;

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'isDone': isDone};

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String || map['text'] is! String) {
      throw const FormatException('Invalid saved task.');
    }
    return TodoTask(
      id: map['id'] as String,
      text: map['text'] as String,
      isDone: map['isDone'] == true,
    );
  }

  TodoTask copyWith({bool? isDone}) =>
      TodoTask(id: id, text: text, isDone: isDone ?? this.isDone);
}
