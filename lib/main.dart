import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: MyTasksPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyTasksPage extends StatefulWidget {
  @override
  _MyTasksPageState createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  List<Task> tasks = [];
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final List<dynamic> tasksJson = jsonDecode(tasksString);
    setState(() {
      tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    prefs.setString('tasks', jsonEncode(tasksJson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: const Color.fromARGB(255, 233, 222, 140),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              TaskFilter(
                onFilterChanged: (newFilter) {
                  setState(() {
                    filter = newFilter;
                  });
                },
              ),
              Expanded(
                child: TaskList(
                  tasks: _getFilteredTasks(),
                  onUpdate: () async {
                    setState(() {});
                    await _saveTasks();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color.fromARGB(255, 233, 233, 233),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Task> _getFilteredTasks() {
    if (filter == 'All') {
      return tasks;
    } else if (filter == 'Pending') {
      return tasks.where((task) => !task.isCompleted).toList();
    } else if (filter == 'Complete') {
      return tasks.where((task) => task.isCompleted).toList();
    } else {
      return tasks
          .where(
              (task) => !task.isCompleted && task.date.isBefore(DateTime.now()))
          .toList();
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          onTaskAdded: (task) async {
            setState(() {
              tasks.add(task);
            });
            await _saveTasks();
          },
        );
      },
    );
  }
}

class Task {
  String title;
  DateTime date;
  bool isCompleted;

  Task(this.title, this.date, this.isCompleted);

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      DateTime.parse(json['date']),
      json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function onUpdate;

  TaskList({required this.tasks, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? Colors.green.withOpacity(0.8)
                  : Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!task.isCompleted)
                        const Icon(Icons.access_time, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM d, yyyy').format(task.date),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (!task.isCompleted)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: () async {
                        task.isCompleted = !task.isCompleted;
                        onUpdate();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditTaskDialog(context, task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () async {
                      tasks.remove(task);
                      onUpdate();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          task: task,
          onTaskUpdated: (updatedTask) async {
            task.title = updatedTask.title;
            task.date = updatedTask.date;
            task.isCompleted = updatedTask.isCompleted;
            onUpdate();
          },
        );
      },
    );
  }
}

class TaskFilter extends StatelessWidget {
  final Function(String) onFilterChanged;

  TaskFilter({required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterChip('All', Icons.filter_list),
          _buildFilterChip('Pending', Icons.access_time),
          _buildFilterChip('Complete', Icons.done),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      onSelected: (isSelected) {
        onFilterChanged(label);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.amber[800],
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(Task)? onTaskAdded;
  final Function(Task)? onTaskUpdated;
  final Task? task;

  AddTaskDialog({this.onTaskAdded, this.onTaskUpdated, this.task});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _taskTitle;
  late DateTime _taskDate;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _taskTitle = widget.task!.title;
      _taskDate = widget.task!.date;
    } else {
      _taskTitle = '';
      _taskDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF4E342E),
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task',
          style: const TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _taskTitle,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              onSaved: (value) {
                _taskTitle = value!;
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _taskDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    _taskDate = picked;
                  });
                }
              },
              controller: TextEditingController(
                text: DateFormat('MMMM d, yyyy').format(_taskDate),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              if (widget.onTaskAdded != null) {
                widget.onTaskAdded!(Task(_taskTitle, _taskDate, false));
              } else if (widget.onTaskUpdated != null) {
                widget.onTaskUpdated!(
                    Task(_taskTitle, _taskDate, widget.task!.isCompleted));
              }
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.task == null ? 'Add' : 'Update',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
