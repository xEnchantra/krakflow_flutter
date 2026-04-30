import 'package:flutter/material.dart';
//import 'task_repository.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = "wszystkie";
  String selectedFilter = "wszystkie";

  @override
  Widget build(BuildContext context) {
    int doneCounter = TaskRepository.tasks
        .where((task) => task.done)
        .length;

    List<Task> filteredTasks = TaskRepository.tasks;
    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [IconButton(icon: Icon(Icons.delete), onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Potwierdzenie"),
                  content: Text(
                      "Czy na pewno chcesz usunac wszystkie zadania?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context),
                      child: Text("Anuluj"),
                    ),
                    TextButton(onPressed: () {
                      setState(() {
                        TaskRepository.tasks.clear();
                      });
                      Navigator.pop(context);
                    },
                      child: Text("Usun"),
                    )
                  ],
                );
              }
          );
        })
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Liczba zadan: ${TaskRepository.tasks.length -
                        doneCounter}, zrobiono: ${doneCounter}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Dzisiejsze zadania",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilter = "wszystkie";
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: selectedFilter == "wszystkie"
                              ? Colors.indigoAccent
                              : Colors.grey,
                          textStyle: TextStyle(
                            fontWeight: selectedFilter == "wszystkie"
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        child: Text("Wszystkie"),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilter = "do zrobienia";
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: selectedFilter == "do zrobienia"
                              ? Colors.indigoAccent
                              : Colors.grey,
                          textStyle: TextStyle(
                            fontWeight: selectedFilter == "do zrobienia"
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        child: Text("Do zrobienia"),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilter = "wykonane";
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: selectedFilter == "wykonane"
                              ? Colors.indigoAccent
                              : Colors.grey,
                          textStyle: TextStyle(
                            fontWeight: selectedFilter == "wykonane"
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        child: Text("Wykonane"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Dismissible(
                    key: ValueKey(task.title),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Zadanie usuniete")),
                      );
                    },
                    child: TaskCard(
                      task: task,
                      onChanged: (value) {
                        setState(() {
                          task.done = value!;
                        });
                      },
                      onTap: () async {
                        final Task? updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        );
                        if (updatedTask != null) {
                          setState(() {
                            TaskRepository.tasks[index] = updatedTask;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddTaskScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: task.done, onChanged: onChanged),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: task.done ? Colors.grey : Colors.black,
            ),
            children: [
              TextSpan(text: "termin: ${task.deadline} | priorytet: "),
              TextSpan(
                text: task.priority,
                style: TextStyle(color: task.done ? Colors.grey : Colors.black),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

class TaskRepository {
  static List<Task> tasks = [
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
}

//-------------------------------------------------------------------------

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nowe zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Deadline",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );
                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

//---------------------------------------------------------------------
class EditTaskScreen extends StatelessWidget {
  final Task task;

  late final TextEditingController titleController;
  late final TextEditingController deadlineController;
  late final TextEditingController priorityController;

  EditTaskScreen({super.key, required this.task}) {
    titleController = TextEditingController(text: task.title);
    deadlineController = TextEditingController(text: task.deadline);
    priorityController = TextEditingController(text: task.priority);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edytuj zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytul zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Deadline",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );
                Navigator.pop(context, updatedTask);
              },
              child: Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}
