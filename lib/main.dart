// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List CRUD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoListScreen(),
    );
  }
}

// Model untuk Task
class Task {
  String id;
  String title;
  String description;
  String category;
  bool isCompleted;
  DateTime createdAt;
  List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Umum',
    this.isCompleted = false,
    required this.createdAt,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'subTasks': subTasks.map((st) => st.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'Umum',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      subTasks: (json['subTasks'] as List?)
          ?.map((st) => SubTask.fromJson(st))
          .toList() ?? [],
    );
  }
}

// Model untuk SubTask
class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

// Service untuk menyimpan data
class TodoService {
  static const String _key = 'todo_tasks';
  static const String _categoriesKey = 'todo_categories';

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_key);
    if (tasksJson == null) return [];

    final List<dynamic> tasksList = json.decode(tasksJson);
    return tasksList.map((task) => Task.fromJson(task)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_key, tasksJson);
  }

  static Future<List<String>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? ['Umum', 'Sekolah', 'Belanja', 'Deadline'];
  }

  static Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }
}

// Main Screen
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Task> tasks = [];
  List<String> categories = [];
  String selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedTasks = await TodoService.loadTasks();
    final loadedCategories = await TodoService.loadCategories();
    setState(() {
      tasks = loadedTasks;
      categories = ['Semua'] + loadedCategories;
    });
  }

  Future<void> _saveTasks() async {
    await TodoService.saveTasks(tasks);
  }

  List<Task> get filteredTasks {
    if (selectedCategory == 'Semua') {
      return tasks;
    }
    return tasks.where((task) => task.category == selectedCategory).toList();
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AddEditTaskDialog(
        categories: categories.where((c) => c != 'Semua').toList(),
        onSave: (task) {
          setState(() {
            tasks.add(task);
          });
          _saveTasks();
        },
      ),
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AddEditTaskDialog(
        task: task,
        categories: categories.where((c) => c != 'Semua').toList(),
        onSave: (updatedTask) {
          setState(() {
            final index = tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              tasks[index] = updatedTask;
            }
          });
          _saveTasks();
        },
      ),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Task'),
        content: Text('Yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasks.removeWhere((t) => t.id == task.id);
              });
              _saveTasks();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleTaskComplete(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      // Ketika task dicentang, semua subtask ikut tercentang
      // Ketika task di-uncheck, semua subtask ikut di-uncheck
      for (var subTask in task.subTasks) {
        subTask.isCompleted = task.isCompleted;
      }
    });
    _saveTasks();
  }

  void _toggleSubTaskComplete(Task task, SubTask subTask) {
    setState(() {
      subTask.isCompleted = !subTask.isCompleted;
      
      // Auto-update status task utama berdasarkan subtask
      if (task.subTasks.isNotEmpty) {
        // Jika semua subtask selesai, maka task utama juga selesai
        bool allSubTasksCompleted = task.subTasks.every((st) => st.isCompleted);
        // Jika ada subtask yang belum selesai, maka task utama belum selesai
        bool anySubTaskIncomplete = task.subTasks.any((st) => !st.isCompleted);
        
        if (allSubTasksCompleted) {
          task.isCompleted = true;
        } else if (anySubTaskIncomplete && task.isCompleted) {
          task.isCompleted = false;
        }
      }
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List CRUD'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
            itemBuilder: (context) {
              return categories.map((category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        selectedCategory == category 
                            ? Icons.check_circle 
                            : Icons.circle_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedCategory),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada task',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tap + untuk menambah task baru',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return TaskCard(
                  task: task,
                  onToggleComplete: () => _toggleTaskComplete(task),
                  onToggleSubTaskComplete: (subTask) => _toggleSubTaskComplete(task, subTask),
                  onEdit: () => _editTask(task),
                  onDelete: () => _deleteTask(task),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget untuk Task Card
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final Function(SubTask) onToggleSubTaskComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onToggleSubTaskComplete,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  // Fungsi untuk mengecek status checkbox task utama
  bool? getTaskCheckboxState() {
    if (task.subTasks.isEmpty) {
      return task.isCompleted;
    }
    
    bool allCompleted = task.subTasks.every((st) => st.isCompleted);
    bool noneCompleted = task.subTasks.every((st) => !st.isCompleted);
    
    if (allCompleted) {
      return true;
    } else if (noneCompleted && !task.isCompleted) {
      return false;
    } else {
      return null; // Indeterminate state (sebagian subtask selesai)
    }
  }

  @override
  Widget build(BuildContext context) {
    bool? checkboxState = getTaskCheckboxState();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        leading: Checkbox(
          value: checkboxState,
          tristate: true,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: checkboxState == true ? TextDecoration.lineThrough : null,
            color: checkboxState == true ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  color: checkboxState == true ? Colors.grey : Colors.black54,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
        children: [
          if (task.subTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subtask:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  ...task.subTasks.map((subtask) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: subtask.isCompleted,
                      title: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          color: subtask.isCompleted ? Colors.grey : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (value) {
                        onToggleSubTaskComplete(subtask);
                      },
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Dialog untuk Add/Edit Task
class AddEditTaskDialog extends StatefulWidget {
  final Task? task;
  final List<String> categories;
  final Function(Task) onSave;

  const AddEditTaskDialog({
    Key? key,
    this.task,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  List<SubTask> _subTasks = [];
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedCategory = widget.task?.category ?? widget.categories.first;
    _subTasks = widget.task?.subTasks ?? [];
  }

  void _addSubTask() {
    if (_subTaskController.text.trim().isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _subTaskController.text.trim(),
        ));
        _subTaskController.clear();
      });
    }
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul task tidak boleh kosong!')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      isCompleted: widget.task?.isCompleted ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      subTasks: _subTasks,
    );

    widget.onSave(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Tambah Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Task',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subtask:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah subtask',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addSubTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSubTask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              return ListTile(
                dense: true,
                title: Text(subtask.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeSubTask(index),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }
}