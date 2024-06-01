import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      body: Container(), // Placeholder for future UI components
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
