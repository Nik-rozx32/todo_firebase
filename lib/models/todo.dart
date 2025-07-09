import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String text;
  final bool isDone;
  final Timestamp timestamp;

  Todo(
      {required this.id,
      required this.text,
      required this.isDone,
      required this.timestamp});

  factory Todo.fromMap(Map<String, dynamic> data, String id) {
    return Todo(
        id: id,
        text: data['text'],
        isDone: data['isDone'],
        timestamp: data['timestamp']);
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'isDone': isDone, 'timestamp': timestamp};
  }
}
