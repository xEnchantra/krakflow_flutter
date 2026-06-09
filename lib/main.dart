import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'task_repository.dart';
import 'dart:convert';
import 'dart:math' hide log;
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:developer';
import 'services/notification_service.dart';

const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'krakflow_tasks',
      'KrakFlow tasks',
      channelDescription: 'Powiadomienia o zadaniach w aplikacji KrakFlow',
      importance: Importance.high,
      priority: Priority.high,
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  runApp(MyApp());
}

class TaskApiService {
  static Future<List<Task>> fetchTasks() async {
    final url = "https://dummyjson.com/todos";
    final response = await http.get(Uri.parse(url));

    log("Adres zapytania: $url", name: "TaskApiService");
    log("Kod odpowiedzi HTTP: ${response.statusCode}", name: "TaskApiService");

    if (response.statusCode == 200) {
      final data = jsonDecode((response.body));
      final List todos = data["todos"];

      log("Pobrano zadan: ${todos.length}", name: "TaskApiService");

      return todos.map((todo) {
        return Task(
          id: todo["id"],
          title: todo["todo"],
          deadline: "brak",
          done: todo["completed"],
          priority: "sredni",
        );
      }).toList();
    } else {
      log("Nie udalo sie pobrac zadan", name: "TaskApiService", error: "Status odpowiedzi inny niz 200");
      throw Exception("Blad pobierania danych");
    }
  }
}

class TaskLocalDatabase {
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    return _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();
    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
    log("Dodano zadanie", name: "TaskLocalDatabase");
  }

  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
    log("Edytowanie zadanie / zmieniono status", name: "TaskLocalDatabase");
  }

  static Future<void> deleteTask(int id) async {
    await _box.delete(id);
    log("Usunieto zadanie", name: "TaskLocalDatabase");
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
    log("Usunieto wszystkie zadania", name: "TaskLocalDatabase");
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}

class TaskSyncService {
  static Future<void> loadInitialDataIfNeeded() async {
    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }
    final tasks = await TaskApiService.fetchTasks();
    await TaskLocalDatabase.saveTasks(tasks);
  }
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
  String selectedFilter = "wszystkie";
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = _loadTasks();
  }

  Future<List<Task>> _loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
    }

  @override
  Widget build(BuildContext context) {
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
                    TextButton(onPressed: () async {
                      await TaskLocalDatabase.deleteAllTasks();
                      setState(() {
                        tasksFuture = _loadTasks();
                      });
                      if(context.mounted) Navigator.pop(context);
                      },
                      child: Text("Usun"),
                    )
                  ],
                );
              },
            );
          },
        )
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Blad: ${snapshot.error}"));
          }

          final tasks = snapshot.data ?? [];
          int doneCounter = tasks.where((task) => task.done).length;
          List<Task> filteredTasks = tasks;

          if (selectedFilter == "wykonane") {
            filteredTasks = tasks.where((task) => task.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks = tasks.where((task) => !task.done).toList();
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Liczba zadan: ${tasks.length -
                            doneCounter}, zrobiono: $doneCounter",
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
                            onPressed: () => setState(() => selectedFilter = "wszystkie"),
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
                            onPressed: () => setState(() => selectedFilter = "do zrobienia"),
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
                            onPressed: () => setState(() => selectedFilter = "wykonane"),
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
                        key: ValueKey(task.id),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) async {
                          setState(() {
                            tasksFuture = _loadTasks();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Zadanie usuniete")),
                          );
                        },
                        child: TaskCard(
                          task: task,
                          onChanged: (value) async {
                            final isDone = value ?? false;
                            final wasDone = task.done;

                            final updatedTask = Task(
                              id: task.id,
                              title: task.title,
                              deadline: task.deadline,
                              priority: task.priority,
                              done: isDone,
                            );
                            await TaskLocalDatabase.updateTask(updatedTask);

                            if (!wasDone && isDone) {
                              await NotificationService.showTaskDoneNotification(task.title);
                            }

                            setState(() {
                              tasksFuture = _loadTasks();
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
                              await TaskLocalDatabase.updateTask(updatedTask);
                              setState(() {
                                tasksFuture = _loadTasks();
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
          );
        }
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
            await TaskLocalDatabase.addTask(newTask);
            setState(() {
              tasksFuture = _loadTasks();
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  final int id;
  final String title;
  final String deadline;
  bool done;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "priority": priority,
      "done": done,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      priority: map["priority"],
      done: map["done"],
    );
  }
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
                  id: Random().nextInt(1000000),
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
                  id: task.id,
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
