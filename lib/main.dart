import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  List<Task> tasks = [
    Task(
      title: "Wyjsc z psem",
      deadline: "o 12",
      done: true,
      priority: "wysoki",
    ),
    Task(
      title: "Umyc podlogi",
      deadline: "po salonie",
      done: false,
      priority: "niski",
    ),
    Task(
      title: "Posprzatac salon",
      deadline: "do 15",
      done: false,
      priority: "sredni",
    ),
    Task(
      title: "Zrobic zakupy",
      deadline: "do 10",
      done: true,
      priority: "wysoki",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    int doneCounter = tasks.where((task) => task.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("KrakFlow")),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      "Liczba zadan: ${tasks.length}, zrobiono: ${doneCounter}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Dzisiejsze zadania",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      title: tasks[index].title,
                      subtitle: "termin: ${tasks[index].deadline} | priorytet: ${tasks[index].priority}",
                      icon: tasks[index].done ? Icons.check_circle : Icons.radio_button_unchecked,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
