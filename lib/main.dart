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
      title: 'To-Do & Notes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
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

// Model untuk Note
class Note {
  String id;
  String title;
  String content;
  String category;
  DateTime createdAt;
  DateTime updatedAt;
  Color color;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Personal',
    required this.createdAt,
    DateTime? updatedAt,
    this.color = Colors.yellow,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'color': color.value,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'] ?? 'Personal',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      color: Color(json['color'] ?? Colors.yellow.value),
    );
  }
}

// Service untuk menyimpan data
class DataService {
  static const String _tasksKey = 'todo_tasks';
  static const String _notesKey = 'notes';
  static const String _categoriesKey = 'todo_categories';
  static const String _noteCategoriesKey = 'note_categories';

  // Tasks
  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) return [];

    final List<dynamic> tasksList = json.decode(tasksJson);
    return tasksList.map((task) => Task.fromJson(task)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }

  // Notes
  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString(_notesKey);
    if (notesJson == null) return [];

    final List<dynamic> notesList = json.decode(notesJson);
    return notesList.map((note) => Note.fromJson(note)).toList();
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final String notesJson = json.encode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);
  }

  // Categories
  static Future<List<String>> loadTaskCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? ['Umum', 'Sekolah', 'Belanja', 'Deadline'];
  }

  static Future<List<String>> loadNoteCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_noteCategoriesKey) ?? ['Personal', 'Kerja', 'Ide', 'Catatan'];
  }
}

// Main Screen dengan BottomNavigationBar
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _titles = ['To-Do List', 'My Notes'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _currentIndex == 0 ? 'Cari task...' : 'Cari note...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodoListScreen(searchQuery: _searchQuery),
          NotesScreen(searchQuery: _searchQuery),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Clear search when switching tabs
            _searchController.clear();
            _searchQuery = '';
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'To-Do',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Todo List Screen
class TodoListScreen extends StatefulWidget {
  final String searchQuery;
  
  const TodoListScreen({Key? key, required this.searchQuery}) : super(key: key);

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
    final loadedTasks = await DataService.loadTasks();
    final loadedCategories = await DataService.loadTaskCategories();
    setState(() {
      tasks = loadedTasks;
      categories = ['Semua'] + loadedCategories;
    });
  }

  Future<void> _saveTasks() async {
    await DataService.saveTasks(tasks);
  }

  List<Task> get filteredTasks {
    var filtered = tasks;
    
    // Filter by category
    if (selectedCategory != 'Semua') {
      filtered = filtered.where((task) => task.category == selectedCategory).toList();
    }
    
    // Filter by search query
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((task) =>
          task.title.toLowerCase().contains(widget.searchQuery) ||
          task.description.toLowerCase().contains(widget.searchQuery) ||
          task.category.toLowerCase().contains(widget.searchQuery) ||
          task.subTasks.any((subtask) => 
              subtask.title.toLowerCase().contains(widget.searchQuery))).toList();
    }
    
    return filtered;
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
      for (var subTask in task.subTasks) {
        subTask.isCompleted = task.isCompleted;
      }
    });
    _saveTasks();
  }

  void _toggleSubTaskComplete(Task task, SubTask subTask) {
    setState(() {
      subTask.isCompleted = !subTask.isCompleted;
      
      if (task.subTasks.isNotEmpty) {
        bool allSubTasksCompleted = task.subTasks.every((st) => st.isCompleted);
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
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Tasks List
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          widget.searchQuery.isNotEmpty
                              ? 'Tidak ada task yang cocok'
                              : 'Belum ada task',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (widget.searchQuery.isEmpty)
                          Text(
                            'Tap + untuk menambah task baru',
                            style: TextStyle(color: Colors.grey[500]),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Notes Screen
class NotesScreen extends StatefulWidget {
  final String searchQuery;
  
  const NotesScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  List<String> categories = [];
  String selectedCategory = 'Semua';
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedNotes = await DataService.loadNotes();
    final loadedCategories = await DataService.loadNoteCategories();
    setState(() {
      notes = loadedNotes;
      categories = ['Semua'] + loadedCategories;
    });
  }

  Future<void> _saveNotes() async {
    await DataService.saveNotes(notes);
  }

  List<Note> get filteredNotes {
    var filtered = notes;
    
    // Filter by category
    if (selectedCategory != 'Semua') {
      filtered = filtered.where((note) => note.category == selectedCategory).toList();
    }
    
    // Filter by search query
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((note) =>
          note.title.toLowerCase().contains(widget.searchQuery) ||
          note.content.toLowerCase().contains(widget.searchQuery) ||
          note.category.toLowerCase().contains(widget.searchQuery)).toList();
    }
    
    // Sort by updated date (newest first)
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return filtered;
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) => AddEditNoteDialog(
        categories: categories.where((c) => c != 'Semua').toList(),
        onSave: (note) {
          setState(() {
            notes.add(note);
          });
          _saveNotes();
        },
      ),
    );
  }

  void _editNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AddEditNoteDialog(
        note: note,
        categories: categories.where((c) => c != 'Semua').toList(),
        onSave: (updatedNote) {
          setState(() {
            final index = notes.indexWhere((n) => n.id == note.id);
            if (index != -1) {
              notes[index] = updatedNote;
            }
          });
          _saveNotes();
        },
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Note'),
        content: Text('Yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notes.removeWhere((n) => n.id == note.id);
              });
              _saveNotes();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Category Filter & View Toggle
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                ),
              ],
            ),
          ),
          // Notes List/Grid
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          widget.searchQuery.isNotEmpty
                              ? 'Tidak ada note yang cocok'
                              : 'Belum ada note',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (widget.searchQuery.isEmpty)
                          Text(
                            'Tap + untuk menambah note baru',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  )
                : isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return NoteGridCard(
                            note: note,
                            onTap: () => _editNote(note),
                            onDelete: () => _deleteNote(note),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return NoteListCard(
                            note: note,
                            onTap: () => _editNote(note),
                            onDelete: () => _deleteNote(note),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget untuk Task Card (sama seperti sebelumnya)
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
      return null;
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

// Widget untuk Note List Card
class NoteListCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteListCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: note.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  '${note.updatedAt.day}/${note.updatedAt.month}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Widget untuk Note Grid Card
class NoteGridCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteGridCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: note.color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.category,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog untuk Add/Edit Task (sama seperti sebelumnya)
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
    _subTasks = List.from(widget.task?.subTasks ?? []);
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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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

// Dialog untuk Add/Edit Note
class AddEditNoteDialog extends StatefulWidget {
  final Note? note;
  final List<String> categories;
  final Function(Note) onSave;

  const AddEditNoteDialog({
    Key? key,
    this.note,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  late Color _selectedColor;

  final List<Color> noteColors = [
    Colors.yellow,
    Colors.orange,
    Colors.pink.shade200,
    Colors.purple.shade200,
    Colors.blue.shade200,
    Colors.green.shade200,
    Colors.teal.shade200,
    Colors.grey.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedCategory = widget.note?.category ?? widget.categories.first;
    _selectedColor = widget.note?.color ?? Colors.yellow;
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul note tidak boleh kosong!')),
      );
      return;
    }

    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      color: _selectedColor,
    );

    widget.onSave(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Tambah Note' : 'Edit Note'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi Note',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
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
                  'Warna Note:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: noteColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.black54)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
    _contentController.dispose();
    super.dispose();
  }
}