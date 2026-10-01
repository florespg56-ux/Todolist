import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'person.dart';
import 'boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(PersonAdapter());

  boxPersons = await Hive.openBox<Person>('personBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hive To-Do List',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pink,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  int selectedIndex = -1;

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // Pick a date
  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text =
            '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}';
      });
    }
  }

  // Add or Update
  void saveTask() {
    if (titleController.text.isEmpty || dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and date'),
        ),
      );
      return;
    }

    setState(() {
      if (selectedIndex == -1) {
        // CREATE
        boxPersons.add(
          Person(
            name: titleController.text,
            age: int.tryParse(
                  dateController.text.replaceAll('/', ''),
                ) ??
                0,
          ),
        );
      } else {
        // UPDATE
        boxPersons.putAt(
          selectedIndex,
          Person(
            name: titleController.text,
            age: int.tryParse(
                  dateController.text.replaceAll('/', ''),
                ) ??
                0,
          ),
        );

        selectedIndex = -1;
      }

      titleController.clear();
      dateController.clear();
    });
  }

  // Edit task
  void editTask(int index) {
    Person person = boxPersons.getAt(index)!;

    setState(() {
      selectedIndex = index;
      titleController.text = person.name;

      // Display stored value as date
      dateController.text = person.age.toString();
    });
  }

  // Delete task
  void deleteTask(int index) {
    setState(() {
      boxPersons.deleteAt(index);

      if (selectedIndex == index) {
        selectedIndex = -1;
        titleController.clear();
        dateController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 228, 122, 136),

      appBar: AppBar(
        title: const Text('My To-Do List'),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // FORM
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Task Title',
                        prefixIcon: Icon(Icons.task),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: selectDate,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Task Date',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: saveTask,
                      child: Text(
                        selectedIndex == -1
                            ? 'Add Task'
                            : 'Update Task',
                      ),
                    ),

                    if (selectedIndex != -1)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedIndex = -1;
                            titleController.clear();
                            dateController.clear();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // TODO LIST
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                child: ListView.builder(
                  itemCount: boxPersons.length,
                  itemBuilder: (context, index) {
                    Person person = boxPersons.getAt(index)!;

                    return Dismissible(
                      key: Key(index.toString()),

                      direction: DismissDirection.endToStart,

                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),

                      onDismissed: (direction) {
                        deleteTask(index);
                      },

                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.check),
                        ),

                        title: Text(
                          person.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          'Date: ${person.age}',
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.purple,
                          ),
                          onPressed: () {
                            editTask(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(()  {
                boxPersons.clear();
              });
              
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete All'),
            )
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            selectedIndex = -1;
            titleController.clear();
            dateController.clear();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
