import 'package:flutter/material.dart';
import 'models/todo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum FilterOption { all, completed, incomplete }

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final _controller = TextEditingController();
  FilterOption _filter = FilterOption.all;

  void _toggleTodo(Todo todo) {
    FirebaseFirestore.instance.collection('todos').doc(todo.id).update({
      'isDone': !todo.isDone,
    });
  }

  void _deleteTodo(String id) {
    FirebaseFirestore.instance.collection('todos').doc(id).delete();
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final collection = FirebaseFirestore.instance
        .collection('todos')
        .orderBy('timestamp', descending: false);

    switch (_filter) {
      case FilterOption.completed:
        return collection.where('isDone', isEqualTo: true).snapshots();
      case FilterOption.incomplete:
        return collection.where('isDone', isEqualTo: false).snapshots();
      case FilterOption.all:
      default:
        return collection.snapshots();
    }
  }

  void _addTodo(String text) async {
    if (text.isEmpty) return;
    final docRef = FirebaseFirestore.instance.collection('todos').doc();
    await docRef.set({
      'text': text,
      'isDone': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo App')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter todo',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: () => _addTodo(_controller.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Dropdown for filtering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<FilterOption>(
              value: _filter,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: FilterOption.all,
                  child: Text('All Tasks'),
                ),
                DropdownMenuItem(
                  value: FilterOption.completed,
                  child: Text('Completed Tasks'),
                ),
                DropdownMenuItem(
                  value: FilterOption.incomplete,
                  child: Text('Incomplete Tasks'),
                ),
              ],
            ),
          ),

          // Todo list section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todos = snapshot.data!.docs.map((doc) {
                  return Todo.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                // Filter based on dropdown
                final filteredTodos = _filter == FilterOption.all
                    ? todos
                    : todos
                        .where((todo) => _filter == FilterOption.completed
                            ? todo.isDone
                            : !todo.isDone)
                        .toList();

                return ListView.builder(
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return ListTile(
                      title: Text(
                        todo.text,
                        style: TextStyle(
                          decoration:
                              todo.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: todo.isDone,
                        onChanged: (_) => _toggleTodo(todo),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTodo(todo.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
