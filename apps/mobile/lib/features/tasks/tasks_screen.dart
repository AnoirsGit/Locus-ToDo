import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цикл'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: const Center(
        child: Text(
          'Задачи появятся здесь...',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
